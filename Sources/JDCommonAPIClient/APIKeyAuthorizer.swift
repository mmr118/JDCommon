//
//  APIKeyAuthorizer.swift
//  
//
//  Created by Conway Charles on 4/19/22.
//

import Foundation

/// DeereAPIRequestAuthorizer that uses a static "API key" header param for all requests
public struct APIKeyAuthorizer: DeereAPIRequestAuthorizer {
    
    let headerKey: String
    let headerValue: String
    
    /// Adds a static "API key" header value to each request for authorization
    ///
    /// Header formatted like "\<key\>: \<value\>"
    /// - Parameter key: The name to use for the header key
    /// - Parameter value: The header value to use after the colon
    public init(key: String, value: String) {
        self.headerKey = key
        self.headerValue = value
    }
    
    public func authorize(_ request: URLRequest) async throws -> URLRequest {
        var authorizedRequest = request
        authorizedRequest.setValue(headerValue, forHTTPHeaderField: headerKey)
        return authorizedRequest
    }
}
