import Foundation

public struct OpenAPIValueContainer: Codable, Hashable, Sendable {
    public var value: (any Sendable)?

    init(validatedValue value: (any Sendable)?) {
        self.value = value
    }

    public init(unvalidatedValue: (any Sendable)? = nil) throws {
        try self.init(validatedValue: Self.tryCast(unvalidatedValue))
    }

    static func tryCast(_ value: (any Sendable)?) throws -> (any Sendable)? {
        guard let value else { return nil }
        if let array = value as? [(any Sendable)?] {
            return try array.map(tryCast(_:))
        }
        if let dictionary = value as? [String: (any Sendable)?] {
            return try dictionary.mapValues(tryCast(_:))
        }
        if let value = tryCastPrimitiveType(value) {
            return value
        }
        throw EncodingError.invalidValue(
            value,
            .init(codingPath: [], debugDescription: "Unsupported OpenAPI value type '\(type(of: value))'.")
        )
    }

    static func tryCastPrimitiveType(_ value: any Sendable) -> (any Sendable)? {
        switch value {
        case is String, is Int, is Bool, is Double:
            return value
        default:
            return nil
        }
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self.init(validatedValue: nil)
        } else if let item = try? container.decode(Bool.self) {
            self.init(validatedValue: item)
        } else if let item = try? container.decode(Int.self) {
            self.init(validatedValue: item)
        } else if let item = try? container.decode(Double.self) {
            self.init(validatedValue: item)
        } else if let item = try? container.decode(String.self) {
            self.init(validatedValue: item)
        } else if let item = try? container.decode([OpenAPIValueContainer].self) {
            self.init(validatedValue: item.map(\.value))
        } else if let item = try? container.decode([String: OpenAPIValueContainer].self) {
            self.init(validatedValue: item.mapValues(\.value))
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "OpenAPIValueContainer cannot be decoded"
            )
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        guard let value else {
            try container.encodeNil()
            return
        }
        switch value {
        case let value as Bool:
            try container.encode(value)
        case let value as Int:
            try container.encode(value)
        case let value as Double:
            try container.encode(value)
        case let value as String:
            try container.encode(value)
        case let value as [(any Sendable)?]:
            try container.encode(value.map(OpenAPIValueContainer.init(validatedValue:)))
        case let value as [String: (any Sendable)?]:
            try container.encode(value.mapValues(OpenAPIValueContainer.init(validatedValue:)))
        default:
            throw EncodingError.invalidValue(
                value,
                .init(codingPath: container.codingPath, debugDescription: "OpenAPIValueContainer cannot be encoded")
            )
        }
    }

    public static func == (lhs: OpenAPIValueContainer, rhs: OpenAPIValueContainer) -> Bool {
        switch (lhs.value, rhs.value) {
        case (nil, nil), is (Void, Void):
            return true
        case let (lhs as Bool, rhs as Bool):
            return lhs == rhs
        case let (lhs as Int, rhs as Int):
            return lhs == rhs
        case let (lhs as Double, rhs as Double):
            return lhs == rhs
        case let (lhs as String, rhs as String):
            return lhs == rhs
        case let (lhs as [(any Sendable)?], rhs as [(any Sendable)?]):
            guard lhs.count == rhs.count else { return false }
            return zip(lhs, rhs).allSatisfy {
                OpenAPIValueContainer(validatedValue: $0) == OpenAPIValueContainer(validatedValue: $1)
            }
        case let (lhs as [String: (any Sendable)?], rhs as [String: (any Sendable)?]):
            guard lhs.count == rhs.count, Set(lhs.keys) == Set(rhs.keys) else { return false }
            for key in lhs.keys {
                guard OpenAPIValueContainer(validatedValue: lhs[key]!) == OpenAPIValueContainer(validatedValue: rhs[key]!) else {
                    return false
                }
            }
            return true
        default:
            return false
        }
    }

    public func hash(into hasher: inout Hasher) {
        switch value {
        case let value as Bool:
            hasher.combine(value)
        case let value as Int:
            hasher.combine(value)
        case let value as Double:
            hasher.combine(value)
        case let value as String:
            hasher.combine(value)
        case let value as [(any Sendable)?]:
            value.forEach { hasher.combine(OpenAPIValueContainer(validatedValue: $0)) }
        case let value as [String: (any Sendable)?]:
            value.forEach { key, itemValue in
                hasher.combine(key)
                hasher.combine(OpenAPIValueContainer(validatedValue: itemValue))
            }
        default:
            break
        }
    }
}

extension OpenAPIValueContainer: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: BooleanLiteralType) {
        self.init(validatedValue: value)
    }
}

extension OpenAPIValueContainer: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(validatedValue: value)
    }
}

extension OpenAPIValueContainer: ExpressibleByNilLiteral {
    public init(nilLiteral: ()) {
        self.init(validatedValue: nil)
    }
}

extension OpenAPIValueContainer: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self.init(validatedValue: value)
    }
}

extension OpenAPIValueContainer: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self.init(validatedValue: value)
    }
}

public struct OpenAPIObjectContainer: Codable, Hashable, Sendable {
    public var value: [String: (any Sendable)?]

    init(validatedValue value: [String: (any Sendable)?]) {
        self.value = value
    }

    public init() {
        self.init(validatedValue: [:])
    }

    public init(unvalidatedValue: [String: (any Sendable)?]) throws {
        try self.init(validatedValue: unvalidatedValue.mapValues(OpenAPIValueContainer.tryCast(_:)))
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let item = try container.decode([String: OpenAPIValueContainer].self)
        self.init(validatedValue: item.mapValues(\.value))
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value.mapValues(OpenAPIValueContainer.init(validatedValue:)))
    }

    public static func == (lhs: OpenAPIObjectContainer, rhs: OpenAPIObjectContainer) -> Bool {
        OpenAPIValueContainer(validatedValue: lhs.value) == OpenAPIValueContainer(validatedValue: rhs.value)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(OpenAPIValueContainer(validatedValue: value))
    }
}

public struct OpenAPIArrayContainer: Codable, Hashable, Sendable {
    public var value: [(any Sendable)?]

    init(validatedValue value: [(any Sendable)?]) {
        self.value = value
    }

    public init() {
        self.init(validatedValue: [])
    }

    public init(unvalidatedValue: [(any Sendable)?]) throws {
        try self.init(validatedValue: unvalidatedValue.map(OpenAPIValueContainer.tryCast(_:)))
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let item = try container.decode([OpenAPIValueContainer].self)
        self.init(validatedValue: item.map(\.value))
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value.map(OpenAPIValueContainer.init(validatedValue:)))
    }

    public static func == (lhs: OpenAPIArrayContainer, rhs: OpenAPIArrayContainer) -> Bool {
        OpenAPIValueContainer(validatedValue: lhs.value) == OpenAPIValueContainer(validatedValue: rhs.value)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(OpenAPIValueContainer(validatedValue: value))
    }
}

extension DecodingError {
    static func unknownOneOfDiscriminator(
        discriminatorKey: any CodingKey,
        discriminatorValue: String,
        codingPath: [any CodingKey]
    ) -> Self {
        .keyNotFound(
            discriminatorKey,
            .init(
                codingPath: codingPath,
                debugDescription: "The oneOf structure does not contain discriminator value '\(discriminatorValue)'."
            )
        )
    }
}
