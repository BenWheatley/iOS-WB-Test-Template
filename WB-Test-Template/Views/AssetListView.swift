import SwiftUI

struct AssetListView: View {
	@StateObject public var viewModel: AssetListViewModel
	@State private var selectedAssetId: String?
	
	var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.filteredAssets) { asset in
                    NavigationLink(
						destination:
							AssetDetailView(
								asset: asset,
								favouriteToggleAction: { viewModel.toggleFavouriteStatus(for: asset) }
							),
						tag: asset.assetId, // This is to resolve a race condition; it's arguable if this is "in" AssetListViewModel (as per task document) or not, but it definitely *involves* AssetListViewModel
						selection: $selectedAssetId
					) {
						AssetRowView(asset: asset)
                    }
                }
            }
			.accessibilityLabel("Asset list") // Note: label, not identifier - this would be the spoken name, not merely an internal ID string
			.searchable(text: $viewModel.searchText)
            .refreshable {
				await viewModel.loadAssets()
			}
            .navigationTitle("Crypto Monitor")
            .toolbar {
				ToolbarItem(placement: .bottomBar) {
					if viewModel.offline {
						Text("Offline")
					}
				}
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
						viewModel.showFavoritesOnly.toggle()
                    }) {
						Image(systemName: viewModel.showFavoritesOnly ? "star.fill" : "star")
                    }
					.accessibilityLabel("favoritesToggleButton") // Minimum needed for UI test; note that this button probably needs more work for actual usability, but that's outside the scope of the design doc
                }
            }
        }
		.onAppear { viewModel.fetchAppState() }
        .task {
			await viewModel.loadAssets()
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
				Text(asset.lastFetched?.description ?? "Asset was never fetched")
					.font(.footnote)
					.foregroundColor(.secondary)
            }
            
            Spacer()
            
            if asset.isFavorite {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
            }
        }
		.accessibilityIdentifier("AssetRowView_\(asset.assetId)") // Note: identifiers are private ID strings, not user-facing
    }
}
