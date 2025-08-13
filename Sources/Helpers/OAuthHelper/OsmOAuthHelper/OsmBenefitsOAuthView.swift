//
//  OsmBenefitsOAuthView.swift
//  OsmAnd Maps
//
//  Created by Max Kojin on 15/07/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import SwiftUI
import Foundation
import AuthenticationServices

@available(iOS 16.4, *)
struct OsmBenefitsOAuthView: View {
    
    //WebAuthenticationSession is SwiftUI-only method for OAuth
    @Environment(\.webAuthenticationSession) private var webAuthenticationSession
    @Environment(\.dismiss) var dismiss
    
    @State var isLoginPaswordVCPresented = false
    
    var body: some View {
        
        GeometryReader { geometry in

            VStack(alignment: .leading, spacing: 0) {

                OsmOAuthButtonCancelView(dismiss: dismiss)

                OsmBenefitsOAuthTextHeaderView()

                OsmBenefitsOAuthFirstDescriptionView()

                OsmBenefitsOAuthSecondDescriptionView()
                
                Divider()
                
                OsmBenefitsOAuthCellView(leftIcon: "ic_custom_map_updates_colored", 
                                              title: localizedString("daily_map_updates"),
                                              rightIcon: "img_openstreetmap_logo")
                Divider().padding(.leading, 62)
                
                OsmBenefitsOAuthCellView(leftIcon: "ic_custom_monthly_map_updates_colored",
                                              title: localizedString("monthly_map_updates"),
                                              rightIcon: "img_openstreetmap_logo")
                Divider().padding(.leading, 62)
                
                OsmBenefitsOAuthCellView(leftIcon: "ic_custom_unlimited_downloads_colored",
                                              title: localizedString("unlimited_map_downloads"),
                                              rightIcon: "img_openstreetmap_logo")
                    
                OsmOAuthButtonOAuthView(session: webAuthenticationSession, dismiss: dismiss)
                
                Divider()
                
                OsmBenefitsOAuthBackgroundView()
                    .padding(.leading, 0)
                    .padding(.trailing, 0)
                    .padding(.top, 0)
                    .padding(.bottom, 0)
            }
        }
    }
}

@available(iOS 16.0, *)
private struct OsmBenefitsOAuthBackgroundView: View {
    var body: some View {
        ZStack {
            Color.viewBg.ignoresSafeArea()
        }
    }
}

@available(iOS 16.0, *)
private struct OsmBenefitsOAuthTextHeaderView: View {
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            Image(uiImage: UIImage(named: "ic_custom_openstreetmap_logo_colored_day_big")!)
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)
                .padding(.leading, 16)
                .padding(.top, 8)
                .padding(.bottom, 20)
            Text(localizedString("benefits_for_contributors"))
                .font(.title)
                .foregroundColor(.textColorPrimary)
                .multilineTextAlignment(.leading)
                .fontWeight(.semibold)
                .padding(.leading, 16)
                .padding(.trailing, 16)
                .padding(.top, 8)
                .padding(.bottom, 20)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

@available(iOS 16.0, *)
private struct OsmBenefitsOAuthFirstDescriptionView: View {
    var body: some View {
        Text(localizedString("benefits_for_contributors_primary_descr"))
            .font(.body)
            .foregroundColor(.textColorPrimary)
            .multilineTextAlignment(.leading)
            .padding(.leading, 16)
            .padding(.trailing, 16)
            .padding(.top, 0)
            .padding(.bottom, 20)
            .fixedSize(horizontal: false, vertical: true)
    }
}

@available(iOS 16.0, *)
private struct OsmBenefitsOAuthSecondDescriptionView: View {
    var body: some View {
        Text(localizedString("benefits_for_contributors_secondary_descr"))
            .font(.subheadline)
            .foregroundColor(.textColorSecondary)
            .multilineTextAlignment(.leading)
            .padding(.leading, 16)
            .padding(.trailing, 16)
            .padding(.top, 0)
            .padding(.bottom, 20)
            .fixedSize(horizontal: false, vertical: true)
    }
}

@available(iOS 16.0, *)
private struct OsmBenefitsOAuthCellView: View {
    var leftIcon: String
    var title: String
    var rightIcon: String
    
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            Image(uiImage: UIImage(named: leftIcon)!)
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
                .padding(.leading, 16)
                .padding(.top, 8)
                .padding(.bottom, 8)
            Text(title)
                .font(.body)
                .foregroundColor(.textColorPrimary)
                .multilineTextAlignment(.leading)
                .padding(.leading, 16)
                .padding(.top, 8)
                .padding(.bottom, 8)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Image(uiImage: UIImage(named: rightIcon)!)
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
                .padding(.leading, 16)
                .padding(.top, 8)
                .padding(.bottom, 8)
                .padding(.trailing, 16)
        }
    }
}

@available(iOS 16.4, *)
private struct OsmBenefitsOAuthView_Previews: PreviewProvider {
    static var previews: some View {
        OsmBenefitsOAuthView()
    }
}

//Wrapper to open this SwiftUI view from obj-c
@available(iOS 16.4, *)
@objc(OAOsmBenefitsOAuthSwiftUIViewWrapper)
@objcMembers
class OAOsmBenefitsOAuthSwiftUIViewWrapper: NSObject {
    static func get() -> UIViewController {
        return UIHostingController(rootView: OsmBenefitsOAuthView())
    }
}
