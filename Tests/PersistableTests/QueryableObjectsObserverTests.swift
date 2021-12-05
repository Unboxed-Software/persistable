//
//  QueryableObjectsObserverTests.swift
//  
//
//  Created by James Pacheco on 12/3/21.
//

import XCTest
import Combine
@testable import Persistable

final class QueryableObjectsObserverTests: XCTestCase {
    
    var cancellables: Set<AnyCancellable> = []
    var observer: AnyObject?

    func test_observerStartsWithPlaceholder() throws {
        let observer = QueryableObjectsObserver<QueryTest>()
        XCTAssertEqual(observer.state, .placeholder)
    }
    
    func test_observerLoadsOnSave() throws {
        try QueryTest.clearAll()
        let observer = QueryableObjectsObserver<QueryTest>(for: .all)
        self.observer = observer
        
        let expectation = self.expectation(description: "Observer value changed")
        expectation.assertForOverFulfill = false
        
        observer.objectWillChange.sink { _ in
            if observer.state == .unmodified,
               observer.value == [QueryTest.all[0]] {
                expectation.fulfill()
            }
        }
        .store(in: &cancellables)
        
        try QueryTest.all[0].save()
        
        wait(for: [expectation], timeout: 5)
    }
    
    func test_observerLoadsValueWhenQueryReplaced() throws {
        for i in QueryTest.all {
            try i.save()
        }
        
        let observer = QueryableObjectsObserver<QueryTest>(for: .all)
        self.observer = observer
        
        let expectation = self.expectation(description: "Observer value changed")
        expectation.assertForOverFulfill = false
        
        observer.objectWillChange.sink { _ in
            if observer.state == .unmodified,
               observer.value.sorted(by: <) == QueryTest.all.sorted(by: <).filter({ $0.id % 2 == 1 }) {
                expectation.fulfill()
            }
        }
        .store(in: &cancellables)
        
        observer.query = .odds
        
        wait(for: [expectation], timeout: 5)
    }
}
