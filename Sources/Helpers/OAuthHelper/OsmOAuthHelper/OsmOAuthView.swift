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
private struct OsmOAuthView: View {
    
    //WebAuthenticationSession is SwiftUI-only method for OAuth
    @Environment(\.webAuthenticationSession) private var webAuthenticationSession
    @Environment(\.dismiss) var dismiss
    
    @State var isLoginPaswordVCPresented = false
    
    var body: some View {
        
        GeometryReader { geometry in

            VStack(alignment: .center, spacing: 0) {

                OsmOAuthButtonCancelView(dismiss: dismiss)

                OsmOAuthImageView()

                OsmOAuthTextHeaderView()

                OsmOAuthTextDescriptionView()

                Spacer()

                OsmOAuthButtonOAuthView(session: webAuthenticationSession, dismiss: dismiss)
            }
        }
    }
}

struct OsmOAuthButtonCancelView: View {
    var dismiss: DismissAction

    var body: some View {
        Button(
            action: { dismiss() },
            label: {
                Text(localizedString("shared_string_cancel"))
                    .font(.body)
                    .foregroundColor(Color(UIColor.textColorActive))
                    .padding(.leading, 16)
                    .padding(.trailing, 16)
            }
        )
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .padding(.top, 6)
        .padding(.bottom, 6)
    }
}

private struct OsmOAuthImageView: View {
    var body: some View {
        Image(uiImage: UIImage(named: "img_openstreetmap_logo_big")!)
            .resizable()
            .scaledToFit()
            .frame(width: 90.0, height: 90.0)
            .padding(.top, 0)
            .padding(.bottom, 20)
    }
}


@available(iOS 16.0, *)
private struct OsmOAuthTextHeaderView: View {
    var body: some View {
        Text(localizedString("login_open_street_map_org"))
            .font(.system(size: 30))
            .multilineTextAlignment(.center)
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
            .padding(.leading, 16)
            .padding(.trailing, 16)
            .padding(.top, 0)
            .padding(.bottom, 20)
    }
}


@available(iOS 16.0, *)
private struct OsmOAuthTextDescriptionView: View {
    var body: some View {
        Text(localizedString("open_street_map_login_mode_simple"))
            .frame(maxWidth: .infinity)
            .padding(.leading, 16)
            .padding(.trailing, 16)
            .padding(.top, 0)
            .padding(.bottom, 0)
            .font(.body)
            .multilineTextAlignment(.center)
    }
}


@available(iOS 16.4, *)
struct OsmOAuthButtonOAuthView: View {
    var session: WebAuthenticationSession
    var dismiss: DismissAction
    
    var body: some View {
        Button(
            action: {
                Task {
                    let _ = await OsmOAuthHelper.performOAuth(session: session)
                    dismiss()
                }
            }
        ) {
            Label(localizedString("sign_in_with_open_street_map"), image: "ic_action_openstreetmap_logo")
                .frame(maxWidth: .infinity, minHeight: 42)
                .background(Color(UIColor.buttonBgColorPrimary))
                .foregroundColor(Color(UIColor.buttonTextColorPrimary))
                .cornerRadius(9)
                .clipShape(RoundedRectangle(cornerRadius: 9))
                .padding(.leading, 16)
                .padding(.trailing, 16)
                .padding(.top, 9)
                .padding(.bottom, 8)
        }
    }
}

@available(iOS 16.4, *)
private struct OsmOAuthView_Previews: PreviewProvider {
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
