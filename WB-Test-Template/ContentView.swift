//
//  ContentView.swift
//  WB-Test-Template
//
//  Created by Admin on 12/24/24.
//

import SwiftUI

struct ContentView: View {
	@StateObject private var coreDataStack = CoreDataStack.shared
	
    var body: some View {
		AssetListView(viewModel: AssetListViewModel(context: coreDataStack.persistentContainer.viewContext))
    }
}

#Preview {
    ContentView()
}
