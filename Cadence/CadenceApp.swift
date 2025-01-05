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
    let container: DependencyContainer
    let modelContainer: ModelContainer
    
    init() {
        container = .shared
        
        // Setup ModelContainer
        let schema = Schema([
            Workout.self,
            Exercise.self,
            ExerciseSet.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema)
        do {
            modelContainer = try ModelContainer(for: schema, configurations: modelConfiguration)
            
            // Register services
            let workoutService = WorkoutService(modelContext: modelContainer.mainContext)
            container.register(WorkoutService.self, instance: workoutService)
            
            let networkMonitor = NetworkMonitor()
            container.register(NetworkMonitor.self, instance: networkMonitor)
            
            let errorHandler = ErrorHandler()
            container.register(ErrorHandler.self, instance: errorHandler)
            
            let openAIService = OpenAIService(
                networkMonitor: networkMonitor,
                errorHandler: errorHandler,
                modelContext: modelContainer.mainContext
            )
            container.register(OpenAIService.self, instance: openAIService)
            
        } catch {
            fatalError("Could not initialize ModelContainer")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(
                service: container.resolve(OpenAIService.self)!,
                errorHandler: container.resolve(ErrorHandler.self)!,
                networkMonitor: container.resolve(NetworkMonitor.self)!
            )
        }
        .modelContainer(modelContainer)
    }
}
