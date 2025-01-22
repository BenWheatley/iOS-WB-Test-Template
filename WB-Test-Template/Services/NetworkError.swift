//
//  NetworkError.swift
//  WB-Test-Template
//
//  Created by Ben Wheatley on 09/01/2025.
//

import Foundation

enum NetworkError: Error, Equatable {
	case invalidURL
	/// Note: "no data" moved into `serverError` under the assumption that this is supposed to represent HTTP 550, which is a server error
	case decodingError
	case serverError(RecognisedServerError?, String)
	case offline
	
	/// These are all the recognised server errors from the API documentation: https://docs.coinapi.io/market-data/rest-api/
	enum RecognisedServerError: Equatable {
		case badRequest
		case unauthorized
		case forbidden
		case tooManyRequests
		/// Moved from `NetworkError` because HTTP 550 ("no data") is classified as a server error
		case noData
		
		init?(statusCode: Int) {
			switch statusCode {
			case 400: self = .badRequest
			case 401: self = .unauthorized
			case 403: self = .forbidden
			case 429: self = .tooManyRequests
			case 550: self = .noData
			default: return nil // If it's any other status code, it's not documented in the API: https://docs.coinapi.io/market-data/rest-api/
			}
		}
	}
}
