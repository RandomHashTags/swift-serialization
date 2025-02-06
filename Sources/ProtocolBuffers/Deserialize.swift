//
//  Deserialize.swift
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

// MARK: Deserialize
extension ProtobufProtocol {
    public init<C: Collection<UInt8>>(protobufSerializedBytes: C) {
        self = SerializationTechnique.Protobuf.deserialize(data: protobufSerializedBytes)
    }
}

extension SerializationTechnique.Protobuf {
    @inlinable
    public static func deserialize<C: Collection<UInt8>, T: ProtobufProtocol>(data: C) -> T {
        var value:T = T()
        var index:C.Index = data.startIndex
        while index < data.endIndex {
            guard let (number, wireType):(Int, WireType) = decodeFieldTag(index: &index, data: data) else {
                break
            }
            let protoValue:Value = T.protobufContent[number-1]
            if let decoded:Any = wireType.decode(dataType: protoValue.dataType, index: &index, data: data) {
                value.setProtobufValue(fieldNumber: protoValue.fieldNumber, value: decoded)
            }
        }
        return value
    }
    @inlinable
    static func decodeLengthDelimited<C: Collection<UInt8>>(index: inout C.Index, data: C) -> C.SubSequence {
        let length:Int = Int(decodeVarInt(index: &index, data: data))
        let ends:C.Index = data.index(index, offsetBy: length)
        defer { index = ends }
        return data[index..<ends]
    }
}

// MARK: VarInt
extension SerializationTechnique.Protobuf {
    @inlinable
    static func decodeVarInt<C: Collection<UInt8>>(index: inout C.Index, data: C) -> UInt64 {
        var result:UInt64 = 0, shift:UInt64 = 0
        while index < data.endIndex {
            let byte:UInt8 = data[index]
            data.formIndex(after: &index)
            result |= UInt64(byte & 0x7F) << shift
            if (byte & 0x80) == 0 {
                break
            }
            shift += 7
        }
        return result
    }
}

// MARK: Field Tag
extension SerializationTechnique.Protobuf {
    @inlinable
    static func decodeFieldTag<C: Collection<UInt8>>(index: inout C.Index, data: C) -> (Int, WireType)? {
        let tag:UInt64 = decodeVarInt(index: &index, data: data)
        let number:Int = Int(tag >> 3)
        guard let wireType:WireType = .init(rawValue: Int(tag & 0x07)) else {
            return nil
        }
        return (number, wireType)
    }
}

// MARK: Standard lib
extension SerializationTechnique.Protobuf {
    @inlinable
    static func decodeFloat<C: Collection<UInt8>>(index: inout C.Index, data: C) -> Float {
        let ends:C.Index = data.index(index, offsetBy: 4)
        defer { index = ends }
        let bytes:[UInt8] = Array(data[index..<ends])
        let bits:UInt32 = UInt32(bytes[0])
            | (UInt32(bytes[1]) << 8)
            | (UInt32(bytes[2]) << 16)
            | (UInt32(bytes[3]) << 24)
        return Float(bitPattern: bits)
    }

    @inlinable
    static func decodeDouble<C: Collection<UInt8>>(index: inout C.Index, data: C) -> Double {
        let ends:C.Index = data.index(index, offsetBy: 8)
        defer { index = ends }
        let bytes:[UInt8] = Array(data[index..<ends])
        let bits:UInt64 = UInt64(bytes[0])
            | (UInt64(bytes[1]) << 8)
            | (UInt64(bytes[2]) << 16)
            | (UInt64(bytes[3]) << 24)
            | (UInt64(bytes[4]) << 32)
            | (UInt64(bytes[5]) << 40)
            | (UInt64(bytes[6]) << 48)
            | (UInt64(bytes[7]) << 56)
        return Double(bitPattern: bits)
    }

    @inlinable
    static func decodeString<C: Collection<UInt8>>(index: inout C.Index, data: C) -> String {
        let bytes:C.SubSequence = decodeLengthDelimited(index: &index, data: data)
        return String(decoding: bytes, as: UTF8.self)
    }

    @inlinable
    static func decodeByteArray<C: Collection<UInt8>>(index: inout C.Index, data: C) -> [UInt8] {
        return [UInt8](decodeLengthDelimited(index: &index, data: data))
    }

    @inlinable
    static func decodeBool<C: Collection<UInt8>>(index: inout C.Index, data: C) -> Bool {
        return Int32(decodeVarInt(index: &index, data: data)) != 0
    }
    
    @inlinable
    static func decodeInt32<C: Collection<UInt8>>(index: inout C.Index, data: C) -> Int32 {
        return Int32(decodeVarInt(index: &index, data: data))
    }

    @inlinable
    static func decodeInt64<C: Collection<UInt8>>(index: inout C.Index, data: C) -> Int64 {
        return Int64(decodeVarInt(index: &index, data: data))
    }

    @inlinable
    static func decodeUInt32<C: Collection<UInt8>>(index: inout C.Index, data: C) -> UInt32 {
        return UInt32(decodeVarInt(index: &index, data: data))
    }

    @inlinable
    static func decodeUInt64<C: Collection<UInt8>>(index: inout C.Index, data: C) -> UInt64 {
        return decodeVarInt(index: &index, data: data)
    }

    @inlinable
    static func decodeUInt8<C: Collection<UInt8>>(index: inout C.Index, data: C) -> UInt8 {
        defer { data.formIndex(after: &index) }
        return data[index]
    }
}


#if canImport(FoundationEssentials) || canImport(Foundation)

// MARK: Foundation
extension ProtobufProtocol {
    public init(protobufSerializedData: Data) {
        self = SerializationTechnique.Protobuf.deserialize(data: [UInt8](protobufSerializedData))
    }
}

extension SerializationTechnique.Protobuf {
    @inlinable
    static func decodeUUID<C: Collection<UInt8>>(index: inout C.Index, data: C) -> UUID {
        let bytes:C.SubSequence = decodeLengthDelimited(index: &index, data: data)
        return UUID(uuid: (
            bytes[bytes.startIndex],
            bytes[bytes.index(bytes.startIndex, offsetBy: 1)],
            bytes[bytes.index(bytes.startIndex, offsetBy: 2)],
            bytes[bytes.index(bytes.startIndex, offsetBy: 3)],
            bytes[bytes.index(bytes.startIndex, offsetBy: 4)],
            bytes[bytes.index(bytes.startIndex, offsetBy: 5)],
            bytes[bytes.index(bytes.startIndex, offsetBy: 6)],
            bytes[bytes.index(bytes.startIndex, offsetBy: 7)],
            bytes[bytes.index(bytes.startIndex, offsetBy: 8)],
            bytes[bytes.index(bytes.startIndex, offsetBy: 9)],
            bytes[bytes.index(bytes.startIndex, offsetBy: 10)],
            bytes[bytes.index(bytes.startIndex, offsetBy: 11)],
            bytes[bytes.index(bytes.startIndex, offsetBy: 12)],
            bytes[bytes.index(bytes.startIndex, offsetBy: 13)],
            bytes[bytes.index(bytes.startIndex, offsetBy: 14)],
            bytes[bytes.index(bytes.startIndex, offsetBy: 15)]
        ))
    }
}

#endif