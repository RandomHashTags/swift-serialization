//
//  ProtocolBuffers.swift
//
//
//  Created by Evan Anderson on 12/14/24.
//

@attached(extension, conformances: ProtobufProtocol, names: arbitrary)
public macro ProtocolBuffer() = #externalMacro(module: "SwiftSerializationMacros", type: "ProtocolBuffer")