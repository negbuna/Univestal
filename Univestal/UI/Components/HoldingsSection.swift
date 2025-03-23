import SwiftUI

struct HoldingsSection<Content: View>: View {
    let title: String
    let isEmpty: Bool
    let type: AssetType
    let content: () -> Content
    
    init(
        title: String,
        isEmpty: Bool,
        type: AssetType,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.isEmpty = isEmpty
        self.type = type
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.headline)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.secondary.opacity(0.1))
            
            if isEmpty {
                EmptyHoldingsView(type: type)
            } else {
                VStack(spacing: 0) {
                    content()
                }
            }
        }
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
    }
}

struct EmptyHoldingsView: View {
    let type: AssetType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(type == .crypto ? "No cryptocurrency holdings yet" : "No stock holdings yet")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}
