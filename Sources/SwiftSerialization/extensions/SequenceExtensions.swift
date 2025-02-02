//
//  SequenceExtensions.swift
//
//
//  Created by Evan Anderson on 2/2/2025.
//

#if canImport(Foundation)
import Foundation

extension Sequence where Element == UInt8 {
    @inlinable
    package func hexadecimal(separator: String = "") -> String {
        return map({ String.init(format: "%02X", $0) }).joined(separator: separator)
    }
}
#endif