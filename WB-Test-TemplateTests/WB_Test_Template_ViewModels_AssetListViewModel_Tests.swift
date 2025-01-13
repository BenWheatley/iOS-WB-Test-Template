//
//  WB_Test_Template_ViewModels_AssetListViewModel_Tests.swift
//  WB-Test-TemplateTests
//
//  Created by Ben Wheatley on 10/01/2025.
//

import Foundation
import Testing
@testable import WB_Test_Template

actor WB_Test_Template_ViewModels_AssetListViewModel_Tests {
	let testBundle: Bundle
	
	init() {
		testBundle = Bundle(for: type(of: self))
	}
}

extension WB_Test_Template_ViewModels_AssetListViewModel_Tests {

	@MainActor @Test func testAssetFilter() {
		let sut = AssetListViewModel()
		sut.assets = []
		#expect(sut.filteredAssets.count == 0)
		
		let mockFileName = "test-asset-id=MST"
		guard let mockFileURL = testBundle.url(forResource: mockFileName, withExtension: "json"),
			  let mockData = try? Data(contentsOf: mockFileURL) else {
			Issue.record("Failed to load mock data from file")
			return
		}
		
		guard let assets = try? Asset.tryToDecodeArray(from: mockData) else {
			Issue.record("Failed to decode mock data from file")
			return
		}
		sut.assets = assets
		#expect(sut.filteredAssets.count == 1)
		
		// Test name/ID filtering
		
		sut.filterAssets(searchText: "any old nonsense h39iunjsdka")
		#expect(sut.filteredAssets.count == 0)
		
		sut.filterAssets(searchText: "MST")
		#expect(sut.filteredAssets.count == 1)
		
		sut.filterAssets(searchText: "alternate between zero and non-zero result searches")
		#expect(sut.filteredAssets.count == 0)
		
		sut.filterAssets(searchText: "MustangCoin")
		#expect(sut.filteredAssets.count == 1)
		
		sut.filterAssets(searchText: "last search text that should get no results")
		#expect(sut.filteredAssets.count == 0)
		
		sut.filterAssets(searchText: "")
		#expect(sut.filteredAssets.count == 1)
		
		// Now test "favourites" filtering
		
		sut.toggleFavoritesFilter(true)
		#expect(sut.filteredAssets.count == 0)
		
		sut.assets[0].isFavorite = true
		#expect(sut.filteredAssets.count == 1)
	}

}
