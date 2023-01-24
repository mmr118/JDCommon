//
//  Users.swift
//  
//
//  Created by Conway Charles on 1/19/22.
//

import Foundation

import JDCommonAPIClient

// MARK: Model
/// Axiom platform "User" object
public struct UserDTO: Codable, CustomDebugStringConvertible {
    
    public enum UserType: String, Codable {
        case customer = "Customer"
        case employee = "Employee"
        case contingentWorker = "ContingentWorker"
        // TODO: Are there other cases here, e.g. "Dealer"?
    }
    
    public let accountName: String
    public let givenName: String
    public let familyName: String
    public let userType: UserType
    
    public var debugDescription: String {
        return "<User: \(givenName) \(familyName) (\(accountName)), \(userType.rawValue)>"
    }
    
    @available(iOS 15, *)
    public var nameComponents: PersonNameComponents { PersonNameComponents(givenName: givenName, familyName: familyName) }
}

// MARK: Requests

/// Request a User object for a particular user by identifier
public struct GetUserRequest: ConfigurableAPIRequest, JSONDeserializableResponse, MockableAPIRequest {
    
    public typealias ResponseType = UserDTO
    
    public var baseURLByEnvironment: [DeereAPIEnvironment : URL?] = axiomBaseURLs
    public let urlComponents: URLComponents?
    public var additionalHTTPHeadersFields: [String : String]?
    public var matrixParameters: [String : String]?
    
    /// - Parameter accountName: This should be the same value provided in the "username" field when authenticating
    public init(accountName: String) {
        urlComponents = URLComponents(string: "users/\(accountName)")
    }
    
    /// Currently undocumented Axiom endpoint that returns the User instance associated with the currently authenticated account
    public static var currentUserRequest: GetUserRequest = GetUserRequest(accountName: "@currentUser")
    
    /// Mock user details to be used in Swift Preview generator
    public func mockResponse() -> UserDTO {
        return UserDTO(accountName: "JohnnyAppleseed", givenName: "Johnny", familyName: "Appleseed", userType: .customer)
    }
}
