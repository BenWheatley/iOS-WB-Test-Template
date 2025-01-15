import SwiftUI

struct AssetListView: View {
	@Environment(\.managedObjectContext) private var viewContext
	
	@StateObject private var viewModel = AssetListViewModel()
    @State private var searchText = ""
    @State private var showFavoritesOnly = false
	
	var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.filteredAssets) { asset in
                    NavigationLink(destination: AssetDetailView(asset: asset)) {
                        AssetRowView(asset: asset)
                    }
                }
            }
            .searchable(text: $searchText)
            .onChange(of: searchText) { _ in
                viewModel.filterAssets(searchText: searchText)
            }
            .navigationTitle("Crypto Monitor")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showFavoritesOnly.toggle()
                        viewModel.toggleFavoritesFilter(showFavoritesOnly)
                    }) {
                        Image(systemName: showFavoritesOnly ? "star.fill" : "star")
                    }
                }
            }
        }
        .task {
			await viewModel.loadAssets(context: viewContext)
        }
    }
}

struct AssetRowView: View {
    let asset: Asset
    
    var body: some View {
        HStack {
            AsyncImage(url: URL(string: asset.iconUrl)) { image in
                image.resizable()
            } placeholder: {
                ProgressView()
            }
            .frame(width: 32, height: 32)
            
            VStack(alignment: .leading) {
				Text(asset.name ?? asset.assetId) // The asset name is observed to sometimes be nil, how such a condition should be displayed is a UI design decision: leaving this line blank is one option; displaying both lines and taking the name from the ID value is a second possibility; a third would be taking the name from the ID value and instead leave the `Text(asset.assetId)` line blank when that happens
                    .font(.headline)
                Text(asset.assetId)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if asset.isFavorite {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
            }
        }
    }
}
