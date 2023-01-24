//
//  AxiomLinks.swift
//
//
//  Created by Conway Charles on 1/21/22.
//

import Foundation
import JDCommonAPIClient

/// JSON schema for LDO is described in https://json-schema.org/draft/2019-09/json-schema-hypermedia.html#relationType
/// This is not a complete implementation for LDOs, just a subset of functionality as needed for use with Axiom API endpoints.
public struct AxiomLinks: Codable, Equatable {
    
    enum CodingKeys: String, CodingKey {
        case type = "@type"
        case rel
        case uri
    }
    
    /// Dictionary or link URLs keyed by their 'rel' (relationship) parameter.
    /// - Note: In the event that more than one link is present with the same 'rel' name only one URL will be stored
    /// here and behavior for which copy is kept is undefined.
    public let urlsByRelationship: [String : URL]
    
    public init(keysAndValues: [String : URL] = [:]) {
        urlsByRelationship = keysAndValues
    }
    
    /// Convenience accessor for creating an empty AxiomLinks instance, e.g. to use in mock objects.
    static let emptySet = AxiomLinks()
    
    public init(from decoder: Decoder) throws {
    
        var outerArray = try decoder.unkeyedContainer()
        
        var urlByRel = [String : URL]()
        
        while outerArray.isAtEnd == false {
            
            let linkContainer = try outerArray.nestedContainer(keyedBy: CodingKeys.self)
            let _ = try linkContainer.decodeIfPresent(String.self, forKey: .type)  // TODO: Do we need to store type? (it's optional)
            let relationship = try linkContainer.decode(String.self, forKey: .rel)
            let uri = try linkContainer.decode(URL.self, forKey: .uri)
            urlByRel[relationship] = uri
        }
        
        self.urlsByRelationship = urlByRel
    }
    
    public func encode(to encoder: Encoder) throws {  // TODO: Verify this implementation works, e.g. with unit test
        
        var outerArray = encoder.unkeyedContainer()
        
        for (aKey, aValue) in urlsByRelationship {
            
            var linkContainer = outerArray.nestedContainer(keyedBy: CodingKeys.self)
            try linkContainer.encode("Link", forKey: .type)
            try linkContainer.encode(aKey, forKey: .rel)
            try linkContainer.encode(aValue, forKey: .uri)
        }
    }
    
    /// - Parameter relationship: The 'rel' key in the response associated with the link URL
    public subscript(_ relationship: String) -> URL? {
        return urlsByRelationship[relationship]
    }
}

/// A protocol indicating that a JSON decodable model object includes a 'links' property. This is common of various Axiom API
/// response object types.
/// - Note: Unclear whether this protocol will be needed. Re-evaluate after more experience with response decoding.
protocol AxiomLinkable {
    
    var links: AxiomLinks { get }  // NOTE: Does this ever need to be optional, or will it just be an empty array?
}
