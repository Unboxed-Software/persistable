//
//  ObjectProvider.swift
//
//  Created by James Pacheco on 11/11/21.
//

import SwiftUI

public struct ObjectProvider<Content: View, T: Persistable>: View {
    public let context: T.LookupContext
    
    public let content: (T) -> Content
    
    @StateObject
    public var value = PersistedObjectObserver<T>()
    
    public init(context: T.LookupContext, @ViewBuilder content: @escaping (T) -> Content ) {
        self.context = context
        self.content = content
    }
    
    public var body: some View {
        content(value.value).onAppear {
            self.firstLoad()
        }
        .if(value.state == .placeholder) { view in
            view.redacted(reason: .placeholder)
        }.disabled(value.state == .placeholder)
    }
    
    func firstLoad() {
        value.context = context
    }
}

public extension View {
    /// Applies the given transform if the given condition evaluates to `true`.
    /// - Parameters:
    ///   - condition: The condition to evaluate.
    ///   - transform: The transform to apply to the source `View`.
    /// - Returns: Either the original `View` or the modified `View` if the condition is `true`.
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

struct PersistedObjectProvider<Content: View, T: Persistable>: View {
    let context: T.LookupContext
    
    let content: (T) -> Content
    
    @StateObject
    var value = PersistedObjectObserver<T>()
    
    init(_ type: T.Type, context: T.LookupContext, @ViewBuilder content: @escaping (T) -> Content ) {
        self.context = context
        self.content = content
    }
    
    var body: some View {
        content(value.value).onAppear {
            self.firstLoad()
        }
        .onChange(of: context) { context in
            self.value.context = context
        }
        .if(value.state == .placeholder) { view in
            view.redacted(reason: .placeholder)
        }.disabled(value.state == .placeholder)
    }
    
    func firstLoad() {
        value.context = context
    }
}
