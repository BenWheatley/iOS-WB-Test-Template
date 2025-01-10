//
//  WB_Test_Template_NetworkService_IntegrationTests.swift
//  WB-Test-TemplateTests
//
//  Created by Ben Wheatley on 10/01/2025.
//

import XCTest // Note: Can't use Testing framework, as that doesn't yet support `self.measure` which I want to use here
@testable import WB_Test_Template

final class WB_Test_TemplateTests: XCTestCase {

    func testIntegratedFetchAndParse_Assets() async throws {
		measureAsync {
			guard let assetsData = try? await NetworkService.shared.fetchAssetsData() else {
				XCTFail("Could not fetch assets data from network")
				return
			}
			guard let assets = try? Asset.tryToDecodeArray(from: assetsData) else {
				XCTFail("Could not parse assets data from network")
				return
			}
			XCTAssertGreaterThan(assets.count, 0)
		}
    }
	
	func testIntegratedFetchAndParse_AssetsIcons() async throws {
		let someIconSize: Int32 = 64
		measureAsync {
			guard let assetsIconsData = try? await NetworkService.shared.fetchAssetIconsData(iconSize: someIconSize) else {
				XCTFail("Could not fetch assets icons data from network")
				return
			}
			guard let assetsIcons = try? AssetIcon.tryToDecodeArray(from: assetsIconsData) else {
				XCTFail("Could not parse assets icons data from network")
				return
			}
			XCTAssertGreaterThan(assetsIcons.count, 0)
		}
	}
	
	func testIntegratedFetchAndParse_ExchangeRate() async throws {
		let assetIdBase = "BTC"
		let assetIdQuote = "USD"
		measureAsync {
			guard let exchangeRateData = try? await NetworkService.shared.fetchExchangeRateData(assetIdBase: assetIdBase, assetIdQuote: assetIdQuote) else {
				XCTFail("Could not fetch exchange rate data from network")
				return
			}
			guard let exchangeRate = try? ExchangeRate(from: exchangeRateData) else {
				XCTFail("Could not parse exchange rate data from network")
				return
			}
			XCTAssertEqual(exchangeRate.assetIdBase, assetIdBase)
			XCTAssertEqual(exchangeRate.assetIdQuote, assetIdQuote)
			XCTAssertGreaterThan(exchangeRate.rate, 0)
		}
	}
}
