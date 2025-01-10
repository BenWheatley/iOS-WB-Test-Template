//
//  AutoDecoder.swift
//  WB-Test-Template
//
//  Created by Ben Wheatley on 09/01/2025.
//

import Foundation

protocol AutoDecoder: Decodable {
	static func tryToDecodeArray(from data: Data) throws -> [Self]
	init(from data: Data) throws
	
	// Allows specification of custom date decoding strategy
	static var dateDecodingStrategy: JSONDecoder.DateDecodingStrategy? { get }
}

extension AutoDecoder {
	
	init(from data: Data) throws {
		do {
			let decoder = JSONDecoder()
			if let dateDecodingStrategy = Self.dateDecodingStrategy {
				decoder.dateDecodingStrategy = dateDecodingStrategy
			}
			self = try decoder.decode(Self.self, from: data)
		} catch {
			throw NetworkError.decodingError
		}
	}
	
	static func tryToDecodeArray(from data: Data) throws -> [Self] {
		do {
			let decoder = JSONDecoder()
			if let dateDecodingStrategy = Self.dateDecodingStrategy {
				decoder.dateDecodingStrategy = dateDecodingStrategy
			}
			return try decoder.decode([Self].self, from: data)
		} catch {
			throw NetworkError.decodingError
		}
	}
	
	static var dateDecodingStrategy: JSONDecoder.DateDecodingStrategy? { nil }
}
