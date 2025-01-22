//
//  TimeSeriesData.swift
//  WB-Test-Template
//
//  Created by Ben Wheatley on 22/01/2025.
//

import Foundation

struct TimeSeriesData: Codable {
	let timePeriodStart: Date
	let timePeriodEnd: Date
	let timeOpen: Date?
	let timeClose: Date?
	let rateOpen: Double?
	let rateHigh: Double?
	let rateLow: Double?
	let rateClose: Double?
	
	enum CodingKeys: String, CodingKey {
		case timePeriodStart = "time_period_start"
		case timePeriodEnd = "time_period_end"
		case timeOpen = "time_open"
		case timeClose = "time_close"
		case rateOpen = "rate_open"
		case rateHigh = "rate_high"
		case rateLow = "rate_low"
		case rateClose = "rate_close"
	}
}

extension TimeSeriesData: AutoDecoder {
	static let dateDecodingStrategy: JSONDecoder.DateDecodingStrategy? = {
		let formatter = DateFormatter()
		formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSSX" // Matches the date format in the JSON
		return .formatted(formatter)
	}()
}
