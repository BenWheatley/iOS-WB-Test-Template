import Foundation
import Network
import Combine

class NetworkService {
	static let shared = NetworkService()
	
	protocol Injectables {
		var apiKey: String { get }
		var baseURL: String { get }
		var networkPathStatus: NWPath.Status? { get }
		var dataFetcher: DataFetcher { get }
	}
	
	// Private inner class: nobody outside this class should ever need to see, or care about, the contents of this. Test-time usage should refer only to `Injectables` protocol for dependency injection.
	private static let injectables: Injectables = {
		class DefaultInjectables: Injectables {
			let apiKey = "9A52912A-724F-493D-90A4-8E7066C15B2E"
			let baseURL = "https://rest.coinapi.io/v1"
			let dataFetcher: DataFetcher = URLSession.shared
			
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
	
	func fetchDataPublisher(from url: URL?, retryAttempts: Int, injectables: Injectables = injectables) -> AnyPublisher<Data, Error> {
		Future { [weak self] promise in
			Task {
				guard let self else {
					// If weak `self` has been deallocated, fail the Future with a `CancellationError`. As NetworkService is a singleton (at the time I write this comment) this can only happen on app shutdown, but being defensive about this means that if I re-write this as not a singleton later (which I've been considering, so it's not premature optimisation to account for that here), this is one less thing to get wrong
					promise(.failure(CancellationError()))
					return
				}
				do {
					let data = try await self.fetchData(from: url, injectables: injectables)
					promise(.success(data))
				} catch {
					promise(.failure(error))
				}
			}
		}
		.retry(retryAttempts) // Note: out of scope for task documentation, but this should really be more more complex: a 401 should never retry (unauthorized), and a 429 (too many requests) must *delay* retries. See e.g. https://www.donnywals.com/retrying-a-network-request-with-a-delay-in-combine/ for possible approaches.
		.eraseToAnyPublisher()
	}
	
	// Note: out of scope for task documentation, but if this was a real project, I would argue that `NetworkService` should become a separate module, as `func fetchData` shouldn't be directly accessible from the app, but needs to be internal so it can be tested
	internal func fetchData(from url: URL?, injectables: Injectables = injectables) async throws -> Data {
		guard let url else {
			throw NetworkError.invalidURL
		}
		
		// injectables.networkPathStatus may be nil if this is the first call and it's not completed startup yet
		if injectables.networkPathStatus == nil {
			// I would use `try await Task.sleep(for: .seconds(2))` but the project minimum deployment says iOS 15 and .seconds was introduced in 16
			try await Task.sleep(nanoseconds: UInt64(2 * 1_000_000_000))
		}
		// no point continuing to wait: if it is still nil, that's likely an error that the user should care about
		guard injectables.networkPathStatus == .satisfied else {
			throw NetworkError.offline
		}
		
		let request = buildRequest(url: url)
		let (data, response) = try await injectables.dataFetcher.data(for: request, delegate: nil) // Have to explicitly provide `delegate: nil`, because I've abstracted up from URLSession to a protocol so I can mock this, but protocols don't allow default arguments (I could also have created a func without that argument at all, passed through to that, but that would then need additional tests and so it doesn't help keep this simple)
		
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
	
	func fetchAssetsData(injectables: Injectables = injectables) -> AnyPublisher<Data, Error> {
		fetchDataPublisher(from: assetsURL(injectables: injectables), retryAttempts: 3, injectables: injectables)
    }
}

// MARK: - Single asset by ID

extension NetworkService {
	func assetURL(id: String, injectables: Injectables = injectables) -> URL? {
		URL(string: "\(injectables.baseURL)/assets/\(id)")
	}
	
	func fetchAssetData(id: String, injectables: Injectables = injectables) -> AnyPublisher<Data, Error> {
		fetchDataPublisher(from: assetURL(id: id, injectables: injectables), retryAttempts: 3, injectables: injectables)
	}
}

// MARK: - Asset icons for size

extension NetworkService {
	func assetIconsURL(iconSize: Int32, injectables: Injectables = injectables) -> URL? {
		URL(string: "\(injectables.baseURL)/assets/icons/\(iconSize)")
	}
	
	func fetchAssetIconsData(iconSize: Int32, injectables: Injectables = injectables) -> AnyPublisher<Data, Error> {
		fetchDataPublisher(from: assetIconsURL(iconSize: iconSize, injectables: injectables), retryAttempts: 3, injectables: injectables)
	}
}

// MARK: - Exchange rates for (base, quote) pair

extension NetworkService {
	func exchangeRateURL(assetIdBase: String, assetIdQuote: String, injectables: Injectables = injectables) -> URL? {
		URL(string: "\(injectables.baseURL)/exchangerate/\(assetIdBase)/\(assetIdQuote)")
	}
	
	func fetchExchangeRateData(assetIdBase: String, assetIdQuote: String, injectables: Injectables = injectables) -> AnyPublisher<Data, Error> {
		fetchDataPublisher(from: exchangeRateURL(assetIdBase: assetIdBase, assetIdQuote: assetIdQuote, injectables: injectables), retryAttempts: 3, injectables: injectables)
	}
}
