import Foundation
import Network

class NetworkService {
	static let shared = NetworkService()
	
	protocol Injectables {
		var apiKey: String { get }
		var baseURL: String { get }
		var networkPathStatus: NWPath.Status? { get }
	}
	
	// Private inner class: nobody outside this class should ever need to see, or care about, the contents of this. Test-time usage should refer only to `Injectables` protocol for dependency injection.
	private static let injectables: Injectables = {
		class DefaultInjectables: Injectables {
			let apiKey = "9A52912A-724F-493D-90A4-8E7066C15B2E"
			let baseURL = "https://rest.coinapi.io/v1"
			
			// Network status — `Reachability` was the old way, `Network` is the new way:
			private let networkPathMonitor = NWPathMonitor()
			var networkPathStatus: NWPath.Status?
			private let networkStatusDispatchQueue = DispatchQueue(label: "Network status monitor")
			
			init() {
				networkPathMonitor.pathUpdateHandler = { [weak self] path in
					self?.networkPathStatus = path.status // We're only using the `status` property at this time, so we don't need to care about storing the *entire* NWPath value
				}
				networkPathMonitor.start(queue: networkStatusDispatchQueue)
			}
		}
		return DefaultInjectables()
	}()
	
	func fetchData(from url: URL?, injectables: Injectables = injectables) async throws -> Data {
		guard let url else {
			throw NetworkError.invalidURL
		}
		
		guard injectables.networkPathStatus == .satisfied else {
			throw NetworkError.offline
		}
		
		let request = buildRequest(url: url)
		let (data, response) = try await URLSession.shared.data(for: request)
		
		guard let httpResponse = response as? HTTPURLResponse else {
			// If we get here, there's an error in the Apple API docs, which claim that "Whenever you make HTTP URL load requests, any response objects you get back from the URLSession, NSURLConnection, or NSURLDownload class are instances of the HTTPURLResponse class."
			throw NetworkError.serverError(nil, "Unknown error — not a HTTPURLResponse")
		}
		guard httpResponse.statusCode == 200 else { // Note: API docs specifically claim that "You should always check that your HTTP response status code is equal to 200, otherwise the requested was not successful.", and that "All HTTP requests with response status codes different to 200 must be considered as failed and you should expect additional JSON inside the body of the response with the error message encapsulated inside it as shown in the example. We use the following error codes:" [400, 401, 403, 429, 550] - https://docs.coinapi.io/market-data/rest-api/
			let errorMessage: String
			if let serverError = try? ServerError(from: data) {
				errorMessage = serverError.error
			} else {
				errorMessage = "Invalid server response, error message not parsed: \(String(data: data, encoding: .utf8) ?? "could not decode response as string")"
			}
			throw NetworkError.serverError(.init(statusCode: httpResponse.statusCode), errorMessage)
		}
		
		return data
	}
	
	func buildRequest(url: URL, injectables: Injectables = injectables) -> URLRequest {
		var request = URLRequest(url: url)
		request.addValue(injectables.apiKey, forHTTPHeaderField: "X-CoinAPI-Key")
		request.addValue("br, gzip", forHTTPHeaderField: "Accept-Encoding") // Requested in API documentation, but not mandatory: https://docs.coinapi.io/market-data/rest-api/
		return request
	}
}

// MARK: - Assets (plural)

extension NetworkService {
	func assetsURL(injectables: Injectables = injectables) -> URL? {
		URL(string: "\(injectables.baseURL)/assets")
	}
	
	func fetchAssetsData() async throws -> Data {
        try await fetchData(from: assetsURL())
    }
}

// MARK: - Single asset by ID

extension NetworkService {
	func assetURL(id: String, injectables: Injectables = injectables) -> URL? {
		URL(string: "\(injectables.baseURL)/assets/\(id)")
	}
	
	func fetchAssetData(id: String) async throws -> Data {
		try await fetchData(from: assetURL(id: id))
	}
}

// MARK: - Asset icons for size

extension NetworkService {
	func assetIconsURL(iconSize: Int32, injectables: Injectables = injectables) -> URL? {
		URL(string: "\(injectables.baseURL)/assets/icons/\(iconSize)")
	}
	
	func fetchAssetIconsData(iconSize: Int32) async throws -> Data {
		try await fetchData(from: assetIconsURL(iconSize: iconSize))
	}
}

// MARK: - Exchange rates for (base, quote) pair

extension NetworkService {
	func exchangeRateURL(assetIdBase: String, assetIdQuote: String, injectables: Injectables = injectables) -> URL? {
		URL(string: "\(injectables.baseURL)/exchangerate/\(assetIdBase)/\(assetIdQuote)")
	}
	
	func fetchExchangeRateData(assetIdBase: String, assetIdQuote: String) async throws -> Data {
		try await fetchData(from: exchangeRateURL(assetIdBase: assetIdBase, assetIdQuote: assetIdQuote))
	}
}
