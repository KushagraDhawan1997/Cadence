//
//  CadenceApp.swift
//  Cadence
//
//  Created by Kushagra Dhawan on 30/12/24.
//

import SwiftUI

@main
struct CadenceApp: App {
    // Initialize dependency container
    init() {
        // Register all services when app starts
        DependencyContainer.shared.registerServices()
    }
    
    var body: some Scene {
        WindowGroup {
            // Initialize ContentView with all required dependencies
            if let service = DependencyContainer.shared.resolve(APIClient.self),
               let errorHandler = DependencyContainer.shared.resolve(ErrorHandling.self),
               let networkMonitor = DependencyContainer.shared.resolve(NetworkMonitor.self) {
                ContentView(service: service, errorHandler: errorHandler, networkMonitor: networkMonitor)
            } else {
                Text("Failed to initialize services")
                    .foregroundColor(.red)
            }
        }
    }
}
