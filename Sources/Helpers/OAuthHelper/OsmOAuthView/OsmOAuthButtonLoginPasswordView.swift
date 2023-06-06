//
//  OsmOAuthButtonLoginPasswordView.swift
//  OsmAnd Maps
//
//  Created by nnngrach on 06.06.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import SwiftUI

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
