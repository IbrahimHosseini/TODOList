//
//  SyncingToDoService.swift
//  testAI
//
//  Created by Mahsa on 6/12/1404 AP.
//

import Foundation

/// A ToDoService that reads from local SwiftData and synchronizes with a remote repository.
public struct SyncingToDoService: ToDoService {

    private let local: SwiftDataToDoRepository
    private let remote: ToDoRepository
    private let syncEngine: SyncEngine

    public init(local: SwiftDataToDoRepository, remote: ToDoRepository) {
        self.local = local
        self.remote = remote
        self.syncEngine = SyncEngine(local: local, remote: remote)
    }

    public func loadItems() async throws -> [ToDoItem] {
        let locals = try local.fetchAll().map { $0.toItem() }
        Task {
            do {
                let remotes = try await self.remote.fetchAll()
                try await MainActor.run {
                    try self.local.replaceAll(with: remotes)
                }
                await self.syncEngine.syncAll()
            } catch {
            }
        }
        return locals
    }

    public func addItem(title: String) async throws -> ToDoItem {
        try await addItem(title: title, dueDate: nil)
    }

    public func addItem(title: String, dueDate: Date?) async throws -> ToDoItem {
        let entity = try local.createLocal(title: title, dueDate: dueDate, markPending: true)
        let localItem = entity.toItem()
        Task {
            do {
                if let remoteRepo = self.remote as? RemoteToDoRepository {
                    let created = try await remoteRepo.create(title: title, dueDate: dueDate)
                    try await MainActor.run {
                        try self.local.markSynced(with: created)
                    }
                } else {
                    let created = try await self.remote.create(title: title)
                    try await MainActor.run {
                        try self.local.markSynced(with: created)
                    }
                }
                await self.syncEngine.syncAll()
            } catch {
            }
        }
        return localItem
    }

    public func toggle(_ item: ToDoItem) async throws -> ToDoItem {
        try local.updateLocalToggle(for: item.id, isCompleted: !item.isCompleted, markPending: true)
        let updatedLocal = ToDoItem(
            id: item.id,
            title: item.title,
            isCompleted: !item.isCompleted,
            createdAt: item.createdAt,
            note: item.note,
            priority: item.priority,
            dueDate: item.dueDate
        )
        Task {
            do {
                let updated = try await self.remote.toggleCompletion(for: item)
                try await MainActor.run {
                    try self.local.markSynced(with: updated)
                }
                await self.syncEngine.syncAll()
            } catch {
            }
        }
        return updatedLocal
    }

    // NEW: Update details
    public func update(_ item: ToDoItem) async throws -> ToDoItem {
        _ = try local.updateLocalDetails(
            for: item.id,
            title: item.title,
            note: item.note,
            priority: item.priority,
            isCompleted: item.isCompleted,
            dueDate: item.dueDate,
            markPending: true
        )
        let updatedLocal = item
        Task {
            // Try to call a remote update if available
            if let remoteRepo = remote as? RemoteToDoRepository {
                do {
                    let updated = try await remoteRepo.updateDetails(for: item)
                    try await MainActor.run {
                        try self.local.markSynced(with: updated)
                    }
                    await self.syncEngine.syncAll()
                } catch {
                }
            } else {
                // If no remote update API, let sync engine handle or remain local
                await self.syncEngine.syncAll()
            }
        }
        return updatedLocal
    }

    public func remove(_ item: ToDoItem) async throws {
        try local.deleteLocal(itemID: item.id, markPending: true)
        Task {
            do {
                try await self.remote.delete(item)
                try await MainActor.run {
                    try self.local.hardDelete(itemID: item.id)
                }
                await self.syncEngine.syncAll()
            } catch {
            }
        }
    }

    public func remove(at offsets: IndexSet, in source: [ToDoItem]) async throws {
        for index in offsets {
            let item = source[index]
            try await remove(item)
        }
    }

    public func removeImmediately(_ item: ToDoItem) async {
        do {
            try local.hardDelete(itemID: item.id)
        } catch {
            return
        }
        Task {
            do {
                try await self.remote.delete(item)
            } catch {
            }
        }
    }

    public func removeCompleted(in items: [ToDoItem]) async {
        let completed = items.filter { $0.isCompleted }
        await withTaskGroup(of: Void.self) { group in
            for item in completed {
                group.addTask {
                    await self.removeImmediately(item)
                }
            }
        }
    }
}

