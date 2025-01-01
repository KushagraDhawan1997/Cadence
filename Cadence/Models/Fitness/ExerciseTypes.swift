//
//  ExerciseTypes.swift
//  Cadence
//
//  Created by Assistant on 1/1/2024
//

import Foundation

// Workout type defines the training focus
enum WorkoutType: String, Codable, CaseIterable {
    case strength = "strength"
    case cardio = "cardio"
    case hiit = "hiit"
    case flexibility = "flexibility"
    case mobility = "mobility"
    case custom = "custom"
}

// Body part target defines the area focus
enum BodyPartTarget: String, Codable, CaseIterable {
    case upperBody = "upper_body"
    case lowerBody = "lower_body"
    case fullBody = "full_body"
    case core = "core"
    case push = "push"
    case pull = "pull"
    case legs = "legs"
}
