//
//  SearchBar.swift
//  RunApp
//
//  Created by Siddiqui Nazim on 28/12/21.
//

import SwiftUI

/// Creating a Custom Search  Bar in Swift UI as there is no Search Bar is not available
/// also  to support pre-iOS 15 clients where .searchable ViewModifier is not available.
public struct SearchBar<Accessory>: View where Accessory: View {
    
    @Binding public var searchString: String
    public let searchPlaceHolder: String
    @ViewBuilder public let rightAccessory: Accessory
    
    /// External Binding allows external views to observe the SearchBar's internal text field focus state. If not supplied during
    /// initialization this gets set to a constant value and has no effect.
    @Binding private var hasFocus: Bool
    /// Internal FocusState for tracking input focus of the SearchBar's TextField
    @FocusState private var textFieldHasFocus: Bool
    
    ///- Parameter SearchText: Search bar pre-filled text
    ///- Parameter SearchBarPlaceHolder: PlaceHolder text for SearchBar
    ///- Parameter hasFocus: Whether the SearchBar's text input has focus. If nil, this value is ignored.
    ///- Parameter accessory: An accessory view shown right-aligned within the search bar.
    public init(searchString: Binding<String>, searchPlaceHolder: String, hasFocus: Binding<Bool>? = nil, @ViewBuilder accessory: () -> Accessory) {
        self._searchString = searchString
        self.searchPlaceHolder = searchPlaceHolder
        self.rightAccessory = accessory()
        
        // If external Binding for focus state is not supplied, just set the
        // binding to a constant value. This does not affect the .textFieldHasFocus
        // parameter behavior.
        self._hasFocus = hasFocus ?? .constant(false)
    }

    public var body: some View {
        
        HStack(spacing: 0) {
            Spacer()
            
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField(searchPlaceHolder, text: $searchString)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(8)
                .focused($textFieldHasFocus)
                .onChange(of: textFieldHasFocus) { newValue in
                    hasFocus = textFieldHasFocus  // Sync internal FocusState to external hasFocus Binding
                }
                .onChange(of: hasFocus) { newValue in
                    textFieldHasFocus = hasFocus  // Sync internal FocusState to external hasFocus Binding
                }

            
            rightButton()
            .padding(4)
            .foregroundColor(.gray)
            
            Spacer()
        }
        .background(Color(.searchBarBackground))
        .cornerRadius(6)
    }
    
    @ViewBuilder private func rightButton() -> some View {
        if !searchString.isEmpty {
            Button {
                searchString = ""
                textFieldHasFocus = true  // Move keyboard focus to the TextField after clearing it
            } label: {
                Image(systemName: "x.circle.fill")
            }
        } else {
            rightAccessory
        }
    }
}


// NOTE: Tried several different ways to make the 'accessory' init parameter be optional
//  and none of the more intuitive ones worked as expected. Found a suggestion to achieve
//  it this way and it works. Could revisit in the future if a better way of declaring
//  optional @ViewBuilder init parameters is discovered.
extension SearchBar where Accessory == EmptyView {
    
    ///- Parameter SearchText: Search bar pre-filled text
    ///- Parameter SearchBarPlaceHolder: PlaceHolder text for SearchBar
    ///- Parameter hasFocus: Whether the SearchBar's text input has focus. If nil, this value is ignored.
    public init(searchString: Binding<String>, searchPlaceHolder: String, hasFocus: Binding<Bool>? = nil) {
        self.init(searchString: searchString, searchPlaceHolder: searchPlaceHolder, hasFocus: hasFocus, accessory: { EmptyView() })
    }
}



//MARK: Demo here
struct SearchBar_Previews: PreviewProvider {
        
    static var previews: some View {
        Group{
            SearchBar(searchString: .constant(""),
                      searchPlaceHolder: "Search Placeholder")
            .padding()
            .previewDisplayName("Empty")
            
            SearchBar(searchString: .constant("Hello world"),
                      searchPlaceHolder: "Search Placeholder")
            .padding()
            .previewDisplayName("With Text")
            
            SearchBar(searchString: .constant(""),
                      searchPlaceHolder: "Search Placeholder",
                      accessory: {
                
                Button {
                    // NO-OP
                } label: {
                    Image(systemName: "barcode.viewfinder")
                }
            })
            .previewDisplayName("With Accessory")
            .padding()
            .preferredColorScheme(.dark)
            .padding()
        }
    }
}
