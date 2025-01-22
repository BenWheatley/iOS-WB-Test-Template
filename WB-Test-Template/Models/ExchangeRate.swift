//
//  ExchangeRate.swift
//  WB-Test-Template
//
//  Created by Ben Wheatley on 09/01/2025.
//

import Foundation

struct ExchangeRate: Codable {
	let time: Date
	let assetIdBase: String?
	let assetIdQuote: String?
	let rate: Double
	
	enum CodingKeys: String, CodingKey {
		case time = "time"
		case assetIdBase = "asset_id_base"
		case assetIdQuote = "asset_id_quote"
		case rate = "rate"
	}
}

extension ExchangeRate: AutoDecoder {
	static let dateDecodingStrategy: JSONDecoder.DateDecodingStrategy? = {
		let formatter = DateFormatter()
		formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSSX" // Matches the date format in the JSON
		return .formatted(formatter)
	}()
}
