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
        content
            .background(alignment: .topLeading) {
                Image(systemName: "globe")
                    .foregroundStyle(.primary)
                    .frame(
                        width: 2*UIScreen.main.bounds.width,
                        height: 2*UIScreen.main.bounds.height)
                    .opacity(0.07)
                    .font(.system(size: 800))
                    .offset(x: 20, y: 2)
                    .ignoresSafeArea()
            }
    }
}

extension View {
    func globeOverlay() -> some View {
        self.modifier(GlobeOverlay())
    }
}
