//
//  QueryTest.swift
//  
//
//  Created by James Pacheco on 12/3/21.
//

import Foundation
import Persistable

struct QueryTest: Codable, Equatable, Comparable {
    static func < (lhs: QueryTest, rhs: QueryTest) -> Bool {
        return lhs.id < rhs.id
    }
    
    let id: Int
    
    static let all: [QueryTest] = [
        QueryTest(id: 1),
        QueryTest(id: 2),
        QueryTest(id: 3),
        QueryTest(id: 4),
        QueryTest(id: 5),
        QueryTest(id: 6),
        QueryTest(id: 7),
        QueryTest(id: 8),
        QueryTest(id: 9),
        QueryTest(id: 10)
    ]
}

fileprivate let objectManager = BaseObjectManager<QueryTest>()

extension QueryTest: ContextProvidingPersistable {
    var context: Int { id }
    
    static var manager: BaseObjectManager<QueryTest> {
        objectManager
    }
    
    static var placeholder: QueryTest {
        QueryTest(id: 0)
    }
    
    typealias LookupContext = Int
}

extension QueryTest: Queryable {
    static func urls(for query: Query) throws -> [URL] {
        switch query {
        case .all:
            return try allUrls()
        case .evens:
            return try allUrls().filter {
                Int($0.fileName) % 2 == 0 }
        case .odds:
            return try allUrls().filter { Int($0.fileName) % 2 == 1 }
        }
    }
    
    enum Query {
        case all
        case evens
        case odds
    }
    
    typealias QueryType = Query
}
