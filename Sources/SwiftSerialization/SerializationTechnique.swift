//
//  SerializationTechnique.swift
//
//
//  Created by Evan Anderson on 12/16/24.
//

public enum SerializationTechnique {
    case json(variant: JSONVariant = .native)
    case protobuf
    case xml
    case yaml

    public enum JSONVariant {
        /// Regular json
        case native

        /// CoffeeScript Object Notation
        case cson

        /// Human-Optimized Config Object Notation
        case hocon

        /// JSON5
        case five

        /// JSONC
        case c

        /// GeoJSON
        case geo

        /// JSON-LD
        case ld

        /// JSON-RCP
        case rcp

        /// JsonML
        case ml

        /// UBJSON
        case ub
    }
}