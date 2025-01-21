//
//  CoreDataStack.swift
//  WB-Test-Template
//
//  Created by Ben Wheatley on 13/01/2025.
//

import Foundation
import CoreData

// As per https://developer.apple.com/documentation/coredata/setting_up_a_core_data_stack
class CoreDataStack: ObservableObject {
	static let shared = CoreDataStack()
	
	// Create a persistent container as a lazy variable to defer instantiation until its first use.
	lazy var persistentContainer: NSPersistentContainer = {
		
		// Pass the data model filename to the container’s initializer.
		let container = NSPersistentContainer(name: "CoreDataModel")
		
		// Load any persistent stores, which creates a store if none exists.
		container.loadPersistentStores { _, error in
			if let error {
				// Handle the error appropriately. However, it's useful to use
				// `fatalError(_:file:line:)` during development.
				fatalError("Failed to load persistent stores: \(error.localizedDescription)")
			}
		}
		return container
	}()
		
	private init() { }
}

extension CoreDataStack {
	// Add a convenience method to commit changes to the store.
	func save() {
		// Verify that the context has uncommitted changes.
		guard persistentContainer.viewContext.hasChanges else { return }
		
		do {
			// Attempt to save changes.
			try persistentContainer.viewContext.save()
		} catch {
			// Handle the error appropriately.
			print("Failed to save the context:", error.localizedDescription)
		}
	}
}
