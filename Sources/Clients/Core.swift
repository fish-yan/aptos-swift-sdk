import Foundation

public struct Configuration: Sendable {
    public init() {}
}

public enum ParameterStyle: Sendable {
    case form
    case simple
    case deepObject
}

public protocol AcceptableProtocol: RawRepresentable, Sendable, Hashable, CaseIterable where RawValue == String {}

public struct AcceptHeaderContentType<ContentType: AcceptableProtocol>: Sendable, Hashable {
    public var contentType: ContentType

    public init(contentType: ContentType) {
        self.contentType = contentType
    }
}

public struct HTTPField: Hashable, Sendable {
    public struct Name: Hashable, Sendable {
        public let rawValue: String

        public init?(_ rawValue: String) {
            let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return nil }
            self.rawValue = trimmed
        }

        public var canonicalName: String {
            rawValue
        }

        public static var accept: Self { Self("Accept")! }
        public static var authorization: Self { Self("Authorization")! }
        public static var contentType: Self { Self("Content-Type")! }
    }

    public var name: Name
    public var value: String

    public init(name: Name, value: String) {
        self.name = name
        self.value = value
    }
}

public struct HTTPFields: Sequence, Sendable {
    private var fields: [HTTPField] = []

    public init() {}

    public mutating func append(_ field: HTTPField) {
        self[field.name] = field.value
    }

    public mutating func removeAll(where shouldBeRemoved: (HTTPField) throws -> Bool) rethrows {
        try fields.removeAll(where: shouldBeRemoved)
    }

    public func contains(_ name: HTTPField.Name) -> Bool {
        fields.contains { $0.name == name }
    }

    public subscript(name: HTTPField.Name) -> String? {
        get {
            fields.first { $0.name == name }?.value
        }
        set {
            fields.removeAll { $0.name == name }
            guard let newValue else { return }
            fields.append(.init(name: name, value: newValue))
        }
    }

    public func makeIterator() -> IndexingIterator<[HTTPField]> {
        fields.makeIterator()
    }
}

public struct HTTPRequest: Sendable {
    public enum Method: String, Sendable {
        case get = "GET"
        case post = "POST"
    }

    public var method: Method
    public var path: String?
    public var headerFields: HTTPFields

    public init(path: String, method: Method, headerFields: HTTPFields = .init()) {
        self.method = method
        self.path = path
        self.headerFields = headerFields
    }
}

public struct HTTPResponse: Sendable {
    public struct Status: Sendable {
        public enum Kind: Sendable, Equatable {
            case successful
            case clientError
            case serverError
            case other
        }

        public var code: Int

        public init(code: Int) {
            self.code = code
        }

        public var kind: Kind {
            switch code {
            case 200..<300:
                return .successful
            case 400..<500:
                return .clientError
            case 500..<600:
                return .serverError
            default:
                return .other
            }
        }

        public var reasonPhrase: String {
            HTTPURLResponse.localizedString(forStatusCode: code)
        }
    }

    public var status: Status
    public var headerFields: HTTPFields

    public init(status: Status, headerFields: HTTPFields = .init()) {
        self.status = status
        self.headerFields = headerFields
    }
}

public struct HTTPBody: Sendable {
    public var data: Data

    public init() {
        self.data = Data()
    }

    public init(_ data: Data) {
        self.data = data
    }

    public init(_ bytes: [UInt8]) {
        self.data = Data(bytes)
    }
}

public protocol ClientTransport: Sendable {
    func send(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String
    ) async throws -> (HTTPResponse, HTTPBody?)
}

public protocol ClientMiddleware: Sendable {
    func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: @Sendable (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?)
}

public struct URLSessionTransport: ClientTransport {
    public var session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func send(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String
    ) async throws -> (HTTPResponse, HTTPBody?) {
        var urlRequest = try URLRequest(request, baseURL: baseURL)
        urlRequest.httpBody = body?.data
        let (responseData, urlResponse) = try await session.dataCompat(for: urlRequest)
        guard let httpURLResponse = urlResponse as? HTTPURLResponse else {
            throw ClientError.nonHTTPResponse(urlResponse)
        }
        return (HTTPResponse(httpURLResponse), HTTPBody(responseData))
    }
}

public enum ClientError: Error {
    case invalidURL(baseURL: URL, path: String?)
    case nonHTTPResponse(URLResponse)
}

public protocol Convertible: Sendable {
    func setQueryItemAsURI<T: Encodable>(
        in request: inout HTTPRequest,
        style: ParameterStyle?,
        explode: Bool?,
        name: String,
        value: T?
    ) throws

    func setAcceptHeader<T: AcceptableProtocol>(
        in headerFields: inout HTTPFields,
        contentTypes: [AcceptHeaderContentType<T>]
    )

    func setRequiredRequestBodyAsBinary(
        _ value: HTTPBody,
        headerFields: inout HTTPFields,
        contentType: String
    ) throws -> HTTPBody

    func setRequiredRequestBodyAsJSON<T: Encodable>(
        _ value: T,
        headerFields: inout HTTPFields,
        contentType: String
    ) throws -> HTTPBody

    func getResponseBodyAsJSON<T: Decodable, C>(
        _ type: T.Type,
        from data: HTTPBody?,
        transforming transform: (T) -> C
    ) async throws -> C
}

public struct Converter: Convertible {
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init() {}

    public func setQueryItemAsURI<T: Encodable>(
        in request: inout HTTPRequest,
        style: ParameterStyle?,
        explode: Bool?,
        name: String,
        value: T?
    ) throws {
        guard let value else { return }
        let queryValue = try Self.queryStringValue(value)
        guard var components = URLComponents(string: request.path ?? "") else { return }
        var queryItems = components.queryItems ?? []
        queryItems.append(URLQueryItem(name: name, value: queryValue))
        components.queryItems = queryItems
        request.path = components.string
    }

    public func setAcceptHeader<T: AcceptableProtocol>(
        in headerFields: inout HTTPFields,
        contentTypes: [AcceptHeaderContentType<T>]
    ) {
        let acceptValue = contentTypes.map { $0.contentType.rawValue }.joined(separator: ", ")
        headerFields[.accept] = acceptValue
    }

    public func setRequiredRequestBodyAsBinary(
        _ value: HTTPBody,
        headerFields: inout HTTPFields,
        contentType: String
    ) throws -> HTTPBody {
        headerFields[.contentType] = contentType
        return value
    }

    public func setRequiredRequestBodyAsJSON<T: Encodable>(
        _ value: T,
        headerFields: inout HTTPFields,
        contentType: String
    ) throws -> HTTPBody {
        headerFields[.contentType] = contentType
        return HTTPBody(try encoder.encode(value))
    }

    public func getResponseBodyAsJSON<T: Decodable, C>(
        _ type: T.Type,
        from data: HTTPBody?,
        transforming transform: (T) -> C
    ) async throws -> C {
        let decoded = try decoder.decode(T.self, from: data?.data ?? Data())
        return transform(decoded)
    }

    private static func queryStringValue<T: Encodable>(_ value: T) throws -> String {
        if let value = value as? String { return value }
        if let value = value as? Bool { return value ? "true" : "false" }
        if let value = value as? CustomStringConvertible { return value.description }

        let data = try JSONEncoder().encode(AnyEncodable(value))
        let decoded = try JSONDecoder().decode(OpenAPIQueryValue.self, from: data)
        return decoded.description
    }
}

public protocol RequestSerializable: Sendable {
    func serializer(with converter: Convertible) throws -> (HTTPRequest, HTTPBody?)
}

public typealias Parameter = [String: any Encodable & Sendable]

public protocol _RequestOptions: Sendable {
    var path: String { get }
    var query: Parameter? { get }
    var contentType: MimeType { get }
    var acceptType: MimeType { get }
    var headers: HTTPFields? { get }
}

package extension _RequestOptions {
    var query: Parameter? {
        nil
    }

    var acceptType: MimeType {
        .json
    }

    var contentType: MimeType {
        .json
    }

    var headers: HTTPFields? {
        nil
    }
}

package extension _RequestOptions {
    func serializer(with converter: Convertible) throws -> (HTTPRequest, HTTPBody?) {
        let method: HTTPRequest.Method
        switch self {
        case is RequestOptions:
            method = .get
        case is PostRequestOptions:
            method = .post
        default:
            preconditionFailure("Unsupported type: \(type(of: self))")
        }
        var request = HTTPRequest(path: path, method: method, headerFields: headers ?? .init())
        converter.setAcceptHeader(in: &request.headerFields, contentTypes: [.init(contentType: acceptType)])

        try query?.forEach { key, value in
            try converter.setQueryItemAsURI(in: &request, style: .form, explode: true, name: key, value: value)
        }

        var body: HTTPBody?
        if let postRequest = self as? PostRequestOptions {
            switch postRequest.body {
            case .json(let value):
                let data = try JSONSerialization.data(withJSONObject: value)
                body = try converter.setRequiredRequestBodyAsBinary(
                    .init(data),
                    headerFields: &request.headerFields,
                    contentType: contentType.rawValue
                )
            case .codable(let value):
                body = try converter.setRequiredRequestBodyAsJSON(
                    AnyEncodable(value),
                    headerFields: &request.headerFields,
                    contentType: contentType.rawValue
                )
            case .binary(let httpBody):
                body = try converter.setRequiredRequestBodyAsBinary(
                    httpBody,
                    headerFields: &request.headerFields,
                    contentType: contentType.rawValue
                )
            case .none:
                break
            }
        }
        return (request, body)
    }
}

public protocol RequestOptions: RequestSerializable, _RequestOptions {}

public protocol PostRequestOptions: _RequestOptions, RequestSerializable {
    var body: RequestBody? { get }
}

public extension PostRequestOptions {
    var body: RequestBody? { nil }
}

public enum RequestBody: Sendable {
    case json([String: Sendable])
    case codable(any Encodable & Sendable)
    case binary(HTTPBody)
}

public protocol ClientInterface: Sendable {
    var serverURL: Foundation.URL { get }
    var converter: Convertible { get }

    init(
        serverURL: Foundation.URL,
        configuration: Configuration,
        transport: any ClientTransport,
        middlewares: [any ClientMiddleware]
    )

    func send<Input, Output>(
        input: Input,
        serializer: @Sendable (Input) throws -> (HTTPRequest, HTTPBody?),
        deserializer: @Sendable (HTTPResponse, HTTPBody?) async throws -> Output
    ) async throws -> Output where Input: Sendable, Output: Sendable
}

public struct Client: ClientInterface {
    public var serverURL: URL
    public let converter: Convertible = Converter()
    private let transport: any ClientTransport
    private let middlewares: [any ClientMiddleware]

    public init(
        serverURL: Foundation.URL,
        configuration: Configuration = .init(),
        transport: any ClientTransport = URLSessionTransport(),
        middlewares: [any ClientMiddleware] = []
    ) {
        self.serverURL = serverURL
        self.transport = transport
        self.middlewares = middlewares
    }

    public func send<Input, Output>(
        input: Input,
        serializer: @Sendable (Input) throws -> (HTTPRequest, HTTPBody?),
        deserializer: @Sendable (HTTPResponse, HTTPBody?) async throws -> Output
    ) async throws -> Output where Input: Sendable, Output: Sendable {
        let operationID = (input as? _RequestOptions)?.path ?? UUID().uuidString
        let (request, body) = try serializer(input)
        let (response, responseBody) = try await sendThroughMiddlewares(
            request,
            body: body,
            baseURL: serverURL,
            operationID: operationID,
            middlewares: ArraySlice(middlewares)
        )
        return try await deserializer(response, responseBody)
    }

    private func sendThroughMiddlewares(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        middlewares: ArraySlice<any ClientMiddleware>
    ) async throws -> (HTTPResponse, HTTPBody?) {
        guard let middleware = middlewares.first else {
            return try await transport.send(request, body: body, baseURL: baseURL, operationID: operationID)
        }
        return try await middleware.intercept(request, body: body, baseURL: baseURL, operationID: operationID) {
            request,
            body,
            baseURL in
            try await sendThroughMiddlewares(
                request,
                body: body,
                baseURL: baseURL,
                operationID: operationID,
                middlewares: middlewares.dropFirst()
            )
        }
    }
}

public enum MimeType: String, AcceptableProtocol, CaseIterable {
    case json = "application/json"
    case bcs = "application/x-bcs"
    case bcsSignedTransaction = "application/x.aptos.signed_transaction+bcs"
    case bcsViewFunction = "application/x.aptos.view_function+bcs"
}

extension HTTPField.Name {
    public struct Aptos {
        public static var chainId: HTTPField.Name { .init("X-APTOS-CHAIN-ID")! }
        public static var ledgerVersion: HTTPField.Name { .init("X-APTOS-LEDGER-VERSION")! }
        public static var ledgerOldestVersion: HTTPField.Name { .init("X-APTOS-LEDGER-OLDEST-VERSION")! }
        public static var ledgerTimestampUsec: HTTPField.Name { .init("X-APTOS-LEDGER-TIMESTAMPUSEC")! }
        public static var epoch: HTTPField.Name { .init("X-APTOS-EPOCH")! }
        public static var blockHeight: HTTPField.Name { .init("X-APTOS-BLOCK-HEIGHT")! }
        public static var oldestBlockHeight: HTTPField.Name { .init("X-APTOS-OLDEST-BLOCK-HEIGHT")! }
        public static var cursor: HTTPField.Name { .init("X-APTOS-CURSOR")! }
    }
}

public struct AptosResponse<T> {
    public var requestOptions: any Sendable
    public var request: HTTPRequest?
    public var requestBody: HTTPBody?
    public var baseURL: URL?
    public var body: T
    public var response: HTTPResponse?
    public var responseBody: HTTPBody?

    public init(
        requestOptions: any Sendable,
        request: HTTPRequest? = nil,
        requestBody: HTTPBody? = nil,
        baseURL: URL? = nil,
        body: T,
        response: HTTPResponse? = nil,
        responseBody: HTTPBody? = nil
    ) {
        self.requestOptions = requestOptions
        self.request = request
        self.requestBody = requestBody
        self.baseURL = baseURL
        self.body = body
        self.response = response
        self.responseBody = responseBody
    }
}

public extension AptosResponse {
    var status: Int {
        response?.status.code ?? 0
    }

    var statusText: String {
        response?.status.reasonPhrase ?? ""
    }
}

private struct AnyEncodable: Encodable {
    private let encodeValue: (Encoder) throws -> Void

    init(_ value: any Encodable) {
        self.encodeValue = value.encode(to:)
    }

    func encode(to encoder: Encoder) throws {
        try encodeValue(encoder)
    }
}

private enum OpenAPIQueryValue: Decodable, CustomStringConvertible {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case array([OpenAPIQueryValue])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([OpenAPIQueryValue].self) {
            self = .array(value)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unsupported query value"
            )
        }
    }

    var description: String {
        switch self {
        case .string(let value):
            return value
        case .int(let value):
            return String(value)
        case .double(let value):
            return String(value)
        case .bool(let value):
            return value ? "true" : "false"
        case .array(let value):
            return value.map(\.description).joined(separator: ",")
        }
    }
}

private extension URLRequest {
    init(_ request: HTTPRequest, baseURL: URL) throws {
        guard var baseComponents = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            throw ClientError.invalidURL(baseURL: baseURL, path: request.path)
        }
        guard let requestPath = request.path,
              let requestComponents = URLComponents(string: requestPath) else {
            throw ClientError.invalidURL(baseURL: baseURL, path: request.path)
        }

        baseComponents.path += requestComponents.path
        baseComponents.queryItems = requestComponents.queryItems
        guard let url = baseComponents.url else {
            throw ClientError.invalidURL(baseURL: baseURL, path: request.path)
        }

        self.init(url: url)
        httpMethod = request.method.rawValue
        for header in request.headerFields {
            setValue(header.value, forHTTPHeaderField: header.name.canonicalName)
        }
    }
}

private extension URLSession {
    func dataCompat(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await withCheckedThrowingContinuation { continuation in
            let task = dataTask(with: request) { data, response, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let data, let response else {
                    continuation.resume(throwing: ClientError.invalidURL(baseURL: request.url ?? URL(fileURLWithPath: "/"), path: nil))
                    return
                }
                continuation.resume(returning: (data, response))
            }
            task.resume()
        }
    }
}

private extension HTTPResponse {
    init(_ response: HTTPURLResponse) {
        var headerFields = HTTPFields()
        for (key, value) in response.allHeaderFields {
            guard let key = key as? String,
                  let name = HTTPField.Name(key),
                  let value = value as? String else {
                continue
            }
            headerFields[name] = value
        }
        self.init(status: .init(code: response.statusCode), headerFields: headerFields)
    }
}
