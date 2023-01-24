//
//  MockAPIClient.swift
//  
//
//  Created by Conway Charles on 1/17/22.
//

import Foundation


/// Because MockableAPIRequest is an optional protocol, the MockAPIClient will throw an error if passed a DeereAPIRequest that
/// does not conform to MockableAPIRequest
///
/// - Note: This is just an initial thought about how we could support mocking with network requests. This approach may change as we
/// spend more time creating tests and better understand our needs.
public class MockAPIClient: DeereAPIClient {
    
    public let authorizer: DeereAPIRequestAuthorizer
    public let environment: DeereAPIEnvironment
    
    init(authorizer: DeereAPIRequestAuthorizer, environment: DeereAPIEnvironment) {
        self.authorizer = authorizer
        self.environment = environment
    }
    
    public func send<T>(request: T, expectingStatusCode: Int?) async throws where T : DeereAPIRequest {
        fatalError("MockAPIClient doesn't support the send(request:expectingStatusCode:) method")
    }
    
    public func object<T>(for apiRequest: T) async throws -> T.ResponseType where T: MockableAPIRequest {
        // TODO: Add delay to simulate async network request?
        return apiRequest.mockResponse()
    }
    
    public func object<T>(for apiRequest: T) async throws -> T.ResponseType where T: DeereAPIRequest & JSONDeserializableResponse {
        assertionFailure("MockAPIClient only accepts MockableAPIRequest")
        throw DeereAPIError.unhandledInternalError
    }
    
    /// This method is ignored by MockAPIClient and it does not affect any mock API calls.
    public func invalidateAndCancel() {
        // NO-OP
    }
}
