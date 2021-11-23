//
//  QueryableObjectsProvider.swift
//
//  Created by James Pacheco on 11/12/21.
//

import Foundation
import SwiftUI 

public struct QueryableObjectsProvider<Content: View, T: Queryable>: View where T.QueryType: Equatable {
    public let query: T.QueryType
    
    public let content: ([T]) -> Content
    
    @StateObject
    public var value = QueryableObjectsObserver<T>()
    
    public init(value: QueryableObjectsObserver<T>, query: T.QueryType, @ViewBuilder content: @escaping ([T]) -> Content) {
        _value = StateObject(wrappedValue: value)
        self.query = query
        self.content = content
    }
    
    @_disfavoredOverload
    public init(query: T.QueryType, @ViewBuilder content: @escaping ([T]) -> Content ) {
        self.query = query
        self.content = content
    }
    
    public var body: some View {
        content(value.value).onAppear {
            self.firstLoad()
        }
        .onChange(of: query) { query in
            self.value.query = query
        }
    }
    
    func firstLoad() {
        value.query = query
    }
}

