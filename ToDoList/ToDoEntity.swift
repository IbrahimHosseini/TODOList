//
//  ToDoEntity.swift
//  testAI
//
//  Created by Mahsa on 6/12/1404 AP.
//

import Foundation
import SwiftData

@Model
public final class ToDoEntity {
    @Attribute(.unique) public var id: UUID
    public var title: String
    public var isCompleted: Bool
    public var lastModified: Date

    // New fields
    public var createdAt: Date
    public var note: String
    public var priorityRaw: String // store enum raw value
    public var dueDate: Date? // NEW

    // Sync metadata
    public var pendingCreate: Bool
    public var pendingUpdate: Bool
    public var pendingDelete: Bool

    public init(id: UUID = UUID(),
                title: String,
                isCompleted: Bool = false,
                lastModified: Date = Date(),
                createdAt: Date = Date(),
                note: String = "",
                priorityRaw: String = ToDoPriority.medium.rawValue,
                dueDate: Date? = nil,
                pendingCreate: Bool = false,
                pendingUpdate: Bool = false,
                pendingDelete: Bool = false) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.lastModified = lastModified
        self.createdAt = createdAt
        self.note = note
        self.priorityRaw = priorityRaw
        self.dueDate = dueDate
        self.pendingCreate = pendingCreate
        self.pendingUpdate = pendingUpdate
        self.pendingDelete = pendingDelete
    }
}

// MARK: - Mapping

public extension ToDoEntity {
    var priority: ToDoPriority {
        get { ToDoPriority(rawValue: priorityRaw) ?? .medium }
        set { priorityRaw = newValue.rawValue }
    }

    func toItem() -> ToDoItem {
        ToDoItem(
            id: id,
            title: title,
            isCompleted: isCompleted,
            createdAt: createdAt,
            note: note,
            priority: priority,
            dueDate: dueDate
        )
    }

    func apply(from item: ToDoItem, modifiedAt: Date = Date()) {
        self.title = item.title
        self.isCompleted = item.isCompleted
        self.createdAt = item.createdAt
        self.note = item.note
        self.priority = item.priority
        self.dueDate = item.dueDate
        self.lastModified = modifiedAt
    }
}

public extension ToDoItem {
    func toEntity(modifiedAt: Date = Date(),
                  pendingCreate: Bool = false,
                  pendingUpdate: Bool = false,
                  pendingDelete: Bool = false) -> ToDoEntity {
        ToDoEntity(
            id: id,
            title: title,
            isCompleted: isCompleted,
            lastModified: modifiedAt,
            createdAt: createdAt,
            note: note,
            priorityRaw: priority.rawValue,
            dueDate: dueDate,
            pendingCreate: pendingCreate,
            pendingUpdate: pendingUpdate,
            pendingDelete: pendingDelete
        )
    }
}

