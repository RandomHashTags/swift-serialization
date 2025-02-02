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
            public let isOptional:Bool

            public init(fieldNumber: Int, optional: Bool = false, dataType: DataType) {
                self.fieldNumber = fieldNumber
                self.isOptional = optional
                self.dataType = dataType
            }
        }

        public enum DataType {
            case any
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
            case reserved(index: Int)
            case reserved(fieldName: String)
            case sfixed32
            case sfixed64
            case sint32
            case sint64
            case string
            case structure(dataTypes: [DataType])
            case uint32
            case uint64
        }
    }
}

// MARK: ProtobufProtocol
public protocol ProtobufProtocol {
    static var protobufContent : [SerializationTechnique.Protobuf.Value] { get }

    init()

    func protobufValue(fieldNumber: Int) -> Any?
    mutating func setProtobufValue(fieldNumber: Int, value: Any)

    func serializeProtobuf(reserveCapacity: Int) -> [UInt8]
    static func deserializeProtobuf(data: [UInt8]) -> Self
}

// MARK: Serialize
extension ProtobufProtocol {
    @inlinable
    public func serializeProtobuf(reserveCapacity: Int = 1024) -> [UInt8] {
        var data:[UInt8] = []
        data.reserveCapacity(reserveCapacity)
        for (index, protoValue) in Self.protobufContent.enumerated() {
            let fieldNumber:Int = index+1
            if let value:Any = protobufValue(fieldNumber: protoValue.fieldNumber) {
                switch protoValue.dataType {
                case .bool:   SerializationTechnique.Protobuf.encodeBool(fieldNumber: fieldNumber, value as! Bool, into: &data)
                case .int32:  SerializationTechnique.Protobuf.encodeInt32(fieldNumber: fieldNumber, value as! Int32, into: &data)
                case .int64:  SerializationTechnique.Protobuf.encodeInt64(fieldNumber: fieldNumber, value as! Int64, into: &data)
                case .string: SerializationTechnique.Protobuf.encodeString(fieldNumber: fieldNumber, value as! String, into: &data)
                case .uint32: SerializationTechnique.Protobuf.encodeUInt32(fieldNumber: fieldNumber, value as! UInt32, into: &data)
                case .uint64: SerializationTechnique.Protobuf.encodeUInt64(fieldNumber: fieldNumber, value as! UInt64, into: &data)
                default:      SerializationTechnique.Protobuf.encodeFieldTag(fieldNumber: fieldNumber, wireType: .varint, into: &data)
                }
            } else {
                SerializationTechnique.Protobuf.encodeFieldTag(fieldNumber: fieldNumber, wireType: .varint, into: &data)
            }
        }
        return data
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