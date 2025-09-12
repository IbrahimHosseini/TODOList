//
//  SyncEngine.swift
//  testAI
//
//  Created by Mahsa on 6/12/1404 AP.
//

import Foundation
import OSLog

/// Processes pending local operations against the remote repository.
actor SyncEngine {
    private let local: SwiftDataToDoRepository
    private let remote: ToDoRepository
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "ToDoApp", category: "SyncEngine")

    init(local: SwiftDataToDoRepository, remote: ToDoRepository) {
        self.local = local
        self.remote = remote
    }

    func syncAll() async {
        await syncCreates()
        await syncUpdates()
        await syncDeletes()
    }

    // A lightweight, Sendable representation of the data we need from ToDoEntity.
    private struct PendingCreateDTO: Sendable {
        let id: UUID
        let title: String
    }

    private struct PendingUpdateDTO: Sendable {
        let item: ToDoItem
    }

    private struct PendingDeleteDTO: Sendable {
        let item: ToDoItem
    }

    private func syncCreates() async {
        do {
            // Fetch Sendable DTOs on the MainActor
            let creates: [PendingCreateDTO] = try await MainActor.run {
                try local.pendingCreates().map { entity in
                    PendingCreateDTO(id: entity.id, title: entity.title)
                }
            }
            for dto in creates {
                do {
                    // Create remotely using current local title
                    let created = try await remote.create(title: dto.title)
                    // Mark synced on MainActor using the remote canonical item
                    try await MainActor.run {
                        try local.markSynced(with: created)
                    }
                } catch {
                    logger.error("Sync create failed for \(dto.id.uuidString, privacy: .public): \(error.localizedDescription, privacy: .public)")
                }
            }
        } catch {
            logger.error("Listing pending creates failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func syncUpdates() async {
        do {
            // Fetch Sendable DTOs on the MainActor
            let updates: [PendingUpdateDTO] = try await MainActor.run {
                try local.pendingUpdates().map { entity in
                    PendingUpdateDTO(item: entity.toItem())
                }
            }
            for dto in updates {
                do {
                    let updated = try await remote.toggleCompletion(for: dto.item)
                    try await MainActor.run {
                        try local.markSynced(with: updated)
                    }
                } catch {
                    logger.error("Sync update failed for \(dto.item.id.uuidString, privacy: .public): \(error.localizedDescription, privacy: .public)")
                }
            }
        } catch {
            logger.error("Listing pending updates failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func syncDeletes() async {
        do {
            // Fetch Sendable DTOs on the MainActor
            let deletes: [PendingDeleteDTO] = try await MainActor.run {
                try local.pendingDeletes().map { entity in
                    PendingDeleteDTO(item: entity.toItem())
                }
            }
            for dto in deletes {
                do {
                    try await remote.delete(dto.item)
                    try await MainActor.run {
                        try local.hardDelete(itemID: dto.item.id)
                    }
                } catch {
                    logger.error("Sync delete failed for \(dto.item.id.uuidString, privacy: .public): \(error.localizedDescription, privacy: .public)")
                }
            }
        } catch {
            logger.error("Listing pending deletes failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}
