//
//  WB_Test_Template_NetworkServiceTests.swift
//  WB-Test-TemplateTests
//
//  Created by Ben Wheatley on 09/01/2025.
//

import Testing
import Foundation
import Network
import Combine
@testable import WB_Test_Template

struct WB_Test_Template_NetworkServiceTests {
	
	// MARK: - Test network issue handling
	
	@Test func testNetworkOffline() async {
		await #expect(throws: NetworkError.invalidURL) { try await NetworkService.shared.fetchData(from: nil) }
		
		let testURL = URL(string: "https://example.com")
		let mockResourceName = "any name"
		let anyStatusCode = 300
		await #expect(throws: NetworkError.offline) { try await NetworkService.shared.fetchData(from: testURL, injectables: TestInjectables(networkPathStatus: .none, mockStatusCode: anyStatusCode, mockResourceName: mockResourceName)) }
		await #expect(throws: NetworkError.offline) { try await NetworkService.shared.fetchData(from: testURL, injectables: TestInjectables(networkPathStatus: .requiresConnection, mockStatusCode: anyStatusCode, mockResourceName: mockResourceName)) }
		await #expect(throws: NetworkError.offline) { try await NetworkService.shared.fetchData(from: testURL, injectables: TestInjectables(networkPathStatus: .unsatisfied, mockStatusCode: anyStatusCode, mockResourceName: mockResourceName)) }
	}
	
	@Test func testNetworkErrors_invalidURL() async {
		let invalidURL: URL? = nil
		let mockResourceName = "any name"
		let anyStatusCode = 200
		await #expect(throws: NetworkError.invalidURL) { try await NetworkService.shared.fetchData(from: invalidURL, injectables: TestInjectables(networkPathStatus: .satisfied, mockStatusCode: anyStatusCode, mockResourceName: mockResourceName)) }
	}
	
	@Test func testNetworkErrors_noData() async {
		let testURL = URL(string: "https://example.com")
		let mockResourceName = "any name"
		let httpOK = 200
		await #expect {
			try await NetworkService.shared.fetchData(from: testURL, injectables: TestInjectables(networkPathStatus: .satisfied, mockStatusCode: httpOK, mockResourceName: mockResourceName))
		} throws: { error in
			guard let networkError = error as? NetworkError else {
				return false
			}
			switch networkError {
			case .serverError(let recognisedServerError, _):
				return recognisedServerError == .noData
			default:
				return false
			}
		}
	}
	
	@Test("Test server errors", arguments: [400, 401, 403, 429, 550])
	func testServerErrors(_ statusCode: Int) async {
		let testURL = URL(string: "https://example.com")
		let mockResourceName = "test-assets-empty-array"
		await #expect {
			try await NetworkService.shared.fetchData(from: testURL, injectables: TestInjectables(networkPathStatus: .satisfied, mockStatusCode: statusCode, mockResourceName: mockResourceName))
		} throws: { error in
			guard let networkError = error as? NetworkError else {
				return false
			}
			switch networkError {
			case .serverError(let recognisedServerError, _):
				switch recognisedServerError! {
				case .badRequest: return statusCode == 400
				case .unauthorized: return statusCode == 401
				case .forbidden: return statusCode == 403
				case .tooManyRequests: return statusCode == 429
				case .noData: return statusCode == 550
				}
			default:
				return false
			}
		}
	}
	
	@Test func testFetch_success() async {
		let testURL = URL(string: "https://example.com")
		let mockResourceName = "test-assets-empty-array"
		let mockStatusCode = 200
		guard let mockData = try? await NetworkService.shared.fetchData(from: testURL, injectables: TestInjectables(networkPathStatus: .satisfied, mockStatusCode: mockStatusCode, mockResourceName: mockResourceName)) else {
			Issue.record("Failed to load mock data from file")
			return
		}
		#expect(mockData.isEmpty == false)
	}
	
	@Test func testBuildRequest() {
		let testURL = URL(string: "https://example.com")!
		let mockResourceName = "test-assets-empty-array"
		let mockAPIKey = "some value to test"
		let injectables = TestInjectables(networkPathStatus: .satisfied, mockStatusCode: 200, mockResourceName: mockResourceName, apiKey: mockAPIKey)
		let value = NetworkService.shared.buildRequest(url: testURL, injectables: injectables).value(forHTTPHeaderField: "X-CoinAPI-Key")
		#expect( value != nil )
		#expect( value?.isEmpty == false )
		#expect( mockAPIKey == value )
	}

	// MARK: - Test url generation
	
	@Test func testAssetsURL() {
		#expect( NetworkService.shared.assetsURL() != nil )
	}
	
	@Test func testAssetByIDURL() {
		#expect( NetworkService.shared.assetURL(id: "generic_example") != nil )
	}

	@Test func testAssetIconsURL() {
		#expect( NetworkService.shared.assetIconsURL(iconSize: 123) != nil )
	}

	@Test func testExchangeRateURL() {
		#expect( NetworkService.shared.exchangeRateURL(assetIdBase: "some-id", assetIdQuote: "some-other-id") != nil )
	}
}
