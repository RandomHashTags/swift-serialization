//
//  Serialize.swift
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

extension ProtobufProtocol {
    @inlinable
    public func serializeProtobuf(reserveCapacity: Int = 1024) -> [UInt8] {
        var data:[UInt8] = []
        data.reserveCapacity(reserveCapacity)
        for value in Self.protobufContent {
            let fieldNumber:Int = value.fieldNumber
            let dataType:SerializationTechnique.Protobuf.DataType = Self.protobufContent[fieldNumber-1].dataType
            serialize(dataType: dataType, fieldNumber: fieldNumber, data: &data)
        }
        return data
    }

    @inlinable
    func serialize(dataType: SerializationTechnique.Protobuf.DataType, fieldNumber: Int, data: inout [UInt8]) {
        var dataType:SerializationTechnique.Protobuf.DataType = dataType
        switch dataType {
        case .optional(let dt):
            dataType = dt
        default:
            break
        }
        switch dataType {
        case .bool:
            guard let v:Bool = protobufValue(fieldNumber: fieldNumber) else { return }
            SerializationTechnique.Protobuf.encodeBool(fieldNumber: fieldNumber, v, into: &data)
        case .int32:
            guard let v:Int32 = protobufValue(fieldNumber: fieldNumber) else { return }
            SerializationTechnique.Protobuf.encodeInt32(fieldNumber: fieldNumber, v, into: &data)
        case .int64:
            guard let v:Int64 = protobufValue(fieldNumber: fieldNumber) else { return }
            SerializationTechnique.Protobuf.encodeInt64(fieldNumber: fieldNumber, v, into: &data)
        case .double:
            guard let v:Double = protobufValue(fieldNumber: fieldNumber) else { return }
            SerializationTechnique.Protobuf.encodeI64(fieldNumber: fieldNumber, v, into: &data)
        case .float:
            guard let v:Float = protobufValue(fieldNumber: fieldNumber) else { return }
            SerializationTechnique.Protobuf.encodeI32(fieldNumber: fieldNumber, v, into: &data)
        case .url:
            #if canImport(FoundationEssentials) || canImport(Foundation)
            guard let v:URL = protobufValue(fieldNumber: fieldNumber) else { return }
            SerializationTechnique.Protobuf.encodeString(fieldNumber: fieldNumber, v.absoluteString, into: &data)
            #endif
            break
        case .uuid:
            #if canImport(FoundationEssentials) || canImport(Foundation)
            guard let v:UUID = protobufValue(fieldNumber: fieldNumber) else { return }
            SerializationTechnique.Protobuf.encodeUUID(fieldNumber: fieldNumber, v, into: &data)
            #endif
            break
        case .string:
            guard let v:String = protobufValue(fieldNumber: fieldNumber) else { return }
            SerializationTechnique.Protobuf.encodeString(fieldNumber: fieldNumber, v, into: &data)
        case .uint32:
            guard let v:UInt32 = protobufValue(fieldNumber: fieldNumber) else { return }
            SerializationTechnique.Protobuf.encodeUInt32(fieldNumber: fieldNumber, v, into: &data)
        case .uint64:
            guard let v:UInt64 = protobufValue(fieldNumber: fieldNumber) else { return }
            SerializationTechnique.Protobuf.encodeUInt64(fieldNumber: fieldNumber, v, into: &data)
        case .structure:
            guard let v:ProtobufProtocol = protobufValue(fieldNumber: fieldNumber) else { return }
            data.append(contentsOf: v.serializeProtobuf())
        case .uint8:
            guard let v:UInt8 = protobufValue(fieldNumber: fieldNumber) else { return }
            SerializationTechnique.Protobuf.encodeUInt8(fieldNumber: fieldNumber, v, into: &data)
        default:
            break
        }
    }
}

// MARK: VarInt
extension SerializationTechnique.Protobuf {
    @inlinable
    static func encodeVarInt<T: FixedWidthInteger>(int: T, into data: inout [UInt8]) {
        var int:UInt64 = UInt64(int)
        while int > 0x7F {
            data.append(UInt8((int & 0x7F) | 0x80))
            int >>= 7
        }
        data.append(UInt8(int))
    }
}

// MARK: Field Tag
extension SerializationTechnique.Protobuf {
    @inlinable
    static func encodeFieldTag(fieldNumber: Int, wireType: WireType, into data: inout [UInt8]) {
        let tag:Int = (fieldNumber << 3) | wireType.rawValue
        encodeVarInt(int: tag, into: &data)
    }
}

// MARK: Standard lib
extension SerializationTechnique.Protobuf {
    @inlinable
    static func encodeBool(fieldNumber: Int, _ bool: Bool, into data: inout [UInt8]) {
        encodeFieldTag(fieldNumber: fieldNumber, wireType: .varint, into: &data)
        encodeVarInt(int: bool ? 1 : 0, into: &data)
    }

    @inlinable
    static func encodeI64<T>(fieldNumber: Int, _ double: T, into data: inout [UInt8]) {
        encodeFieldTag(fieldNumber: fieldNumber, wireType: .i64, into: &data)
        let bytes:[UInt8] = withUnsafePointer(to: double) {
            $0.withMemoryRebound(to: UInt8.self, capacity: MemoryLayout<T>.size) {
                Array(UnsafeBufferPointer(start: $0, count: MemoryLayout<T>.size))
            }
        }
        data.append(contentsOf: bytes)
    }

    @inlinable
    static func encodeI32<T>(fieldNumber: Int, _ float: T, into data: inout [UInt8]) {
        encodeFieldTag(fieldNumber: fieldNumber, wireType: .i32, into: &data)
        let bytes:[UInt8] = withUnsafePointer(to: float) {
            $0.withMemoryRebound(to: UInt8.self, capacity: MemoryLayout<T>.size) {
                Array(UnsafeBufferPointer(start: $0, count: MemoryLayout<T>.size))
            }
        }
        data.append(contentsOf: bytes)
    }

    @inlinable
    static func encodeInt32(fieldNumber: Int, _ int: Int32, into data: inout [UInt8]) {
        encodeFieldTag(fieldNumber: fieldNumber, wireType: .varint, into: &data)
        encodeVarInt(int: int, into: &data)
    }

    @inlinable
    static func encodeInt64(fieldNumber: Int, _ int: Int64, into data: inout [UInt8]) {
        encodeFieldTag(fieldNumber: fieldNumber, wireType: .varint, into: &data)
        encodeVarInt(int: int, into: &data)
    }

    @inlinable
    static func encodeUInt8(fieldNumber: Int, _ int: UInt8, into data: inout [UInt8]) {
        encodeFieldTag(fieldNumber: fieldNumber, wireType: .byte, into: &data)
        data.append(int)
    }

    @inlinable
    static func encodeUInt32(fieldNumber: Int, _ int: UInt32, into data: inout [UInt8]) {
        encodeFieldTag(fieldNumber: fieldNumber, wireType: .varint, into: &data)
        encodeVarInt(int: int, into: &data)
    }
    
    @inlinable
    static func encodeUInt64(fieldNumber: Int, _ int: UInt64, into data: inout [UInt8]) {
        encodeFieldTag(fieldNumber: fieldNumber, wireType: .varint, into: &data)
        encodeVarInt(int: int, into: &data)
    }

    @inlinable
    static func encodeString(fieldNumber: Int, _ string: String, into data: inout [UInt8]) {
        encodeFieldTag(fieldNumber: fieldNumber, wireType: .len, into: &data)
        let utf8:[UInt8] = [UInt8](string.utf8)
        encodeVarInt(int: utf8.count, into: &data)
        data.append(contentsOf: utf8)
    }

    @inlinable
    static func encodeByteArray<C: Collection<UInt8>>(fieldNumber: Int, _ array: C, into data: inout [UInt8]) {
        encodeFieldTag(fieldNumber: fieldNumber, wireType: .len, into: &data)
        encodeVarInt(int: array.count, into: &data)
        data.append(contentsOf: array)
    }
}

#if canImport(FoundationEssentials) || canImport(Foundation)

// MARK: Foundation
extension SerializationTechnique.Protobuf {
    @inlinable
    static func encodeUUID(fieldNumber: Int, _ uuid: UUID, into data: inout [UInt8]) {
        encodeFieldTag(fieldNumber: fieldNumber, wireType: .len, into: &data)
        encodeVarInt(int: 16, into: &data)
        data.append(uuid.uuid.0)
        data.append(uuid.uuid.1)
        data.append(uuid.uuid.2)
        data.append(uuid.uuid.3)
        data.append(uuid.uuid.4)
        data.append(uuid.uuid.5)
        data.append(uuid.uuid.6)
        data.append(uuid.uuid.7)
        data.append(uuid.uuid.8)
        data.append(uuid.uuid.9)
        data.append(uuid.uuid.10)
        data.append(uuid.uuid.11)
        data.append(uuid.uuid.12)
        data.append(uuid.uuid.13)
        data.append(uuid.uuid.14)
        data.append(uuid.uuid.15)
    }
}

#endif