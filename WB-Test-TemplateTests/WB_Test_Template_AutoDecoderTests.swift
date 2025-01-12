//
//  WB_Test_Template_AutoDecoderTests.swift
//  WB-Test-TemplateTests
//
//  Created by Ben Wheatley on 12/01/2025.
//

import Testing
import Foundation
@testable import WB_Test_Template

struct WB_Test_Template_AutoDecoderTests {
	
	// General note for these test cases: Force unwrap used. I assert this is acceptable in test cases, because a test that crashes shouldn't be considered a success
	
	@Test func testAutoDecoder_decodingError() async throws {
		struct AutoDecoderBrokenJSONTest: AutoDecoder {
			let foo: String
		}
		
		let invalidJsonData = "{foo: \"bar\"}".data(using: .utf8)!
		#expect(throws: NetworkError.decodingError) { try AutoDecoderBrokenJSONTest.init(from: invalidJsonData) }
	}
	
	@Test func testAutoDecoder_String() async throws {
		struct AutoDecoderStringTest: AutoDecoder {
			let foo: String
		}
		
		let jsonData = "{\"foo\": \"bar\"}".data(using: .utf8)!
		#expect(throws: Never.self) { try AutoDecoderStringTest(from: jsonData) }
		
		let jsonDataArray = "[{\"foo\": \"bar\"}]".data(using: .utf8)!
		#expect(throws: Never.self) { try AutoDecoderStringTest.tryToDecodeArray(from: jsonDataArray) }
		
		let jsonDataWrongType = "{\"foo\": 1}".data(using: .utf8)!
		#expect(throws: NetworkError.decodingError) { try AutoDecoderStringTest(from: jsonDataWrongType) }
	}
	
	@Test func testAutoDecoder_Date() async throws {
		struct AutoDecoderDateTest_noCustomDateDecoder: AutoDecoder {
			let foo: Date
		}
		
		let jsonData = "{\"foo\": \"2025-01-09T10:03:59.5855665Z\"}".data(using: .utf8)!
		#expect(throws: NetworkError.decodingError) {
			// We expect a decoding error because this is not the default date format Swift+Decoder expects
			try AutoDecoderDateTest_noCustomDateDecoder(from: jsonData)
		}
		
		struct AutoDecoderDateTest_withCustomDateDecoder: AutoDecoder {
			let foo: Date
			static let dateDecodingStrategy: JSONDecoder.DateDecodingStrategy? = {
				let formatter = DateFormatter()
				formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSSX" // Matches the date format in the JSON
				return .formatted(formatter)
			}()
		}
		
		#expect(throws: Never.self) { try AutoDecoderDateTest_withCustomDateDecoder(from: jsonData) }
		
		let jsonDataArray = "[{\"foo\": \"2025-01-09T10:03:59.5855665Z\"}]".data(using: .utf8)!
		#expect(throws: Never.self) { try AutoDecoderDateTest_withCustomDateDecoder.tryToDecodeArray(from: jsonDataArray) }
		
		let jsonDataWrongType = "{\"foo\": 1}".data(using: .utf8)!
		#expect(throws: NetworkError.decodingError) { try AutoDecoderDateTest_withCustomDateDecoder(from: jsonDataWrongType) }
	}
	
	@Test func testAutoDecoder_Bool() async throws {
		struct AutoDecoderBoolTest: AutoDecoder {
			let foo: Bool
		}
		
		let jsonData = "{\"foo\": true}".data(using: .utf8)!
		#expect(throws: Never.self) { try AutoDecoderBoolTest(from: jsonData) }
		
		let jsonDataArray = "[{\"foo\": false}]".data(using: .utf8)!
		#expect(throws: Never.self) { try AutoDecoderBoolTest.tryToDecodeArray(from: jsonDataArray) }
		
		let jsonDataWrongType = "{\"foo\": 1}".data(using: .utf8)!
		#expect(throws: NetworkError.decodingError) { try AutoDecoderBoolTest(from: jsonDataWrongType) }
	}
	
	@Test func testAutoDecoder_Int() async throws {
		struct AutoDecoderIntTest: AutoDecoder {
			let foo: Int
		}
		
		let jsonData = "{\"foo\": 3}".data(using: .utf8)!
		#expect(throws: Never.self) { try AutoDecoderIntTest(from: jsonData) }
		
		let jsonDataArray = "[{\"foo\": -42}]".data(using: .utf8)!
		#expect(throws: Never.self) { try AutoDecoderIntTest.tryToDecodeArray(from: jsonDataArray) }
		
		let jsonDataWrongType = "{\"foo\": \"1\"}".data(using: .utf8)!
		#expect(throws: NetworkError.decodingError) { try AutoDecoderIntTest(from: jsonDataWrongType) }
	}
	
	@Test func testAutoDecoder_Double() async throws {
		struct AutoDecoderDoubleTest: AutoDecoder {
			let foo: Double
		}
		
		let jsonData = "{\"foo\": 3.141592}".data(using: .utf8)!
		#expect(throws: Never.self) { try AutoDecoderDoubleTest(from: jsonData) }
		
		let jsonDataArray = "[{\"foo\": 0}]".data(using: .utf8)!
		#expect(throws: Never.self) { try AutoDecoderDoubleTest.tryToDecodeArray(from: jsonDataArray) }
		
		let jsonDataWrongType = "{\"foo\": \"1\"}".data(using: .utf8)!
		#expect(throws: NetworkError.decodingError) { try AutoDecoderDoubleTest(from: jsonDataWrongType) }
	}
	
	@Test func testAutoDecoder_InnerArray() async throws {
		struct AutoDecoderInnerArrayTest: AutoDecoder {
			let foo: [Double]
		}
		
		let jsonData = "{\"foo\": [1,1,2,3,5,8,13,21,34,55,89]}".data(using: .utf8)!
		#expect(throws: Never.self) { try AutoDecoderInnerArrayTest(from: jsonData) }
		
		let jsonDataArray = "[{\"foo\": [1,1,2,3,5,8,13,21,34,55,89]}]".data(using: .utf8)!
		#expect(throws: Never.self) { try AutoDecoderInnerArrayTest.tryToDecodeArray(from: jsonDataArray) }
		
		let jsonDataWrongType = "{\"foo\": \"1\"}".data(using: .utf8)!
		#expect(throws: NetworkError.decodingError) { try AutoDecoderInnerArrayTest(from: jsonDataWrongType) }
	}

}
