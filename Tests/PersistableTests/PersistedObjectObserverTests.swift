//
//  PersistedObjectObserverTests.swift
//  
//
//  Created by James Pacheco on 12/3/21.
//

import XCTest
import Combine
@testable import Persistable

final class PersistedObjectObserverTests: XCTestCase {
    
    var cancellables: Set<AnyCancellable> = []
    var observer: AnyObject?
    
    func test_observerLoadsWhenValueSaved() throws {
        let observer = PersistedObjectObserver<PersistableUser>(at: PersistableUser.test.id)
        self.observer = observer
        
        let expectation = self.expectation(description: "Observer value changed")
        expectation.assertForOverFulfill = false
        
        observer.objectWillChange.sink { _ in
            if observer.state == .unmodified,
               observer.value == PersistableUser.test {
                expectation.fulfill()
            }
        }
        .store(in: &cancellables)
        
        try PersistableUser.test.save(to: PersistableUser.test.id)
        
        wait(for: [expectation], timeout: 5)
    }
    
    func test_observerStartsWithPlaceholder() {
        let observer = PersistedObjectObserver<PersistableUser>(at: PersistableUser.test.id)
        XCTAssertEqual(observer.state, .placeholder)
    }
    
    func test_observerLoadsValueWhenContextReplaced() throws {
        try PersistableUser.test.save(to: PersistableUser.test.id)
        
        let observer = PersistedObjectObserver<PersistableUser>()
        self.observer = observer
        
        let expectation = self.expectation(description: "Observer value changed")
        expectation.assertForOverFulfill = false
        
        observer.objectWillChange.sink { _ in
            if observer.state == .unmodified,
               observer.value == PersistableUser.test {
                expectation.fulfill()
            }
        }
        .store(in: &cancellables)
        
        observer.context = PersistableUser.test.id
        
        wait(for: [expectation], timeout: 5)
    }
    
    func test_observerLoadsNewValueWhenContextChanges() throws {
        try PersistableUser.test.save(to: PersistableUser.test.id)
        let id = "84959"
        let newValue = PersistableUser(id: id, email: "testing@test.com", firstName: "Tester", lastName: "McTested")
        try newValue.save(to: id)
        
        let observer = PersistedObjectObserver<PersistableUser>(at: PersistableUser.test.id)
        self.observer = observer
        
        let expectation = self.expectation(description: "Observer value changed")
        expectation.assertForOverFulfill = false
        
        observer.objectWillChange.sink { _ in
            if observer.state == .unmodified,
               observer.value == newValue {
                expectation.fulfill()
            }
        }
        .store(in: &cancellables)
        
        observer.context = id
        
        wait(for: [expectation], timeout: 5)
    }
}
