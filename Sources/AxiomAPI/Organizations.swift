//
//  Organizations.swift
//  
//
//  Created by Conway Charles on 1/16/22.
//

import Foundation
import JDCommonAPIClient

// MARK: Model
public struct OrganizationDTO: Identifiable, Equatable, Codable, CustomDebugStringConvertible, AxiomLinkable {
    
    public enum OrgType: String, Codable {
        case customer
        case dealer
    }
    
    public enum OrganizationStatus : String, Codable {
        case unaccepted = "UNACCEPTED"
        case accepted = "ACCEPTED"
        case firstRestriction = "FIRST_RESTRICTION"
        case secondRestriction = "SECOND_RESTRICTION"
    }
    
    public let id: String
    public let name: String
    public let type: OrgType
    public let member: Bool
    public let status: OrganizationStatus?
    public let links: AxiomLinks
    
    public init(id: String, name: String, type: OrgType, member: Bool, status: OrganizationStatus? = nil) {  // "public" doesn't get automatically synthesized init
        self.id = id
        self.name = name
        self.type = type
        self.member = member
        self.status = status
        self.links = AxiomLinks.emptySet  // TODO: Do we need to be able to pass in links to this initializer?
    }
    
    public var debugDescription: String {
        return "<Organization: \"\(name)\", id: \(id), type: \(type)>"
    }
    
    public var termsAndConditionsURL: (URL, callback: URL)? {
        
        // NOTE: The Terms & Conditions website accepts a "target" parameter for specifying a redirect
        //  upon [successful] completion of the acceptance process. This parameter appears to enforce
        //  that the target URL has host == deere.com otherwise it silently ignores it and redirects
        //  to a target of its choosing. Upon request it may be possible to register a specific custom
        //  app scheme to use with the target parameter.
        
        guard let theTermsURL = links["termsRequired"] else { return nil }
        guard let theRedirectURL = URL(string: "https://deere.com/back/to/equipmentplus/mobile") else { return nil }
        
        guard var urlComponents = URLComponents(url: theTermsURL, resolvingAgainstBaseURL: false) else { return nil }
        urlComponents.queryItems = [URLQueryItem(name: "target", value: theRedirectURL.absoluteString)]
        guard let urlWithRedirect = urlComponents.url else { return nil }
        
        return (urlWithRedirect, theRedirectURL)
    }
}

extension OrganizationDTO: PreviewContentDecodable {
    
    public static let demoFirstRestrictionOrg = OrganizationDTO.previewContentFromBundleJSON("Organization-FirstRestriction")
}



// MARK: Requests
public struct GetOrgListRequest: ConfigurableAPIRequest, JSONDeserializableResponse, AxiomPagination {
    
    public typealias ResponseType = AxiomV3List<OrganizationDTO>
    
    public var baseURLByEnvironment: [DeereAPIEnvironment : URL?] = axiomBaseURLs
    public let urlComponents = URLComponents(string: "organizations", queryItems: [URLQueryItem(name: "embed", value: "status")])
    public var additionalHTTPHeadersFields: [String : String]?
    
    public let startingItemIndex: Int = 0
    public let itemsPerPage: Int = 100
    
    public init() { /* NO-OP */ }
}

public struct GetOrgRequest: ConfigurableAPIRequest, JSONDeserializableResponse {
    
    public typealias ResponseType = OrganizationDTO
    
    public var baseURLByEnvironment: [DeereAPIEnvironment : URL?] = axiomBaseURLs
    public let urlComponents: URLComponents?
    public var additionalHTTPHeadersFields: [String : String]?
    public var matrixParameters: [String : String]?
    
    public init(orgId: String) {
        urlComponents = URLComponents(string: "organizations/\(orgId)")
    }
}
