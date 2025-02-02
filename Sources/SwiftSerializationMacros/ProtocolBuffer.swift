//
//  ProtocolBuffer.swift
//
//
//  Created by Evan Anderson on 12/16/24.
//

import SwiftSyntax
import SwiftSyntaxMacros

enum ProtocolBuffer : ExtensionMacro {
    static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        let protocols:String = protocols.compactMap({ $0.as(IdentifierTypeSyntax.self)?.name.text }).joined(separator: ",")
        guard let structure:String = declaration.as(StructDeclSyntax.self)?.name.text else {
            return []
        }
        return [
            try! ExtensionDeclSyntax("extension \(raw: structure) : \(raw: protocols)", membersBuilder: {
                MemberBlockItemListSyntax(stringLiteral: block(declaration: declaration))
            })
        ]
    }

    static func block(
        declaration: some DeclGroupSyntax
    ) -> String {
        var values:String = "static let protobufContent:[SerializationTechnique.Protobuf.Value] = [\n"
        var initializer:String = "init() {"
        var getVariable:String = "func protobufValue(fieldNumber: Int) -> Any? {\nswitch fieldNumber {\n"
        var setVariable:String = "mutating func setProtobufValue(fieldNumber: Int, value: Any) {\nswitch fieldNumber {\n"
        var content:[String] = []
        var fieldNumber:Int = 1
        for member in declaration.memberBlock.members {
            if let decl:VariableDeclSyntax = member.decl.as(VariableDeclSyntax.self) {
                var name:String = "", dataType:String = ""
                for binding in decl.bindings {
                    if let id:IdentifierPatternSyntax = binding.pattern.as(IdentifierPatternSyntax.self) {
                        name = id.identifier.text
                        dataType = binding.typeAnnotation?.type.as(IdentifierTypeSyntax.self)?.name.text ?? ""
                    }
                }
                if !name.isEmpty && !dataType.isEmpty {
                    let isOptional:Bool = dataType.last == "?"
                    if isOptional {
                        dataType.removeLast()
                    }
                    let defaultValue:String
                    switch dataType {
                    case "Bool":   defaultValue = "false"
                    case "Double": defaultValue = "0.0"
                    case "Float":  defaultValue = "0.0"
                    case "Int32":  defaultValue = "0"
                    case "Int64":  defaultValue = "0"
                    case "String": defaultValue = "\"\""
                    case "UInt32": defaultValue = "0"
                    case "UInt64": defaultValue = "0"
                    default:       continue
                    }
                    initializer += "\n" + name + " = " + defaultValue
                    getVariable += "case \(fieldNumber): return " + name + "\n"
                    setVariable += "case \(fieldNumber): " + name + " = value as! " + dataType + "\n"
                    content.append(".init(fieldNumber: \(fieldNumber), optional: \(isOptional), dataType: .\(dataType.lowercased()))")
                }
                fieldNumber += 1
            }
        }
        values += content.joined(separator: ",\n") + "\n]"
        initializer += "}"
        getVariable += "default: return nil\n}\n}"
        setVariable += "default: break\n}\n}"
        return [
            "\(values)",
            "\(initializer)",
            "\(getVariable)",
            "\(setVariable)"
        ].joined()
    }
}