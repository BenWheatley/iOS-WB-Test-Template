import SwiftUI

struct AssetDetailView: View {
    let asset: Asset
	let favouriteToggleAction: () -> Void
    
    var body: some View {
		// This is not a "Complete *AssetDetailView* implementation" (task says "Any Two" and I've already done two), but it is necessary to test the workflow for isFavorite, which I would consider to be a part of the Testing section "Add UI tests for critical user flows" (TODO: write that UI test)
        VStack(alignment: .leading, spacing: 16) {
			Button(action: favouriteToggleAction) {
				Image(systemName: asset.isFavorite ? "star.fill" : "star")
					.foregroundColor(asset.isFavorite ? .yellow : .primary)
			}
        }
		.navigationTitle(asset.name ?? asset.assetId) // The asset name is observed to sometimes be nil, how such a condition should be displayed is a UI design decision, this seems like a reasonable fallback. Note that API docs say assetId is also nullable, but (1) I've not observed that in practice, and (2) that seems like it should be impossible.
    }
}
