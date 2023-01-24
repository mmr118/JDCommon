//
//  EngineHours.swift
//
//
//  Created by Chahare Vinit on 08/08/22.
//

import Foundation
import JDCommonAPIClient

// MARK: Model

public struct EngineHoursDTO: Codable {
    
    public struct ReadingDTO: Codable {
        
        public let valueAsDouble: Double?
        /// The measurement unit of the value in 'valueAsDouble' parameter. e.g. Hours
        public let unit: String?
    }
    
    public let reading: ReadingDTO?
    public let reportTime: Date?
}




// MARK: Requests

/// Request engine hours for a particular machine
public struct GetEngineHoursRequest: ConfigurableAPIRequest, JSONDeserializableResponse, AxiomPagination {
   
    public typealias ResponseType = AxiomV3List<EngineHoursDTO>
    
    public var baseURLByEnvironment: [DeereAPIEnvironment : URL?] = axiomBaseURLs
    public var urlComponents: URLComponents?
    public var additionalHTTPHeadersFields: [String : String]?
    
    public let startingItemIndex: Int = 0
    public let itemsPerPage: Int = 100
    
    public init(machineId: String) {
        
        urlComponents = URLComponents(string: "machines/\(machineId)/engineHours",
                                      queryItems: [URLQueryItem(name: "lastKnown", value: "true")])
    }
    
}




