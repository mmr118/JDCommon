//
//  Implements.swift
//  
//
//  Created by Conway Charles on 12/9/22.
//

import Foundation
import JDCommonAPIClient

/// Implemnents Model class contains all the parameters which we will get ffrom the Implements API
/// call few parameters get skipped as they are not required
/// In the initialiser only few patameters are  iniliased as rest of them are mosly nil can be updated in future
public struct ImplementDTO: Equipment, Equatable, Codable, CustomDebugStringConvertible, Identifiable, OrganizationOwned {
    
    public static func == (lhs: ImplementDTO, rhs: ImplementDTO) -> Bool {
        return lhs.id == rhs.id
    }
    
    public let id: String
    public var equipmentCategory: EquipmentCategory { .implement }
    public let guid: String?
    public let vin: String?
    public let name: String
    public var detailedName: String { name }
    public let icon: EquipmentIconDTO?
    public let owningOrganization: OwningOrganizationDTO
    
    public let equipmentMake: EquipmentMakeDTO?
    public let equipmentType: EquipmentTypeDTO?
    public let equipmentModel: EquipmentModelDTO?
    
    public var debugDescription: String {
        return "<Implements: \"\(name)\", id: \(id)>"
    }
    
    public var hierarchyLevelMake: EquipmentHierarchyLevel? { equipmentMake }
    public var hierarchyLevelType: EquipmentHierarchyLevel? { equipmentType }
    public var hierarchyLevelModel: EquipmentHierarchyLevel? { equipmentModel }
    
    public var organizationIdentifier: String? { owningOrganization.id }
    public var serialNumber: String? { vin }
    public var pairings: [Equipment] { [] }  // TODO: Check if API can return pairings for Implement objects
}

/// MachineDTO extension with Preview Content accessors
extension ImplementDTO: PreviewContentDecodable {
    
    public static let demoImplements = AxiomV3List<ImplementDTO>.previewContentFromBundleJSON("DemoImplementsList").values
}


// MARK: - API Requests

/// Request an array of ImplementDTO records associated with a particular Organization
public struct GetImplementListRequest: ConfigurableAPIRequest, JSONDeserializableResponse, AxiomPagination {
    
    public typealias ResponseType = AxiomV3List<ImplementDTO>
    public var baseURLByEnvironment: [DeereAPIEnvironment: URL?] = axiomBaseURLs
    public var urlComponents : URLComponents?
    public var additionalHTTPHeadersFields: [String : String]?
    
    public let startingItemIndex: Int = 0
    public let itemsPerPage: Int = 100
    
    public init(orgID: String) {

        // NOTE:
        // embed=equipmentIcon will gave back the icon in response. EquipmentIconDTO is the model class for this reponse data
        // embed=terminals will gave back the terminal in response. EmbeddedTerminalsDTO is the model class for this reponse data
        // embed=capabilities will gave back the capabilities details in response. CapabilityDTO is the model class for this reponse data
        
        urlComponents = URLComponents(string: "organizations/\(orgID)/implements",
                                      queryItems: [URLQueryItem(name: "embed", value: "equipmentIcon,terminals,capabilities,displays")])
    }
}
