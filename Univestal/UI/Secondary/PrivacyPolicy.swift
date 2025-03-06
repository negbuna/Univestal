//
//  PrivacyPolicy.swift
//  Univestal
//
//  Created by Nathan Egbuna on 11/22/24.
//

import SwiftUI

struct PrivacyPolicy: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            Text(
        """
        \(boldText("Effective Date: December 28, 2024"))
        
        \(boldText("Univestal")) (“we,” “our,” or “us”) values your privacy and is committed to protecting your personal data. This Privacy Policy explains how we collect, use, and safeguard your information when you use our app.
        
        \(boldText("Data We Collect"))
        Login Information: You are required to create an account to use Univestal. We collect your username and email address to manage your account and ensure your data, such as portfolio value and past trades, is assigned to you.
        
        Photos: If you grant access to your device's photo library (via Apple’s private photo access), we only use this data for app functionality. These photos remain on your device and are not stored on our servers.
        
        \(boldText("How We Use Your Data"))
        To manage your account and provide access to your portfolio and trading history.
        To enable functionality requiring access to photos.
        To communicate with you about app updates, changes, or account issues.
        
        \(boldText("Data Security"))
        We take your privacy seriously and employ technical and organizational measures to protect your information. Your data is encrypted and stored securely. Photos accessed through Apple’s private photo library are never stored on our servers and remain fully under your control.
        Sharing Your Data
        We do not sell, rent, or share your personal information or photos with third parties.
        
        \(boldText("Your Choices"))
        Account Creation: An account is required to use Univestal, as it ensures your portfolio and data are assigned to you.
        Photo Access: Granting access to your photo library is optional. You can revoke access at any time through your device settings.
        
        \(boldText("Changes To This Policy"))
        We may update this Privacy Policy to reflect changes in our practices. Any updates will be communicated through the app or via email.
        
        \(boldText("Contact Us"))
        If you have questions or concerns about this Privacy Policy, please contact us at univestal@gmail.com.
        
        """
                )
                .padding()
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.blue)
                }
            }
        }
    }
    
    private func boldText(_ text: String) -> Text {
        return Text(text).bold()
    }
}

#Preview {
    PrivacyPolicy()
}
