//
//  PersistableUser.swift
//  
//
//  Created by James Pacheco on 12/3/21.
//

import Foundation
import Persistable

struct PersistableUser: Codable, Equatable {
    let id: String
    let email: String
    let firstName: String
    let lastName: String
    
    static let test = PersistableUser(id: "12345", email: "test@test.com", firstName: "Tester", lastName: "McTestson")
}

fileprivate let objectManager = BaseObjectManager<PersistableUser>()

extension PersistableUser: Persistable {
    static var manager: BaseObjectManager<PersistableUser> {
        objectManager
    }
    
    static func load(from url: URL) throws -> PersistableUser {
        fatalError()
    }
    
    static var placeholder: PersistableUser { .test }
    
    typealias LookupContext = String
}
