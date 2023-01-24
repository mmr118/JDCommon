//
//  MakeTypeModel.swift
//  
//
//  Created by Conway Charles on 12/9/22.
//

import Foundation

/// Common protocol encompassing different levels of product hierarchy like Make ("JOHN DEERE"), Type ("Hay & Forage"), and Model ("8460")
///
/// In addition to encompassing different levels of product hierarchy, this protocol also represents the least common denominator between
/// different make/type/model response schemas across different API endpoints.
public protocol EquipmentHierarchyLevel {
    
    /// An identifier parameter returned by the API. This may be relevant only in the context in which it is returned, and shouldn't necessarily
    /// be compared to identifiers returned from other endpoints (e.g. when received from a Displays endpoint vs. a Machines endpoint)
    var id: String { get }
    var name: String { get }
}

/// Equipment Make (i.e. brand). Observed to be returned from Machines and Implements endpoints.
public struct EquipmentMakeDTO: EquipmentHierarchyLevel, Codable {
    
    public let name: String
    public let ERID: String
    public let certified: Bool
    public let id: String
    /// Indicates this equipment make is associated with either John Deere or one of its subsidiary companies.
    /// - Note: May not be available depending on which API endpoint is returning the object
    public let deereOrSubsidiary: Bool?
}

/// Equipment Type. Observed to be returned from Machines and Implements endpoints.
public struct EquipmentTypeDTO: EquipmentHierarchyLevel, Codable {
    
    public let name: String
    public let GUID: String?  // NOTE: Observed to be missing in QUAL, so made optional
    public let category: String
    public let certified: Bool
    public let marketSegment: String
    public let id: String
}

/// Equipment Apex Type (a separate, more limited type enumeration from the legacy Apex software platform). Observed
/// to be returned from Machines and Implements endpoints.
public struct EquipmentApexTypeDTO: EquipmentHierarchyLevel, Codable {
    
    public let name: String
    public let GUID: String
    public let category: String
    public let id: String
}

/// Equipment Model. Observed to be returned from Machines and Implements endpoints.
public struct EquipmentModelDTO: EquipmentHierarchyLevel, Codable {
    
    public let name: String
    public let GUID: String?  // NOTE: Observed to be nil in rare cases
    public let certified: Bool
    public let classification: String
    public let id: String
    
    // Can be embedded in /equipmentModel search endpoint responses
    public let equipmentMake: EquipmentMakeDTO?
    public let equipmentType: EquipmentTypeDTO?
    
    // Additional parameters associated with /equipment/{serialNumber}/equipmentModel responses
    /// The icon name, if available
    public let icon: String?
    /// The icon style, if available
    public let iconStyle: EquipmentIconStyleDTO?
    
    // SwiftUI Preview demo data
    public static let demoModelSearchResults = AxiomV3List<EquipmentModelDTO>.previewContentFromBundleJSON("ModelSearchResults-ExampleA").values
}

/// A simpler schema used for Make and Model information in some Machine records.
public struct LegacyMachineCategory: EquipmentHierarchyLevel, Codable {
    public let name: String
    public let id: String
}

/// A simpler schema used across Make, Type, and Model levels for Display and Terminal devices.
public struct DeviceCategory: EquipmentHierarchyLevel, Codable {
    public let name: String
    public let commonName: String?
    public let id: String
}


// NOTE: GetModelNamesRequest() can be implemented here as a request by an authenticated user to Axiom platform
//  but we will instead use the my-ops-api middleware to be able to proxy that request so it can be used by
//  both authenticated and unauthenticated users.
