//
//  SafariView.swift
//  RunApp
//
//  Created by Siddiqui Nazim on 07/01/22.
//

import SafariServices
import SwiftUI

/// A class used to open the SFSafariViewController from the SwiftUI class
public struct SafariView: UIViewControllerRepresentable {

    /// URL required for the Safari ViewController to open it.
    let url: URL
    /// (Optional) provide the tint color for Navigation bar if nothing is provided JD Green will be applied
    var tintColor: UIColor?
    
    public init(url: URL, tintColor: UIColor? = UIColor(DeereSwatch.green)){
        self.url = url
        self.tintColor = tintColor
    }

    public func makeUIViewController(context: UIViewControllerRepresentableContext<SafariView>) -> SFSafariViewController {
        let safariVC = SFSafariViewController(url: url)
        safariVC.preferredControlTintColor = tintColor
        return safariVC
    }

    public func updateUIViewController(_ uiViewController: SFSafariViewController, context: UIViewControllerRepresentableContext<SafariView>) {

    }

}
