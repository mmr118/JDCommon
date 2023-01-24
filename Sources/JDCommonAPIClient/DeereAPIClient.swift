//
//  DeereAPIClient.swift
//  
//
//  Created by Conway Charles on 1/6/22.
//

import Foundation


public protocol DeereAPIClient {
    
    /// Used to modify the derived URLRequest in order to authorize it, often by adding a specific token or access key in an HTTP header.
    var authorizer: DeereAPIRequestAuthorizer { get }
    /// The API environment used for authorization/login and all requests.
    var environment: DeereAPIEnvironment { get }
    
    /// Performs the associated HTTP network request without returning response data. Can be used for endpoints where no response body
    /// is returned or where the response body can be ignored. Most likely to be used for POST or PUT type requests.
    /// - Parameter expectingStatusCode: If specified, enforces that the HTTP response's status code matches the expected value,
    /// otherwise it throws DeereAPIError.badStatusCode. If nil, default HTTP status code handling is used.
    func send<T: DeereAPIRequest>(request: T, expectingStatusCode: Int?) async throws
    
    /// Performs the associated HTTP network request, parses the JSON response body, and returns the associated instance type.
    ///
    /// Internally this method uses the authorizer to authorize the associated URL Request. Depending on the client's configuration this
    /// step may block the initiation of the network request while waiting on asynchronous authorization steps such as login or refreshing tokens.
    /// The Decodable return type is inferred from the associatedType defined in the DeereAPIRequest parameter.
    func object<T: DeereAPIRequest & JSONDeserializableResponse>(for apiRequest: T) async throws -> T.ResponseType
    
    /// Cancel any outstanding requests. After calling this method the DeereAPIClient instance is no longer valid and should not be used.
    func invalidateAndCancel()
}

public enum DeereAPIError: Error {
    case unhandledInternalError
    case implausibleInternalState
    case badStatusCode(Int)
    case unsupportedEnvironment
    case noContent
}

public enum DeereAPIEnvironment: String, CaseIterable,Identifiable,Sendable {
    public var id: String { self.rawValue }
    /// Development (lowest environment)
    case devl
    /// Qualification (?)
    case qual
    /// Certification (?)
    case cert
    /// Production (highest environment)
    case prod
}

public protocol DeereAPIRequestAuthorizer {
    
    /// - Parameter request: The URLRequest that needs modification to add authorization info that the API vendor is expecting to receive.
    /// This often involves adding an access key or token to a particular HTTP header.
    /// - Returns: A copy of the URLRequest with the necessary authorization information added
    func authorize(_ request: URLRequest) async throws -> URLRequest
}
