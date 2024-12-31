//
//  NetworkStatusView.swift
//  Cadence
//
//  Created by Kushagra Dhawan on 30/12/24.
//

import SwiftUI

struct NetworkStatusView: View {
    @ObservedObject var networkMonitor: NetworkMonitor
    
    var body: some View {
        VStack {
            // Show different status based on connection type
            switch networkMonitor.status {
            case .disconnected:
                statusBanner(icon: "wifi.slash",
                           text: "No Internet Connection",
                           color: .red)
            case .cellular:
                statusBanner(icon: "antenna.radiowaves.left.and.right",
                           text: "Cellular Connection",
                           color: .orange)
            case .wifi:
                statusBanner(icon: "wifi",
                           text: "WiFi Connection",
                           color: .green)
            default:
                EmptyView()
            }
        }
        .animation(.easeInOut, value: networkMonitor.status)
    }
    
    private func statusBanner(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(text)
                .font(.subheadline)
                .foregroundColor(color)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

// Add Preview for better development
#Preview {
    VStack(spacing: 20) {
        NetworkStatusView(networkMonitor: NetworkMonitor())
    }
    .padding()
}

// End of file. No additional code.
