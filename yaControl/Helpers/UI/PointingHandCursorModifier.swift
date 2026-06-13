//
//  PointingHandCursorModifier.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 13/06/2026.
//

import SwiftUI
import AppKit

struct PointingHandCursorModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.onHover { hovering in
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

extension View {
    func pointingHandCursor() -> some View {
        modifier(PointingHandCursorModifier())
    }
}
