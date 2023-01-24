//
//  DeereAPIRequest.swift
//  
//
//  Created by Conway Charles on 1/14/22.
//

import Foundation


/// A general protocol describing a type of API endpoint request that return URLRequest instances specific to a particular API environment,
/// for example by changing the hostname or base URL.
public protocol DeereAPIRequest {
    /// - Returns: A URL request appropriate for the specified development environment or nil, if that environment is not supported by this request.
    /// - Note: This URLRequest only needs to include HTTP headers specific to the endpoint. Common HTTP request headers will be included by the
    /// DeereAPIClient. It also does not need to include API authorization information; that will be added by the DeereAPIRequestAuthorizer.
    func request(for environment: DeereAPIEnvironment) -> URLRequest?
}

/// A protocol to be adopted by DeereAPIRequests that have a JSON response body that can be deserialized as an instance of a Decodable type.
public protocol JSONDeserializableResponse {
    /// The Decodable type that the returned JSON should be parsed into
    associatedtype ResponseType: Decodable
}

/// A version of DeereAPIRequest that defines a number of configuration points as opposed to needing to manually build and return the
/// URLRequest. This allows for simpler definition of common API endpoints with minimal lines of code.
public protocol ConfigurableAPIRequest: DeereAPIRequest {
    var baseURLByEnvironment: [DeereAPIEnvironment : URL?] { get }
    var urlComponents: URLComponents? { get }
    var additionalHTTPHeadersFields: [String : String]? { get }
    
    /// Additional key-value pairs associated with a URL component know either as "params" or "matrix params". This URL component
    /// appears to have fallen out of common use and is no longer natively supported by iOS's URL, URLComponents, etc.
    ///
    /// - Important: Key and value strings are not automatically percent-encoded before use, so the caller must take care that any
    /// required percent-encoding is manually applied prior.
    ///
    /// Apple formly supported "params" as defined by RFC 1808 with the NSURL.parameterString. There is no simple way to approximate
    /// this with non-deprecated APIs because adding ";key=value" to your URL string, path, etc. will cause the semicolon to get percent-
    /// escaped. Instead we have to format the parameter string ourselves and manually append it to the URL's path after percent-escaping
    /// has already occurred.
    ///
    /// The only known use case at the time of writing for "params" is the Axiom/Platform APIs pagination system. The developer.deere.com
    /// documentation refers to these as "matrix parameters" which was another proposed standard that doesn't appear to been formally
    /// ratified.
    ///
    /// References:
    ///
    /// [https://www.logicbig.com/quick-info/web/matrix-param.html]()
    /// [https://www.w3.org/DesignIssues/MatrixURIs.html]()
    /// [https://datatracker.ietf.org/doc/html/rfc1808]()
    var matrixParameters: [String : String]? { get }
}

/// A protocol to be adopted by DeereAPIRequests that have an HTTP method other than "GET", need to include an HTTP request body, or both.
/// Common use cases would be POST or PUT requests.
/// - Note: The term "unsafe" here is used in the sense as defined by https://www.rfc-editor.org/rfc/rfc7231#section-4.2.1
public protocol UnsafeAPIRequest {
    
    var httpMethod: String { get }
    var httpBody: Data? { get }
}

/// A version of of UnsafeAPIRequest that accepts an instance of an Encodable object, to be serialized to JSON, instead of directly assigning Data
/// to the .httpBody property. This can be used when you want to POST or PUT an object's JSON representation to an API endpoint.
public protocol JSONSerializableRequest: UnsafeAPIRequest {
    
    /// The Encodable type that will be serialized to JSON as the HTTP body
    associatedtype RequestType: Encodable
    
    var requestBodyObject: RequestType? { get }
}

extension JSONSerializableRequest {

    public var httpBody: Data? {
        guard let theObject = requestBodyObject else { return nil }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        do {
            return try encoder.encode(theObject)
        } catch {
            assertionFailure(error.localizedDescription)
            return nil
        }
    }
}


/// An optional protocol for DeereAPIRequest types that opts in to supporting a mock response.
/// - Note: This is just an initial thought about how we could support mocking with network requests. This approach may change as we
/// spend more time creating tests and better understand our needs.
public protocol MockableAPIRequest where Self: DeereAPIRequest & JSONDeserializableResponse {
    
    func mockResponse() -> Self.ResponseType
}

extension ConfigurableAPIRequest {
    
    /// - Returns: The complete URL for the associated environment, ready to be used in the URLRequest.
    private func url(for environment: DeereAPIEnvironment) -> URL? {

        guard let theBaseURL = baseURLByEnvironment[environment] else { return nil }
        
        if let theURLComponents = urlComponents {
            
            if let theMatrixParameters = matrixParameters {
                // NOTE: See ConfigurableAPIRequest.matrixParameters for more information.
                //  This manually creates the "params" string from provided key-value pairs
                //  and manually appends it to the already-escaped URL Path as a work-around
                //  for the deprecation of support for this URL component in the iOS SDK.
                let matrixParameterString = theMatrixParameters.map({ pair in ";\(pair.key)=\(pair.value)" }).joined()
                var urlComponentsWithMatrixParams = theURLComponents
                urlComponentsWithMatrixParams.percentEncodedPath += matrixParameterString
                return urlComponentsWithMatrixParams.url(relativeTo: theBaseURL)
            } else {  // No matrix params
                return theURLComponents.url(relativeTo: theBaseURL)
            }
            
        } else {
            return theBaseURL
        }
    }
    
    /// - Returns: A URLRequest instance configured for this Deere API endpoint in the specified API environment.
    public func request(for environment: DeereAPIEnvironment) -> URLRequest? {

        guard let theURL = url(for: environment) else { return nil }
        
        var urlRequest = URLRequest(url: theURL)
        
        // Copy the HTTP header field overrides into the URLRequest
        if let theAdditionalHeaderFields = additionalHTTPHeadersFields {

            for (key, value) in theAdditionalHeaderFields {
                urlRequest.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        // Check if API Request specified HTTP method or body
        if let unsafeAPIRequest = self as? UnsafeAPIRequest {
            urlRequest.httpMethod = unsafeAPIRequest.httpMethod
            urlRequest.httpBody = unsafeAPIRequest.httpBody
        }
        
        return urlRequest
    }
}

/// A generic DeereAPIRequest allowing you to directly provide the complete URL. Can be used for quick testing
/// or even to programatically create a request from an arbitrary URL that's received at runtime.
public struct ManualAPIRequest<T: Decodable>: DeereAPIRequest, JSONDeserializableResponse {
    
    public typealias ResponseType = T
    let url: URL
    let additionalHTTPHeadersFields: [String : String]?
    
    public init(url: URL, httpHeaders: [String : String]? = nil) {
        self.url = url
        self.additionalHTTPHeadersFields = httpHeaders
    }
    
    public func request(for environment: DeereAPIEnvironment) -> URLRequest? {
        
        var request = URLRequest(url: url)
        
        if let theAdditionalHeaderFields = additionalHTTPHeadersFields {

            for (key, value) in theAdditionalHeaderFields {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        return request
    }
}

public extension URLComponents {
    
    /// Convenience initializer accepting both a components string as well as an array of `URLQueryItem`
    init?(string: String, queryItems: [URLQueryItem]) {
        
        guard var components = URLComponents(string: string) else { return nil }
        components.queryItems = queryItems
        
        self = components
    }
}
