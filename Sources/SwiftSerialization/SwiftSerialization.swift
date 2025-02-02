//
//  SwiftSerialization.swift
//
//
//  Created by Evan Anderson on 12/16/24.
//

@attached(extension, conformances: ProtobufProtocol, names: arbitrary)
public macro ProtocolBuffer() = #externalMacro(module: "SwiftSerializationMacros", type: "ProtocolBuffer")

extension Encodable {
    @inlinable
    public func serialize(using technique: SerializationTechnique) -> [UInt8] {
        return []
    }
}

extension Decodable {
    @inlinable
    public func deserialize(using technique: SerializationTechnique) -> [UInt8] {
        return []
    }
}