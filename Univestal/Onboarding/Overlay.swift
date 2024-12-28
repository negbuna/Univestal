//
//  Overlay.swift
//  Univestal
//
//  Created by Nathan Egbuna on 12/24/24.
//

import SwiftUI

// Trying overlay as a var in a different way
struct GlobeOverlay: ViewModifier {
    func body(content: Content) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomTrailing) {
                content
                
                let size = min(geometry.size.width, geometry.size.height) * 1.5
                Image(systemName: "globe")
                    .foregroundStyle(.primary)
                    .font(.system(size: size))
                    .frame(width: size, height: size)
                    .opacity(0.07)
                    .offset(x: size/7, y: size/7) 
                    .clipped()
                    .frame(width: size/7, height: size/7)
                    .position(x: geometry.size.width, y: geometry.size.height)
            }
        }
    }
}

extension View {
    func globeOverlay() -> some View {
        self.modifier(GlobeOverlay())
    }
}
