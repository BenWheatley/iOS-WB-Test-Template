import Foundation
import Network

class NetworkService {
	// TODO: make the values injectable for testing
	static let shared = NetworkService()
	private let apiKey = "9A52912A-724F-493D-90A4-8E7066C15B2E"
	private let baseURL = "https://rest.coinapi.io/v1"
	
	// Network status — `Reachability` was the old way, `Network` is the new way:
	private let networkPathMonitor = NWPathMonitor()
	private var networkPath: NWPath?
	private let networkStatusDispatchQueue = DispatchQueue(label: "Network status monitor")
	private init() {
		networkPathMonitor.pathUpdateHandler = { [weak self] path in
			self?.networkPath = path
		}
		networkPathMonitor.start(queue: networkStatusDispatchQueue)
	}
	
	func fetchData(from url: URL?) async throws -> Data {
		guard let url else {
			throw NetworkError.invalidURL
		}
		
		guard networkPath?.status == .satisfied else {
			throw NetworkError.offline
		}
		
		let request = buildRequest(url: url)
		let (data, response) = try await URLSession.shared.data(for: request)
		
		guard let httpResponse = response as? HTTPURLResponse,
			  httpResponse.statusCode == 200 else {
			throw NetworkError.serverError("Invalid server response")
		}
		
		return data
	}
	
	func buildRequest(url: URL) -> URLRequest {
		var request = URLRequest(url: url)
		request.addValue(apiKey, forHTTPHeaderField: "X-CoinAPI-Key")
		return request
	}
}

// MARK: - Assets (plural)

extension NetworkService {
	func assetsURL() -> URL? {
		URL(string: "\(baseURL)/assets")
	}
	
	func fetchAssetsData() async throws -> Data {
        try await fetchData(from: assetsURL())
        
    }
}

// MARK: - Single asset by ID

extension NetworkService {
	func assetURL(id: String) -> URL? {
		URL(string: "\(baseURL)/assets/\(id)")
	}
	
	func fetchAssetData(id: String) async throws -> Data {
		try await fetchData(from: assetURL(id: id))
	}
}

// MARK: - Asset icons for size

extension NetworkService {
	func assetIconsURL(iconSize: Int) -> URL? {
		URL(string: "\(baseURL)/assets/icons/\(iconSize)")
	}
	
	func fetchAssetIconsData(iconSize: Int) async throws -> Data {
		try await fetchData(from: assetIconsURL(iconSize: iconSize))
	}
}

// MARK: - Exchange rates for (base, quote) pair

extension NetworkService {
	func exchangeRateURL(assetIdBase: String, assetIdQuote: String) -> URL? {
		URL(string: "\(baseURL)/exchangerate/\(assetIdBase)/\(assetIdQuote)")
	}
	
	func fetchExchangeRateData(assetIdBase: String, assetIdQuote: String) async throws -> Data {
		try await fetchData(from: exchangeRateURL(assetIdBase: assetIdBase, assetIdQuote: assetIdQuote))
	}
}
