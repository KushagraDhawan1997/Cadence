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
    @Published private(set) var status: NetworkStatus = .connected  // Default to connected
    @Published private(set) var isConnected = true  // Default to true
    
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
    
    // MARK: - Monitoring Control
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.status = self?.determineStatus(from: path) ?? .disconnected
            }
        }
        monitor.start(queue: queue)
    }
    
    private func stopMonitoring() {
        monitor.cancel()
    }
    
    private func determineStatus(from path: NWPath) -> NetworkStatus {
        if !path.usesInterfaceType(.wifi) && !path.usesInterfaceType(.cellular) {
            return .disconnected
        }
        
        if path.usesInterfaceType(.wifi) {
            return .wifi
        }
        
        if path.usesInterfaceType(.cellular) {
            return .cellular
        }
        
        return path.status == .satisfied ? .connected : .disconnected
    }
}

