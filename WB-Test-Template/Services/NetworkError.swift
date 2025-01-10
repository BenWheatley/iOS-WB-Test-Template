//
//  NetworkError.swift
//  WB-Test-Template
//
//  Created by Ben Wheatley on 09/01/2025.
//

import Foundation

enum NetworkError: Error, Equatable {
	case invalidURL
	/// This is "no data" in the client level, as HTTP 550 "No data" would be a `serverError`
	case noData
	case decodingError
	case serverError(RecognisedServerError?, String)
	case offline
	
	/// These are all the recognised server errors from the API documentation: https://docs.coinapi.io/market-data/rest-api/
	enum RecognisedServerError: Equatable {
		case badRequest
		case unauthorized
		case forbidden
		case tooManyRequests
		/// This is "no data" as a `serverError`, if there is no data at the client level this would be `NetworkError.noData`
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
