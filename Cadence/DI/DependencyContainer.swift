//
//  DependencyContainer.swift
//  Cadence
//
//  Created by Kushagra Dhawan on 30/12/24.
//

import Foundation

// Protocol for our services to conform to
protocol Injectable {}

// Main container that will hold all our dependencies
class DependencyContainer {
    // MARK: - Singleton instance
    static let shared = DependencyContainer()
    
    // MARK: - Private properties
    private var services: [String: Any] = [:]
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - Registration
    func register<Service>(_ type: Service.Type, instance: Service) {
        services[String(describing: type)] = instance
    }
    
    // MARK: - Resolution
    func resolve<Service>(_ type: Service.Type) -> Service? {
        return services[String(describing: type)] as? Service
    }
}

// MARK: - Service Registration
extension DependencyContainer {
    func registerServices() {
        // Register network monitor first
        let networkMonitor = NetworkMonitor()
        register(NetworkMonitor.self, instance: networkMonitor)
        
        // Register error handler
        let errorHandler = ErrorHandler()
        register(ErrorHandling.self, instance: errorHandler)
        
        // Register OpenAI service with its dependencies
        let openAIService = OpenAIService(networkMonitor: networkMonitor, errorHandler: errorHandler)
        register(APIClient.self, instance: openAIService)
    }
}

// Make our NetworkService conform to Injectable
extension OpenAIService: Injectable {}
