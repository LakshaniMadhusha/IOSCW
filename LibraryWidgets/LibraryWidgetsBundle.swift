//
//  LibraryWidgetsBundle.swift
//  LibraryWidgets
//
//  Created by COBSCCOMP242P-062 on 2026-04-27.
//

import WidgetKit
import SwiftUI

@main
struct LibraryWidgetsBundle: WidgetBundle {
    var body: some Widget {
        LibraryWidgets()
        LibraryWidgetsControl()
        LibraryWidgetsLiveActivity()
    }
}
