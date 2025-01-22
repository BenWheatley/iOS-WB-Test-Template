//
//  XCTestUtilities.swift
//  WB-Test-Template
//
//  Created by Ben Wheatley on 10/01/2025.
//

import XCTest

// Based on https://stackoverflow.com/a/75369851
extension XCTestCase {
	func measureAsync(
		expectationDescription: String = "\(#function) expectation",
		timeout: TimeInterval = 5.0,
		for block: @escaping () async throws -> Void,
		file: StaticString = #file,
		line: UInt = #line
	) {
		measureMetrics([.wallClockTime], automaticallyStartMeasuring: true) {
			let expectation = expectation(description: expectationDescription)
			Task { @MainActor in
				defer {
					expectation.fulfill()
				}
				do {
					try await block()
				} catch {
					XCTFail(error.localizedDescription, file: file, line: line)
				}
			}
			wait(for: [expectation], timeout: timeout)
		}
	}
}
