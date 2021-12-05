//
//  Queryable.swift
//
//  Created by James Pacheco on 11/12/21.
//

import Foundation

public protocol Queryable: Persistable where Manager: QueryableObjectManager {
    associatedtype QueryType
    static func urls(for query: QueryType) throws -> [URL]
}

public extension Queryable {
    static func allUrls() throws -> [URL] {
        return try FileManager.default.contentsOfDirectory(at: Self.baseDirectory, includingPropertiesForKeys: nil, options: [])
    }
    
    static func load(with query: QueryType) throws -> [Self] {
        try manager.load(with: query)
    }
}
