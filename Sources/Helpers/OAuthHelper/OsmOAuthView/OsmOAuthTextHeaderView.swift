//
//  OsmOAuthTextHeaderView.swift
//  OsmAnd Maps
//
//  Created by nnngrach on 06.06.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import SwiftUI

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

