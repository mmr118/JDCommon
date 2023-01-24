//
//  Machines.swift
//  
//
//  Created by Conway Charles on 12/9/22.
//

import Foundation
import JDCommonAPIClient

/// Machine Model class contains all the parameters which we will get ffrom the Machine API
/// call few parameters get skipped as they are not required
/// In the initialiser only few patameters are  iniliased as rest of them are mosly nil can be updated in future
public struct MachineDTO: Equipment, Equatable, Codable, CustomDebugStringConvertible, Identifiable, OrganizationOwned {
    
    public static func == (lhs: MachineDTO, rhs: MachineDTO) -> Bool {
        return lhs.id == rhs.id
    }
    
    public var debugDescription: String {
        return "<Machine: \"\(name)\", id: \(id)>"
    }
    
    public let id: String
    public var equipmentCategory: EquipmentCategory {
        
        // Mimicing the behavior of Equipment Manager web by preferring category from `equipmentApexType` over `equipmentType`
        // Reference: https://github.deere.com/equipment/equipment/blob/master/src/server/helpers/machine-helper.ts
        let theCategoryString: String? = equipmentApexType?.category ?? equipmentType?.category
        
        // Due to server-side architectural limitations, implements with JDLink installed will be returned from
        //  the /machines and other API endpoints as if they are a machine. To try to distinguish implements with
        //  JDLink installed from actual Machines we check Machine.equipmentType.category and otherwise fall back
        //  to default value of .machine.
        switch theCategoryString {
        case "Machine": return .machine
        case "Implement": return .implement
        default: return .machine
        }
    }
    public let name: String
    public var detailedName: String { name }
    public let guid: String?
    public let vin: String?
    public let icon : EquipmentIconDTO?
    public let visualizationCategory: String?
    public let telematicsState: String?
    public let capabilities: [CapabilityDTO]?
    public let terminals: EmbeddedTerminalsDTO?
    public let displays: EmbeddedDisplaysDTO?
    public let modelYear: String?
    public let links: AxiomLinks?  // NOTE: Optional because links not present when MachineDTO is a nested child of another DTO type
    
    public let equipmentMake: EquipmentMakeDTO?
    public let equipmentApexType: EquipmentApexTypeDTO?
    public let equipmentType: EquipmentTypeDTO?
    public let equipmentModel: EquipmentModelDTO?
    
    public var hierarchyLevelMake: EquipmentHierarchyLevel? { equipmentMake }
    public var hierarchyLevelType: EquipmentHierarchyLevel? { equipmentType }
    public var hierarchyLevelModel: EquipmentHierarchyLevel? { equipmentModel }
    
    // NOTE: Because current Operations Center architecture only supports having telematically-connected "Machines"
    //  we make `.telematicsEnabled` a property of Machines directly instead of at the `Equipment` level. This could
    //  be revisited in the future.
    public var telematicsEnabled: Bool {
        
        // TODO: Is .telematicsState sufficient alone to answer this question? Is there reason we would need to look at the .capabilities (or other) section instead?
        switch telematicsState {
        case "active": return true
        case "inactive": return false
        default: return false  // Includes 'nil' case when value not present in response
        }
    }
    
    public var organizationIdentifier: String? {
        
        guard let orgLink = self.links?["organizations"] else { return nil }
        
        let orgIdentifier = orgLink.lastPathComponent
        return (orgIdentifier.isEmpty) ? nil : orgIdentifier
    }
    
    public var serialNumber: String? { vin }
    
    /// Concatenates the Terminals and Displays paired with this Machine
    public var pairings: [Equipment] { (terminals?.terminals ?? []) + (displays?.displaies ?? []) }
}

/// MachineDTO extension with Preview Content accessors
extension MachineDTO: PreviewContentDecodable {
    
    public static let demoMachines = AxiomV3List<MachineDTO>.previewContentFromBundleJSON("DemoMachinesList").values
}


// MARK: - API Requests

/// Request an array of MachineDTO records associated with a particular Organization
public struct GetMachineListRequest: ConfigurableAPIRequest, JSONDeserializableResponse, AxiomPagination {
    
    public typealias ResponseType = AxiomV3List<MachineDTO>
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
        
        urlComponents = URLComponents(string: "organizations/\(orgID)/machines",
                                      queryItems: [URLQueryItem(name: "embed", value: "equipmentIcon,terminals,capabilities,displays")])
    }
}

public struct GetMachineRequest: ConfigurableAPIRequest, JSONDeserializableResponse {
    
    public typealias ResponseType = MachineDTO
    public var baseURLByEnvironment: [DeereAPIEnvironment: URL?] = axiomBaseURLs
    public var urlComponents : URLComponents?
    public var additionalHTTPHeadersFields: [String : String]?
    public var matrixParameters: [String : String]?
    
    public init(machineID: String) {
        
        // NOTE:
        // embed=equipmentIcon will gave back the icon in response. EquipmentIconDTO is the model class for this reponse data
        // embed=terminals will gave back the terminal in response. EmbeddedTerminalsDTO is the model class for this reponse data
        // embed=capabilities will gave back the capabilities details in response. CapabilityDTO is the model class for this reponse data
        
        urlComponents = URLComponents(string: "machines/\(machineID)",
                                      queryItems: [URLQueryItem(name: "embed", value: "equipmentIcon,terminals,capabilities,displays")])
    }
}
