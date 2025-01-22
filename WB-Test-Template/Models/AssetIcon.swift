//
//  AssetIcon.swift
//  WB-Test-Template
//
//  Created by Ben Wheatley on 09/01/2025.
//

import Foundation

struct AssetIcon: Codable {
	let exchangeId: String?
	let assetId: String?
	let url: String?
	
	enum CodingKeys: String, CodingKey {
		case exchangeId = "exchange_id"
		case assetId = "asset_id"
		case url = "url"
	}
}

extension AssetIcon: AutoDecoder {}
