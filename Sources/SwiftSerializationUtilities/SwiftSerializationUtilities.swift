//
//  SwiftSerialization.swift
//
//
//  Created by Evan Anderson on 12/16/24.
//

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