import SwiftUI
import SwiftData

struct WorkoutHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Workout.timestamp, order: .reverse) private var workouts: [Workout]
    @State private var selectedType: WorkoutType?
    
    private var filteredWorkouts: [Workout] {
        guard let selectedType else { return workouts }
        return workouts.filter { workout in
            workout.type == selectedType
        }
    }
    
    private var groupedWorkouts: [(String, [Workout])] {
        print("Total workouts: \(workouts.count)")
        workouts.forEach { workout in
            print("Workout: \(workout.type.displayName), Duration: \(workout.duration ?? 0), Time: \(workout.timestamp)")
        }
        
        let grouped = Dictionary(grouping: filteredWorkouts) { workout in
            Calendar.current.startOfDay(for: workout.timestamp)
        }
        return grouped.map { (date, workouts) in
            (date.formatted(date: .abbreviated, time: .omitted), workouts)
        }.sorted { $0.0 > $1.0 }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Quick Stats
                QuickStatsView(workouts: workouts)
                    .padding()
                    .background(Color(.systemGroupedBackground))
                
                // Filter Pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterPill(title: "All", isSelected: selectedType == nil) {
                            selectedType = nil
                        }
                        
                        ForEach(WorkoutType.allCases, id: \.self) { type in
                            FilterPill(
                                title: type.displayName,
                                isSelected: selectedType == type
                            ) {
                                selectedType = type
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .background(Color(.systemGroupedBackground))
                
                List {
                    ForEach(groupedWorkouts, id: \.0) { date, dayWorkouts in
                        Section(date) {
                            ForEach(dayWorkouts) { workout in
                                WorkoutRow(workout: workout)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Workout History")
        }
        .onAppear {
            print("WorkoutHistoryView appeared")
            print("ModelContext available: \(modelContext != nil)")
            print("Current workouts count: \(workouts.count)")
        }
    }
}

struct QuickStatsView: View {
    let workouts: [Workout]
    
    private var thisWeekCount: Int {
        let startOfWeek = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        return workouts.filter { $0.timestamp >= startOfWeek }.count
    }
    
    private var thisMonthCount: Int {
        let startOfMonth = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date()))!
        return workouts.filter { $0.timestamp >= startOfMonth }.count
    }
    
    var body: some View {
        HStack(spacing: 20) {
            StatBox(title: "This Week", value: "\(thisWeekCount)")
            StatBox(title: "This Month", value: "\(thisMonthCount)")
        }
    }
}

struct StatBox: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(10)
    }
}

struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? .blue : Color(.secondarySystemGroupedBackground))
                .foregroundStyle(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

struct WorkoutRow: View {
    let workout: Workout
    
    var body: some View {
        HStack {
            Image(systemName: workout.type.iconName)
                .font(.title2)
                .frame(width: 32)
                .foregroundStyle(.blue)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.type.displayName)
                    .font(.headline)
                
                if let duration = workout.duration {
                    Text("\(duration) minutes")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                if let notes = workout.notes {
                    Text(notes)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Text(workout.timestamp.formatted(date: .omitted, time: .shortened))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    NavigationStack {
        WorkoutHistoryView()
    }
    .modelContainer(for: Workout.self, inMemory: true)
} 