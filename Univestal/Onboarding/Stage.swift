//
//  Stage.swift
//  Univestal
//
//  Created by Nathan Egbuna on 7/6/24.
//

import SwiftUI

struct Stage: View {
    @EnvironmentObject private var sessionManager: SessionManager
    
    var body: some View {
        Group {
            if let _ = sessionManager.currentUser {
                HomepageView()
            } else {
                AuthenticationView()
            }
        }
    }
}

#Preview { 
    Stage()
        .environmentObject(SessionManager())
        .environmentObject(AuthenticationService(sessionManager: SessionManager()))
        .environmentObject(TradingEnvironment.shared)
        .environmentObject(News())
        .environmentObject(Finnhub())
}

