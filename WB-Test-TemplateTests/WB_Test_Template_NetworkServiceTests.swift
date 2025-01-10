//
//  WB_Test_Template_NetworkServiceTests.swift
//  WB-Test-TemplateTests
//
//  Created by Ben Wheatley on 09/01/2025.
//

import Testing
import Foundation
import Network
@testable import WB_Test_Template

struct WB_Test_Template_NetworkServiceTests {
	
	struct TestInjectables: NetworkService.Injectables {
		let apiKey = "9A52912A-724F-493D-90A4-8E7066C15B2E"
		let baseURL = "https://rest.coinapi.io/v1"
		var networkPathStatus: NWPath.Status?
	}
	
	// MARK: - Test network issue handling
	
	@Test func testNetworkErrors() async {
		await #expect(throws: NetworkError.invalidURL) { try await NetworkService.shared.fetchData(from: nil) }
		
		let testURL = URL(string: "https://example.com")
		await #expect(throws: NetworkError.offline) { try await NetworkService.shared.fetchData(from: testURL, injectables: TestInjectables(networkPathStatus: .none)) }
		await #expect(throws: NetworkError.offline) { try await NetworkService.shared.fetchData(from: testURL, injectables: TestInjectables(networkPathStatus: .requiresConnection)) }
		await #expect(throws: NetworkError.offline) { try await NetworkService.shared.fetchData(from: testURL, injectables: TestInjectables(networkPathStatus: .unsatisfied)) }
		
		Issue.record("TODO: Remaining NetworkError cases, also add more network error values to match API docs")
	}

	@Test func testRequestRetryMechanism() {
		Issue.record("TODO: Test the retry mechanism under failure conditions.")
	}
	
	@Test func testBuildRequest() {
		let testURL = URL(string: "https://example.com")!
		let value = NetworkService.shared.buildRequest(url: testURL).value(forHTTPHeaderField: "X-CoinAPI-Key")
		// TODO: make the value injectable for equality testing
		#expect( value != nil )
		#expect( value?.isEmpty == false )
	}

	// MARK: - Test "assets"
	
	@Test func testAssetsURL() {
		#expect( NetworkService.shared.assetsURL() != nil )
	}

	@Test func testFetchAssets_success() {
		Issue.record("TODO: Simulate successful fetch and validate the result.")
	}

	@Test func testFetchAssets_noData() {
		Issue.record("TODO: Simulate no data returned and validate the error.")
	}

	@Test func testFetchAssets_serverError() {
		Issue.record("TODO: Simulate server error response and validate the error.")
	}
	
	// MARK: - Test "asset by ID"
	
	@Test func testAssetByIDURL() {
		#expect( NetworkService.shared.assetURL(id: "generic_example") != nil )
	}

	@Test func testFetchAssetByID_success() {
		Issue.record("TODO: Simulate successful fetch of an asset by ID and validate the result.")
	}

	@Test func testFetchAssetByID_noData() {
		Issue.record("TODO: Simulate no data returned for GetAssetByID and validate the error.")
	}

	@Test func testFetchAssetByID_serverError() {
		Issue.record("TODO: Simulate server error for GetAssetByID and validate the error.")
	}
	
	// MARK: - Test "asset icons"
	
	@Test func testAssetIconsURL() {
		#expect( NetworkService.shared.assetIconsURL(iconSize: 123) != nil )
	}

	@Test func testFetchAssetIcons_success() {
		Issue.record("TODO: Simulate successful fetch of asset icons and validate the result.")
	}

	@Test func testFetchAssetIcons_noData() {
		Issue.record("TODO: Simulate no data returned for GetAssetIcons and validate the error.")
	}

	@Test func testFetchAssetIcons_serverError() {
		Issue.record("TODO: Simulate server error for GetAssetIcons and validate the error.")
	}
	
	// MARK: - Test "exchange rate"
	
	@Test func testExchangeRateURL() {
		#expect( NetworkService.shared.assetIconsURL(iconSize: 123) != nil )
	}

	@Test func testFetchExchangeRate_success() {
		Issue.record("TODO: Simulate successful fetch of exchange rate and validate the result.")
	}

	@Test func testFetchExchangeRate_noData() {
		Issue.record("TODO: Simulate no data returned for GetExchangeRate and validate the error.")
	}

	@Test func testFetchExchangeRate_serverError() {
		Issue.record("TODO: Simulate server error for GetExchangeRate and validate the error.")
	}

}
