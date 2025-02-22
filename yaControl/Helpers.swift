//
//  Helpers.swift
//  yaControl
//
//  Created by Sedoykin Alexey on 19/02/2025.
//

import SwiftUI

func numberStringBinding(for intValue: Binding<Int?>) -> Binding<String> {
    Binding(
        get: {
            // Convert Int? to String (use "" if nil)
            intValue.wrappedValue.map(String.init) ?? ""
        },
        set: { newValue in
            // Convert String back to Int?
            intValue.wrappedValue = Int(newValue)
        }
    )
}
