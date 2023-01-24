# JDCommon

TODO: General description.


## Design Decisions

### Common Colors
Deere UX color naming conventions may lead to ambiguity when supporting both light and dark mode. Deere color names with adjectives like "Light Green" or "Dark Yellow" are from a Light Mode perspective and may actually appear opposite in Dark Mode. To address this Apple has switched to terminology like "Primary", "Secondary", and "Tertiatry" to denote role while allowing for different visual representations in Light and Dark Modes. We could adopt a similar pattern for color naming within this codebase but then we would diverge from the broad corporate naming and make it more difficult to to compare between them.

### Package Structure
Believe issue causing failure of SwiftUI Preview when viewing DeereButtons is related to: https://forums.swift.org/t/xcode-previews-swiftpm-resources-xcpreviewagent-crashed/51680/5
When having a `JDCommonSwiftUI` that depended on `JDCommonUIKit`, the resources from the transitive dependency aren't currently accessible correctly when doing Xcode's SwiftUI Preview directly in the package, but it does work OK when previewing the same views inside a View in the app target.

### Random Issues
SwiftUI Preview failing with "Cannot preview ... not found in any targets" message when SwiftUI View implementation was in a subfolder of the Sources/ folder for that module.
