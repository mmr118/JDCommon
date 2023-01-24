//
//  AxiomAPI.swift
//  
//
//  Created by Conway Charles on 1/19/22.
//

import Foundation
import JDCommonAPIClient
import JDCommonLogging

internal let log = JDCommonLog.sharedLog

/// Reusable definition of base URLs to be referenced from each Axiom API request
internal let axiomBaseURLs: [DeereAPIEnvironment : URL?] = [
    .qual: URL(string: "https://apiqa.tal.deere.com/platform/"),
    .cert: URL(string: "https://apicert.deere.com/platform/"),
    .prod: URL(string: "https://api.deere.com/platform/")
]

/// Models the outermost JSON structure of Axiom API requests that return more than one result, e.g. a list
/// - Note: This model definition is not exhaustive and other parseable parameters may still exist for future enhancement.
///
/// Instead of defining custom list result types for each model object you can use this generic type to represent a homogenous
/// list of any other Decodable object.
public struct AxiomV3List<T: Decodable>: Decodable, CustomDebugStringConvertible, PreviewContentDecodable {
    
    public let values: [T]
    public let links: AxiomLinks
    
    /// Direct access into the `values` array
    public subscript(index: Int) -> T { values[index] }
    
    public var debugDescription: String {
        return "List: \(values)"
    }
    
    public var nextPageRequest: ManualAPIRequest<Self>? {
        
        guard let nextPageURL = links["nextPage"] else { return nil }
        return ManualAPIRequest<Self>(url: nextPageURL)
    }
}

/// Indicates that the API request supports  "Axiom"/"Platform" API endpoint style pagination configuration.
/// Adding `AxiomPagination` protocol conformance will automatically implement `ConfigurableAPIRequest.matrixParameters`
/// and fill it out according to the `startingItemIndex` and `itemsPerPage` properties.
///
/// [Platform API Pagination Documentation](https://developer.deere.com/#/start-developing/help/get-started/pagination-guide)
public protocol AxiomPagination where Self: ConfigurableAPIRequest {
    
    /// The number of records to skip before starting the current page of results. This is often expected to be a multiple
    /// of `.itemsPerPage`.
    ///
    /// **Example:** If `.itemsPerPage = 10` then the first page of results would have `.startingItemIndex = 0`
    /// while the second page of results would be accessed at `.startingItemIndex = 10`.
    var startingItemIndex: Int { get }
    
    /// The desired number of records per "page" of results. API documentation suggests that values greater than 100
    /// will be ignored. A common default page size is 10.
    var itemsPerPage: Int { get }
}

extension AxiomPagination {
    
    /// Default implementation of `.matrixParameters` that returns the Axiom/Platform API pagination parameters.
    public var matrixParameters: [String : String]? {
        return ["start": String(startingItemIndex), "count": String(itemsPerPage)]
    }
}
