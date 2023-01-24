//
//  Terminals.swift
//  
//
//  Created by Conway Charles on 3/24/22.
//

import Foundation
import JDCommonAPIClient

public struct TerminalDTO: Equipment, Codable, Identifiable, OrganizationOwned {
    
    public let id: String
    public var equipmentCategory: EquipmentCategory { .terminal }
    public let serialNumber: String?
    public let type: String
    /// Instances returned as part of `MachineDTO.terminals` response include the `.hardwareType` property with marketing name
    /// for the Terminal, whereas instances returned from a Terminals endpoint don't have this property but include the marketing
    /// name as part of `.deviceModel.name`
    public let hardwareType: String?
    public let firmwareVersion: FirmwareVersionDTO?
    public let registrationDate: String?
    public let registrationStatus: String?
    public let owningOrganization: OwningOrganizationWrapper?
    public let managed: Bool?
    public let subscriptionModel: String?
    public let decommissioned: Bool?
    public let stolen: Bool?
    public let associatedMachine: MachineDTO?
    
    public let deviceMake: DeviceCategory?
    public let deviceType: DeviceCategory?
    public let deviceModel: DeviceCategory?
    
    public let links: AxiomLinks?  // NOTE: Optional because links not present depending on scenario
    
    public var name: String { (hierarchyLevelModel?.name ?? hardwareType) ?? type }
    public var detailedName: String { name }
    public var icon: EquipmentIconDTO? = nil
    
    public var hierarchyLevelMake: EquipmentHierarchyLevel? { deviceMake }
    public var hierarchyLevelType: EquipmentHierarchyLevel? { deviceType }
    public var hierarchyLevelModel: EquipmentHierarchyLevel? { deviceModel }
    
    public var organizationIdentifier: String? {
        
        if let theAssociatedMachineOrgId = associatedMachine?.organizationIdentifier {
            return theAssociatedMachineOrgId
        } else if let theOwningOrgId = owningOrganization?.value.id {
            return theOwningOrgId
        } else if let orgLink = self.links?["owningOrganization"] {
            let orgIdentifier = orgLink.lastPathComponent
            return (orgIdentifier.isEmpty) ? nil : orgIdentifier
        } else {
            return nil
        }
    }
    
    public var pairings: [Equipment] { if let theMachine = associatedMachine { return [theMachine] } else { return [] }}
}

extension TerminalDTO {
    
    /// Terminal schema differs from others in that it has an outer wrapper around the OwningOrganizationDTO.
    public struct OwningOrganizationWrapper: Codable {
        let value: OwningOrganizationDTO
    }
}

extension TerminalDTO: PreviewContentDecodable {
    
    public static let demo_3G_MTG_exampleA = TerminalDTO.previewContentFromBundleJSON("Terminal-3G-MTG-ExampleA")
}

// MARK: Requests
/// Request all TerminalDTO objects associated with a particular Organization.
public struct GetTerminalListRequest: ConfigurableAPIRequest, JSONDeserializableResponse, AxiomPagination {
    
    public typealias ResponseType = AxiomV3List<TerminalDTO>
    public var baseURLByEnvironment: [DeereAPIEnvironment: URL?] = axiomBaseURLs
    public var urlComponents : URLComponents?
    public var additionalHTTPHeadersFields: [String : String]?
    
    public let startingItemIndex: Int = 0
    public let itemsPerPage: Int = 100
    
    public init(orgID: String) {
        self.urlComponents = URLComponents(string: "organizations/\(orgID)/terminals")
    }
}

/// Request a single TerminalDTO instance identified by its serial number.
public struct GetTerminalRequest: ConfigurableAPIRequest, JSONDeserializableResponse {
    
    public typealias ResponseType = TerminalDTO
    public var baseURLByEnvironment: [DeereAPIEnvironment: URL?] = axiomBaseURLs
    public var urlComponents : URLComponents?
    public var additionalHTTPHeadersFields: [String : String]?
    public var matrixParameters: [String : String]?
    
    public init(terminalSerialNumber: String) {
        // NOTE: For future reference, there are a number of other Terminal APIs that appear to be
        //  candidates for this request that are either not consistently documented or don't function
        //  as documented. This particular endpoint was verified to work through trial and error.
        urlComponents = URLComponents(string: "terminals/\(terminalSerialNumber)",
                                      queryItems: [URLQueryItem(name: "embed", value: "machine,machines,associatedMachine")])
    }
}
