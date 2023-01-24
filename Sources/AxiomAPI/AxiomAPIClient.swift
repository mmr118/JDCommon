//
//  AxiomAPIClient.swift
//  
//
//  Created by Conway Charles on 1/14/22.
//

import Foundation
import JDCommonAPIClient


/// An implementation of DeereAPIClient customized for making requests to Axiom API endpoints and handling
/// their return types.
public class AxiomAPIClient: DeereAPIClient, ObservableObject {
    
    public let authorizer: DeereAPIRequestAuthorizer
    public let environment: DeereAPIEnvironment
    
    /// - Note: Declared implicit optional because of conflict between passing self as delegate during initialization.
    private let urlSession: URLSession
    
    /// Customized JSONDecoder that handles ISO8601 dates with fractional sections
    private let jsonDecoder: JSONDecoder = {
        
        enum DateParsingError: Error {
            case invalidDate
        }
        
        let decoder = JSONDecoder()
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]  // Some Axiom APIs return fractional seconds, which aren't supported by .iso8601 decoding strategy
        
        decoder.dateDecodingStrategy = .custom({ (decoder) -> Date in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            if let date = dateFormatter.date(from: dateString) {
                return date
            }
            throw DateParsingError.invalidDate
        })
        return decoder
    }()
    
    public init(authorizer: DeereAPIRequestAuthorizer, environment: DeereAPIEnvironment) {
        
        self.authorizer = authorizer
        self.environment = environment
        
        let urlSessionConfiguration = URLSessionConfiguration.default
        urlSessionConfiguration.httpAdditionalHeaders = ["Accept" : "application/vnd.deere.axiom.v3+json"]
        
        self.urlSession = URLSession(configuration: urlSessionConfiguration, delegate: nil, delegateQueue: nil)  // NOTE: URLSession strongly retains its delegate. Must make sure that the URLSession is invalidated in order to break the retain cycle between Self and URLSession.
    }
    
    /// Centralized implementation of a switch statement that checks if the returned status code is in a "success" or "redirection" range and
    /// throws an error if the status code is unexpected or indicates an error. Returns nothing and does nothing if the status code is in a generally
    /// "OK" range.
    func verifyStatusCodeOK(_ statusCode: Int) throws {
        switch statusCode {
        case 200..<400: break
        case 400...: throw DeereAPIError.badStatusCode(statusCode)
        default: throw DeereAPIError.badStatusCode(statusCode)
        } // TODO: Need ways to trigger more failure modes, e.g. access token expiration, refresh token expiration, access token invalid, etc. May need to invalidate authorizer and reauthenticate?
    }
    
    public func send<T>(request apiRequest: T, expectingStatusCode: Int?) async throws where T : DeereAPIRequest {
        
        guard let theURLRequest = apiRequest.request(for: environment) else { throw DeereAPIError.unsupportedEnvironment }
        
        let authorizedRequest = try await authorizer.authorize(theURLRequest)
                
        let (_, response): (Data, URLResponse)
        if #available(iOS 15.0, *) {
            (_, response) = try await urlSession.data(for: authorizedRequest, delegate: nil)
        } else {
            // Fallback on earlier versions
            (_, response) = try await urlSession.legacyData(for: authorizedRequest)
        }
        
        guard let httpResponse = response as? HTTPURLResponse else { throw DeereAPIError.implausibleInternalState }
        
        // Check HTTP status code
        if let theExpectedStatusCode = expectingStatusCode {
            // Check if returned HTTP status code matches expectation
            guard httpResponse.statusCode == theExpectedStatusCode else { throw DeereAPIError.badStatusCode(httpResponse.statusCode) }
        } else {
            // Fall-back to generic status code check
            try verifyStatusCodeOK(httpResponse.statusCode)
        }
    }
    
    /// Authenticates and performs the associated DeereAPIRequest then parses the response and returns it as an object.
    /// - Note: This method does NOT respect pagination "nextPage" links. If multiple pages exist this method will only return the first page.
    /// This method is better suited to response types that don't include a list (i.e. AxiomV3List as the root of the JSON response).
    /// - Returns: An instance of the DeereAPIRequest.ResponseType if the JSON response body could be parsed as that type
    public func object<T>(for apiRequest: T) async throws -> T.ResponseType where T : DeereAPIRequest & JSONDeserializableResponse {
        
        guard let theURLRequest = apiRequest.request(for: environment) else { throw DeereAPIError.unsupportedEnvironment }
        
        let authorizedRequest = try await authorizer.authorize(theURLRequest)
                
        let (data, response): (Data, URLResponse)
        if #available(iOS 15.0, *) {
            (data, response) = try await urlSession.data(for: authorizedRequest, delegate: nil)
        } else {
            // Fallback on earlier versions
            (data, response) = try await urlSession.legacyData(for: authorizedRequest)
        }
        
        guard let httpResponse = response as? HTTPURLResponse else { throw DeereAPIError.implausibleInternalState }
        
        try verifyStatusCodeOK(httpResponse.statusCode)
        
        let jsonObject = try jsonDecoder.decode(T.ResponseType.self, from: data)
        
        return jsonObject
    }
    
    /// Automatically follows 'nextPage' links and downloads the contents of all available pages before returning the entire collection of list items
    /// - Note: This method is **only** applicable to API requests that return a list, i.e. AxiomV3List as the root of the JSON response. Instead
    /// of returning an instance of AxiomV3List<U> it will fetch all available pages and directly return an array of `U` instances.
    public func arrayOfObjects<T, U>(for apiRequest: T, maxPageCount: Int = Int.max) async throws -> [U] where T : DeereAPIRequest & JSONDeserializableResponse, T.ResponseType == AxiomV3List<U> {
        
        var combinedObjects = [U]()
        var nextPageRequest: ManualAPIRequest<T.ResponseType>?
        
        // Request the first page using the original DeereAPIRequest
        let firstPage: AxiomV3List<U> = try await object(for: apiRequest)
        combinedObjects.append(contentsOf: firstPage.values)  // Add AxiomV3List contents to output
        nextPageRequest = firstPage.nextPageRequest  // Check if another page exists
        var returnedPageCount = 1
        
        while let theNextRequest = nextPageRequest, returnedPageCount < maxPageCount {  // More pages exist, haven't exceeded page limit

            // Request the next page of results using the response's 'nextPage' link
            log.debug("Requesting additional page of response")
            let nextPage: AxiomV3List<U> = try await object(for: theNextRequest)
            combinedObjects.append(contentsOf: nextPage.values)  // Add AxiomV3List contents to output
            nextPageRequest = nextPage.nextPageRequest  // Check if another page exists
            returnedPageCount += 1
        }
        
        return combinedObjects
    }
    
    public func invalidateAndCancel() {
        urlSession.invalidateAndCancel()
    }
}
