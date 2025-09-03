//
//  ToDoRepository.swift
//  testAI
//
//  Created by Mahsa on 6/12/1404 AP.
//

import Foundation

/// Abstraction for accessing To-Do data, e.g. from remote servers or local stores.
public protocol ToDoRepository {
    /// Fetches all to-do items from the data source.
    /// - Returns: An array of `ToDoItem` fetched from the repository.
    /// - Throws: An error if the fetch operation fails (e.g., network or decoding errors).
    func fetchAll() async throws -> [ToDoItem]

    /// Persists a new to-do item in the data source.
    /// - Parameter title: The title of the new to-do item.
    /// - Returns: The created `ToDoItem` returned by the data source.
    /// - Throws: An error if the creation operation fails.
    func create(title: String) async throws -> ToDoItem

    /// Toggles completion state for an item in the data source.
    /// - Parameter item: The item whose completion state should be toggled.
    /// - Returns: The updated `ToDoItem` returned by the data source.
    /// - Throws: An error if the update operation fails.
    func toggleCompletion(for item: ToDoItem) async throws -> ToDoItem

    /// Deletes an item in the data source.
    /// - Parameter item: The item to delete.
    /// - Throws: An error if the delete operation fails.
    func delete(_ item: ToDoItem) async throws

    /// Deletes multiple items by offsets. This is a convenience for batch deletes.
    /// - Parameter offsets: Indexes of items to delete in a given array context.
    /// - Parameter source: The source array to map offsets into items.
    /// - Throws: An error if any delete operation fails.
    func delete(at offsets: IndexSet, in source: [ToDoItem]) async throws
}

