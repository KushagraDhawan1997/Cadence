//
//  CadenceApp.swift
//  Cadence
//
//  Created by Kushagra Dhawan on 30/12/24.
//

import SwiftUI
import SwiftData

@main
struct CadenceApp: App {
    @StateObject private var dependencies = Dependencies()
    
    var body: some Scene {
        WindowGroup {
            ContentView(
                service: dependencies.apiClient,
                errorHandler: dependencies.errorHandler,
                networkMonitor: dependencies.networkMonitor
            )
            .modelContainer(dependencies.modelContainer)
        }
    }
}

// MARK: - Dependencies Management
class Dependencies: ObservableObject {
    let container = DependencyContainer.shared
    let modelContainer: ModelContainer
    let modelContext: ModelContext
    private var hasRegisteredDependencies = false
    
    // Expose dependencies as computed properties to ensure they're always available
    var apiClient: APIClient {
        guard hasRegisteredDependencies,
              let client = container.resolve(APIClient.self) else {
            fatalError("APIClient not available - Dependencies not properly initialized")
        }
        return client
    }
    
    var errorHandler: ErrorHandling {
        guard hasRegisteredDependencies,
              let handler = container.resolve(ErrorHandling.self) else {
            fatalError("ErrorHandler not available - Dependencies not properly initialized")
        }
        return handler
    }
    
    var networkMonitor: NetworkMonitor {
        guard hasRegisteredDependencies,
              let monitor = container.resolve(NetworkMonitor.self) else {
            fatalError("NetworkMonitor not available - Dependencies not properly initialized")
        }
        return monitor
    }
    
    init() {
        print("Initializing Dependencies...")
        
        // Create model container first
        let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: false)
        
        do {
            print("Creating ModelContainer...")
            modelContainer = try ModelContainer(for: Workout.self, configurations: modelConfiguration)
            modelContext = ModelContext(modelContainer)
            print("ModelContainer and ModelContext created successfully")
        } catch {
            print("Failed to create ModelContainer: \(error)")
            fatalError("Could not initialize ModelContainer: \(error)")
        }
        
        // Register core dependencies
        print("Registering core dependencies...")
        
        container.register(ModelContainer.self, instance: modelContainer)
        container.register(ModelContext.self, instance: modelContext)
        print("Registered ModelContainer and ModelContext")
        
        let errorHandler = ErrorHandler()
        container.register(ErrorHandling.self, instance: errorHandler)
        print("Registered ErrorHandler")
        
        let networkMonitor = NetworkMonitor()
        container.register(NetworkMonitor.self, instance: networkMonitor)
        print("Registered NetworkMonitor")
        
        // Register API client last since it depends on other services
        print("Registering APIClient...")
        container.register(APIClient.self) { container in
            guard let errorHandler = container.resolve(ErrorHandling.self),
                  let networkMonitor = container.resolve(NetworkMonitor.self),
                  let modelContext = container.resolve(ModelContext.self) else {
                print("Failed to resolve dependencies for APIClient")
                print("ErrorHandler available: \(container.resolve(ErrorHandling.self) != nil)")
                print("NetworkMonitor available: \(container.resolve(NetworkMonitor.self) != nil)")
                print("ModelContext available: \(container.resolve(ModelContext.self) != nil)")
                fatalError("Failed to resolve dependencies for APIClient")
            }
            
            print("Creating OpenAIService...")
            return OpenAIService(
                networkMonitor: networkMonitor,
                errorHandler: errorHandler,
                modelContext: modelContext
            )
        }
        
        hasRegisteredDependencies = true
        print("Dependencies initialization completed")
    }
}
