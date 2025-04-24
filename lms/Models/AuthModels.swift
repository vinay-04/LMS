//
//  AuthModels.swift
//  lms
//
//  Created by VR on 25/04/25.
//

import Foundation
import UIKit

// MARK: - User Model

struct User: Codable, Identifiable {
    let id: String
    let fullName: String
    let email: String
    var profileImageUrl: String?
    var role: UserRole
    var isVerified: Bool
    var mfaEnabled: Bool
    var preferences: [String: String]?
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case fullName = "full_name"
        case email
        case profileImageUrl = "profile_image_url"
        case role
        case isVerified = "is_verified"
        case mfaEnabled = "mfa_enabled"
        case preferences
        case createdAt = "created_at"
    }
}

enum UserRole: String, Codable, CaseIterable {
    case admin
    case librarian
    case member

    var description: String {
        switch self {
        case .admin:
            return "System Administrator"
        case .librarian:
            return "Library Staff"
        case .member:
            return "Library Member"
        }
    }

    var permissions: [Permission] {
        switch self {
        case .admin:
            return Permission.allCases
        case .librarian:
            return [.viewBooks, .manageBooks, .viewMembers, .viewLoans, .manageLoans]
        case .member:
            return [.viewBooks, .viewOwnLoans]
        }
    }
}

enum Permission: String, Codable, CaseIterable {
    case viewBooks = "view:books"
    case manageBooks = "manage:books"
    case viewMembers = "view:members"
    case manageMembers = "manage:members"
    case viewLoans = "view:loans"
    case manageLoans = "manage:loans"
    case viewOwnLoans = "view:own_loans"
    case systemConfig = "system:config"
}

// MARK: - Request Models

struct RegisterRequest: Codable {
    let fullName: String
    let email: String
    let password: String
    let role: UserRole

    enum CodingKeys: String, CodingKey {
        case fullName = "full_name"
        case email
        case password
        case role
    }
}

struct LoginRequest: Codable {
    let email: String
    let password: String

    enum CodingKeys: String, CodingKey {
        case email
        case password
    }
}

// MARK: - Response Models

struct AuthResponse: Codable {
    let userId: String
    let session: Session
    let user: User?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case session
        case user
    }
}

struct Session: Codable {
    let id: String
    let userId: String
    let provider: String
    let token: String
    let secret: String?
    let expire: Date
    let mfaPending: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case provider
        case token
        case secret
        case expire
        case mfaPending = "mfa_pending"
    }
}

// MARK: - MFA Models

struct MfaChallenge: Codable {
    let id: String
    let userId: String
    let createdAt: Date
    let expiresAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case createdAt = "created_at"
        case expiresAt = "expires_at"
    }
}

struct MfaResponse: Codable {
    let userId: String
    let session: Session

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case session
    }
}

struct MfaFactor: Codable, Identifiable {
    let id: String
    let type: MfaFactorType
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case createdAt = "created_at"
    }
}

enum MfaFactorType: String, Codable {
    case totp = "totp"
    case sms = "sms"
    case email = "email"
}

// MARK: - Auth State

enum AuthState: Equatable {
    case unauthenticated
    case authenticating
    case authenticated(User)
    case mfaRequired(MfaChallenge)
    case error(String)

    static func == (lhs: AuthState, rhs: AuthState) -> Bool {
        switch (lhs, rhs) {
        case (.unauthenticated, .unauthenticated):
            return true
        case (.authenticating, .authenticating):
            return true
        case (.authenticated(let lhsUser), .authenticated(let rhsUser)):
            return lhsUser.id == rhsUser.id
        case (.mfaRequired(let lhsChallenge), .mfaRequired(let rhsChallenge)):
            return lhsChallenge.id == rhsChallenge.id
        case (.error(let lhsMessage), .error(let rhsMessage)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }
}

// MARK: - Validation Helpers

struct ValidationError: Identifiable {
    let id = UUID()
    let message: String
}

extension RegisterRequest {
    static func validate(fullName: String, email: String, password: String, confirmPassword: String)
        -> [ValidationError]
    {
        var errors = [ValidationError]()

        if fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(ValidationError(message: "Full name is required"))
        }

        if email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(ValidationError(message: "Email is required"))
        } else if !isValidEmail(email) {
            errors.append(ValidationError(message: "Please enter a valid email address"))
        }

        if password.count < 8 {
            errors.append(ValidationError(message: "Password must be at least 8 characters"))
        }

        if password != confirmPassword {
            errors.append(ValidationError(message: "Passwords do not match"))
        }

        return errors
    }

    private static func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
}

struct MfaSetupData {
    let userId: String
    let secret: String
    let uri: String
    let qrCode: UIImage
}
