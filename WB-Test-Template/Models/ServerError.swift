//
//  ServerError.swift
//  WB-Test-Template
//
//  Created by Ben Wheatley on 10/01/2025.
//

import Foundation

struct ServerError: Codable {
	let error: String
}

extension ServerError: AutoDecoder {}
