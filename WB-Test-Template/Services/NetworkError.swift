//
//  NetworkError.swift
//  WB-Test-Template
//
//  Created by Ben Wheatley on 09/01/2025.
//

import Foundation

enum NetworkError: Error, Equatable {
	case invalidURL
	case noData
	case decodingError
	case serverError(String)
	case offline
}
