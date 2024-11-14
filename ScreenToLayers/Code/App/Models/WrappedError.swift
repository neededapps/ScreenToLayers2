
import Foundation
import SwiftUI

public enum WrappedError: Error, LocalizedError {
    
    case none
    case wrapped(Error)
    
    // MARK: Initializers
    
    public static func wrap<T: Error>(_ errorOrNil: T?) -> WrappedError {
        guard let error = errorOrNil else { return .none }
        return .wrapped(error)
    }
    
    // MARK: Properties
    
    public var errorDescription: String? {
        switch self {
        case .none:
            return String(localized: "No errors.")
        case .wrapped(let error):
            return error.localizedDescription
        }
    }
    
    public var isNone: Bool {
        switch self {
        case .none:
            return true
        case .wrapped(_):
            return false
        }
    }
}

extension Binding where Value == WrappedError {
    
    // MARK: Binding
    
    public func isPresented() -> Binding<Bool> {
        Binding<Bool>(get: {
            !self.wrappedValue.isNone
        }, set: { newValue in
            guard newValue == false else { return }
            self.wrappedValue = .none
        })
    }
}
