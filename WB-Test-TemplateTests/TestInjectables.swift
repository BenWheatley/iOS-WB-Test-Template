//
//  TestInjectables.swift
//  WB-Test-TemplateTests
//
//  Created by Ben Wheatley on 13/01/2025.
//

import Foundation
import Network
@testable import WB_Test_Template

struct TestInjectables: NetworkService.Injectables {
	let apiKey = "9A52912A-724F-493D-90A4-8E7066C15B2E"
	let baseURL = "https://rest.coinapi.io/v1"
	let dataFetcher: DataFetcher
	var networkPathStatus: NWPath.Status?
	
	init(networkPathStatus: NWPath.Status?, mockStatusCode: Int, mockResourceName: String) {
		dataFetcher = MockURLSession(mockStatusCode: mockStatusCode, mockResourceName: mockResourceName)
		self.networkPathStatus = networkPathStatus
	}
	
	class MockURLSession: DataFetcher {
		let testBundle: Bundle
		let mockStatusCode: Int
		let mockResourceName: String
		
		init(mockStatusCode: Int, mockResourceName: String) {
			testBundle = Bundle(for: type(of: self))
			self.mockStatusCode = mockStatusCode
			self.mockResourceName = mockResourceName
		}
		
		// Other sensible ways to test this would include the mock pointing to a locally hosted test server with a copy of the data — IMO putting test data on a test host would be better as it actually tests the networking code (so less chance that the test is testing itself instead of reality), but it's harder to demonstrate that kind of thing in a code challenge as then you'd need to know to set up the test host so that the tests can run.
		func data(for request: URLRequest, delegate: (any URLSessionTaskDelegate)?) async throws -> (Data, URLResponse) {
			guard let mockFileURL = testBundle.url(forResource: mockResourceName, withExtension: "json"),
				  let mockData = try? Data(contentsOf: mockFileURL) else {
				throw NetworkError.noData
			}
			guard let mockResponse = HTTPURLResponse(
				url: request.url ?? mockFileURL,
				statusCode: mockStatusCode,
				httpVersion: "1.1",
				headerFields: nil
			) else {
				fatalError("There's something wrong with the test itself")
			}
			return (mockData, mockResponse)
		}
	}
}
