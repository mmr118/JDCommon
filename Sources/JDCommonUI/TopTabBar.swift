//
//  TopTabBar.swift
//  RunApp
//
//  Created by Siddiqui Nazim on 28/12/21.
//

import SwiftUI

/// A custom tab bar, to be used on top of content, that can be configured flexibly with any array of items that
/// satisfy the `TabItem` requirements, e.g. a custom Enum type.
///
/// The text for each tab item comes from `TabItem.description`. Behavior when `selectedItem` doesn't
/// exist in `items` is not defined.
///
/// - Parameters:
///  - items: List of the tabs need to display on the screen
///  - selectedItem: Binding type of parameter to manage/notify the tab pressed
///  - enabledScrolling: Boolean representing if the tab view is scrollable. If the tab views exceed the
///  width of the screen, this value should be set to `true`; default is `false`.
public struct TopTabBar<TabItem: Identifiable & Equatable & CustomStringConvertible>: View {
    
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    
    let scrollingEnabled: Bool
    /// List of the tabs need to display on the screen
    let items: [TabItem]
    /// Binding type of parameter to manage/notify the tab pressed
    @Binding var selectedItem: TabItem

    public init(items: [TabItem], selectedItem: Binding<TabItem>, scrollingEnabled: Bool = false) {
        self.items = items
        self._selectedItem = selectedItem
        self.scrollingEnabled = scrollingEnabled
    }


    /// Available when `TabItem` conforms to `CaseIterable` and `TabItem.AllCases` equals `[TabItem]`,
    /// - Note: The view's `items` will be set to `TabItem.allCases`.
    public init(selection: Binding<TabItem>, scrollingEnabled: Bool = false) where TabItem: CaseIterable, TabItem.AllCases == [TabItem] {
        self.init(items: TabItem.allCases, selectedItem: selection, scrollingEnabled: scrollingEnabled)
    }

    public var body: some View {
        
        VStack(alignment: .leading, spacing: 0){

            if scrollingEnabled {
                ScrollViewReader { scrollViewProxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        tabContent(scrollProxy: scrollViewProxy)
                    }
                }
            } else {
                tabContent(scrollProxy: nil)
            }

            Rectangle()
                .foregroundColor(Color(.graySeparator))
                .frame(maxHeight: 1)
        }
    }

    @ViewBuilder private func tabContent(scrollProxy: ScrollViewProxy?) -> some View {

        HStack(alignment: .lastTextBaseline, spacing: 20) {
                
            ForEach(items) { tabItem in

                Button {
                    selectedItem = tabItem
                    
                    if scrollingEnabled {
                        withAnimation(.spring()) {
                            // NOTE: Attempts to scroll selected item into the center of the TopTabBar so
                            //  that a bit of the preceding and succeeding tab buttons is visible, to clue
                            //  the user in that there is more to scroll to.
                            scrollProxy?.scrollTo(tabItem.id, anchor: .top)
                        }
                    }
                    
                } label: {
                    TabItemView(title: tabItem.description, isSelected: tabItem == selectedItem)
                }
            }
        }
        .padding([.top, .leading, .trailing])

    }

}

extension TopTabBar {
    
    struct TabItemView: View {
        
        let title: String
        let isSelected: Bool
        
        var body: some View {
                            
            Text(title)
                .foregroundColor(isSelected ? .accentColor : .secondary)
                .fontWeight(.medium)
                .padding(.bottom, 9)
                .background {
                    
                    Rectangle()
                        .fill(isSelected ? Color.accentColor : .clear)
                        .frame(maxHeight: 3)
                        .cornerRadius(1)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                }
        }
    }
}


// MARK: - Demo
struct TopTabsView_Previews: PreviewProvider {
    
    static var previews: some View {

        PreviewContent { selection in
            TopTabBar.init(items: [SampleTabBar.first_tab, SampleTabBar.second_tab, SampleTabBar.third_tab, SampleTabBar.fourth_tab], selectedItem: selection)
        }

        PreviewContent { selection in
            TopTabBar(selection: selection, scrollingEnabled: true)
        }
        .preferredColorScheme(.dark)

    }

}

private struct PreviewContent<Content: View>: View {

    @State var selection: SampleTabBar = .first_tab
    let content: (Binding<SampleTabBar>) -> Content

    var body: some View {
        VStack(spacing: 0) {
            content($selection)
            Text(selection.description)
                .font(.title)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}


private enum SampleTabBar: String, Identifiable, CustomStringConvertible, CaseIterable {
    
    var id: String { self.rawValue }
    var description: String { return self.rawValue.capitalized.replacingOccurrences(of: "_", with: " ") }
    
    case first_tab
    case second_tab
    case third_tab
    case fourth_tab
    case fifth_tab
    case sixth_tab
    case seventh_tab
    case eigth_tab
    case ninth_tab
    case tenth_tab

}
