//
//  LoadingView.swift
//  Cadence
//
//  Created by Kushagra Dhawan on 30/12/24.
//

import SwiftUI

struct LoadingView: View {
    let message: String?
    @State private var isAnimating = false
    
    init(_ message: String? = nil) {
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(Color.accentColor, lineWidth: 4)
                .frame(width: 50, height: 50)
                .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                .animation(
                    Animation
                        .linear(duration: 1)
                        .repeatForever(autoreverses: false),
                    value: isAnimating
                )
            
            Color.clear
                .frame(width: 120, height: 120)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                .overlay {
                    VStack(spacing: 12) {
                        Circle()
                            .trim(from: 0, to: 0.7)
                            .stroke(Color.accentColor, lineWidth: 4)
                            .frame(width: 50, height: 50)
                            .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                            .animation(
                                Animation
                                    .linear(duration: 1)
                                    .repeatForever(autoreverses: false),
                                value: isAnimating
                            )
                        
                        if let message = message {
                            Text(message)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: 100)
                        }
                    }
                    .padding()
                }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.systemBackground))
                .shadow(radius: 8)
        )
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        LoadingView()
        LoadingView("Loading messages...")
    }
    .padding()
}
