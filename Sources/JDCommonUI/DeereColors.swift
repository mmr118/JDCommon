//
//  File.swift
//  
//
//  Created by Conway Charles on 1/3/22.
//

import UIKit
import SwiftUI

/// - Note: This enumeration must be kept in sync with the Common.xcassets Asset Catalog. The value of enum must match with the Asset colour name.
public enum DeereSwatch: String {
    case darkGreen = "DarkGreen"
    case darkYellow = "DarkYellow"
    case green = "Green"
    case lightGray = "LightGray"
    case lightGreen = "LightGreen"
    case lightYellow = "LightYellow"
    case mediumGray = "MediumGray"
    case yellow = "Yellow"
    case textDarkGrey = "TextDarkGrey"
    case textLightGrey = "TextLightGrey"
    case textMediumGrey = "TextMediumGrey"
    case backgroundGrey = "BackgroundGrey"
    case discloseIndicator = "DiscloseIndicator"
    case iconBackground = "IconBackground"
    case searchBarBackground = "SearchBarBackground"
    case backgroundWhite = "BackgroundWhite"
    case greenHeader = "GreenHeader"
    case graySeparator = "GraySeparator"
    case whiteHeader = "WhiteHeader"
}

public extension UIColor {
    
    /// Initialize one of the UIColor swatches defined in the JDCommonUI Asset Catalog
    convenience init?(_ deereSwatch: DeereSwatch) {
        self.init(named: deereSwatch.rawValue, in: Bundle.module, compatibleWith: nil)
    }
}

public extension Color {
    
    /// Initialize one of the UIColor swatches defined in the JDCommonUI Asset Catalog
    init(_ deereSwatch: DeereSwatch) {
        self.init(deereSwatch.rawValue, bundle: Bundle.module)
    }
    
    /// An "elevated" variant of the current UIColor.systemBackground color, for example in modal views
    static var backgroundElevated: Color {
       
        let updatedTraitCollection = UITraitCollection(traitsFrom: [.current, UITraitCollection(userInterfaceLevel: .elevated)])
        return Color(UIColor.systemBackground.resolvedColor(with: updatedTraitCollection))
    }
}
