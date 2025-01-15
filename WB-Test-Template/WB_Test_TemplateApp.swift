//
//  WB_Test_TemplateApp.swift
//  WB-Test-Template
//
//  Created by Admin on 12/24/24.
//

import SwiftUI

@main
struct WB_Test_TemplateApp: App {
	@StateObject private var coreDataStack = CoreDataStack.shared
	
    var body: some Scene {
        WindowGroup {
            AssetListView()
				.environment(\.managedObjectContext, coreDataStack.persistentContainer.viewContext)
        }
    }
}

