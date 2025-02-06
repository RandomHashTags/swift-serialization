//
//  ProtobufProtocol.swift
//
//
//  Created by Evan Anderson on 12/14/24.
//

#if canImport(FoundationEssentials)
import FoundationEssentials
#elseif canImport(Foundation)
import Foundation
#endif

import SwiftSerializationUtilities

public protocol ProtobufProtocol {
    static var protobufContent : [SerializationTechnique.Protobuf.Value] { get }

    init()

    /// Deserialize
    init<C: Collection<UInt8>>(protobufSerializedBytes: C)

    #if canImport(FoundationEssentials) || canImport(Foundation)
    /// Deserialize
    init(protobufSerializedData: Data)
    #endif

    func protobufDataType(fieldNumber: Int) -> SerializationTechnique.Protobuf.DataType
    func protobufValue<T>(fieldNumber: Int) -> T?
    mutating func setProtobufValue<T>(fieldNumber: Int, value: T)

    func serializeProtobuf(reserveCapacity: Int) -> [UInt8]
}