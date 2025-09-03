//
//  AppError.swift
//  testAI
//
//  Created by Mahsa on 6/12/1404 AP.
//

import Foundation

/// A user-facing error type that wraps underlying technical errors and provides friendly messages.
public enum AppError: Error, LocalizedError, Equatable {
    case network(description: String)
    case server(statusCode: Int, description: String)
    case decoding(description: String)
    case timeout
    case cancelled
    case unknown(description: String)

    public var errorDescription: String? {
        switch self {
        case .network:
            return "Network Error"
        case .server:
            return "Server Error"
        case .decoding:
            return "Data Error"
        case .timeout:
            return "Request Timed Out"
        case .cancelled:
            return "Operation Cancelled"
        case .unknown:
            return "Something Went Wrong"
        }
    }

    public var failureReason: String? {
        switch self {
        case .network(let description):
            return description
        case .server(let statusCode, let description):
            return "Status code: \(statusCode). \(description)"
        case .decoding(let description):
            return description
        case .timeout:
            return "The request took too long to complete."
        case .cancelled:
            return "The operation was cancelled."
        case .unknown(let description):
            return description
        }
    }

    /// Maps any Error to AppError with best-effort classification.
    public static func map(_ error: Error) -> AppError {
        if let app = error as? AppError { return app }

        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost, .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed:
                return .network(description: urlError.localizedDescription)
            case .timedOut:
                return .timeout
            case .cancelled:
                return .cancelled
            default:
                return .network(description: urlError.localizedDescription)
            }
        }

        if let decoding = error as? DecodingError {
            return .decoding(description: decoding.localizedDescription)
        }

        if let http = error as? HTTPError {
            return .server(statusCode: http.statusCode, description: http.message ?? "Unexpected server response.")
        }

        return .unknown(description: (error as NSError).localizedDescription)
    }
}

/// A lightweight HTTP error used by repositories to surface status codes.
public struct HTTPError: Error, Equatable {
    public let statusCode: Int
    public let message: String?

    public init(statusCode: Int, message: String? = nil) {
        self.statusCode = statusCode
        self.message = message
    }
}
