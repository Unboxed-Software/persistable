//
//  SaveAndLoadTests.swift
//
//
//  Created by James Pacheco on 12/3/21.
//

import XCTest
@testable import Persistable

final class SaveAndLoadTests: XCTestCase {
    func test_simpleSaveAndLoad() throws {
        try PersistableUser.test.save(to: PersistableUser.test.id)
        let user: PersistableUser = try PersistableUser.manager.load(from: PersistableUser.test.id)
        XCTAssertEqual(user, PersistableUser.test)
    }
    
    func test_contextProvidingPersistableSaveAndLoad() throws {
        try ContextProvidingPersistableUser.test.save()
        let user: ContextProvidingPersistableUser = try ContextProvidingPersistableUser.manager.load(from: ContextProvidingPersistableUser.test.context)
        XCTAssertEqual(user, ContextProvidingPersistableUser.test)
    }
    
    func test_singletonPersistableSaveAndLoad() throws {
        try SingletonPersistableUser.test.save()
        let user = try SingletonPersistableUser.load()
        XCTAssertEqual(user, SingletonPersistableUser.test)
    }
}
