//
//  Queryable.swift
//
//  Created by James Pacheco on 11/12/21.
//

import Foundation

public protocol Queryable: Persistable {
    associatedtype QueryType
    static func urls(for query: QueryType) throws -> [URL]
    
    static func load(with query: QueryType) throws -> [Self]
}

public extension Queryable {
    static func load(with query: QueryType) throws -> [Self] {
        let urls = try Self.urls(for: query)
        let data = try urls.map { try Data(contentsOf: $0) }
        let decoder = JSONDecoder()
        return try data.compactMap { try decoder.decode(Self.self, from: $0) }
    }
}
