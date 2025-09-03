//
//  ToDoListViewModel.swift
//  testAI
//
//  Created by Mahsa on 6/12/1404 AP.
//

import Foundation
import Combine
import SwiftUI
import SwiftData
import OSLog

@MainActor
final class ToDoListViewModel: ObservableObject {
    @Published private(set) var items: [ToDoItem] = []
    @Published var errorPresentation: ErrorPresentation?
    @Published var isLoading: Bool = false

    private let service: ToDoService
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "ToDoApp", category: "ToDoListViewModel")

    init(context: ModelContext,
         baseURL: URL = URL(string: "https://example.com/api")!) {
        let localRepo = SwiftDataToDoRepository(context: context)
        let remoteRepo = RemoteToDoRepository(baseURL: baseURL)
        self.service = SyncingToDoService(local: localRepo, remote: remoteRepo)
    }

    var hasCompletedItems: Bool {
        items.contains(where: { $0.isCompleted })
    }

    func load() async {
        isLoading = true
        do {
            let loaded = try await service.loadItems()
            withAnimation(.easeInOut(duration: 0.2)) {
                self.items = sortItems(loaded)
            }
        } catch {
            handle(error, context: "Loading items")
        }
        isLoading = false
    }

    func add(title: String) {
        add(title: title, dueDate: nil)
    }

    func add(title: String, dueDate: Date?) {
        Task {
            do {
                let created = try await service.addItem(title: title, dueDate: dueDate)
                withAnimation(.easeInOut(duration: 0.2)) {
                    self.items = sortItems(self.items + [created])
                }
            } catch {
                handle(error, context: "Adding item")
            }
        }
    }

    func toggleCompletion(for item: ToDoItem) {
        Task {
            do {
                let updated = try await service.toggle(item)
                var newItems = items
                if let idx = newItems.firstIndex(where: { $0.id == item.id }) {
                    newItems[idx] = updated
                }
                withAnimation(.easeInOut(duration: 0.2)) {
                    self.items = sortItems(newItems)
                }
            } catch {
                handle(error, context: "Toggling completion")
            }
        }
    }

    func delete(_ item: ToDoItem) {
        Task {
            do {
                try await service.remove(item)
                withAnimation(.easeInOut(duration: 0.2)) {
                    self.items.removeAll { $0.id == item.id }
                }
            } catch {
                handle(error, context: "Deleting item")
            }
        }
    }

    func delete(at offsets: IndexSet) {
        Task {
            do {
                try await service.remove(at: offsets, in: self.items)
                withAnimation(.easeInOut(duration: 0.2)) {
                    self.items.remove(atOffsets: offsets)
                }
            } catch {
                handle(error, context: "Deleting items")
            }
        }
    }

    func moveItems(from source: IndexSet, to destination: Int) {
        // Since ordering is determined by sortItems, moving may be temporary.
        // We still reflect the move locally for immediate UX feedback.
        withAnimation(.easeInOut(duration: 0.2)) {
            var newItems = items
            newItems.move(fromOffsets: source, toOffset: destination)
            self.items = newItems
        }
    }

    func clearCompleted() {
        let snapshot = items
        Task {
            await service.removeCompleted(in: snapshot)
            withAnimation(.easeInOut(duration: 0.2)) {
                self.items.removeAll { $0.isCompleted }
            }
        }
    }

    // Update item details and re-sort
    func update(item: ToDoItem) {
        Task {
            do {
                let updated = try await service.update(item)
                var newItems = items
                if let idx = newItems.firstIndex(where: { $0.id == item.id }) {
                    newItems[idx] = updated
                }
                withAnimation(.easeInOut(duration: 0.2)) {
                    items = sortItems(newItems)
                }
            } catch {
                handle(error, context: "Updating item")
            }
        }
    }

    private func sortItems(_ items: [ToDoItem]) -> [ToDoItem] {
        func priorityRank(_ p: ToDoPriority) -> Int {
            switch p {
            case .high: return 0
            case .medium: return 1
            case .low: return 2
            }
        }

        return items.sorted { a, b in
            // 1) Incomplete first
            if a.isCompleted != b.isCompleted {
                return b.isCompleted // false < true
            }
            // 2) Priority: high, medium, low
            let ar = priorityRank(a.priority)
            let br = priorityRank(b.priority)
            if ar != br { return ar < br }
            // 3) Created date ascending (older first)
            if a.createdAt != b.createdAt { return a.createdAt < b.createdAt }
            // 4) Title localized, case-insensitive
            let at = a.title.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            let bt = b.title.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            if at != bt { return at.localizedCompare(bt) == .orderedAscending }
            // 5) Stable fallback by id
            return a.id.uuidString < b.id.uuidString
        }
    }

    private func handle(_ error: Error, context: String) {
        // Log
        logger.error("\(context, privacy: .public) failed: \(String(describing: error), privacy: .public)")
        // Map to presentation if possible
        if let appError = error as? AppError {
            errorPresentation = ErrorPresentation.from(appError)
        } else if let localized = error as? LocalizedError {
            let title = localized.errorDescription ?? context
            let message = localized.failureReason ?? localized.recoverySuggestion
            errorPresentation = ErrorPresentation(title: title, message: message)
        } else {
            errorPresentation = ErrorPresentation(title: context, message: error.localizedDescription)
        }
    }
}

