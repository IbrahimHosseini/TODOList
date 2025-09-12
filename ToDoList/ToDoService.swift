//
//  ToDoService.swift
//  testAI
//
//  Created by Mahsa on 6/12/1404 AP.
//

import Foundation

/// Business-facing service for managing to-do items within the app.
/// This layer is intended for use by view models and coordinates with repositories.
public protocol ToDoService {
    func loadItems() async throws -> [ToDoItem]
    func addItem(title: String) async throws -> ToDoItem
    func addItem(title: String, dueDate: Date?) async throws -> ToDoItem
    func toggle(_ item: ToDoItem) async throws -> ToDoItem

    // NEW: Update editable fields of an item
    func update(_ item: ToDoItem) async throws -> ToDoItem

    func remove(_ item: ToDoItem) async throws
    func remove(at offsets: IndexSet, in: [ToDoItem]) async throws
    func removeImmediately(_ item: ToDoItem) async
    func removeCompleted(in items: [ToDoItem]) async
}

