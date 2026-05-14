//
//  NetworkSession.swift
//  IELTSBuddy
//
//  Created by Soyeon Kim on 14/5/2026.
//

import Foundation

enum NetworkSession {
    static func makeDefault() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = true
        return URLSession(configuration: config)
    }
}
