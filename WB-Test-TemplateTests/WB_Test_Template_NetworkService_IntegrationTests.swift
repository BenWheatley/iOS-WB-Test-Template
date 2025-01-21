//
//  WB_Test_Template_NetworkService_IntegrationTests.swift
//  WB-Test-TemplateTests
//
//  Created by Ben Wheatley on 10/01/2025.
//

import XCTest // Note: Was originally done without the Testing framework as I initially wanted to use `self.measure` which isn't supported in `Testing`, but I changed my mind and have not updated this code to the new framework
import Combine
@testable import WB_Test_Template

final class WB_Test_TemplateTests: XCTestCase {

    func testIntegratedFetchAndParse_Assets() {
		let expectation = XCTestExpectation(description: "Fetch and parse assets")
		var cancellables = Set<AnyCancellable>()
		
		let testInjectables = TestInjectables(networkPathStatus: .satisfied, mockStatusCode: 200, mockResourceName: "test-assets")
		
		let assetsDataPublisher = NetworkService.shared.fetchAssetsData(injectables: testInjectables)
		assetsDataPublisher.sink( receiveCompletion: { completion in
			switch completion {
			case .finished: break
			case .failure(let error): XCTFail("Could not fetch assets data from mock network: \(error.localizedDescription)")
			}
		}, receiveValue: { data in
			guard let assets = try? Asset.tryToDecodeArray(from: data) else {
				XCTFail("Could not parse assets data from network")
				return
			}
			XCTAssertEqual(assets.count, 18373)
			expectation.fulfill()
		})
		.store(in: &cancellables)
		
		wait(for: [expectation], timeout: 15)
    }
	
	func testIntegratedFetchAndParse_AssetsIcons() {
		let expectation = XCTestExpectation(description: "Fetch and parse icons")
		var cancellables = Set<AnyCancellable>()
		let testInjectables = TestInjectables(networkPathStatus: .satisfied, mockStatusCode: 200, mockResourceName: "test-asset-icons=64")
		
		let someIconSize: Int32 = 64
		
		let assetsIconsDataPublisher = NetworkService.shared.fetchAssetIconsData(iconSize: someIconSize, injectables: testInjectables)
		assetsIconsDataPublisher.sink( receiveCompletion: { completion in
			switch completion {
			case .finished: break
			case .failure(let error): XCTFail("Could not fetch assets icons data from mock network: \(error.localizedDescription)")
			}
		}, receiveValue: { data in
			guard let assetsIcons = try? AssetIcon.tryToDecodeArray(from: data) else {
				XCTFail("Could not parse assets icons data from network")
				return
			}
			XCTAssertEqual(assetsIcons.count, 2820)
			expectation.fulfill()
		})
		.store(in: &cancellables)
		
		wait(for: [expectation], timeout: 2)
	}
	
	func testIntegratedFetchAndParse_ExchangeRate() {
		let expectation = XCTestExpectation(description: "Fetch and parse exchange rate")
		var cancellables = Set<AnyCancellable>()
		let testInjectables = TestInjectables(networkPathStatus: .satisfied, mockStatusCode: 200, mockResourceName: "test-asset-exchangerate=BTC-USD")
		
		let assetIdBase = "BTC"
		let assetIdQuote = "USD"
		let exchangeRateDataPublisher = NetworkService.shared.fetchExchangeRateData(assetIdBase: assetIdBase, assetIdQuote: assetIdQuote, injectables: testInjectables)
		exchangeRateDataPublisher.sink(receiveCompletion: { completion in
			switch completion {
			case .finished: break
			case .failure(let error): XCTFail("Could not fetch exchange rate data from mock network: \(error.localizedDescription)")
			}
		}, receiveValue: { data in
			guard let exchangeRate = try? ExchangeRate(from: data) else {
				XCTFail("Could not parse exchange rate data from network")
				return
			}
			XCTAssertEqual(exchangeRate.assetIdBase, assetIdBase)
			XCTAssertEqual(exchangeRate.assetIdQuote, assetIdQuote)
			XCTAssertGreaterThan(exchangeRate.rate, 0)
			expectation.fulfill()
		})
		.store(in: &cancellables)
		
		wait(for: [expectation], timeout: 1)
	}
	
	func testRequestRetryMechanism() {
		testRequestRetryMechanism(shouldRetry: true)
		testRequestRetryMechanism(shouldRetry: false)
	}
	
	func testRequestRetryMechanism(shouldRetry: Bool) {
		let expectation = XCTestExpectation(description: "Automatic retry mechanism test - shouldRetry: \(shouldRetry)")
		var cancellables = Set<AnyCancellable>()
		
		let testURL = URL(string: "https://example.com")
		let mockResourceName = "test-assets-empty-array"
		let mockStatusCode = shouldRetry ? 429 : 200
		let testInjectables = TestInjectables(networkPathStatus: .satisfied, mockStatusCode: mockStatusCode, mockResourceName: mockResourceName)
		
		guard let mockSession = testInjectables.dataFetcher as? TestInjectables.MockURLSession else {
			XCTFail("There is something wrong with the test itself")
			return
		}
		XCTAssertEqual(mockSession.callCount, 0) // Should start off never called
		
		let testRetryAttempts = 3
		
		let mockDataPublisher = NetworkService.shared.fetchDataPublisher(from: testURL, retryAttempts: testRetryAttempts, injectables: testInjectables)
		mockDataPublisher.sink(
			receiveCompletion: { _ in
				expectation.fulfill()
			},
			receiveValue: { _ in
				if shouldRetry {
					XCTAssertEqual(mockSession.callCount, testRetryAttempts)
				} else {
					XCTAssertEqual(mockSession.callCount, 1)
				}
				expectation.fulfill()
			}
		)
		.store(in: &cancellables)
		
		wait(for: [expectation], timeout: 1) // testRequestRetryMechanism(): Asynchronous wait failed: Exceeded timeout of 3 seconds, with unfulfilled expectations: "Fetch and parse exchange rate".
	}
}
