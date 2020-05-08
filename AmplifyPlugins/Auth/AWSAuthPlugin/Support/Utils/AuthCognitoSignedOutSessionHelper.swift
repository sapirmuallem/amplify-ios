//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSMobileClient
import AWSPluginsCore

struct AuthCognitoSignedOutSessionHelper {

    /// Creates a signedOut session information with valid identityId and aws credentials.
    /// - Parameters:
    ///   - identityId: Valid identity id for the current signedOut session
    ///   - awsCredentials: Valid AWS Credentials for the current signedOut session
    /// - Returns: Returns a valid signedOut session
    static func makeSignedOutSession(identityId: String,
                                 awsCredentials: AuthAWSCredentials) -> AWSAuthCognitoSession {
        let tokensError = makeCognitoTokensSignedOutError()
        let userSubError = makeUserSubSignedOutError()
        let authSession = AWSAuthCognitoSession(isSignedIn: false,
                                                userSubResult: .failure(userSubError),
                                                identityIdResult: .success(identityId),
                                                awsCredentialsResult: .success(awsCredentials),
                                                cognitoTokensResult: .failure(tokensError))
        return authSession
    }

    /// Creates a signedOut session by handling the error
    /// - Parameter error: Error received while fetching session information
    /// - Returns: SignedOut session with isSignedIn = false and appropriate error result for other values.
    static func makeSignedOutSession(withError error: Error) -> AWSAuthCognitoSession {

        if let urlError = error as NSError?, urlError.domain == NSURLErrorDomain {
            return makeOfflineSignedOutSession()

        } else if let awsMobileClientError = error as? AWSMobileClientError {
            if case .guestAccessNotAllowed = awsMobileClientError {
                return makeSessionWithNoGuestAccess()
            } else if case .identityIdUnavailable = awsMobileClientError {
                return makeSignedOutSessionWithServiceIssue()
            }
        }
        if let authError = error as? AmplifyAuthError {
            return makeSignedOutSession(withUnhandledError: authError)
        } else {
            let authError = AuthErrorHelper.toAmplifyAuthError(error)
            return makeSignedOutSession(withUnhandledError: authError)
        }
    }

    /// Guest/SignedOut session with any unhandled error
    ///
    /// The unhandled error is passed as identityId and aws credentials result. UserSub and Cognito Tokens will still
    /// have signOut error.
    ///
    /// - Parameter error: Unhandled error
    /// - Returns: Session will have isSignedIn = false
    private static func makeSignedOutSession(withUnhandledError error: AmplifyAuthError) -> AWSAuthCognitoSession {

        let identityIdError = error
        let awsCredentialsError = error

        let tokensError = makeCognitoTokensSignedOutError()
        let userSubError = makeUserSubSignedOutError()

        let authSession = AWSAuthCognitoSession(isSignedIn: false,
                                                userSubResult: .failure(userSubError),
                                                identityIdResult: .failure(identityIdError),
                                                awsCredentialsResult: .failure(awsCredentialsError),
                                                cognitoTokensResult: .failure(tokensError))
        return authSession
    }

    /// Guest/SignOut session when the guest access is not enabled.
    /// - Returns: Session with isSignedIn = false
    private static func makeSessionWithNoGuestAccess() -> AWSAuthCognitoSession {
        let identityIdError = AmplifyAuthError.service(
            AuthPluginErrorConstants.identityIdSignOutError.errorDescription,
            AuthPluginErrorConstants.identityIdSignOutError.recoverySuggestion,
            AWSCognitoAuthError.invalidAccountTypeException)

        let awsCredentialsError = AmplifyAuthError.service(
            AuthPluginErrorConstants.awsCredentialsSignOutError.errorDescription,
            AuthPluginErrorConstants.awsCredentialsSignOutError.recoverySuggestion,
            AWSCognitoAuthError.invalidAccountTypeException)

        let tokensError = makeCognitoTokensSignedOutError()
        let userSubError = makeUserSubSignedOutError()

        let authSession = AWSAuthCognitoSession(isSignedIn: false,
                                                userSubResult: .failure(userSubError),
                                                identityIdResult: .failure(identityIdError),
                                                awsCredentialsResult: .failure(awsCredentialsError),
                                                cognitoTokensResult: .failure(tokensError))
        return authSession
    }

    private static func makeOfflineSignedOutSession() -> AWSAuthCognitoSession {
        let identityIdError = AmplifyAuthError.service(
            AuthPluginErrorConstants.identityIdOfflineError.errorDescription,
            AuthPluginErrorConstants.identityIdOfflineError.recoverySuggestion,
            AWSCognitoAuthError.network)

        let awsCredentialsError = AmplifyAuthError.service(
            AuthPluginErrorConstants.awsCredentialsOfflineError.errorDescription,
            AuthPluginErrorConstants.awsCredentialsOfflineError.recoverySuggestion,
            AWSCognitoAuthError.network)

        let tokensError = makeCognitoTokensSignedOutError()
        let userSubError = makeUserSubSignedOutError()

        let authSession = AWSAuthCognitoSession(isSignedIn: false,
                                                userSubResult: .failure(userSubError),
                                                identityIdResult: .failure(identityIdError),
                                                awsCredentialsResult: .failure(awsCredentialsError),
                                                cognitoTokensResult: .failure(tokensError))
        return authSession
    }

    /// Guest/SignedOut session with couldnot retreive either aws credentials or identity id.
    /// - Returns: Session will have isSignedIn = false
    private static func makeSignedOutSessionWithServiceIssue() -> AWSAuthCognitoSession {

        let identityIdError = AmplifyAuthError.service(
            AuthPluginErrorConstants.identityIdServiceError.errorDescription,
            AuthPluginErrorConstants.identityIdServiceError.recoverySuggestion)

        let awsCredentialsError = AmplifyAuthError.service(
            AuthPluginErrorConstants.awsCredentialsServiceError.errorDescription,
            AuthPluginErrorConstants.awsCredentialsServiceError.recoverySuggestion)

        let tokensError = makeCognitoTokensSignedOutError()
        let userSubError = makeUserSubSignedOutError()

        let authSession = AWSAuthCognitoSession(isSignedIn: false,
                                                userSubResult: .failure(userSubError),
                                                identityIdResult: .failure(identityIdError),
                                                awsCredentialsResult: .failure(awsCredentialsError),
                                                cognitoTokensResult: .failure(tokensError))
        return authSession
    }

    private static func makeUserSubSignedOutError() -> AmplifyAuthError {
        let userSubError = AmplifyAuthError.service(
            AuthPluginErrorConstants.userSubSignOutError.errorDescription,
            AuthPluginErrorConstants.userSubSignOutError.recoverySuggestion,
            AWSCognitoAuthError.signedOut)
        return userSubError
    }

    private static func makeCognitoTokensSignedOutError() -> AmplifyAuthError {
        let tokensError = AmplifyAuthError.service(
            AuthPluginErrorConstants.cognitoTokensSignOutError.errorDescription,
            AuthPluginErrorConstants.cognitoTokensSignOutError.recoverySuggestion,
            AWSCognitoAuthError.signedOut)
        return tokensError
    }
}
