//
//  ContextProvidingPersistableUser.swift
//  
//
//  Created by James Pacheco on 12/3/21.
//

import Foundation
import Persistable

struct ContextProvidingPersistableUser: Codable, Equatable {
    let id: String
    let email: String
    let firstName: String
    let lastName: String
    
    static let test = ContextProvidingPersistableUser(id: "12345", email: "test@test.com", firstName: "Tester", lastName: "McTestson")
}

fileprivate let objectManager = BaseObjectManager<ContextProvidingPersistableUser>()

extension ContextProvidingPersistableUser: ContextProvidingPersistable {
    static var manager: BaseObjectManager<ContextProvidingPersistableUser> {
        objectManager
    }
    
    static var placeholder: ContextProvidingPersistableUser { .test }
    
    var context: LookupContext { id }
    
    typealias LookupContext = String
}
