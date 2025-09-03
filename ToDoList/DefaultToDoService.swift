//
//  DefaultToDoService.swift
//  testAI
//
//  Created by Mahsa on 6/12/1404 AP.
//

import Foundation

/// Default implementation of `ToDoService` that uses a `ToDoRepository`.
public struct DefaultToDoService: ToDoService {

    private let repository: ToDoRepository
    private let logger: (@Sendable (String) -> Void)?

    /// Creates a new service using the given repository.
    /// - Parameters:
    ///   - repository: The repository used for data access.
    ///   - logger: Optional logging closure for best-effort error reporting.
    public init(repository: ToDoRepository, logger: (@Sendable (String) -> Void)? = nil) {
        self.repository = repository
        self.logger = logger
    }

    /// Loads all items from the repository.
    public func loadItems() async throws -> [ToDoItem] {
        try await repository.fetchAll()
    }

    /// Adds a new item through the repository.
    public func addItem(title: String) async throws -> ToDoItem {
        try await repository.create(title: title)
    }

    /// Adds a new item with an optional due date.
    public func addItem(title: String, dueDate: Date?) async throws -> ToDoItem {
        if let remote = repository as? RemoteToDoRepository {
            return try await remote.create(title: title, dueDate: dueDate)
        } else {
            // Fallback: repository doesn’t support dueDate on create
            return try await repository.create(title: title)
        }
    }

    /// Toggles completion state through the repository.
    public func toggle(_ item: ToDoItem) async throws -> ToDoItem {
        try await repository.toggleCompletion(for: item)
    }

    /// NEW: Update editable fields of an item.
    /// Tries to use a RemoteToDoRepository if available; otherwise throws unsupported.
    public func update(_ item: ToDoItem) async throws -> ToDoItem {
        if let remote = repository as? RemoteToDoRepository {
            return try await remote.updateDetails(for: item)
        } else {
            // If only completion changed and generic repo supports toggling, try that path.
            // Without the "previous" item, we can’t infer field changes here, so we declare unsupported.
            struct UnsupportedUpdateError: LocalizedError {
                var errorDescription: String? { "Update operation is not supported by the current repository." }
            }
            throw UnsupportedUpdateError()
        }
    }

    /// Removes an item through the repository.
    public func remove(_ item: ToDoItem) async throws {
        try await repository.delete(item)
    }

    /// Removes multiple items through the repository.
    public func remove(at offsets: IndexSet, in source: [ToDoItem]) async throws {
        try await repository.delete(at: offsets, in: source)
    }

    /// Immediately attempts to delete the item (best effort).
    /// Errors are intentionally ignored to satisfy "best effort" semantics.
    public func removeImmediately(_ item: ToDoItem) async {
        do {
            try await repository.delete(item)
        } catch {
            // Best-effort: ignore errors, optionally log
            logger?("Best-effort delete failed for item \(item.id): \(error)")
        }
    }

    /// Convenience to immediately delete all completed items (best effort).
    /// Errors for individual deletions are ignored so others can proceed.
    public func removeCompleted(in items: [ToDoItem]) async {
        // Capture dependencies locally to avoid cross-actor access to self.
        let localRepository = repository
        let localLogger = logger

        // Process concurrently but don’t fail the whole operation if one fails.
        await withTaskGroup(of: Void.self) { group in
            for item in items where item.isCompleted {
                group.addTask {
                    do {
                        try await localRepository.delete(item)
                    } catch {
                        // Best-effort: ignore and continue, optionally log
                        localLogger?("Best-effort delete failed for completed item \(item.id): \(error)")
                    }
                }
            }
        }
    }
}

