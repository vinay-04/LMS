//
//  AppwriteConfig.swift
//  lms
//
//  Created by VR on 25/04/25.
//

import Foundation

class DotEnv {
    static let shared = DotEnv()
    private var variables: [String: String] = [:]

    private init() {
        loadEnv()
    }

    private func loadEnv() {
        guard let path = Bundle.main.path(forResource: ".env", ofType: nil) else {
            print("No .env file found")
            return
        }

        do {
            let content = try String(contentsOfFile: path, encoding: .utf8)
            let lines = content.components(separatedBy: "\n")

            for line in lines {
                let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmedLine.isEmpty || trimmedLine.hasPrefix("#") {
                    continue
                }

                let parts = trimmedLine.components(separatedBy: "=")
                if parts.count >= 2 {
                    let key = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
                    let value = parts[1...].joined(separator: "=").trimmingCharacters(
                        in: .whitespacesAndNewlines)
                    variables[key] = value.replacingOccurrences(of: "\"", with: "")
                }
            }
        } catch {
            print("Error loading .env file: \(error)")
        }
    }

    func get(_ key: String) -> String? {
        return variables[key] ?? ProcessInfo.processInfo.environment[key]
    }
}

struct AppwriteConfig {
    static var endpoint: String {
        DotEnv.shared.get("APPWRITE_ENDPOINT")!
    }

    static var projectId: String {
        DotEnv.shared.get("APPWRITE_PROJECT_ID")!
    }

    static var databaseId: String {
        DotEnv.shared.get("APPWRITE_DATABASE_ID")!
    }

    static var usersCollectionId: String {
        DotEnv.shared.get("APPWRITE_USERS_COLLECTION_ID")!
    }
}
