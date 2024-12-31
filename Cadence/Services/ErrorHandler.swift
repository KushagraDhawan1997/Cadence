//
//  ErrorHandler.swift
//  Cadence
//
//  Created by Kushagra Dhawan on 30/12/24.
//

import Foundation

// MARK: - App Error Types
enum AppError: LocalizedError {
    case network(NetworkError)
    case authentication
    case serverError(String)
    case userError(String)
    case systemError(String)
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .network(let error):
            return "Network Error: \(error.localizedDescription)"
        case .authentication:
            return "Authentication failed. Please check your credentials."
        case .serverError(let message):
            return "Server Error: \(message)"
        case .userError(let message):
            return message
        case .systemError(let message):
            return "System Error: \(message)"
        case .unknown(let error):
            return "An unexpected error occurred: \(error.localizedDescription)"
        }
    }
}

// MARK: - Error Handler Protocol
protocol ErrorHandling {
    func handle(_ error: Error) -> AppError
    func handleWithRetry(_ operation: @escaping () async throws -> Void) async throws
    func log(_ error: Error)
}

// MARK: - Error Handler Implementation
class ErrorHandler: ErrorHandling {
    // MARK: - Properties
    private let maxRetries = 3
    private let retryDelay: UInt64 = 2_000_000_000 // 2 seconds
    
    // MARK: - Error Handling
    func handle(_ error: Error) -> AppError {
        if let appError = error as? AppError {
            return appError
        }
        
        if let networkError = error as? NetworkError {
            return .network(networkError)
        }
        
        // Add more specific error type handling here
        
        return .unknown(error)
    }
    
    // MARK: - Retry Logic
    func handleWithRetry(_ operation: @escaping () async throws -> Void) async throws {
        var lastError: Error?
        
        for attempt in 1...maxRetries {
            do {
                try await operation()
                return
            } catch {
                lastError = error
                log(error)
                
                if attempt < maxRetries {
                    try await Task.sleep(nanoseconds: retryDelay * UInt64(attempt))
                }
            }
        }
        
        if let error = lastError {
            throw handle(error)
        }
    }
    
    // MARK: - Logging
    func log(_ error: Error) {
        // In a real app, you might want to use a proper logging service
        #if DEBUG
        print("🔴 Error: \(error.localizedDescription)")
        if let appError = error as? AppError {
            print("📝 App Error Type: \(String(describing: type(of: appError)))")
        }
        print("📍 Stack Trace: \(Thread.callStackSymbols)")
        #endif
        
        // TODO: Add crash reporting service integration
        // TODO: Add remote logging
    }
}

// MARK: - Error Handler Extensions
extension ErrorHandler {
    func handleNetworkError(_ error: Error) -> NetworkError {
        if let networkError = error as? NetworkError {
            return networkError
        }
        return .requestFailed(error)
    }
}
