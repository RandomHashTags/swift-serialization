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
        var visibility:String = ""
        for modifier in declaration.modifiers {
            switch modifier.name.text {
            case "public", "package":
                visibility = modifier.name.text + " "
                break
            default:
                break
            }
        }
        return [
            try! ExtensionDeclSyntax("extension \(raw: structure) : \(raw: protocols)", membersBuilder: {
                MemberBlockItemListSyntax(stringLiteral: block(visibility: visibility, declaration: declaration))
            })
        ]
    }

    static func block(
        visibility: String,
        declaration: some DeclGroupSyntax
    ) -> String {
        var values:String = visibility + "static let protobufContent:[SerializationTechnique.Protobuf.Value] = ["
        var initializer:String = visibility + "init() {"
        var getDataType:String = "@inlinable " + visibility + "func protobufDataType(fieldNumber: Int) -> SerializationTechnique.Protobuf.DataType {\nswitch fieldNumber {\n"
        var getVariable:String = visibility + "func protobufValue<T>(fieldNumber: Int) -> T? {\nswitch fieldNumber {\n"
        var setVariable:String = visibility + "mutating func setProtobufValue<T>(fieldNumber: Int, value: T) {\nswitch fieldNumber {\n"
        var content:[String] = []
        var fieldNumber:Int = 1
        loop: for member in declaration.memberBlock.members {
            if let decl:VariableDeclSyntax = member.decl.as(VariableDeclSyntax.self) {
                for modifier in decl.modifiers {
                    if modifier.name.text == "static" {
                        continue loop
                    }
                }

                var name:String = "", dataType:String = "", isOptional:Bool = false
                for binding in decl.bindings {
                    if let id:IdentifierPatternSyntax = binding.pattern.as(IdentifierPatternSyntax.self) {
                        name = id.identifier.text
                        if let annotation:TypeAnnotationSyntax = binding.typeAnnotation, binding.accessorBlock == nil {
                            var type:TypeSyntax = annotation.type
                            if let optional:OptionalTypeSyntax = type.as(OptionalTypeSyntax.self) {
                                isOptional = true
                                type = optional.wrappedType
                            }
                            if let member:MemberTypeSyntax = type.as(MemberTypeSyntax.self) {
                                if let id:String = member.baseType.as(IdentifierTypeSyntax.self)?.name.text {
                                    dataType = id + "." + member.name.text
                                }
                            } else if let id:String = type.as(IdentifierTypeSyntax.self)?.name.text {
                                dataType = id
                            }
                        }
                    }
                }
                if !name.isEmpty && !dataType.isEmpty {
                    var dataTypeEnum:String = "\(dataType.lowercased().split(separator: ".").last!)"
                    var defaultValue:String
                    switch dataType {
                    case "Swift.Bool", "Bool": defaultValue = "false"
                    case "Swift.Double", "Double": defaultValue = "0"
                    case "Swift.Float", "Float": defaultValue = "0"
                    case "Swift.Int32", "Int32": defaultValue = "0"
                    case "Swift.Int64", "Int64": defaultValue = "0"
                    case "Swift.String", "String": defaultValue = "\"\""
                    case "FoundationEssentials.UUID", "Foundation.UUID", "UUID": defaultValue = "UUID()"
                    case "FoundationEssentials.URL", "Foundation.URL", "URL": defaultValue = "URL(string: \"https://google.com\")!"
                    case "Swift.UInt32", "UInt32": defaultValue = "0"
                    case "Swift.UInt64", "UInt64": defaultValue = "0"
                    case "Swift.UInt8", "UInt8": defaultValue = "0"
                    default: defaultValue = dataType + "()"; dataTypeEnum = "structure(\(dataType).protobufContent)"
                    }
                    if isOptional {
                        defaultValue = "nil"
                        dataTypeEnum = "optional(.\(dataTypeEnum))"
                    }
                    initializer += "\n" + name + " = " + defaultValue
                    getDataType += "case \(fieldNumber): return .\(dataTypeEnum)\n"
                    getVariable += "case \(fieldNumber): return " + name + " as? T\n"
                    setVariable += "case \(fieldNumber): " + name + " = value as\(isOptional ? "?" : "!") " + dataType + "\n"
                    content.append(".init(fieldNumber: \(fieldNumber), dataType: .\(dataTypeEnum))")
                }
                fieldNumber += 1
            }
        }
        values += content.isEmpty ? "]" : "\n" + content.joined(separator: ",\n") + "\n]"
        initializer += "}"
        getDataType += "default: return .nil\n}\n}"
        getVariable += "default: return nil\n}\n}"
        setVariable += "default: break\n}\n}"
        return [
            "\(values)",
            "\(initializer)",
            "\(getDataType)",
            "\(getVariable)",
            "\(setVariable)"
        ].joined()
    }
}