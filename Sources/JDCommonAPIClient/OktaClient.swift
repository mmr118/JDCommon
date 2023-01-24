//
//  OktaClient.swift
//  
//
//  Created by Conway Charles on 9/8/21.
//

import UIKit
import AuthFoundation
import WebAuthenticationUI
import OktaOAuth2
import JDCommonLogging

internal let log = JDCommonLog.sharedLog

/// An implementation of OAuth2Client that utilizes the okta/okta-mobile-swift framework as the underlying OAuth client.
@MainActor
public class OktaClient: OAuth2Client {
    // TODO: Verify we can still get expected behavior without being 'actor'
    
    public let requestAuthorizationOptions: Set<OAuth2ClientOptions>
    
    /// The underlying OAuth client instance from the okta-mobile-swift framework
    private let webAuthentication: WebAuthentication
    
    /// Indicates that an online (i.e. server based) check has been performed – by this particular object instance – to confirm
    /// the validity of the access token since it was restored from persistent storage. This gives additional confidence that the
    /// access token will be accepted when used.
    private var tokenValidatedSinceRestoration = false
    
    
    /// Gets the Main KeyWindow. This is a solution compatible with iOS >= 15
    @MainActor
    private var keyWindow: UIWindow? {
        return UIApplication
            .shared
            .connectedScenes
            .flatMap { ($0 as? UIWindowScene)?.windows ?? [] }
            .first { $0.isKeyWindow }
    }
    
    private var updateAuthTask: Task<OAuth2ClientAuthenticationStatus,Error>?

    /// - Parameter config: The URL to pass to the underlying Okta library
    /// - Parameter options: The options to use when authorizing URLRequests as `DeereAPIRequestAuthorizer`
    /// - Note: Currently overrides all configs to set .noSSO = true
    public init(config: URL, options: Set<OAuth2ClientOptions>) throws {

        webAuthentication = try WebAuthentication(plist: config)
        
        // Setting 'ephemeralSession' to 'true' in order to request that the browser doesn’t share cookies
        // or other browsing data between the authentication session and the user’s normal browser session.
        // This will disable 'SSO Token Exchange' functionality for the moment, until it's fully setup and ready.
        webAuthentication.ephemeralSession = true
        requestAuthorizationOptions = options
        
        // If no Credential stored, check if earlier Okta OIDC framework credentials can be migrated
        if Credential.default == nil {
            migrateFromOIDCCredentialIfNeeded(configURL: config)
        }
        
        // Check if credentials need to be cleared after reinstallation
        // FIXME: This check for app reinstallation will sign-out any user who had a version of the app installed prior to when this feature was introduced (due to lack of UserDefaults value)
        checkForAppReinstallation()
    }

    /// - Parameter configName: Attempts to load an OktaOidcConfig plist file with the given name (not including file extension)
    /// - Parameter options: The options to use when authorizing URLRequests as `DeereAPIRequestAuthorizer`
    public convenience init(configName: String, options: Set<OAuth2ClientOptions>) throws {
        
        guard let plist = Bundle.main.path(forResource: configName, ofType: "plist") else {
            throw OAuth2ClientError.implausibleInternalState
        }
        try self.init(config: URL(fileURLWithPath: plist), options: options)
    }

    /// The computed authentication status based on the current state of the last saved Token.
    ///
    /// Relies on Credential implementation to indicate whether an access token exists or is expired,
    /// and whether a efresh token exists.
    private var lastKnownAuthenticationStatus: OAuth2ClientAuthenticationStatus {

        guard let token = Credential.default?.token else {
            // If state manager doesn't exist no previous login has been stored
            return .signedOut
        }

        if token.isValid {
            return tokenValidatedSinceRestoration ? .credentialsValidated : .priorCredentialsSaved
        } else if let refreshToken = token.refreshToken, !refreshToken.isEmpty {
            return .expiredRefreshAvailable
        } else {
            return .expired
        }
    }

    /// Convenience accessor for fetching the subjectIdentifier value.
    /// - Note: This property ignores whether the associated idToken has expired, and returns any
    /// subjectIdentifier that is avaialble from a cached response.
    public var subjectIdentifier: String? { Credential.default?.token.idToken?.subject }

    /// Requests the current authentication status. Depending on the supplied options the OAuth2Client may automatically
    /// attempt to login, refresh tokens, or validate existing tokens *before* returning the result.
    ///
    /// - Parameter options: The supplied options may be used to limit or modify the behavior of the method, e.g. to avoid triggering display of the
    /// web-based login screen when that isn't appropriate (e.g. a background task).
    /// - Note: Concurrent calls to this method will result in the first invocation triggering the update while
    /// other invocations block waiting for the update to complete, then all invocations will receive the same
    /// result. For example, if this method is called a second time while an asynchronous refresh operation is
    /// in progress, the second call will block until the refresh completes rather than triggering two parallel
    /// refresh requests.
    public func updateAuthenticationStatus(options: Set<OAuth2ClientOptions>) async throws -> OAuth2ClientAuthenticationStatus {

        if let theAuthUpdateTask = updateAuthTask {  // Asynchronous update task is already in-progress

            // NOTE: If `options` differs between the original and subsequent concurrent invocations
            // we ignore those differences, which could lead to unexpected results. Future enhancement
            // could ensure that we don't re-use result if `options` parameter is different?

            log.info("Waiting for in-progress request to finish")
            // Block until existing task is finished, then return the same result
            let status = try await theAuthUpdateTask.value
            log.info("Got result from in-progress task")
            return status
        }

        // Create new Task
        let urlTask: Task<OAuth2ClientAuthenticationStatus,Error> = Task {

            do {
                let result = try await _updateAuthenticationStatus(options: options)
                updateAuthTask = nil  // Mark task as complete (so subsequent requests don't await it)
                return result
            } catch {
                updateAuthTask = nil  // Mark task as complete (so subsequent requests don't await it)
                throw error  // Re-throw after clearing updateAuthTask
            }
        }

        // Keep reference to task to detect concurrent invocations
        updateAuthTask = urlTask

        log.verbose("Starting Auth update")
        // Wait for Task to complete
        let status = try await urlTask.value
        log.verbose("Finished Auth update")
        return status
    }

    /// Internal inner method called by the outer wrapper function `updateAuthenticationStatus(options:)` in order to
    /// implement the concurrency behavior.
    /// - Warning: Should not be called directly, only through the wrapper function
    private func _updateAuthenticationStatus(options: Set<OAuth2ClientOptions>) async throws -> OAuth2ClientAuthenticationStatus {

        let initialStatus = lastKnownAuthenticationStatus
        switch initialStatus {
        case .unknown:
            assertionFailure("OktaClient should never have .unknown status")
            return initialStatus

        case .signedOut, .credentialsInvalid, .expired:

            if options.contains(.reauthenticateIfNeeded) {  // Allowed to perform full sign-in flow
                try await performInteractiveAuthentication()
                return lastKnownAuthenticationStatus
            } else {
                throw OAuth2ClientError.blocked(requiring: .reauthenticateIfNeeded)
            }

        case .expiredRefreshAvailable:

            guard options.contains(.refreshIfNeeded) else { throw OAuth2ClientError.blocked(requiring: .refreshIfNeeded) }   // Not allowed to refresh token

            do {

                try await refreshAccessToken()

            } catch {  // Distinguish between hard and soft failure??

                // Refreshing token failed...
                if options.contains(.reauthenticateIfNeeded) {  // Allowed to perform full sign-in flow
                    try await performInteractiveAuthentication()
                } else {
                    throw OAuth2ClientError.blocked(requiring: .reauthenticateIfNeeded)
                }
            }

            return lastKnownAuthenticationStatus

        case .priorCredentialsSaved:

            // If online validation is not required, immediately return .priorCredentialsSaved.
            // Because these credentials could be usable we don't need to throw .blocked(requiring:)
            guard options.contains(.requireOnlineValidation) else {
                return initialStatus
            }

            guard let theCredential = Credential.default else {
                // Can't find token
                throw OAuth2ClientError.implausibleInternalState  // Status shouldn't be .priorCredentialsSaved w/o .accessToken
            }

            // Perform online verification that access token is still valid. Call Okta framework's
            // completion-block based asynchronous introspection method within an 'async' method.
            log.info("Performing online validation of OAuth access token")
            let isValid: Bool = try await withCheckedThrowingContinuation({ renewContinuation in

                theCredential.oauth2.introspect(token: theCredential.token, type: .accessToken) { result in
                    switch result {
                    case .success(let tokenInfo):
                        if let isValid = tokenInfo.payload["active"] as? Bool {
                            renewContinuation.resume(returning: isValid)
                        }
                    case .failure(let error):
                        renewContinuation.resume(throwing: error)
                    }
                }
            })
            
            tokenValidatedSinceRestoration = true
            return isValid ? .credentialsValidated : .priorCredentialsSaved

        case .credentialsValidated:
            return initialStatus
        }
    }

    /// Internal method for ensuring consistent handling of new Token and saving it as default.
    private func updatedToken(_ token: Token) throws {

        // Check if .idToken "sub" has changed and notify
        let originalSubjectId = subjectIdentifier
        defer {
            if let newSubjectIdentifier = token.idToken?.subject {
               if originalSubjectId == nil || originalSubjectId != newSubjectIdentifier {
                    NotificationCenter.default.post(name: .oAuthSubjectIdentifierDidChangeNotification, object: self)
                }  // else, 'sub' didn't change
            } else {
                assertionFailure("New Token missing 'sub' field in idToken")
            }
        }
        
        if let originalTokenId = Credential.tokenStorage.defaultTokenID {
            try Credential.tokenStorage.remove(id: originalTokenId)
        }
        try Credential.store(token)
        try Credential.tokenStorage.setDefaultTokenID(token.id)

        tokenValidatedSinceRestoration = true  // Consider token validated, since it was just returned
    }

    @MainActor
    public func performInteractiveAuthentication() async throws {

        guard let keyWindow = keyWindow else {
            assertionFailure("Cannot identify view controller to present sign-in UI from")
            throw OAuth2ClientError.interactiveAuthPresentation
        }
        
        let token = try await webAuthentication.signIn(from: keyWindow)
        // Persist result
        try updatedToken(token)
    }

    func refreshAccessToken() async throws {

        // Wrap Okta framework's callback-based asynchronous method into Swift Async context
        log.info("Attempting refresh of expired/missing access token using refresh token")
        
        guard let credential = Credential.default else {
            assertionFailure("Cannot get last credential's manager")
            return
        }
        
        let token: Token = try await credential.oauth2.refresh(credential.token)
        // Persist result
        try updatedToken(token)
    }
    
    public func signOut() async {
        
        guard let keyWindow = keyWindow else {
            assertionFailure("Cannot identify view controller to present sign-in UI from")
            return
        }
        
        do {
            try await webAuthentication.signOut(from: keyWindow)
            try Credential.tokenStorage.setDefaultTokenID(nil)
        } catch {  // Distinguish between hard and soft failure??
            debugPrint("Error signing Out: \(error.localizedDescription)")
        }

        // Notify that we cleared the previously stored identity
        NotificationCenter.default.post(name: .oAuthSubjectIdentifierDidChangeNotification, object: self)
    }

    // MARK: - DeereAPIRequestAuthorizer methods
    public func authorize(_ request: URLRequest) async throws -> URLRequest {

        let authStatus = try await updateAuthenticationStatus(options: requestAuthorizationOptions)

        if (authStatus == .credentialsValidated || authStatus == .priorCredentialsSaved) {

            var authorizedRequest = request
            await Credential.default?.authorize(&authorizedRequest)
            return authorizedRequest

        } else {

            throw OAuth2ClientError.implausibleInternalState
        }
    }

    private func migrateFromOIDCCredentialIfNeeded(configURL: URL) {
        
        // Enforce that OIDC credential migration hasn't already been attempted
        guard UserDefaults.standard.bool(forKey: OktaClient.hasAttemptedOIDCMigrationDefaultsKey) == false else { return }
        
        do {
            try SDKVersion.Migration.LegacyOIDC.register(plist: configURL)
            try SDKVersion.migrateIfNeeded()
            
            // Mark that OIDC migration attempt completed successfully
            UserDefaults.standard.set(true, forKey: OktaClient.hasAttemptedOIDCMigrationDefaultsKey)
            UserDefaults.standard.synchronize()
        } catch {
            log.error(error)
        }
    }
    
    /// Detects when the app is first run after being reinstalled and attempts to remove an Okta Credential stored in the Keychain
    /// that didn't get removed as part of the app uninstallation. (Sidenote: This is a controversial behavior that Apple has acknowledged
    /// but doesn't guarantee will always be this way because the expected Keychain behavior during uninstallation is not documented)
    ///
    /// If an existing Credential is found it will attempt to remove it. If the removal is successful it will emit an .oAuthSubjectIdentifierDidChangeNotification.
    private func checkForAppReinstallation() {

        if UserDefaults.standard.value(forKey: OktaClient.appReinstallationUserDefaultsKey) == nil {  // First start after uninstalling the app
            
            if let preexistingCredential = Credential.default {  // A stored Credential from the previous installation exists
                do {
                    // Attempt to remove Credential still stored in the Keychain even after uninstallation
                    try preexistingCredential.remove()
                    // Notify app that .subjectIdentifier has changed (since it comes from Credential.default)
                    NotificationCenter.default.post(name: .oAuthSubjectIdentifierDidChangeNotification, object: self)
                } catch {
                    log.error(error)
                }
            }
            
            // Mark that the check for pre-existing Credentials after app [re]installation has been completed.
            UserDefaults.standard.set(true, forKey: OktaClient.appReinstallationUserDefaultsKey)
            UserDefaults.standard.synchronize()
        }
    }
}

// MARK: Constants
extension OktaClient {

    /// Boolean – 'True' post user reinstalled application. Defaults to 'Nil'.
    static let appReinstallationUserDefaultsKey: String = "com.deere.runapp.userdefaults.appReinstallationUserDefaultsKey"
    
    /// Boolean – 'True' post user reinstalled application. Defaults to 'Nil'.
    static let hasAttemptedOIDCMigrationDefaultsKey: String = "com.deere.runapp.userdefaults.hasAttemptedOIDCMigrationUserDefaultsKey"
}


// NOTE: Use of @unchecked is required in Xcode 13.2.1 but not 13.3 beta
extension URLRequest: @unchecked Sendable {
    // NOTE: Required for authorize(_:) to conform to @MainActor. Not sure why Foundation doesn't already define it as Sendable...
}
