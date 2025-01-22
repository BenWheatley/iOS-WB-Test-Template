import SwiftUI

struct AssetDetailView: View {
    let asset: Asset
	let favouriteToggleAction: () -> Void
    
    var body: some View {
		// This is not a "Complete *AssetDetailView* implementation" (task says "Any Two" and I've already done two), but it is necessary to test the workflow for isFavorite, which I would consider to be a part of the Testing section "Add UI tests for critical user flows"
        VStack(alignment: .leading, spacing: 16) {
			HStack {
				Spacer()
				
				Button(action: favouriteToggleAction) {
					Image(systemName: asset.isFavorite ? "star.fill" : "star")
						.foregroundColor(asset.isFavorite ? .yellow : .primary)
				}
				.accessibilityIdentifier("isFavorite")
				.accessibilityValue(asset.isFavorite ? "Is currently a favourite" : "Is not currently a favourite")
				
				Spacer()
			}
			
			Spacer()
			
			// Pre-set values rather than user-editable; no need to go overboard for this version
			let from = Date(timeIntervalSinceNow: -3600*24*100) // 100 days; I would suggest using a calendar date picker in a real app, e.g. https://developer.apple.com/documentation/swiftui/datepicker
			// Note: observed that this actually returns 14 values
			TimeSeriesDataView(viewModel: TimeSeriesDataViewModel(assetIdBase: asset.assetId, from: from, to: .now))
        }
		.navigationTitle(asset.name ?? asset.assetId) // The asset name is observed to sometimes be nil, how such a condition should be displayed is a UI design decision, this seems like a reasonable fallback. Note that API docs say assetId is also nullable, but (1) I've not observed that in practice, and (2) that seems like it should be impossible.
    }
}


struct TimeSeriesDataView: View {
	@StateObject public var viewModel: TimeSeriesDataViewModel
	
	var body: some View {
		ZStack {
			// This project is set to minimum deployment version of iOS 15, which means we don't have the Charts framework (iOS 16+); therefore, here's a quick and dirty demo of how to chart data using CoreGraphics
			// The Charts framework is much better than this, if I were actually in the team, I'd strongly suggest updating to a minium version of 16 — as I recall from the Developer session, the Charts framework has built-in acessibility features
			// https://developer.apple.com/documentation/charts
			
			// Other alternatives include:
			// - Render to image, either locally or on a server - strongly recommend against, due to accessibility issues
			// - Use 3rd party charting library - mild recommendation against, if they support accessibility: Charts framework likely better, minimum version hike would have to happen soon-ish anyway
			
			let data = viewModel.timeSeries
			let maxRate = data.compactMap { $0.rateHigh }.max() ?? 0.0
			let minRate = data.compactMap { $0.rateLow }.min() ?? 0.0
			let currency = viewModel.assetIdQuote
			
			VStack {
				Text("\(maxRate, format: .currency(code: currency))")
				
				HStack {
					if let start = data.first?.timePeriodStart {
						Text(start.formatted(date: .abbreviated, time: .omitted))
							.rotationEffect(.degrees(90)) // Note: the rotation effect does not change the layout boundaries; I could go into this via GeometryReader etc., but this seems out of scope given I'm also suggesting that it's easier and faster to increase minimum deployment version and switch to Apple's `Charts`
					}
					
					GeometryReader { geometry in
						let stepX = geometry.size.width / CGFloat(data.count)
						let scaleY = geometry.size.height / CGFloat(maxRate - minRate)
						
						Path { path in
							for (index, item) in data.enumerated() {
								if let rateLow = item.rateLow, let rateHigh = item.rateHigh {
									let x = CGFloat(index) * stepX + stepX / 2
									let yLow = geometry.size.height - CGFloat(rateLow - minRate) * scaleY
									let yHigh = geometry.size.height - CGFloat(rateHigh - minRate) * scaleY
									
									path.move(to: CGPoint(x: x, y: yLow))
									path.addLine(to: CGPoint(x: x, y: yHigh))
								}
							}
						}
						.stroke(Color.blue, lineWidth: 2)
					}
					.frame(height: 300)
					.padding()
							 
					if let end = data.last?.timePeriodStart {
						Text(end.formatted(date: .abbreviated, time: .omitted))
							.rotationEffect(.degrees(90))
					}
				}
				
				Text("\(minRate, format: .currency(code: currency))")
			}
			
			if viewModel.isLoading {
				ProgressView()
					.progressViewStyle(CircularProgressViewStyle())
			} else if viewModel.offline {
				Text("Offline")
			} else if let error = viewModel.error {
				Text("Error: \(error)")
			}
		}
		.task {
			await viewModel.loadData()
		}
	}
}
