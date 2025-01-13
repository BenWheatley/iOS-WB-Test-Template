//
//  WB_Test_Template_ModelTests.swift
//  WB-Test-TemplateTests
//
//  Created by Ben Wheatley on 10/01/2025.
//

import Testing
import Foundation
@testable import WB_Test_Template

// MARK: - Test "assets"
struct WB_Test_Template_ModelTests {
	@Test func testDecodeAssets_success() {
		guard let mockData = try? TestBundleLoader.shared.data(forResource: "test-assets", withExtension: "json") else {
			Issue.record("Failed to load mock data from file")
			return
		}
		
		let assets = try? Asset.tryToDecodeArray(from: mockData)
		#expect( assets != nil )
		
		for asset in assets! {
			if asset.name == nil {
				print("asset with ID found to have nil name: \(asset.assetId)")
			}
		}
	}
	
	@Test func testDecodeAssets_failure() {
		guard let mockData = try? TestBundleLoader.shared.data(forResource: "test-fail", withExtension: "json") else {
			Issue.record("Failed to load mock data from file")
			return
		}
		
		let assets = try? Asset.tryToDecodeArray(from: mockData)
		#expect( assets == nil ) // If this isn't nil, it was sucessfully parsed — but the data is garbage, it *should* be nil
	}
}

// MARK: - Test "asset by ID"
extension WB_Test_Template_ModelTests {
	@Test("Test loading of various example assets", arguments: ["EOSISH", "MST", "METADOGEV2", "REBUS", "RLUSD"])
	func testDecodeAssetByID_success(expectedAssetID: String) {
		let mockFileName = "test-asset-id=\(expectedAssetID)"
		guard let mockData = try? TestBundleLoader.shared.data(forResource: mockFileName, withExtension: "json") else {
			Issue.record("Failed to load mock data from file")
			return
		}
		
		let assets = try? Asset.tryToDecodeArray(from: mockData)
		#expect( assets != nil )
		#expect( assets?.count == 1 )
		guard let asset = assets?.first else {
			Issue.record("Cannot complete tests: could not retrieve first item from array in \(expectedAssetID)")
			return
		}
		#expect( asset.assetId == expectedAssetID)
		#expect( asset.typeIsCrypto == 1 )
	}
	
	@Test func testDecodeAssetByID_failure() {
		guard let mockData = try? TestBundleLoader.shared.data(forResource: "test-fail", withExtension: "json") else {
			Issue.record("Failed to load mock data from file")
			return
		}
		
		let asset = try? Asset(from: mockData)
		#expect( asset == nil ) // If this isn't nil, it was sucessfully parsed — but the data is garbage, it *should* be nil
	}
}

// MARK: - Test "asset icons"
extension WB_Test_Template_ModelTests {
	@Test func testDecodeAssetIcons_success() {
		guard let mockData = try? TestBundleLoader.shared.data(forResource: "test-asset-icons=64", withExtension: "json") else {
			Issue.record("Failed to load mock data from file")
			return
		}
		
		let assetIcons = try? AssetIcon.tryToDecodeArray(from: mockData)
		guard let assetIcons else {
			Issue.record("Failed to decode asset icons")
			return
		}
		for icon in assetIcons {
			#expect( icon.assetId != nil )
			#expect( icon.url != nil )
			if let url = icon.url {
				#expect( URL(string: url) != nil )
			} else {
				Issue.record("Asset icon URL failed to parse")
			}
		}
	}
	
	@Test func testDecodeAssetIcons_failure() {
		guard let mockData = try? TestBundleLoader.shared.data(forResource: "test-fail", withExtension: "json") else {
			Issue.record("Failed to load mock data from file")
			return
		}
		
		let assetIcons = try? AssetIcon.tryToDecodeArray(from: mockData)
		#expect( assetIcons == nil ) // If this isn't nil, it was sucessfully parsed — but the data is garbage, it *should* be nil
	}
}

// MARK: - Test "exchange rate"
extension WB_Test_Template_ModelTests {
	@Test func testDecodeExchangeRate_success() {
		guard let mockData = try? TestBundleLoader.shared.data(forResource: "test-asset-exchangerate=BTC-USD", withExtension: "json") else {
			Issue.record("Failed to load mock data from file")
			return
		}
		
		let exchangeRate = try? ExchangeRate(from: mockData)
		guard let exchangeRate else {
			Issue.record("Failed to decode exchange rate sample provided by API documentation")
			return
		}
		#expect( exchangeRate.assetIdBase == "BTC" )
		#expect( exchangeRate.assetIdQuote == "USD" )
		#expect( exchangeRate.rate == 10000 )
		let calendar = Calendar(identifier: .gregorian)
		let year = calendar.component(.year, from: exchangeRate.time)
		#expect(year == 2025)
	}
	
	@Test func testDecodeExchangeRate_failure() {
		guard let mockData = try? TestBundleLoader.shared.data(forResource: "test-fail", withExtension: "json") else {
			Issue.record("Failed to load mock data from file")
			return
		}
		
		let exchangeRate = try? ExchangeRate(from: mockData)
		#expect( exchangeRate == nil ) // If this isn't nil, it was sucessfully parsed — but the data is garbage, it *should* be nil
	}
}
