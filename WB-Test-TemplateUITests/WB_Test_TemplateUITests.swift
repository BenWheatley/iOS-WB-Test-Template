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
	 
	 [x] View currency list
	 [x] Use string search filter
	 [x] Use favourites filter
	 [x] View specific currency details
	 [x] Mark specific currency as favorite
	 [ ] Refresh currency data
	 
	 The way these tests are currently functioning is more like a full integration test than a pure UI test
	 
	 If I wanted to reconfigure this into a *pure* UI test, I'd need to use the existing dependency injection system
	 
	 I'd probably move the `TestInjectables` type to the main project (which feels like a "code smell" in that it seems wrong but I can't say why exactly) — if there's a mechanism for creating a TestInjectables instance here, in the test target, and passing that instance (by val as it's a struct) to the app, I don't know it
	 */
	
	private var app: XCUIApplication! // Allowed to be implictly unwrapping because if a test crashes this counts as a way to fail sucessfully
	
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
		
		app = XCUIApplication()
		/*
		 I'm not actually using launchArguments in this in this projct, but it could be done via:
		 
		- `app.launchArguments = ["ui-testing"]` // here
		- `ProcessInfo.processInfo.arguments.contains("ui-testing")` // in the app code
		 */
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
	
	func testSearchAndFavouriteFilter() {
		let favoritesButton = app.buttons["favoritesToggleButton"]
		let showingFavoritesBefore = utility_isShowingFavoritesOnly(favoritesButton)
		
		// We need to ensure favourites are off, may as well test the favourites button as part of this
		if showingFavoritesBefore {
			favoritesButton.tap()
			XCTAssertNotEqual(showingFavoritesBefore, utility_isShowingFavoritesOnly(favoritesButton))
		} else {
			favoritesButton.tap()
			XCTAssertNotEqual(showingFavoritesBefore, utility_isShowingFavoritesOnly(favoritesButton))
			favoritesButton.tap()
			XCTAssertEqual(showingFavoritesBefore, utility_isShowingFavoritesOnly(favoritesButton))
		}
		
		let searchField = utility_getSearchField()
		XCTAssertTrue(searchField.exists, "Search field should be visible.")
		let desirableCell = utility_getBitcoinElement(searchField: searchField)
		let foundCellThatShouldExist = desirableCell.waitForExistence(timeout: 5) // My observation is that it can take 4 seconds even over the network to fetch and parse all the data
		XCTAssertTrue(foundCellThatShouldExist, "Should be able to find Bitcoin cell")
		
		searchField.tap()
		searchField.clearText(andReplaceWith: "any_text_that_finds_nothing_e8392jdsjjd398j3j2dmsd")
		let undesirableCell = app.collectionViews["Asset list"].buttons["AssetRowView_BTC-AssetRowView_BTC-AssetRowView_BTC"]
		let foundCellThatShouldNotExist = undesirableCell.waitForExistence(timeout: 1) // Should already be loaded, won't need 5 seconds this time
		XCTAssertFalse(foundCellThatShouldNotExist, "Found Bitcoin cell but it should have been filtered out")
	}
	
	func testViewBitcoinDetails() {
		utility_makeSureFavouritesIsOff()
		
		let searchField = utility_getSearchField()
		let cell = utility_getBitcoinElement(searchField: searchField).firstMatch
		let exists = cell.waitForExistence(timeout: 15) // My observation is that it can take 4 seconds to fetch and parse all the data; even though this is already tested, we need to wait so we can tap the cell
		XCTAssertTrue(exists, "Should be able to find Bitcoin cell")
		cell.tap()
		
		// We should now be in the details page, of which there is only the favourite button and the navigation stack
		let favouriteButton = app.buttons["Favourite"]
		XCTAssertTrue(favouriteButton.exists)
	}
	
	func testBitcoinFavourite() {
		utility_makeSureFavouritesIsOff()
		
		let searchField = utility_getSearchField()
		let cell = utility_getBitcoinElement(searchField: searchField).firstMatch
		let searchExists = cell.waitForExistence(timeout: 5)
		XCTAssertTrue(searchExists, "Should be able to find Bitcoin cell")
		
		cell.tap()
		
		let favouriteButton = app.buttons["isFavorite"]
		XCTAssertTrue(favouriteButton.exists)
		let wasAlreadyAFavorite = utility_isFavouriteTest(element: favouriteButton)
		
		// Does button change state?
		favouriteButton.tap()
		XCTAssertNotEqual(wasAlreadyAFavorite, utility_isFavouriteTest(element: favouriteButton))
		
		// Does button return to old state?
		favouriteButton.tap()
		XCTAssertEqual(wasAlreadyAFavorite, utility_isFavouriteTest(element: favouriteButton))
		
		// If current state at this point is "not favorite" then make it a favorite
		if !utility_isFavouriteTest(element: favouriteButton) {
			favouriteButton.tap()
		}
		
		// Return to main screen, close search
		app.navigationBars["Bitcoin"].buttons["Crypto Monitor"].tap()
		app.navigationBars["Crypto Monitor"].buttons["Cancel"].tap()
		
		// Favourites filter has already been set to off, now make it on
		let favouriteFilter = app.buttons["favoritesToggleButton"]
		let favouriteFilterExists = favouriteFilter.waitForExistence(timeout: 1)
		XCTAssertTrue(favouriteFilterExists, "Should be able to find favourites filter button")
		favouriteFilter.tap()
		
		// Find asset in list
		let updatedCell = utility_getBitcoinElement(searchField: searchField)
		let updatedCellExists = cell.waitForExistence(timeout: 5)
		XCTAssertTrue(updatedCellExists, "Should have found Bitcoin cell but didn't")
		
		// Return to details page, clear favourite state
		updatedCell.tap()
		let newFavouriteButton = app.buttons["isFavorite"]
		XCTAssertTrue(newFavouriteButton.exists)
		// Button should exist and be in "is fave" state
		XCTAssertTrue(utility_isFavouriteTest(element: newFavouriteButton))
	}
	
	func testDragToReload() {
		app.collectionViews["Asset list"].swipeDown()
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

extension WB_Test_TemplateUITests {
	func utility_getSearchField() -> XCUIElement {
		app.navigationBars["Crypto Monitor"].searchFields["Search"]
	}
	
	func utility_isShowingFavoritesOnly(_ favoritesButton: XCUIElement) -> Bool {
		favoritesButton.identifier == "star.fill" // As we can't read @State or viewModel directly from test, read the identifier of the label
	}
	
	func utility_makeSureFavouritesIsOff() {
		let favoritesButton = app.buttons["favoritesToggleButton"]
		let showingFavoritesBefore = utility_isShowingFavoritesOnly(favoritesButton)
		
		if showingFavoritesBefore {
			favoritesButton.tap()
		}
	}
	
	func utility_isFavouriteTest(element: XCUIElement) -> Bool {
		(element.value as? String == "Is currently a favourite")
	}
	
	func utility_getBitcoinElement(searchField: XCUIElement) -> XCUIElement {
		searchField.tap()
		searchField.clearText(andReplaceWith: "Bitcoin")
		return app.collectionViews["Asset list"]
			.buttons
			.element(matching: NSPredicate(format: "identifier CONTAINS[c] 'AssetRowView_BTC'"))
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
