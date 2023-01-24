//
//  PreviewContentDecodable.swift
//  RunApp
//
//  Created by Conway Charles on 3/22/22.
//

import Foundation

/// An object confirming to Decodable that can load content for SwiftUI previews from a JSON file residing in the main Bundle
public protocol PreviewContentDecodable where Self: Decodable {
    
    /// The JSON file is expected to contain only the JSON associated with one instance of the current object type. To decode
    /// entire list responses look at calling this method on AxiomV3List instead of directly on the list item type.
    /// - Parameter filename: The filename (excluding file extension) of the JSON file containing demo data that
    /// exists in the main Bundle.
    ///
    /// If the file cannot be found this method throws a fatal error. If JSON decoding fails the exception will be uncaught.
    static func previewContentFromBundleJSON(_ filename: String, dateStrategy: JSONDecoder.DateDecodingStrategy) -> Self
}

public extension PreviewContentDecodable {
    
    static func previewContentFromBundleJSON(_ filename: String, dateStrategy: JSONDecoder.DateDecodingStrategy = .deferredToDate) -> Self {
        
        guard let fileURL = Bundle.main.url(forResource: filename, withExtension: "json") else {
            fatalError("Preview data JSON file not found in main Bundle")
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = dateStrategy
        return try! decoder.decode(Self.self, from: Data(contentsOf: fileURL))
    }
}
