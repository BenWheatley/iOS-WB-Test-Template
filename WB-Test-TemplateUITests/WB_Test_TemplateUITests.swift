//
//  WB_Test_TemplateUITests.swift
//  WB-Test-TemplateUITests
//
//  Created by Admin on 12/24/24.
//

import XCTest

final class WB_Test_TemplateUITests: XCTestCase {

	/*
	 Critical flows:
	 
	 - View currency list
	 - View specific currency details
	 - Mark specific currency as favorite, remove specific currency as favourite
	 - Refresh currency data
	 - Does cached data re-load when offline? (Prerequisite: already has already downloaded data)
	 - Save and restore app state
	 */
	
	private var app: XCUIApplication! // Allowed to be implictly unwrapping because if a test crashes this counts as a way to fail sucessfully
	
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
		
		app = XCUIApplication()
		// TODO: pre-load test values
		// e.g. app.launchArguments = ["enable-testing"]
		app.launch()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
		app = nil
    }
	
	func testViewCurrencyList() {
		let list = app.collectionViews["Asset list"]
		XCTAssert(list.exists, "Currency list should be visible.")
	}
	
	func testViewBitcoinDetails() {
		let searchField = app.navigationBars["Crypto Monitor"].searchFields["Search"]
		XCTAssertTrue(searchField.exists, "Search field should be visible.")
		searchField.tap()
		searchField.clearText(andReplaceWith: "Bitcoin")
		let cell = app.collectionViews["Asset list"].buttons["AssetRowView_BTC-AssetRowView_BTC-AssetRowView_BTC"]
		let exists = cell.waitForExistence(timeout: 5)
		XCTAssertTrue(exists, "Should be able to find Bitcoin cell")
		cell.tap()
	}
	
	func testBitcoinFavourite() {
		let searchField = app.navigationBars["Crypto Monitor"].searchFields["Search"]
		XCTAssertTrue(searchField.exists, "Search field should be visible.")
		
		// TODO: test if bitcoint in favourite list at this point
		
		searchField.tap()
		searchField.clearText(andReplaceWith: "Bitcoin")
		let cell = app.collectionViews["Asset list"].buttons["AssetRowView_BTC-AssetRowView_BTC-AssetRowView_BTC"]
		let exists = cell.waitForExistence(timeout: 5)
		XCTAssertTrue(exists, "Should be able to find Bitcoin cell")
		cell.tap()
		
		// TODO: test if its != previous "is in list"-ness
		// TODO: return to this view, tap again
		// TODO: test if its has returned to == previous "is in list"-ness
		
		let favouriteButton = app.buttons["Favourite"]
		XCTAssertTrue(favouriteButton.exists)
		let previousFavouriteState = favouriteButton.value
		favouriteButton.tap()
		favouriteButton.tap()
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

// Taken from https://stackoverflow.com/a/54455917
extension XCUIElement {
	func clearText(andReplaceWith newText:String? = nil) {
		tap()
		press(forDuration: 1.0)
		var select = XCUIApplication().menuItems["Select All"]

		if !select.exists {
			select = XCUIApplication().menuItems["Select"]
		}
		//For empty fields there will be no "Select All", so we need to check
		if select.waitForExistence(timeout: 0.5), select.exists {
			select.tap()
			typeText(String(XCUIKeyboardKey.delete.rawValue))
		} else {
			tap()
		}
		if let newVal = newText {
			typeText(newVal)
		}
	}
}
