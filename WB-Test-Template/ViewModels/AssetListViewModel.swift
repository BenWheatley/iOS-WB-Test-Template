import Foundation
import Combine
import CoreData

@MainActor
class AssetListViewModel: ObservableObject {
	@Published var assets: [Asset] = [] {
		didSet {
			applyFilters() // If `assets` value changes, the derived value of `filteredAssets` should be updated due to new data (filter and favourites are private, already do this side-effect via functions)
		}
	}
    @Published private(set) var filteredAssets: [Asset] = [] // Changed to private(set) so that there's no danger of this property being mutated from outside
    @Published var isLoading = false
    @Published var error: String?
	@Published var offline: Bool = false
    
	@Published var showFavoritesOnly: Bool = false {
		didSet {
			applyFilters()
			saveAppState()
		}
	}
	
	@Published var searchText: String = "" {
		didSet {
			applyFilters()
			saveAppState()
		}
	}
	
	let context: NSManagedObjectContext
	
	init(context: NSManagedObjectContext) {
		self.context = context
	}
	
	private var networkCancellables = Set<AnyCancellable>()
	
	/// Used to prevent conflict between save and load of app state; I could also have made this it's own type so that saving and loading are atomic
	private var supressSaveAppState: Bool = false
	
	func fetchAppState() {
		supressSaveAppState = true
		let fetchRequest: NSFetchRequest<AppState> = AppState.fetchRequest()
		fetchRequest.fetchLimit = 1
		if let appState = try? context.fetch(fetchRequest).first {
			showFavoritesOnly = appState.showFavoritesOnly
			searchText = appState.searchText ?? ""
		}
		supressSaveAppState = false
	}
	
	func saveAppState() {
		guard !supressSaveAppState else { return }
		
		let fetchRequest: NSFetchRequest<AppState> = AppState.fetchRequest()
		fetchRequest.fetchLimit = 1
		let appState = (try? context.fetch(fetchRequest).first) ?? AppState(context: context)
		
		appState.searchText = searchText
		appState.showFavoritesOnly = showFavoritesOnly
		
		do {
			try context.save()
		} catch {
			print("Failed to save app state: \(error)")
		}
	}
	
    func loadAssets() async {
		// potential race condition of this is called twice, so use the (already present, originally added for UI task) `isLoading` flag to also prevent that
		guard !isLoading else { return }
		
		isLoading = true
		
		// If we have cached data, provide that immediately.
		reloadCoreData()
		
		// Now attempt to fetch from network. This may fail, or take a long time.
		NetworkService.shared.fetchAssetsData()
			.sink(receiveCompletion: { [weak self] completion in
				guard let self else { return }
				DispatchQueue.main.sync { self.isLoading = false }
				if case .failure(let error) = completion { // We don't need a switch, as we only care about the failure case here
					offline = (error as? NetworkError) == NetworkError.offline
					self.error = error.localizedDescription
				}
			}, receiveValue: { [weak self] data in
				guard let self else { return }
				DispatchQueue.main.sync { self.offline = false }
				do {
					var decodedAssets = try Asset.tryToDecodeArray(from: data)
					
					// New asset values should update existing content, but not delete it: deleting the content will remove isFav and lastCache values:
					// This would be simpler if the DTO was also the CoreData model
					
					let currentAssetsDictionary = Dictionary(uniqueKeysWithValues: self.assets.map { ($0.assetId, $0) }) // For efficiency — if I did this with arrays, it would be O(n^2) most of the time, and n is large enough that I expect this to be noticable
					
					// Note: I'm assuming assets never get de-listed — this may be a false assumption, but considerations for this possibility appear to be beyond the scope of the task document
					for index in decodedAssets.indices {
						var asset = decodedAssets[index]
						guard let correspondingAsset = currentAssetsDictionary[asset.assetId] else { continue }
						asset.performCacheUpdate(using: correspondingAsset)
						decodedAssets[index] = asset
					}
					
					DispatchQueue.main.sync { self.assets = decodedAssets }
					self.saveAssetsToCoreData(assets: self.assets) // It looks like the API would return *everything*? If it doesn't, then this would need to be changed so that it merges diff of new content rather than replacing everything
				} catch {
					self.error = error.localizedDescription
				}
			})
			.store(in: &networkCancellables)
    }
    
    func toggleFavouriteStatus(for asset: Asset) {
		// This is necessary because `Asset` is a `struct`, so it's being passed around by value not by reference; we could change this to a `class` and then this part becomes `asset.isFavourite.toggle()`
		guard let index = assets.firstIndex(where: { $0.assetId == asset.assetId }) else {
			return
		}
		
		// Note: we could instead toggle assetEntity.isFavorite in the if-let below, then reload everything from CoreData. CoreData is fast, but not fast enough for that, and also the UI flow has no considerations for this (and fixing that is out of scope) so it would look worse to no advantage.
		assets[index].isFavorite.toggle()
		
		// Persist the change to Core Data
		if let assetEntity = fetchAssetEntity(by: asset.assetId) {
			assetEntity.isFavorite = assets[index].isFavorite
			CoreDataStack.shared.save()
		}
		
		applyFilters()
	}
    
    private func applyFilters() {
        filteredAssets = assets.filter { asset in
            let matchesSearch = searchText.isEmpty || 
                (asset.name?.localizedCaseInsensitiveContains(searchText) == true) ||
                asset.assetId.localizedCaseInsensitiveContains(searchText)
            
            let matchesFavorites = !showFavoritesOnly || asset.isFavorite
            
            return matchesSearch && matchesFavorites
        }
    }
	
	private func reloadCoreData() {
		// Note: The order of results returned by CoreData has no relation to what was provided by the API response, but doing anything about that is outside the scope of the task requirements
		let cachedAssets = fetchCachedAssets()
		if !cachedAssets.isEmpty {
			self.assets = cachedAssets
		}
	}
	
	// This could also be inlined as I'm only using it one place, but feels like the kind of thing that I would expect to be re-used when considering architectural-level decisions. The actual task requirements neither require nor implicitly argue against doing it as a separate function.
	private func fetchAssetEntity(by assetId: String) -> AssetEntity? {
		let fetchRequest: NSFetchRequest<AssetEntity> = AssetEntity.fetchRequest()
		fetchRequest.predicate = NSPredicate(format: "assetId == %@", assetId)
		fetchRequest.fetchLimit = 1
		
		do {
			let results = try context.fetch(fetchRequest)
			return results.first
		} catch {
			debugPrint("Error fetching AssetEntity (id=\(assetId)) from CoreData: \(error.localizedDescription)")
			return nil
		}
	}
	
	func fetchCachedAssets() -> [Asset] {
		let fetchRequest: NSFetchRequest<AssetEntity> = AssetEntity.fetchRequest()
		
		do {
			return try context.fetch(fetchRequest).compactMap { Asset.init(from: $0) }
		} catch {
			print("Failed to fetch cached assets: \(error.localizedDescription)")
			return []
		}
	}
	
	func saveAssetsToCoreData(assets: [Asset]) {
		context.perform { [weak self] in
			guard let self else { return }
			/*
			 Fetch existing, or create new, `managedObject: AssetEntity`
			 
			 Naive solution would search for asset by ID within the `for … in` loop, but that's:
			 - O(n^2) for the first run (where n=assets.count)
			 – O(m) for adding one single new Asset later (where m = how many assets are already in CoreData)
			 
			 So make this more complex but bring it out of the loop.
			 */
			
			// 1. Predicate matching all CoreData values that match any assetId from argument
			let assetIds = Set(assets.compactMap { $0.assetId })
			let existingAssetsSearch = AssetEntity.fetchRequest()
			existingAssetsSearch.predicate = NSPredicate(format: "assetId IN %@", assetIds)
			
			// 2. Fetch all those assets from CoreData (dictionary for faster lookup)
			var existingAssets: [String: AssetEntity] = [:]
			do {
				let assetArray = try self.context.fetch(existingAssetsSearch)
				for asset in assetArray {
					// I'm not clear why, but despite the Optional flag being off in the CoreData inspector, this is being treated as if it was optional. Can't figure out how to fix that. If I can, this becomes much simpler.
					guard let assetId = asset.assetId else {
						// We've already got a compactMap so this should never happen in practice, but just in case someone changes that and this breaks, log it
						debugPrint("Alert: We seem to have an asset with a nil ID coming from CoreData, this shouldn't happen")
						continue
					}
					existingAssets[assetId] = asset
				}
			} catch {
				debugPrint("Error when attempting to fetch existing assets: \(error.localizedDescription)")
			}
			
			for asset in assets {
				let managedObject: AssetEntity
				if let existingAsset = existingAssets[asset.assetId] {
					managedObject = existingAsset
				} else {
					managedObject = AssetEntity(context: self.context)
					managedObject.assetId = asset.assetId // If it's new, we need to set the assetId, otherwise we don't.
				}
				
				managedObject.name = asset.name
				managedObject.typeIsCrypto = asset.typeIsCrypto
				managedObject.dataQuoteStart = asset.dataQuoteStart
				managedObject.dataQuoteEnd = asset.dataQuoteEnd
				managedObject.dataOrderbookStart = asset.dataOrderbookStart
				managedObject.dataOrderbookEnd = asset.dataOrderbookEnd
				managedObject.dataTradeStart = asset.dataTradeStart
				managedObject.dataTradeEnd = asset.dataTradeEnd
				
				// This weirdness because CoreData uses Optional<NSNumber> and the API is giving me Optional<Int64> etc.
				// (It's a compact way of saying "if foo is nil return nil, otherwise map foo")
				managedObject.dataSymbolsCount = asset.dataSymbolsCount.map(NSNumber.init(value:)) ?? nil
				managedObject.volume1HrsUsd = asset.volume1HrsUsd.map(NSNumber.init(value:)) ?? nil
				managedObject.volume1DayUsd = asset.volume1DayUsd.map(NSNumber.init(value:)) ?? nil
				managedObject.volume1MthUsd = asset.volume1MthUsd.map(NSNumber.init(value:)) ?? nil
				managedObject.priceUsd = asset.priceUsd.map(NSNumber.init(value:)) ?? nil
				
				managedObject.isFavorite = asset.isFavorite
				
				managedObject.cacheLastUpdated = asset.lastFetched ?? .now
			}
			
			CoreDataStack.shared.save()
		}
	}
}
