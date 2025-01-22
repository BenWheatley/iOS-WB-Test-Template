//
//  TestBundleLoader.swift
//  WB-Test-TemplateTests
//
//  Created by Ben Wheatley on 13/01/2025.
//

import Foundation

class TestBundleLoader {
	static let shared = TestBundleLoader()
	
	private let testBundle: Bundle
	
	private init() {
		testBundle = Bundle(for: type(of: self))
	}
	
	func data(forResource resource: String, withExtension fileExtension: String) throws -> Data? {
		guard let mockFileURL = TestBundleLoader.shared.testBundle.url(forResource: resource, withExtension: fileExtension) else {
			return nil
		}
		return try Data(contentsOf: mockFileURL)
	}
}
