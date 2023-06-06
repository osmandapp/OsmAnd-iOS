//
//  OsmOAuthView.swift
//  OsmAnd Maps
//
//  Created by nnngrach on 30.05.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import SwiftUI
import Foundation
import AuthenticationServices

@available(iOS 16.4, *)
struct OsmOAuthView: View {
    
    @Environment(\.webAuthenticationSession) private var webAuthenticationSession
    @Environment(\.dismiss) var dismiss
    
    @State var isLoginPaswordVCPresented = false
    
    var body: some View {
        
        GeometryReader { geometry in
            NavigationView {
                VStack(spacing: 0) {
                    
                    OsmOAuthImageView()
                    
                    OsmOAuthTextHeaderView(screenWidth: geometry.size.width)
                    
                    OsmOAuthTextDescriptionView(screenWidth: geometry.size.width)
                    
                    Spacer()
                    
                    OsmOAuthButtonOAuthView(session: webAuthenticationSession, screenWidth: geometry.size.width, dismiss: dismiss)
                    
                    OsmOAuthButtonLoginPasswordView(isPresented: isLoginPaswordVCPresented, screenWidth: geometry.size.width, dismiss: dismiss)
                    
                }
                .navigationBarTitleDisplayMode(NavigationBarItem.TitleDisplayMode.inline)
                .navigationBarItems(
                    leading: Button(
                        action: { dismiss() },
                        label: {
                            Text(localizedString("shared_string_cancel"))
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.init(UIColor(rgbValue: color_primary_purple)))
                        }
                    )
                )
            }
        }
    }
}



@available(iOS 16.4, *)
struct OsmOAuthView_Previews: PreviewProvider {
    static var previews: some View {
        OsmOAuthView()
    }
}

//Wrapper to open this SwiftUI view from obj-c
@available(iOS 16.4, *)
@objc(OsmOAuthSwiftUIViewWrapper)
@objcMembers
class OsmOAuthSwiftUIViewWrapper: NSObject {
    static func get() -> UIViewController {
        return UIHostingController(rootView: OsmOAuthView())
    }
}


//Wrapper to open ViewController from this SwiftUI view
struct AccountSettingsVCWrapper: UIViewControllerRepresentable {
    
    typealias UIViewControllerType = OAOsmAccountSettingsViewController
    
    func makeUIViewController(context: Context) -> OAOsmAccountSettingsViewController {
        return OAOsmAccountSettingsViewController()
    }
    
    func updateUIViewController(_ uiViewController: OAOsmAccountSettingsViewController, context: Context) {
        //Do nothing
    }
}
