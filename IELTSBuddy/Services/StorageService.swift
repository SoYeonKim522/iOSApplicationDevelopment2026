//
//  StorageService.swift
//  IELTSBuddy
//
//  Created by Stefy Thomas on 15/5/2026.
//

import Foundation

// abstract storage so ViewModels dont depend directly on UserDefaults
protocol StorageService {
    func save<T: Encodable>(_ value: T, forKey key: String) throws
    func load<T: Decodable>(_ type: T.Type, forKey key: String) throws -> T?
}
class UserDefaultsStorageService: StorageService {
    
    private let defaults: UserDefaults
    
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }
    
    func save<T: Encodable>(_ value: T, forKey key: String) throws {
        let encoded = try JSONEncoder().encode(value)
        defaults.set(encoded, forKey: key)
    }
    
    func load<T: Decodable>(_ type: T.Type, forKey key: String) throws -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try JSONDecoder().decode(type, from: data)
    }
}
