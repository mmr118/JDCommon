//
//  Displays.swift
//  
//
//  Created by Conway Charles on 3/23/22.
//

import Foundation
import JDCommonAPIClient

public struct DisplayDTO: Equipment, Codable, Identifiable, OrganizationOwned {

    public let id: String  // TODO: Determine if 'id' parameters cannot collide or if we need to prefix them to avoid collision with other equipment (for Identifiable protocol)
    public var equipmentCategory: EquipmentCategory { .display }
    public let serialNumber: String?
    public let type: String
    public let firmwareVersion: FirmwareVersionDTO
    public let screenHeight: Int?
    public let screenWidth: Int?
    public let machine: MachineDTO?
    public let organization: OwningOrganizationDTO?
    
    public let deviceMake: DeviceCategory?
    public let deviceType: DeviceCategory
    public let deviceModel: DeviceCategory
    
    /// Return the 'type' as display name
    public var name: String { hierarchyLevelModel?.name ?? type }
    public var detailedName: String { name }
    public var icon: EquipmentIconDTO? = nil
    
    public var hierarchyLevelMake: EquipmentHierarchyLevel? { deviceMake }
    public var hierarchyLevelType: EquipmentHierarchyLevel? { deviceType }
    public var hierarchyLevelModel: EquipmentHierarchyLevel? { deviceModel }
    
    public var organizationIdentifier: String? { organization?.id }
    
    public var pairings: [Equipment] { if let theMachine = machine { return [theMachine] } else { return [] }}
}

extension DisplayDTO: PreviewContentDecodable {
    
    public static let demo_model2630 = DisplayDTO.previewContentFromBundleJSON("Display-2630-ExampleA")
    public static let demo_model4640 = DisplayDTO.previewContentFromBundleJSON("Display-4640-ExampleA")
}

/// Methods that calculate the bundle version number taking the provided software version into account.
/// The logic from this was taken from the project: 'JDLink/jdlux-client', and can be fin in here:
/// https://github.deere.com/JDLink/jdlux-client/blob/master/src/components/machine-details/machine-setup/SetupDisplays.js
extension DisplayDTO {
    
    private static func getOlderVersionNumber(majorVersionNumber: Int, minorVersionNumber: Int) -> String {
        if majorVersionNumber < 10 {
            if minorVersionNumber < 12 { return "14-2" }
            return "15-1"
        }
        
        switch minorVersionNumber {
        case 0:
            return "15-2"
        case 1...4:
            return "16-1"
        case 5...7:
            return "16-2"
        case 8:
            return "17-1"
        case 9:
            return "17-2"
        case 10:
            return "18-1"
        default:
            return "18-2"
        }
    }
    
    private static func getNewerVersionNumber(majorVersionNumber: Int, minorVersionNumber: Int) -> String {
        let BASE_MAJOR_GENOS_VERSION = 19
        let NEWER_MINOR_VERSION_START = 13
        let THIRDS_DENOMINATOR = 3
        let minorVersionOffset = minorVersionNumber - NEWER_MINOR_VERSION_START
        let fractionalBit = minorVersionOffset % THIRDS_DENOMINATOR
        let integerVersionToAdd = (minorVersionOffset - fractionalBit) / THIRDS_DENOMINATOR
        
        let majorGenosVersion = BASE_MAJOR_GENOS_VERSION + integerVersionToAdd
        let minorGenosVersion = fractionalBit + 1
        
        return "\(majorGenosVersion)-\(minorGenosVersion)"
    }
    
    /// Calculates the bundle version number taking the provided 'softwareVersion' number into account
    /// - Parameter softwareVersion: The software version number to validate against the oldest and newest threshold versions.
    /// - Returns: A formatted String that represents the calculated 'Bundle Version' and then the original 'softwareVersion' inside parentheses.
    /// With the following format: 'xx-x (xxx.xx.xxxx-xx)'
    public static func getSoftwareBundleVersionString(from softwareVersion: String) -> String {
        let OLDEST_MAJOR_VERSION = 8
        let NEWEST_MAJOR_VERSION = 10
        let MAJOR_VERSION_THRESHOLD = 10
        let MINOR_VERSION_THRESHOLD = 13
        let versionNumberSplitList = softwareVersion.split(separator: ".")
        
        guard versionNumberSplitList.count >= 2,
              let majorVersionNumber = Int(versionNumberSplitList[0]),
              let minorVersionNumber = Int(versionNumberSplitList[1]),
              majorVersionNumber > OLDEST_MAJOR_VERSION,
              majorVersionNumber <= NEWEST_MAJOR_VERSION else {
            return softwareVersion
        }
        
        if (majorVersionNumber < MAJOR_VERSION_THRESHOLD || minorVersionNumber < MINOR_VERSION_THRESHOLD) {
            return DisplayDTO.getOlderVersionNumber(majorVersionNumber: majorVersionNumber, minorVersionNumber: minorVersionNumber) + " (\(softwareVersion))"
        }
        
        return DisplayDTO.getNewerVersionNumber(majorVersionNumber: majorVersionNumber, minorVersionNumber: minorVersionNumber) + " (\(softwareVersion))"
    }
}


// MARK: Requests
public struct GetDisplayListRequest: ConfigurableAPIRequest, JSONDeserializableResponse, AxiomPagination {
    
    public typealias ResponseType = AxiomV3List<DisplayDTO>
    public var baseURLByEnvironment: [DeereAPIEnvironment: URL?] = axiomBaseURLs
    public var urlComponents : URLComponents?
    public var additionalHTTPHeadersFields: [String : String]?
    public let orgID: String
    
    public let startingItemIndex: Int = 0
    public let itemsPerPage: Int = 100
    
    public init(orgID: String) {
        
        self.orgID = orgID
        self.urlComponents = URLComponents(string: "organizations/\(orgID)/displays",
                                           queryItems: [URLQueryItem(name: "embed", value: "machine")])
    }
}

public struct GetDisplayRequest: ConfigurableAPIRequest, JSONDeserializableResponse {
    
    public typealias ResponseType = DisplayDTO
    public var baseURLByEnvironment: [DeereAPIEnvironment: URL?] = axiomBaseURLs
    public var urlComponents : URLComponents?
    public var additionalHTTPHeadersFields: [String : String]?
    public var matrixParameters: [String : String]?
    
    public init(displayID: String) {
        
        self.urlComponents = URLComponents(string: "displays/\(displayID)",
                                           queryItems: [URLQueryItem(name: "embed", value: "machine")])
    }
}
