//
//  Protobuf.swift
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

// MARK: Protobuf
extension SerializationTechnique {
    public enum Protobuf {
    }
}

// MARK: WireType
extension SerializationTechnique.Protobuf {
    public enum WireType : Int {
        case varint
        case i64
        case len
        case sgroup
        case egroup
        case i32
        case byte

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
            case .i64:
                switch dataType {
                case .double:
                    let v:Double = decodeDouble(index: &index, data: data)
                    return v
                default: return nil
                }
            case .i32:
                switch dataType {
                case .float:
                    let v:Float = decodeFloat(index: &index, data: data)
                    return v
                default: return nil
                }
            case .len:
                switch dataType {
                case .string: return decodeString(index: &index, data: data)
                case .url:
                    #if canImport(FoundationEssentials) || canImport(Foundation)
                    let string:String = decodeString(index: &index, data: data)
                    return URL(string: string)
                    #else
                    return nil
                    #endif
                case .uuid:
                    #if canImport(FoundationEssentials) || canImport(Foundation)
                    return decodeUUID(index: &index, data: data)
                    #else
                    return nil
                    #endif
                default: return nil
                }
            case .byte:
                switch dataType {
                case .uint8: return decodeUInt8(index: &index, data: data)
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
            case .byte:   index += 1
            default: break
            }
        }
    }
}

// MARK: Value
extension SerializationTechnique.Protobuf {
    public struct Value {
        public let fieldNumber:Int
        public let dataType:DataType

        public init(fieldNumber: Int, dataType: DataType) {
            self.fieldNumber = fieldNumber
            self.dataType = dataType
        }
    }
}

// MARK: DataType
extension SerializationTechnique.Protobuf {
    public enum DataType {
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
        case url
        case uuid
        case structure([Value])
        case uint32
        case uint64

        case uint8
        case int8

        @inlinable
        public var isOptional : Bool {
            switch self {
            case .optional: return true
            default: return false
            }
        }
    }
}