//
//  ErrorPresentation.swift
//  testAI
//
//  Created by Mahsa on 6/12/1404 AP.
//

import Foundation

/// An Identifiable wrapper for presenting errors in SwiftUI alerts.
public struct ErrorPresentation: Identifiable, Equatable {
    public let id = UUID()
    public let title: String
    public let message: String?

    public init(title: String, message: String?) {
        self.title = title
        self.message = message
    }

    public static func from(_ error: AppError) -> ErrorPresentation {
        ErrorPresentation(title: error.errorDescription ?? "Error", message: error.failureReason)
    }
}
