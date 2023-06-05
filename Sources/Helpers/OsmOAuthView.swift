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
    
    //TODO: delete
    @Environment(\.authorizationController) private var authorizationController
    
    @State var isLoginPaswordVCPresented = false
    
    var body: some View {
        
        GeometryReader { geometry in
            NavigationView {
                VStack(spacing: 0) {
                
                    Image(uiImage: UIImage(named: "img_openstreetmap_logo_big")!)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 90.0, height: 90.0)
                        .padding(.top, 8)
                        .padding(.bottom, 20)
                    
                    Text(localizedString("login_open_street_map_org"))
                        .font(.system(size: 30))
                        .multilineTextAlignment(.center)
                        .fontWeight(.semibold)
                        .frame(width: (geometry.size.width - 16))
                        .padding(.bottom, 20)
                    
                    Text(localizedString("open_street_map_login_mode_simple"))
                        .frame(width: (geometry.size.width - 16))
                        .font(.body)
                        .multilineTextAlignment(.center)
                    
                    
                    Spacer()
                    
                    
                    Button {
                        Task {
                            let token = await OsmOAuthHelper.performOAuth(session: webAuthenticationSession)
                            dismiss()
                        }
                    } label: {
                        Text(localizedString("sign_in_with_open_street_map"))
                    }
                    .frame(width: (geometry.size.width - 32), height: 42)
                    .background(Color.init(UIColor(rgbValue: color_primary_purple)))
                    .foregroundColor(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 9))
                    .padding(.bottom, 16)
                    
                    Button {
                        Task {
                            isLoginPaswordVCPresented = true
                            NavigationLink(destination: AccountSettingsVCWrapper()) {
                                EmptyView()
                            }
                        }
                    } label: {
                        Text(localizedString("use_login_and_password"))
                    }
                    .frame(width: (geometry.size.width - 32), height: 42)
                    .background(Color.init(UIColor(rgbValue: color_button_gray_background)))
                    .foregroundColor(Color.init(UIColor(rgbValue: color_primary_purple)))
                    .clipShape(RoundedRectangle(cornerRadius: 9))
                    .padding(.bottom, 10)
                    .sheet(isPresented: $isLoginPaswordVCPresented) {
                        
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
@objc class OsmOAuthSwidtUIViewWrapper: NSObject {
    @objc static func get() -> UIViewController {
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
