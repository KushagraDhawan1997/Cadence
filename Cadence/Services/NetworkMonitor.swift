//
//  NetworkMonitor.swift
//  Cadence
//
//  Created by Kushagra Dhawan on 30/12/24.
//

import Foundation
import Network

// MARK: - Network Status
enum NetworkStatus: String {
    case connected
    case disconnected
    case cellular
    case wifi
    
    var description: String {
        switch self {
        case .connected:
            return "Connected"
        case .disconnected:
            return "Not Connected"
        case .cellular:
            return "Cellular Connection"
        case .wifi:
            return "WiFi Connection"
        }
    }
}

// MARK: - Network Monitor
class NetworkMonitor: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var status: NetworkStatus = .disconnected
    @Published private(set) var isConnected = false
    
    // MARK: - Private Properties
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    // MARK: - Initialization
    init() {
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    // MARK: - Monitoring Methods
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            
            // Determine connection type
            let status: NetworkStatus = path.status == .satisfied
                ? (path.usesInterfaceType(.cellular) ? .cellular : .wifi)
                : .disconnected
            
            DispatchQueue.main.async {
                self.status = status
                self.isConnected = path.status == .satisfied
            }
        }
        
        monitor.start(queue: queue)
    }
    
    private func stopMonitoring() {
        monitor.cancel()
    }
    
    // MARK: - Helper Methods
    func isNetworkAvailable() -> Bool {
        return isConnected
    }
    
    func getNetworkType() -> NetworkStatus {
        return status
    }
}

