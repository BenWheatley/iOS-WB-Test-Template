import SwiftUI

struct AssetDetailView: View {
    let asset: Asset
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
        }
		.navigationTitle(asset.name ?? asset.assetId) // The asset name is observed to sometimes be nil, how such a condition should be displayed is a UI design decision, this seems like a reasonable fallback. Note that API docs say assetId is also nullable, but (1) I've not observed that in practice, and (2) that seems like it should be impossible.
    }
}
