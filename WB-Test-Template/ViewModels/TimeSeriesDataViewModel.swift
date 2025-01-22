//
//  TimeSeriesDataViewModel.swift
//  WB-Test-Template
//
//  Created by Ben Wheatley on 22/01/2025.
//

import Foundation
import Combine

@MainActor
class TimeSeriesDataViewModel: ObservableObject {
	let assetIdBase: String
	let assetIdQuote = "EUR" // Constant value for this version, no need for more complexity right now
	let from: Date
	let to: Date
	
	@Published public var timeSeries: [TimeSeriesData] = []
	@Published public var isLoading = false
	@Published public var offline = false
	@Published public var error: String? = nil
	
	private var networkCancellables = Set<AnyCancellable>()
	
	init(assetIdBase: String, from: Date, to: Date) {
		self.assetIdBase = assetIdBase
		self.from = from
		self.to = to
	}
	
	func loadData() async {
		guard !isLoading else { return }
		
		isLoading = true
		
		NetworkService.shared.fetchExchangeRateTimeSeriesData(assetIdBase: assetIdBase, assetIdQuote: assetIdQuote, from: from, to: to)
			.sink(receiveCompletion: { [weak self] completion in
				guard let self else { return }
				DispatchQueue.main.sync { self.isLoading = false
					if case .failure(let error) = completion { // We don't need a switch, as we only care about the failure case here
						self.offline = (error as? NetworkError) == NetworkError.offline
						self.error = error.localizedDescription
					}
				}
			}, receiveValue: { [weak self] data in
				guard let self else { return }
				DispatchQueue.main.sync { self.offline = false }
				do {
					let decodedTimeSeries = try TimeSeriesData.tryToDecodeArray(from: data)
					
					DispatchQueue.main.sync { self.timeSeries = decodedTimeSeries }
				} catch {
					DispatchQueue.main.sync { self.error = error.localizedDescription }
				}
			})
			.store(in: &networkCancellables)
	}
}
