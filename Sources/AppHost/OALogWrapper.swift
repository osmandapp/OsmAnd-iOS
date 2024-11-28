//
//  OALogWrapper.swift
//  OsmAnd
//
//  Created by Max Kojin on 28/11/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

func OALog(_ format: String, _ arguments: CVarArg...) {
    withVaList(arguments) { OALogger.log(format, withArguments: $0) }
}
