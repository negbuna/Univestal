//
//  HomepageView.swift
//  Univestal
//
//  Created by Nathan Egbuna on 7/6/24.
//

import SwiftUI

struct HomepageView: View {
    @EnvironmentObject var appData: AppData
    @EnvironmentObject var environment: TradingEnvironment
    @State var isAnimating: Bool = false
    @State var appState: Int = 0
    @State var page: Int = 0
    @Binding var tradeUUID: UUID?
    
    var body: some View {
        VStack {
            switch appState {
            case 0:
                welcomeSec2
                    .transition(appData.transition)
            case 1:
                homepage
                    .transition(appData.transition)
            default:
                welcomeSec2
                    .transition(appData.transition)
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    HomepageView(tradeUUID: .constant(UUID()))
        .environmentObject(AppData())
        .environmentObject(TradingEnvironment.shared)
}

extension HomepageView {
    private var welcomeSec2: some View {
        GeometryReader { geometry in
            VStack {
                Text("Welcome")
                    .foregroundStyle(.primary)
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                    .padding()
                    .offset(y: isAnimating ? 0 : geometry.size.height)
                    .opacity(isAnimating ? 1 : 0)
                    .frame(
                        width: geometry.size.width,
                        height: geometry.size.height,
                        alignment: .center)
            }
            .onAppear {
                withAnimation(.easeOut(duration: 2)) {
                    isAnimating = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        appState = 1
                    }
                }
            }
        }
    }
    
    private var homepage: some View {
        TabView(selection: $page) {
            UVHubView()
                .tabItem {
                    Label("Hub", systemImage: "globe")
                }
                .tag(0)
            Watchlist()
                .tabItem {
                    Label("Watchlist", systemImage: "star")
                }
                .tag(1)
            TradingView(tradeUUID: $tradeUUID)
                .tabItem {
                    Label("Trade", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(2)
            Learn()
                .tabItem {
                    Label("Learn", systemImage: "puzzlepiece")
                }
                .tag(3)
            UVProfileView()
                .tabItem {
                    Label("Me", systemImage: "person")
                }
                .tag(4)
        }
        .tabViewStyle(DefaultTabViewStyle())
        .edgesIgnoringSafeArea(.bottom)
    }
}
