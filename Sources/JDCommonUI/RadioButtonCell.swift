//
//  RadioButtonCell.swift
//  RunApp
//
//  Created by Abhyankar Bhushan on 15/02/22.
//

import SwiftUI

public struct RadioButtonCell: View {
    
    let title: String
    let subtitle: String?
    let isSelected: Bool
    
    public init(title: String, subtitle: String? = nil, isSelected: Bool) {
        self.title = title
        self.subtitle = subtitle
        self.isSelected = isSelected
    }
    
    public var body: some View {
        
        HStack {
            
            VStack {
                Text(title)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                if let theSubtitle = subtitle {
                    Text(theSubtitle)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Image(systemName: isSelected ? "circle.inset.filled" : "circle")
                .foregroundColor(isSelected ? .accentColor : .gray)
        }
    }
}

struct RadioButtonCellView_Previews: PreviewProvider {
    static var previews: some View {
        
        List {
            RadioButtonCell(title: "Title", isSelected: true)
            
            RadioButtonCell(title: "Title", subtitle: "Organization Action Required", isSelected: false)
            
            RadioButtonCell(title: "Title", subtitle: "Some condition that needs to be met, potentially a very long string", isSelected: true)
        }
    }
}
