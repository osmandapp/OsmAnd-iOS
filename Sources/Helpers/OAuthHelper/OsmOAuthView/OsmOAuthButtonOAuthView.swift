//
//  OsmOAuthButtonOAuthView.swift
//  OsmAnd Maps
//
//  Created by nnngrach on 06.06.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import SwiftUI
import AuthenticationServices

@available(iOS 16.4, *)
struct OsmOAuthButtonOAuthView: View {
    var session: WebAuthenticationSession
    var screenWidth: CGFloat
    var dismiss: DismissAction
    
    var body: some View {
        Button {
            Task {
                let token = await OsmOAuthHelper.performOAuth(session: session)
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
