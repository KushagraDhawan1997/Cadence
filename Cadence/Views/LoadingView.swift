//
//  LoadingView.swift
//  Cadence
//
//  Created by Kushagra Dhawan on 30/12/24.
//

import SwiftUI

struct LoadingView: View {
    let message: String?
    
    init(_ message: String? = nil) {
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: 8) {
            ProgressView()
            
            if let message = message {
                Text(message)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        LoadingView()
        LoadingView("Loading messages...")
    }
}

// End of file. No additional code.
