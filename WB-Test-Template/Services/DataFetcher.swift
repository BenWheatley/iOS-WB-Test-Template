//
//  DataFetcher.swift
//  WB-Test-Template
//
//  Created by Ben Wheatley on 13/01/2025.
//

import Foundation

// This is to allow a mocked version of URLSession for testing. As we only use this one function, there's no need for anything more complex.
protocol DataFetcher {
	func data(for request: URLRequest, delegate: (any URLSessionTaskDelegate)?) async throws -> (Data, URLResponse)
}

extension URLSession: DataFetcher {}
