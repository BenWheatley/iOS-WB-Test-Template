//
//  WB_Test_Template_NetworkService_IntegrationTests.swift
//  WB-Test-TemplateTests
//
//  Created by Ben Wheatley on 10/01/2025.
//

import XCTest // Note: Can't use Testing framework, as that doesn't yet support `self.measure` which I want to use here
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
		
		wait(for: [expectation], timeout: 3)
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
}
