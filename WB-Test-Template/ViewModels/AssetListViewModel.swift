import Foundation
import Combine
import CoreData

@MainActor
class AssetListViewModel: ObservableObject {
	@Published var assets: [Asset] = [] {
		didSet {
			applyFilters() // If `assets` value changes, the derived value of `filteredAssets` should be updated due to new data (filter and favourites are private, already do this side-effect via functions) TODO: this isn't idiomatic reactive, there's a better way to do it with modern Swift
		}
	}
    @Published private(set) var filteredAssets: [Asset] = [] // Changed to private(set) so that there's no danger of this property being mutated from outside
    @Published var isLoading = false
    @Published var error: String?
    
    private var showFavoritesOnly = false
    private var searchText = ""
	
	private var networkCancellables = Set<AnyCancellable>()
	
    func loadAssets(context: NSManagedObjectContext) async {
        isLoading = true
		
		// If we have cached data, provide that immediately.
		let cachedAssets = fetchCachedAssets(from: context)
		if !cachedAssets.isEmpty {
			self.assets = cachedAssets
		}
		
		// Now attempt to fetch from network. This may fail, or take a long time.
		NetworkService.shared.fetchAssetsData()
			.receive(on: DispatchQueue.main)
			.sink(receiveCompletion: { [weak self] completion in
				guard let self else { return }
				self.isLoading = false
				if case .failure(let error) = completion { // We don't need a switch, as we only care about the failure case here
					self.error = error.localizedDescription
				}
			}, receiveValue: { [weak self] data in
				guard let self else { return }
				do {
					self.assets = try Asset.tryToDecodeArray(from: data)
					self.saveAssetsToCoreData(assets: self.assets, context: context) // It looks like the API would return *everything*? If it doesn't, then this would need to be changed so that it merges diff of new content rather than replacing everything
				} catch {
					self.error = error.localizedDescription
				}
			})
			.store(in: &networkCancellables)
    }
    
    func filterAssets(searchText: String) {
        self.searchText = searchText
        applyFilters()
    }
    
    func toggleFavoritesFilter(_ showFavorites: Bool) {
        showFavoritesOnly = showFavorites
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
}

// MARK: - CoreData

extension AssetListViewModel {
	func fetchCachedAssets(from context: NSManagedObjectContext) -> [Asset] {
		let fetchRequest: NSFetchRequest<AssetEntity> = AssetEntity.fetchRequest()
		
		do {
			return try context.fetch(fetchRequest).compactMap { Asset.init(from: $0) }
		} catch {
			print("Failed to fetch cached assets: \(error.localizedDescription)")
			return []
		}
	}
	
	func saveAssetsToCoreData(assets: [Asset], context: NSManagedObjectContext) {
		context.performAndWait {
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
				let assetArray = try context.fetch(existingAssetsSearch)
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
					managedObject = AssetEntity(context: context)
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
			}
			
			do {
				try context.save()
			} catch {
				print("Failed to save assets to Core Data: \(error.localizedDescription)")
			}
		}
	}
}
