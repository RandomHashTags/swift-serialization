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