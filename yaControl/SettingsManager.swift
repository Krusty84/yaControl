//
//  SettingsManager.swift
//  WavesVista
//
//  Created by Sedoykin Alexey on 11/01/2025.
//

import Foundation

class SettingsManager {
    static let shared = SettingsManager() // Singleton instance
    
    private let defaults = UserDefaults.standard
    
    private init() {} // Private initializer to prevent instantiation
    
    // Properties with default values
    var oAuthKey: String {
        get { defaults.string(forKey: "oAuthKey") ?? "" }
        set { defaults.set(newValue, forKey: "oAuthKey") }
    }
    
}
