//
//  DependencyContainer.swift
//  Cadence
//
//  Created by Kushagra Dhawan on 30/12/24.
//

import Foundation
import SwiftData

// Protocol for our services to conform to
protocol Injectable {}

// Main container that will hold all our dependencies
final class DependencyContainer {
    // MARK: - Singleton instance
    static let shared = DependencyContainer()
    
    // MARK: - Private properties
    private let lock = NSRecursiveLock()
    private var services: [String: Any] = [:]
    private var factories: [String: (DependencyContainer) -> Any] = [:]
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - Registration
    func register<Service>(_ type: Service.Type, instance: Service) {
        lock.lock()
        defer { lock.unlock() }
        services[String(describing: type)] = instance
    }
    
    func register<Service>(_ type: Service.Type, factory: @escaping (DependencyContainer) -> Service) {
        lock.lock()
        defer { lock.unlock() }
        factories[String(describing: type)] = factory
    }
    
    // MARK: - Resolution
    func resolve<Service>(_ type: Service.Type) -> Service? {
        lock.lock()
        defer { lock.unlock() }
        
        let key = String(describing: type)
        
        // First check if we have an instance
        if let instance = services[key] as? Service {
            return instance
        }
        
        // Then check if we have a factory
        if let factory = factories[key] {
            let instance = factory(self) as! Service
            // Cache the instance
            services[key] = instance
            return instance
        }
        
        return nil
    }
}

// Make our services conform to Injectable
extension OpenAIService: Injectable {}
extension ErrorHandler: Injectable {}
extension NetworkMonitor: Injectable {}
