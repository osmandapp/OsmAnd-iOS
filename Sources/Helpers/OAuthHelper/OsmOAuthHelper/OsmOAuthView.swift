//
//  OsmOAuthView.swift
//  OsmAnd Maps
//
//  Created by nnngrach on 30.05.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

// Waiting for GitHub Actions XCode and macOS version updating
/*
import SwiftUI
import Foundation
import AuthenticationServices

@available(iOS 16.4, *)
struct OsmOAuthView: View {
    
    //WebAuthenticationSession is SwiftUI-only method for OAuth
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



struct OsmOAuthImageView: View {
    var body: some View {
        Image(uiImage: UIImage(named: "img_openstreetmap_logo_big")!)
            .resizable()
            .scaledToFit()
            .frame(width: 90.0, height: 90.0)
            .padding(.top, 8)
            .padding(.bottom, 20)
    }
}


@available(iOS 16.0, *)
struct OsmOAuthTextHeaderView: View {
    var screenWidth: CGFloat
    var body: some View {
        Text(localizedString("login_open_street_map_org"))
            .font(.system(size: 30))
            .multilineTextAlignment(.center)
            .fontWeight(.semibold)
            .frame(width: (screenWidth - 16))
            .padding(.bottom, 20)
    }
}


@available(iOS 16.0, *)
struct OsmOAuthTextDescriptionView: View {
    var screenWidth: CGFloat
    
    var body: some View {
        Text(localizedString("open_street_map_login_mode_simple"))
            .frame(width: (screenWidth - 16))
            .font(.body)
            .multilineTextAlignment(.center)
    }
}


@available(iOS 16.4, *)
struct OsmOAuthButtonOAuthView: View {
    var session: WebAuthenticationSession
    var screenWidth: CGFloat
    var dismiss: DismissAction
    
    var body: some View {
        Button {
            Task {
                let _ = await OsmOAuthHelper.performOAuth(session: session)
                dismiss()
            }
        } label: {
            Text(localizedString("sign_in_with_open_street_map"))
        }
        .frame(width: (screenWidth - 32), height: 42)
        .background(Color.init(UIColor(rgbValue: color_primary_purple)))
        .foregroundColor(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 9))
        .padding(.bottom, 16)
    }
}


struct OsmOAuthButtonLoginPasswordView: View {
    @State var isPresented: Bool
    var screenWidth: CGFloat
    var dismiss: DismissAction
    
    var body: some View {
        Button {
            Task {
                isPresented = true
                NavigationLink(destination: AccountSettingsVCWrapper()) {
                    EmptyView()
                }
            }
        } label: {
            Text(localizedString("use_login_and_password"))
        }
        .frame(width: (screenWidth - 32), height: 42)
        .background(Color.init(UIColor(rgbValue: color_button_gray_background)))
        .foregroundColor(Color.init(UIColor(rgbValue: color_primary_purple)))
        .clipShape(RoundedRectangle(cornerRadius: 9))
        .padding(.bottom, 10)
        .sheet(isPresented: $isPresented) {
            
            NavigationView {
                AccountSettingsVCWrapper()
                    .ignoresSafeArea()
                    .navigationBarTitleDisplayMode(NavigationBarItem.TitleDisplayMode.inline)
                    .navigationTitle(Text(localizedString("shared_string_account_add")))
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
@objc(OAOsmOAuthSwiftUIViewWrapper)
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
*/
