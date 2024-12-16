//
//  SwiftSerialization.swift
//
//
//  Created by Evan Anderson on 12/16/24.
//

@attached(member, names: arbitrary)
public macro ProtocolBuffer(
    content: [String:SerializationTechnique.Protobuf.DataType]
) = #externalMacro(module: "SwiftSerializationMacros", type: "ProtocolBuffer")

public extension Encodable {
    @inlinable
    func serialize(using technique: SerializationTechnique) -> [UInt8] {
        return []
    }
}

public extension Decodable {
    @inlinable
    func deserialize(using technique: SerializationTechnique) -> [UInt8] {
        return []
    }
}