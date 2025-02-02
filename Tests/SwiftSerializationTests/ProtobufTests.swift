//
//  ProtobufTests.swift
//
//
//  Created by Evan Anderson on 12/14/24.
//

#if compiler(>=6.0)

#if canImport(FoundationEssentials)
import FoundationEssentials
#elseif canImport(Foundation)
import Foundation
#endif

import Testing
@testable import SwiftSerialization

struct ProtobufTests {
    @Test func protobuf() {
        let example1:ProtobufExample1 = ProtobufExample1(id: 9, name: "HOOPLA", isTrue: true)
        var data:[UInt8] = example1.serializeProtobuf()
        let result:ProtobufExample1 = ProtobufExample1(protobufSerializedBytes: data)
        #expect(example1 == result)

        #if canImport(FoundationEssentials) || canImport(Foundation)
        #expect(data.hexadecimal() == "08091206484F4F504C411801")

        let uuid:UUID = UUID(uuidString: "FE1F6228-0D64-48A9-A2B0-9E6185715107")!
        let example2:ProtobufExample2 = ProtobufExample2(isBig: uuid)
        data = example2.serializeProtobuf()
        let result2:ProtobufExample2 = ProtobufExample2(protobufSerializedBytes: data)
        #expect(example2 == result2)
        #expect(data.hexadecimal() == "0A10FE1F62280D6448A9A2B09E6185715107")
        #endif
    }
}

@ProtocolBuffer
struct ProtobufExample1 : Hashable {
    var id:Int32
    var name:String
    var isTrue:Swift.Bool
    var example2:ProtobufExample2?
    
    init(
        id: Int32,
        name: String,
        isTrue: Bool,
        example2: ProtobufExample2? = nil
    ) {
        self.id = id
        self.name = name
        self.isTrue = isTrue
        self.example2 = example2
    }

    var computed : Bool { true }
}

#if canImport(FoundationEssentials) || canImport(Foundation)
@ProtocolBuffer
struct ProtobufExample2 : Hashable {
    var isBig:FoundationEssentials.UUID
}
#else
typealias ProtobufExample2 = String 
#endif

#endif