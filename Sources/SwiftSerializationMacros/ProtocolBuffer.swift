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
        var getDataType:String = "@inlinable func protobufDataType(fieldNumber: Int) -> SerializationTechnique.Protobuf.DataType {\nswitch fieldNumber {\n"
        var getVariable:String = "@inlinable func protobufValue<T>(fieldNumber: Int) -> T? {\nswitch fieldNumber {\n"
        var setVariable:String = "@inlinable mutating func setProtobufValue<T>(fieldNumber: Int, value: T) {\nswitch fieldNumber {\n"
        var content:[String] = []
        var fieldNumber:Int = 1
        for member in declaration.memberBlock.members {
            if let decl:VariableDeclSyntax = member.decl.as(VariableDeclSyntax.self) {
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
                            dataType = type.as(IdentifierTypeSyntax.self)?.name.text ?? ""
                        }
                    }
                }
                if !name.isEmpty && !dataType.isEmpty {
                    var dataTypeEnum:String = "\(dataType.lowercased())"
                    var defaultValue:String
                    switch dataType {
                    case "Bool":   defaultValue = "false"
                    case "Double": defaultValue = "0.0"
                    case "Float":  defaultValue = "0.0"
                    case "Int32":  defaultValue = "0"
                    case "Int64":  defaultValue = "0"
                    case "String": defaultValue = "\"\""
                    case "UInt32": defaultValue = "0"
                    case "UInt64": defaultValue = "0"
                    default:       defaultValue = dataType + "()"; dataTypeEnum = "structure(\(dataType).protobufContent)"
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
        values += content.joined(separator: ",\n") + "\n]"
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