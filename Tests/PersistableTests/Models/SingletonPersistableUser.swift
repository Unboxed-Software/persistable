//
//  SingletonPersistableUser.swift
//  
//
//  Created by James Pacheco on 12/3/21.
//

import Foundation
import Persistable

struct SingletonPersistableUser: Codable, Equatable {
    let id: String
    let email: String
    let firstName: String
    let lastName: String
    
    static let test = SingletonPersistableUser(id: "12345", email: "test@test.com", firstName: "Tester", lastName: "McTestson")
}

fileprivate let objectManager = BaseObjectManager<SingletonPersistableUser>()

extension SingletonPersistableUser: SingletonPersistable {
    var manager: BaseObjectManager<SingletonPersistableUser> {
        objectManager
    }
    
    static var manager: BaseObjectManager<SingletonPersistableUser> {
        objectManager
    }
    
    static var placeholder: SingletonPersistableUser { .test }
}
