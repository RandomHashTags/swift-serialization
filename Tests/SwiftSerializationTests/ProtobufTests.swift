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
        let data:[UInt8] = example1.serializeProtobuf()

        #if canImport(FoundationEssentials) || canImport(Foundation)
        #expect(data.hexadecimal() == "08091206484F4F504C411801")
        #endif

        let result:ProtobufExample1 = ProtobufExample1.deserializeProtobuf(data: data)
        #expect(example1 == result)
        //print("protobuf;example1;serialized=\([UInt8](data))")
    }
}

@ProtocolBuffer
struct ProtobufExample1 : Hashable {
    var id:Int32
    var name:String
    var isTrue:Bool
    
    init(id: Int32, name: String, isTrue: Bool) {
        self.id = id
        self.name = name
        self.isTrue = isTrue
    }
}

#endif