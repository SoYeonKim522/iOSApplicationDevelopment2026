//
//  APIKeyManager.swift
//  IELTSBuddy
//
//  Created by Soyeon Kim on 4/5/2026.
//


import Foundation

enum APIKeyManagerError: LocalizedError {
    case plistNotFound
    case keyMissingOrEmpty

    var errorDescription: String? {
        switch self {
        case .plistNotFound:
            return "Secrets.plist was not found in the app bundle. Add Secrets.plist to the IELTSBuddy target (Copy Bundle Resources)."
        case .keyMissingOrEmpty:
            return "GEMINI_API_KEY is missing or empty in Secrets.plist."
        }
    }
}

final class APIKeyManager {
    static let shared = APIKeyManager()

    private init() {}

    /// Reads `GEMINI_API_KEY` from `Secrets.plist` in the main bundle.
    func geminiAPIKey() throws -> String {
        guard let plistURL = Bundle.main.url(forResource: "Secrets", withExtension: "plist") else {
            throw APIKeyManagerError.plistNotFound
        }

        let data = try Data(contentsOf: plistURL)
        let object = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)

        guard let dictionary = object as? [String: Any] else {
            throw APIKeyManagerError.keyMissingOrEmpty
        }

        guard let raw = dictionary["GEMINI_API_KEY"] as? String else {
            throw APIKeyManagerError.keyMissingOrEmpty
        }

        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw APIKeyManagerError.keyMissingOrEmpty
        }

        return trimmed
    }
}
