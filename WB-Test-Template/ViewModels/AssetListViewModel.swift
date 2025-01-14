import Foundation
import Combine

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
    
    func loadAssets() async {
        isLoading = true
		
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
					self.filterAssets(searchText: self.searchText)
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
