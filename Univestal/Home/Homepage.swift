//
//  HomepageView.swift
//  Univestal
//
//  Created by Nathan Egbuna on 7/6/24.
//

import SwiftUI

struct HomepageView: View {
    @ObservedObject var appData: AppData
    @ObservedObject var crypto: Crypto
    @ObservedObject var news: News
    
    @State var isAnimating: Bool = false
    @State var appState: Int = 0 // REMEMBER TO CHANGE THIS BACK TO 0 WHEN SIMULATING
    @State var page: Int = 0
    
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
    HomepageView(appData: AppData(), crypto: Crypto(), news: News())
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
            UVHubView(appData: appData, news: news)
                .tabItem {
                    Label("Hub", systemImage: "globe")
                }
                .tag(0)
            Search(appData: appData, crypto: crypto)
                .tabItem {
                    Label("Coins", systemImage: "magnifyingglass")
                }
                .tag(1)
            Text("Trading View")
                .tabItem {
                    Label("Trade", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(2)
            Learn()
                .tabItem {
                    Label("Learn", systemImage: "puzzlepiece.extension")
                }
                .tag(3)
            UVProfileView(appData: appData)
                .tabItem {
                    Label("Me", systemImage: "person")
                }
                .tag(4)
        }
        .tabViewStyle(DefaultTabViewStyle())
        .edgesIgnoringSafeArea(.bottom)
    }
}
