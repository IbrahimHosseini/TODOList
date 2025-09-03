//
//  RemoteToDoRepository.swift
//  testAI
//
//  Created by Mahsa on 6/12/1404 AP.
//

import Foundation

/// A concrete repository that interacts with a remote HTTP API for to-do items.
public final class RemoteToDoRepository: ToDoRepository {

    private let baseURL: URL
    private let urlSession: URLSession
    private let jsonDecoder: JSONDecoder
    private let jsonEncoder: JSONEncoder

    public init(baseURL: URL, urlSession: URLSession = .shared) {
        self.baseURL = baseURL
        self.urlSession = urlSession
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.jsonDecoder = decoder
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.jsonEncoder = encoder
    }

    public func fetchAll() async throws -> [ToDoItem] {
        let url = baseURL.appending(path: "todos")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let (data, response) = try await urlSession.data(for: request)
        try RemoteToDoRepository.validate(response: response)
        let items = try jsonDecoder.decode([ToDoItem].self, from: data)
        return items
    }

    public func create(title: String) async throws -> ToDoItem {
        try await create(title: title, dueDate: nil)
    }

    public func create(title: String, dueDate: Date?) async throws -> ToDoItem {
        let url = baseURL.appending(path: "todos")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        struct CreatePayload: Encodable {
            let title: String
            let createdAt: Date
            let note: String
            let priority: ToDoPriority
            let dueDate: Date?
        }
        let payload = CreatePayload(title: title, createdAt: Date(), note: "", priority: .low, dueDate: dueDate)
        request.httpBody = try jsonEncoder.encode(payload)

        let (data, response) = try await urlSession.data(for: request)
        try RemoteToDoRepository.validate(response: response)
        let created = try jsonDecoder.decode(ToDoItem.self, from: data)
        return created
    }

    public func toggleCompletion(for item: ToDoItem) async throws -> ToDoItem {
        let url = baseURL.appending(path: "todos/\(item.id.uuidString)")
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        struct PatchPayload: Encodable { let isCompleted: Bool }
        request.httpBody = try jsonEncoder.encode(PatchPayload(isCompleted: !item.isCompleted))

        let (data, response) = try await urlSession.data(for: request)
        try RemoteToDoRepository.validate(response: response)
        let updated = try jsonDecoder.decode(ToDoItem.self, from: data)
        return updated
    }

    // NEW: Update details (title, note, priority, isCompleted, dueDate)
    public func updateDetails(for item: ToDoItem) async throws -> ToDoItem {
        let url = baseURL.appending(path: "todos/\(item.id.uuidString)")
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        struct PatchPayload: Encodable {
            let title: String
            let note: String
            let priority: ToDoPriority
            let isCompleted: Bool
            let dueDate: Date?
        }
        let payload = PatchPayload(
            title: item.title,
            note: item.note,
            priority: item.priority,
            isCompleted: item.isCompleted,
            dueDate: item.dueDate
        )
        request.httpBody = try jsonEncoder.encode(payload)

        let (data, response) = try await urlSession.data(for: request)
        try RemoteToDoRepository.validate(response: response)
        let updated = try jsonDecoder.decode(ToDoItem.self, from: data)
        return updated
    }

    public func delete(_ item: ToDoItem) async throws {
        let url = baseURL.appending(path: "todos/\(item.id.uuidString)")
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        let (_, response) = try await urlSession.data(for: request)
        try RemoteToDoRepository.validate(response: response, expectingBody: false)
    }

    public func delete(at offsets: IndexSet, in source: [ToDoItem]) async throws {
        for index in offsets {
            let item = source[index]
            try await delete(item)
        }
    }

    private static func validate(response: URLResponse, expectingBody: Bool = true) throws {
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        guard (200..<300).contains(http.statusCode) else {
            throw HTTPError(statusCode: http.statusCode, message: HTTPURLResponse.localizedString(forStatusCode: http.statusCode))
        }
        if !expectingBody, http.statusCode == 204 {
            return
        }
    }
}

