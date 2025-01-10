import Foundation


class NetworkService {
    static let shared = NetworkService()
    private let apiKey = "9A52912A-724F-493D-90A4-8E7066C15B2E"
    private let baseURL = "https://rest.coinapi.io/v1"
    private init() {}
    
    func fetchAssets() async throws -> [Asset] {
        let dataTask = { [self] in  
            guard let url = URL(string: "\(baseURL)/assets") else {
                throw NetworkError.invalidURL
            }
            var request = URLRequest(url: url)
            request.addValue(apiKey, forHTTPHeaderField: "X-CoinAPI-Key")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw NetworkError.serverError("Invalid server response")
            }
            
            do {
                return try JSONDecoder().decode(
                    [Asset].self, from: data
                )
            } catch {
                throw NetworkError.decodingError
            }
        }
        return try await dataTask()
        
    }
    
    // Add other network calls here
} 
