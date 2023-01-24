//
//  OAuth2Client.swift
//  
//
//  Created by Conway Charles on 1/16/22.
//

import Foundation


extension Notification.Name {
    /// The currently authenticated user account/identity has been initialized or changed.
    ///
    /// All user account-specific data and activities should be purged to reflect the change in
    /// user identity.
    public static let oAuthSubjectIdentifierDidChangeNotification = Notification.Name(rawValue: "com.deere.jdcommonauth.oauthSubjectIdentifierDidChangeNotification")
}

@MainActor
public protocol OAuth2Client: DeereAPIRequestAuthorizer {

    /// The OAuth "sub" or "subject identifier" associated with the most recently logged in account. This uniquely identifies the
    /// account and can be used to distinguish when the user logs in with a different account, so that the app can clean up any
    /// cached data or UI state that still relates to a previous account.
    var subjectIdentifier: String? { get }
    
    /// Requests the current authentication status. Depending on the supplied options the OAuth2Client may automatically
    /// attempt to login, refresh tokens, or validate existing tokens *before* returning the result.
    /// - Parameter options: The supplied options may be used to limit or modify the behavior of the method, e.g. to avoid triggering display of the
    /// web-based login screen when that isn't appropriate (e.g. a background task).
    func updateAuthenticationStatus(options: Set<OAuth2ClientOptions>) async throws -> OAuth2ClientAuthenticationStatus
    /// Triggers presentation of web-based login UI flow
    func performInteractiveAuthentication() async throws
    /// Signs out of the account and clears associated account data within the client. Individual implementations will decide if this
    /// is an on-line of off-line operation, i.e. reaching out to the auth server to invalidate the tokens or just clearing local storage of them.
    func signOut() async
}

public enum OAuth2ClientAuthenticationStatus: Sendable {
    case unknown
    /// The client has no stored identity or credentials available
    case signedOut
    /// The client has some identity state, but has not successfully authorized
    case credentialsInvalid
    /// Access token has expired and refresh token is not available.
    case expired
    /// Access token has expired but a refresh token is available
    case expiredRefreshAvailable
    /// Access token has not expired, but hasn't been verified as working since being restored from persistent storage
    case priorCredentialsSaved
    /// Access token has not expired and has been verified as working since restoration from persistent storage
    case credentialsValidated
    
    /// Even if current access token is expired, client has previously authorized successfully and has not been explicitly logged out since.
    var wasSignedIn: Bool {
        switch self {
        case .unknown, .signedOut:
            return false
        case .credentialsInvalid, .expired, .expiredRefreshAvailable, .priorCredentialsSaved, .credentialsValidated:
            return true
        }
    }
}

public enum OAuth2ClientOptions: Hashable, Sendable {
    /// Automatically use "refresh" token to get a new "access" token if the access token has expired.
    /// Doesn't present UI.
    case refreshIfNeeded
    /// If no access token exists or it has expired and refresh token is unavailable or fails, allow presenting
    /// the user-facing UI for logging in again.
    case reauthenticateIfNeeded
    /// Perform an active online check to verify the access token is still valid (if not already performed since
    /// the access token was restored)
    case requireOnlineValidation
}

enum OAuth2ClientError: Error {
    /// An internal assertion with no plausible reason for failure has not been met
    case implausibleInternalState
    /// Failure trying to present interactive authentication UI to the user
    case interactiveAuthPresentation
    /// Cannot proceed due to missing option.
    /// - Parameter requiring: The option required to proceed.
    case blocked(requiring: OAuth2ClientOptions)
}
