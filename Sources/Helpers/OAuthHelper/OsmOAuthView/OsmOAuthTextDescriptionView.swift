//
//  OsmOAuthTextDescriptionView.swift
//  OsmAnd Maps
//
//  Created by nnngrach on 06.06.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import SwiftUI

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
