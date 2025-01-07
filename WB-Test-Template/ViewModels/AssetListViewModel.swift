import Foundation

@MainActor
class AssetListViewModel: ObservableObject {
    @Published var assets: [Asset] = []
    @Published var filteredAssets: [Asset] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private var showFavoritesOnly = false
    private var searchText = ""
    
    func loadAssets() async {
        isLoading = true
        DispatchQueue.main.async { [weak self] in
            Task {
                do {
                    self?.assets = try await NetworkService.shared.fetchAssets()
                    self?.filterAssets(searchText: self?.searchText ?? "")
                } catch {
                    self?.error = error.localizedDescription
                }
                self?.isLoading = false
            }
        }
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
                asset.name.localizedCaseInsensitiveContains(searchText) ||
                asset.assetId.localizedCaseInsensitiveContains(searchText)
            
            let matchesFavorites = !showFavoritesOnly || asset.isFavorite
            
            return matchesSearch && matchesFavorites
        }
    }
}
