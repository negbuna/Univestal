# Authentication System Documentation

## Overview
The authentication system provides local user authentication using secure storage and biometric capabilities.

## Components
- `AuthenticationService`: Handles auth operations
- `SecureStorage`: Manages credential storage in Keychain
- `SessionManager`: Maintains user session state
- `AuthLogger`: Handles authentication logging

## Security Features
- Password hashing using SHA-256
- Secure credential storage in Keychain
- Biometric authentication support
- Session management
- Proper error handling

## Usage Examples
```swift
// Sign up
let auth = AuthenticationService()
try await auth.signUp(username: "user", password: "pass")

// Sign in
let user = try await auth.signIn(username: "user", password: "pass")

// Reset password
try await auth.resetPassword(username: "user", 
                           currentPassword: "old", 
                           newPassword: "new")
```