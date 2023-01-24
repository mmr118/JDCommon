//
//  Equipment.swift
//
//
//  Created by Siddiqui Nazim on 04/02/22.
//

import Foundation
import JDCommonAPIClient

/// A top-level grouping for Equipment, chosen to align with how Platform APIs are segregated for different equipment types.
/// - Note: Chose "Category" terminology here because there is already an "Equipment Type" like Harvester, Sprayer, Tractor, etc.
public enum EquipmentCategory: Int, Comparable, Codable {
    // WARNING: Do not change the raw values for existing cases, only add new ones.
    //  These values are stored in persistent storage and would become out of sync.
    case unknown = 0
    case machine = 1
    case implement = 2
    case display = 3
    case gnssReceiver = 4
    case terminal = 5
    case guidance = 6
    
    /// Lower values will preceed higher ones in an ascending sort. Cases sharing a value will not be ordered relative
    /// to one-another.
    private var sortIndex: Int {
        switch self {
        case .machine: return 0
        case .implement: return 1
        case .display: return 2
        case .gnssReceiver: return 3
        case .terminal: return 4
        case .guidance: return 5
        case .unknown: return Int.max
        }
    }
    
    public static func < (lhs: EquipmentCategory, rhs: EquipmentCategory) -> Bool {
        return lhs.sortIndex < rhs.sortIndex
    }
}

/// Protocol encompassing Machines, Implements, Displays, Modems, and Receivers in an Organization
public protocol Equipment {
    
    var id: String { get }
    var name: String { get }
    var detailedName: String { get }
    /// The primary, public-facing serialized identifier for the piece of equipment. For self-propelled equipment this could be a VIN or PIN.
    /// For other types of equipment it could just be a simple serial number.
    var serialNumber: String? { get }
    /// Generally coincides with the object type returned from the Platform APIs
    var equipmentCategory: EquipmentCategory { get }
    /// - Note: Not available for all equipment
    var icon: EquipmentIconDTO? { get }
    /// Other Equipment instances "paired" or associated with this piece of Equipment (e.g. Terminal and Display associated with a Machine)
    var pairings: [Equipment] { get }
    
    /// Individual implementations may have custom Make objects, but this property represents a common Make representation.
    var hierarchyLevelMake: EquipmentHierarchyLevel? { get }
    /// Individual implementations may have custom Type objects, but this property represents a common Type representation.
    var hierarchyLevelType: EquipmentHierarchyLevel? { get }
    /// Individual implementations may have custom Model objects, but this property represents a common Model representation.
    var hierarchyLevelModel: EquipmentHierarchyLevel? { get }
}

/// Protocol for Equipment that is part of a John Deere Organization
public protocol OrganizationOwned where Self: Equipment {
    
    var organizationIdentifier: String? { get }
}


// MARK: - Equipment API responses child objects
public struct EmbeddedTerminalsDTO: Codable, AxiomLinkable {
    
    public let type: String?
    public var links: AxiomLinks = .emptySet
    public let terminals: [TerminalDTO]?
}

public struct EmbeddedDisplaysDTO: Codable, AxiomLinkable {
    
    public let displaies: [DisplayDTO]
    public let links: AxiomLinks
}

public struct FirmwareVersionDTO: Codable {
    
    public let number: String?
    let type: String?
}

public struct OwningOrganizationDTO: Codable {
    
    let id: String
    let member: Bool
}

public struct CapabilityDTO: Codable {
    
    public let availability: String?
    public let capable: Bool?
    public let type: String?
}

public struct EquipmentIconDTO: Codable {
    
    /// The identifier for the icon in the icon library (not human readable)
    public let name: String
    /// Optional color theming information
    public let iconStyle: EquipmentIconStyleDTO?
    
    private enum CodingKeys : String, CodingKey {
        case name
        case iconStyle
        
    }
    
    public init(name: String, primaryColorHex: String? = nil, secondaryColorHex: String? = nil, stripeColorHex: String? = nil) {

        self.name = name
        self.iconStyle = EquipmentIconStyleDTO(primaryColor: primaryColorHex, secondaryColor: secondaryColorHex, stripeColor: stripeColorHex)
    }
}

/// The color theme for a JDIcon instance
public struct EquipmentIconStyleDTO: Codable {
    
    /// The primary color of the icon as a hexadecimal string
    public let primaryColor: String?
    /// The secondary color of the icon as a hexadecimal string
    public let secondaryColor: String?
    /// The outline color of the icon as a hexadecimal string
    public let stripeColor: String?
}
