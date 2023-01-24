//
//  URLSession+Extensions.swift
//  
//
//  Created by Conway Charles on 1/6/22.
//

import Foundation

extension URLSession {
    
    /// This wraps the completion-block URLSession API with a Swift Async compatible method because although iOS 13+
    /// now supports Swift Async, the Foundation library in iOS 13-14 hasn't been updated with async methods like iOS 15 has.
    public func legacyData(for urlRequest: URLRequest) async throws -> (Data, URLResponse) {
        
        return try await withCheckedThrowingContinuation { continuation in
            
            let dataTask = dataTask(with: urlRequest) { data, response, error in
                
                if let theError = error {
                    continuation.resume(throwing: theError)
                } else if let theData = data, let theResponse = response {
                    continuation.resume(returning: (theData, theResponse))
                } else {
                    continuation.resume(throwing: DeereAPIError.implausibleInternalState)
                }
            }
            
            dataTask.resume()
        }
    }
}
