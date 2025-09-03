//
//  SwiftDataToDoRepository.swift
//  testAI
//
//  Created by Mahsa on 6/12/1404 AP.
//

import Foundation
import SwiftData

/// Local repository backed by SwiftData.
/// Provides CRUD operations and helpers for pending sync management.
public final class SwiftDataToDoRepository {

    private let context: ModelContext

    public init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Queries

    public func fetchAll() throws -> [ToDoEntity] {
        let descriptor = FetchDescriptor<ToDoEntity>(sortBy: [SortDescriptor(\.lastModified, order: .reverse)])
        return try context.fetch(descriptor)
    }

    public func fetch(by id: UUID) throws -> ToDoEntity? {
        let predicate = #Predicate<ToDoEntity> { $0.id == id }
        var descriptor = FetchDescriptor<ToDoEntity>(predicate: predicate)
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    // MARK: - Mutations

    @discardableResult
    public func upsert(from item: ToDoItem, markUpdated: Bool = false) throws -> ToDoEntity {
        if let existing = try fetch(by: item.id) {
            existing.apply(from: item)
            if markUpdated { existing.pendingUpdate = true }
            try context.save()
            return existing
        } else {
            let entity = item.toEntity(pendingCreate: true)
            context.insert(entity)
            try context.save()
            return entity
        }
    }

    @discardableResult
    public func createLocal(title: String, dueDate: Date? = nil, markPending: Bool = true) throws -> ToDoEntity {
        let now = Date()
        let entity = ToDoEntity(
            title: title,
            isCompleted: false,
            lastModified: now,
            createdAt: now,
            note: "",
            priorityRaw: ToDoPriority.medium.rawValue,
            dueDate: dueDate,
            pendingCreate: markPending
        )
        context.insert(entity)
        try context.save()
        return entity
    }

    public func updateLocalToggle(for itemID: UUID, isCompleted: Bool, markPending: Bool = true) throws {
        guard let entity = try fetch(by: itemID) else { return }
        entity.isCompleted = isCompleted
        entity.lastModified = Date()
        entity.pendingUpdate = markPending || entity.pendingCreate
        try context.save()
    }

    // NEW: Update multiple editable fields locally and mark pending update
    public func updateLocalDetails(
        for itemID: UUID,
        title: String,
        note: String,
        priority: ToDoPriority,
        isCompleted: Bool,
        dueDate: Date?, // NEW
        markPending: Bool = true
    ) throws -> ToDoEntity? {
        guard let entity = try fetch(by: itemID) else { return nil }
        entity.title = title
        entity.note = note
        entity.priority = priority
        entity.isCompleted = isCompleted
        entity.dueDate = dueDate
        entity.lastModified = Date()
        // If it was a brand-new pendingCreate, keep pendingCreate; otherwise mark update
        entity.pendingUpdate = markPending || entity.pendingCreate
        try context.save()
        return entity
    }

    public func deleteLocal(itemID: UUID, markPending: Bool = true) throws {
        guard let entity = try fetch(by: itemID) else { return }
        if markPending {
            entity.pendingDelete = true
            entity.lastModified = Date()
        } else {
            context.delete(entity)
        }
        try context.save()
    }

    public func hardDelete(itemID: UUID) throws {
        guard let entity = try fetch(by: itemID) else { return }
        context.delete(entity)
        try context.save()
    }

    // MARK: - Sync Helpers

    public func clearPendingFlags(for id: UUID) throws {
        guard let entity = try fetch(by: id) else { return }
        entity.pendingCreate = false
        entity.pendingUpdate = false
        entity.pendingDelete = false
        try context.save()
    }

    public func markSynced(with remote: ToDoItem) throws {
        guard let entity = try fetch(by: remote.id) else {
            let new = remote.toEntity()
            context.insert(new)
            try context.save()
            return
        }
        entity.apply(from: remote)
        entity.pendingCreate = false
        entity.pendingUpdate = false
        entity.pendingDelete = false
        try context.save()
    }

    public func replaceAll(with remotes: [ToDoItem]) throws {
        let current = try fetchAll()
        let remoteIDs = Set(remotes.map { $0.id })
        for item in remotes {
            if let entity = current.first(where: { $0.id == item.id }) {
                entity.apply(from: item)
                entity.pendingCreate = false
                entity.pendingUpdate = false
                entity.pendingDelete = false
            } else {
                let entity = item.toEntity()
                context.insert(entity)
            }
        }
        for entity in current {
            if !remoteIDs.contains(entity.id) && !entity.pendingCreate {
                context.delete(entity)
            }
        }
        try context.save()
    }

    public func pendingCreates() throws -> [ToDoEntity] {
        let predicate = #Predicate<ToDoEntity> { $0.pendingCreate == true && $0.pendingDelete == false }
        return try context.fetch(FetchDescriptor(predicate: predicate))
    }

    public func pendingUpdates() throws -> [ToDoEntity] {
        let predicate = #Predicate<ToDoEntity> { $0.pendingUpdate == true && $0.pendingDelete == false && $0.pendingCreate == false }
        return try context.fetch(FetchDescriptor(predicate: predicate))
    }

    public func pendingDeletes() throws -> [ToDoEntity] {
        let predicate = #Predicate<ToDoEntity> { $0.pendingDelete == true }
        return try context.fetch(FetchDescriptor(predicate: predicate))
    }
}

