//
//  ToDoItem.swift
//  testAI
//
//  Created by Mahsa on 6/12/1404 AP.
//

import Foundation

public enum ToDoPriority: String, Codable, CaseIterable, Hashable {
    case low
    case medium
    case high
}

public struct ToDoItem: Identifiable, Hashable, Codable {
    public let id: UUID
    public internal(set) var title: String
    public internal(set) var isCompleted: Bool
    public internal(set) var createdAt: Date
    public internal(set) var note: String
    public internal(set) var priority: ToDoPriority
    public internal(set) var dueDate: Date? // NEW

    public init(
        id: UUID = UUID(),
        title: String,
        isCompleted: Bool = false,
        createdAt: Date = Date(),
        note: String = "",
        priority: ToDoPriority = .medium,
        dueDate: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.note = note
        self.priority = priority
        self.dueDate = dueDate
    }
}

