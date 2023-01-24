//
//  DeereButtons.swift
//  JDCommonSwiftUI
//
//  Created by Conway Charles on 8/19/21.
//

import SwiftUI

public enum DeereButtonLayout {
    case defaultPadding
    case fullWidth
}

public struct DeerePrimaryButton: ButtonStyle {
    
    @Environment(\.isEnabled) public var isEnabled: Bool
    
    let layout: DeereButtonLayout
    
    public init(layout: DeereButtonLayout = .defaultPadding) {
        self.layout = layout
    }
    
    private func backgroundColor(for configuration: ButtonStyleConfiguration) -> Color {
                
        if isEnabled == false {
            return Color(.lightGray)
        } else if configuration.isPressed {
            return Color(.darkYellow)
        } else {
            return Color(.yellow)
        }
    }
    
    public func makeBody(configuration: Configuration) -> some View {
  
        configuration.label
            .padding(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
            .frame(maxWidth: (layout == .fullWidth) ? .infinity : nil)
            .background(backgroundColor(for: configuration))
            .cornerRadius(4)
            .font(.body.weight(.medium))
            .foregroundColor(isEnabled ? Color.black : Color(.mediumGray))
    }
}

public struct DeereSecondaryButton: ButtonStyle {
    
    @Environment(\.isEnabled) public var isEnabled: Bool
    
    let layout: DeereButtonLayout
    
    public init(layout: DeereButtonLayout = .defaultPadding) {
        self.layout = layout
    }
    
    private func backgroundColor(for configuration: ButtonStyleConfiguration) -> Color {
        
        if isEnabled == false {
            return Color(.lightGray)
        } else if configuration.isPressed {
            return Color(.lightGreen).opacity(0.2)
        } else {
            return .clear
        }
    }
    
    public func makeBody(configuration: Configuration) -> some View {
        
        configuration.label
            .padding(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
            .frame(maxWidth: (layout == .fullWidth) ? .infinity : nil)
            .background(backgroundColor(for: configuration))
            .cornerRadius(4)
            .font(.body.weight(.semibold))
            .foregroundColor(isEnabled ? Color(.green) : Color(.mediumGray))
            .overlay(RoundedRectangle(cornerRadius: 4)
                        .stroke(lineWidth: isEnabled ? 1.5 : 0)
                        .foregroundColor(Color(.green)))
    }
}

public struct DeereTertiaryButton: ButtonStyle {
    
    @Environment(\.isEnabled) public var isEnabled: Bool
    
    let layout: DeereButtonLayout
    
    public init(layout: DeereButtonLayout = .defaultPadding) {
        self.layout = layout
    }
    
    public func makeBody(configuration: Configuration) -> some View {
        
        configuration.label
            .padding(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
            .frame(maxWidth: (layout == .fullWidth) ? .infinity : nil)
            .background(configuration.isPressed ? Color(.lightGreen).opacity(0.2) : .clear)
            .cornerRadius(4)
            .font(.body.weight(.semibold))
            .foregroundColor(isEnabled ? Color(.green) : Color(.mediumGray))
    }
}

internal struct DeereButton_Previews: PreviewProvider {
    internal static var previews: some View {
        Group {
            VStack(spacing: 32.0) {
                
                Text("JD Button Styles").font(.title2)
                
                HStack(spacing: 16) {
                    
                    Button("Save") {
                        
                    }.buttonStyle(DeerePrimaryButton())
                    
                    Button("Save") {
                        
                    }.buttonStyle(DeerePrimaryButton()).environment(\.isEnabled, false)
                }
                
                HStack(spacing: 16) {
                    
                    Button("Save") {
                        
                    }.buttonStyle(DeereSecondaryButton())
                    
                    Button("Save") {
                        
                    }.buttonStyle(DeereSecondaryButton()).environment(\.isEnabled, false)
                }
                
                HStack(spacing: 16) {
                    
                    Button(action: {}, label: {
                        Label("Save", systemImage: "checkmark.circle.fill")
                    }).buttonStyle(DeereTertiaryButton())
                    
                    Button(action: {}, label: {
                        Label("Save", systemImage: "checkmark.circle.fill")
                    }).buttonStyle(DeereTertiaryButton()).environment(\.isEnabled, false)
                }
                
                Button("Full Width Button") {
                    
                }
                .buttonStyle(DeerePrimaryButton(layout: .fullWidth))
                .padding()
                
                Spacer()
                
            }.padding(.top, 64)
            
            VStack(spacing: 32.0) {
                
                Text("JD Button Styles").font(.title2)
                
                HStack(spacing: 16) {
                    
                    Button("Save") {
                        
                    }.buttonStyle(DeerePrimaryButton())
                    
                    Button("Save") {
                        
                    }.buttonStyle(DeerePrimaryButton()).environment(\.isEnabled, false)
                }
                
                HStack(spacing: 16) {
                    
                    Button("Save") {
                        
                    }.buttonStyle(DeereSecondaryButton())
                    
                    Button("Save") {
                        
                    }.buttonStyle(DeereSecondaryButton()).environment(\.isEnabled, false)
                }
                
                HStack(spacing: 16) {
                    
                    Button(action: {}, label: {
                        Label("Save", systemImage: "checkmark.circle.fill")
                    }).buttonStyle(DeereTertiaryButton())
                    
                    Button(action: {}, label: {
                        Label("Save", systemImage: "checkmark.circle.fill")
                    }).buttonStyle(DeereTertiaryButton()).environment(\.isEnabled, false)
                }
                
                Button("Full Width Button") {
                    
                }
                .buttonStyle(DeerePrimaryButton(layout: .fullWidth))
                .padding()
                
                Spacer()
                
            }
            .preferredColorScheme(.dark)
            .padding(.top, 64)
        }
    }
}
