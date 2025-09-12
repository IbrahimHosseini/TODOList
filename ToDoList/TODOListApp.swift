//
//  TODOListApp.swift
//  testAI
//
//  Created by Mahsa on 6/12/1404 AP.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

@main
struct TODOListApp: App {

    // MARK: - ModelContainer

    var container: ModelContainer = {
        let schema = Schema([ToDoEntity.self])

        // Primary on-disk configuration (SwiftData manages the file location).
        let persistentConfig = ModelConfiguration(
            "Main",
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )

        do {
            return try ModelContainer(for: schema, configurations: [persistentConfig])
        } catch {
            #if DEBUG
            // In Debug, fall back to in-memory so the app can still run after incompatible changes.
            let inMemory = ModelConfiguration(
                "InMemory",
                schema: schema,
                isStoredInMemoryOnly: true,
                allowsSave: true
            )
            return try! ModelContainer(for: schema, configurations: [inMemory])
            #else
            // In Release, also fall back to in-memory so the app still runs.
            let inMemory = ModelConfiguration(
                "InMemory",
                schema: schema,
                isStoredInMemoryOnly: true,
                allowsSave: true
            )
            return try! ModelContainer(for: schema, configurations: [inMemory])
            #endif
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
        }
    }
}

// MARK: - Legacy Helpers (unused with current SwiftData API)
// Keeping this around in case you later adopt a custom store location via
// groupContainer or future APIs that expose file URLs. Currently unused.
private func resetStore(at url: URL) throws {
    let fm = FileManager.default

    // SwiftData (Core Data) may create -shm/-wal sidecars for SQLite.
    let basePath = url.path
    let shm = URL(fileURLWithPath: basePath + "-shm")
    let wal = URL(fileURLWithPath: basePath + "-wal")

    if fm.fileExists(atPath: url.path) {
        try fm.removeItem(at: url)
    }
    if fm.fileExists(atPath: shm.path) {
        try fm.removeItem(at: shm)
    }
    if fm.fileExists(atPath: wal.path) {
        try fm.removeItem(at: wal)
    }
}
