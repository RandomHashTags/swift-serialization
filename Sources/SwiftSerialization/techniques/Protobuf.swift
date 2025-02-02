//
//  Protobuf.swift
//
//
//  Created by Evan Anderson on 12/14/24.
//

#if canImport(Foundation)
import Foundation
#endif

// MARK: Protobuf
extension SerializationTechnique {
    public enum Protobuf {
        public enum WireType : Int {
            case varint
            case i64
            case len
            case sgroup
            case egroup
            case i32

            @inlinable
            func decode<C: Collection<UInt8>>(dataType: DataType, index: inout C.Index, data: C) -> Any? {
                switch self {
                case .varint:
                    switch dataType {
                    case .bool:   return decodeBool(index: &index, data: data)
                    case .int32:  return decodeInt32(index: &index, data: data)
                    case .int64:  return decodeInt64(index: &index, data: data)
                    case .uint32: return decodeUInt32(index: &index, data: data)
                    case .uint64: return decodeUInt64(index: &index, data: data)
                    default:      return nil
                    }
                case .len:
                    switch dataType {
                    case .string: return decodeString(index: &index, data: data)
                    default: return nil
                    }
                default: return nil
                }
            }

            @inlinable
            func skip(index: inout Int, data: [UInt8]) {
                switch self {
                case .varint: index += Int(decodeVarInt(index: &index, data: data))
                case .i64:    index += 8
                case .len:
                    let length:Int = Int(decodeVarInt(index: &index, data: data))
                    index += length
                case .i32:    index += 4
                default: break
                }
            }
        }

        public struct Value {
            public let fieldNumber:Int
            public let dataType:DataType

            public init(fieldNumber: Int, dataType: DataType) {
                self.fieldNumber = fieldNumber
                self.dataType = dataType
            }
        }

        public enum DataType {
            case any
            case `nil`
            case bool
            case bytes
            case double
            case fixed32
            case fixed64
            case float
            case int32
            case int64
            indirect case map(key: DataType, value: DataType)
            indirect case repeated(DataType)
            indirect case optional(DataType)
            case reserved(index: Int)
            case reserved(fieldName: String)
            case sfixed32
            case sfixed64
            case sint32
            case sint64
            case string
            case structure([Value])
            case uint32
            case uint64

            @inlinable
            public var isOptional : Bool {
                switch self {
                case .optional: return true
                default: return false
                }
            }
        }
    }
}

// MARK: ProtobufProtocol
public protocol ProtobufProtocol {
    static var protobufContent : [SerializationTechnique.Protobuf.Value] { get }

    init()

    func protobufDataType(fieldNumber: Int) -> SerializationTechnique.Protobuf.DataType
    func protobufValue<T>(fieldNumber: Int) -> T?
    mutating func setProtobufValue<T>(fieldNumber: Int, value: T)

    func serializeProtobuf(reserveCapacity: Int) -> [UInt8]
    static func deserializeProtobuf(data: [UInt8]) -> Self
}

// MARK: Serialize
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
        func value<T>() -> T? {
            return protobufValue(fieldNumber: fieldNumber)
        }
        var dataType:SerializationTechnique.Protobuf.DataType = dataType
        switch dataType {
        case .optional(let dt):
            dataType = dt
        default:
            break
        }
        switch dataType {
        case .bool:
            guard let v:Bool = value() else { return }
            SerializationTechnique.Protobuf.encodeBool(fieldNumber: fieldNumber, v, into: &data)
        case .int32:
            guard let v:Int32 = value() else { return }
            SerializationTechnique.Protobuf.encodeInt32(fieldNumber: fieldNumber, v, into: &data)
        case .int64:
            guard let v:Int64 = value() else { return }
            SerializationTechnique.Protobuf.encodeInt64(fieldNumber: fieldNumber, v, into: &data)
        case .string:
            guard let v:String = value() else { return }
            SerializationTechnique.Protobuf.encodeString(fieldNumber: fieldNumber, v, into: &data)
        case .uint32:
            guard let v:UInt32 = value() else { return }
            SerializationTechnique.Protobuf.encodeUInt32(fieldNumber: fieldNumber, v, into: &data)
        case .uint64:
            guard let v:UInt64 = value() else { return }
            SerializationTechnique.Protobuf.encodeUInt64(fieldNumber: fieldNumber, v, into: &data)
        case .structure(let _):
            guard let v:ProtobufProtocol = value() else { return }
            break
        default:
            break
        }
    }
}

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

    @inlinable
    static func encodeFieldTag(fieldNumber: Int, wireType: SerializationTechnique.Protobuf.WireType, into data: inout [UInt8]) {
        let tag:Int = (fieldNumber << 3) | wireType.rawValue
        encodeVarInt(int: tag, into: &data)
    }

    @inlinable
    static func encodeBool(fieldNumber: Int, _ bool: Bool, into data: inout [UInt8]) {
        SerializationTechnique.Protobuf.encodeFieldTag(fieldNumber: fieldNumber, wireType: .varint, into: &data)
        encodeVarInt(int: bool ? 1 : 0, into: &data)
    }

    @inlinable
    static func encodeInt32(fieldNumber: Int, _ int: Int32, into data: inout [UInt8]) {
        SerializationTechnique.Protobuf.encodeFieldTag(fieldNumber: fieldNumber, wireType: .varint, into: &data)
        encodeVarInt(int: int, into: &data)
    }

    @inlinable
    static func encodeInt64(fieldNumber: Int, _ int: Int64, into data: inout [UInt8]) {
        SerializationTechnique.Protobuf.encodeFieldTag(fieldNumber: fieldNumber, wireType: .varint, into: &data)
        encodeVarInt(int: int, into: &data)
    }

    @inlinable
    static func encodeUInt32(fieldNumber: Int, _ int: UInt32, into data: inout [UInt8]) {
        SerializationTechnique.Protobuf.encodeFieldTag(fieldNumber: fieldNumber, wireType: .varint, into: &data)
        encodeVarInt(int: int, into: &data)
    }
    
    @inlinable
    static func encodeUInt64(fieldNumber: Int, _ int: UInt64, into data: inout [UInt8]) {
        SerializationTechnique.Protobuf.encodeFieldTag(fieldNumber: fieldNumber, wireType: .varint, into: &data)
        encodeVarInt(int: int, into: &data)
    }

    @inlinable
    static func encodeString(fieldNumber: Int, _ string: String, into data: inout [UInt8]) {
        SerializationTechnique.Protobuf.encodeFieldTag(fieldNumber: fieldNumber, wireType: .len, into: &data)
        let utf8:[UInt8] = [UInt8](string.utf8)
        encodeVarInt(int: utf8.count, into: &data)
        data.append(contentsOf: utf8)
    }
}

// MARK: Deserialize
extension ProtobufProtocol {
    public static func deserializeProtobuf<C: Collection<UInt8>>(data: C) -> Self {
        var value:Self = Self()
        var index:C.Index = data.startIndex
        while index < data.endIndex {
            guard let (number, wireType):(Int, SerializationTechnique.Protobuf.WireType) = SerializationTechnique.Protobuf.decodeFieldTag(index: &index, data: data) else {
                break
            }
            let protoValue:SerializationTechnique.Protobuf.Value = protobufContent[number-1]
            if let decoded:Any = wireType.decode(dataType: protoValue.dataType, index: &index, data: data) {
                value.setProtobufValue(fieldNumber: protoValue.fieldNumber, value: decoded)
            }
        }
        return value
    }
}

extension SerializationTechnique.Protobuf {
    @inlinable
    static func decodeVarInt<C: Collection<UInt8>>(index: inout C.Index, data: C) -> UInt64 {
        var result:UInt64 = 0, shift:UInt64 = 0
        while index < data.endIndex {
            let byte:UInt8 = data[index]
            data.formIndex(&index, offsetBy: 1)
            result |= UInt64(byte & 0x7F) << shift
            if (byte & 0x80) == 0 {
                break
            }
            shift += 7
        }
        return result
    }

    @inlinable
    static func decodeFieldTag<C: Collection<UInt8>>(index: inout C.Index, data: C) -> (Int, SerializationTechnique.Protobuf.WireType)? {
        let tag:UInt64 = decodeVarInt(index: &index, data: data)
        let number:Int = Int(tag >> 3)
        guard let wireType:SerializationTechnique.Protobuf.WireType = .init(rawValue: Int(tag & 0x07)) else {
            return nil
        }
        return (number, wireType)
    }

    @inlinable
    static func decodeLengthDelimited<C: Collection<UInt8>>(index: inout C.Index, data: C) -> C.SubSequence {
        let length:Int = Int(decodeVarInt(index: &index, data: data))
        let ends:C.Index = data.index(index, offsetBy: length)
        defer { index = ends }
        return data[index..<ends]
    }
}

extension SerializationTechnique.Protobuf {
    @inlinable
    static func decodeString<C: Collection<UInt8>>(index: inout C.Index, data: C) -> String {
        let bytes:C.SubSequence = decodeLengthDelimited(index: &index, data: data)
        return String(decoding: bytes, as: UTF8.self)
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
}