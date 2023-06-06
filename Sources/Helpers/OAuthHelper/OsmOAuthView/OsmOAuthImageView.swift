//
//  OsmOAuthImageView.swift
//  OsmAnd Maps
//
//  Created by nnngrach on 06.06.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import SwiftUI

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
