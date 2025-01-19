//
//  WB_Test_TemplateUITests.swift
//  WB-Test-TemplateUITests
//
//  Created by Admin on 12/24/24.
//

import XCTest

final class WB_Test_TemplateUITests: XCTestCase {

	/* TODO: list critical user flows, then implement tests for them
	 
	 - View Cryptocurrency List
	 - View Cryptocurrency Details
	 - Mark Cryptocurrency as Favorite
	 - Refresh Cryptocurrency Data
	 - Does cached data re-load when offline? (Prerequisite: already has already downloaded data)
	 - Save and Restore App State
	 
	 */
	
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
