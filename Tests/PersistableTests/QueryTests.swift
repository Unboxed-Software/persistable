//
//  QueryTests.swift
//  
//
//  Created by James Pacheco on 12/3/21.
//

import XCTest
@testable import Persistable

final class QueryTests: XCTestCase {
    
    func test_loadQuery() throws {
        for i in QueryTest.all {
            try i.save()
        }
        
        let all: [QueryTest] = try QueryTest.manager.load(with: .all)
        
        XCTAssertEqual(
            all.sorted(by: <),
            QueryTest.all.sorted(by: <)
        )
        
        let evens: [QueryTest] = try QueryTest.manager.load(with: .evens)
        
        XCTAssertEqual(
            evens.sorted(by: <),
            QueryTest.all.filter { $0.id % 2 == 0 }.sorted(by: <)
        )
        
        let odds: [QueryTest] = try QueryTest.manager.load(with: .odds)
        
        XCTAssertEqual(
            odds.sorted(by: <),
            QueryTest.all.filter { $0.id % 2 == 1 }.sorted(by: <)
        )
    }
}
