//
//  LocalizationAttribute.swift
//  iTorrent
//
//  Created by Daniil Vinogradov on 02/04/2024.
//

import Foundation

prefix operator %

prefix func %(expression: String.LocalizationValue) -> String {
    String(localized: expression)
}
