//
//  Colors.swift
//  Semantic color tokens for Deej.
//
//  Two-tier palette: orange = data, cream = identity. See PLAN.md §5 for the
//  full design-system mapping. Phase 8 will move these into an Asset Catalog
//  with dark/light variants; for v1 we live in dark mode only.
//

import SwiftUI

extension Color {
    // MARK: Backgrounds
    static let deejBgCanvas      = Color(red: 0.055, green: 0.055, blue: 0.063) // #0E0E10
    static let deejBgPanel       = Color(red: 0.102, green: 0.102, blue: 0.110) // #1A1A1C
    static let deejBgPanelEdge   = Color(red: 0.165, green: 0.165, blue: 0.176) // #2A2A2D
    static let deejBgScreen      = Color(red: 0.039, green: 0.024, blue: 0.016) // #0A0604
    static let deejBgScreenEdge  = Color(red: 0.102, green: 0.059, blue: 0.031) // #1A0F08

    // MARK: Orange (data) — bright → deep
    static let deejOrangeHigh    = Color(red: 1.000, green: 0.690, blue: 0.439) // #FFB070
    static let deejOrangeBright  = Color(red: 1.000, green: 0.541, blue: 0.239) // #FF8A3D
    static let deejOrangePrimary = Color(red: 1.000, green: 0.416, blue: 0.122) // #FF6A1F
    static let deejOrangeMid     = Color(red: 0.773, green: 0.376, blue: 0.125) // #C56020
    static let deejOrangeLow     = Color(red: 0.541, green: 0.251, blue: 0.082) // #8A4015
    static let deejOrangeDeep    = Color(red: 0.478, green: 0.208, blue: 0.063) // #7A3510
    static let deejOrangeTrack   = Color(red: 0.239, green: 0.122, blue: 0.063) // #3D1F10

    // MARK: Cream (identity / system labels)
    static let deejCream         = Color(red: 0.925, green: 0.898, blue: 0.816) // #ECE5D0
    static let deejCreamDim      = Color(red: 0.639, green: 0.608, blue: 0.522) // #A39B85

    // MARK: Engraving / chrome
    static let deejEngraving     = Color(red: 0.290, green: 0.290, blue: 0.298) // #4A4A4C
    static let deejTextFaint     = Color(red: 0.420, green: 0.420, blue: 0.431) // #6B6B6E

    // MARK: Status / LEDs
    static let deejStatusGreen   = Color(red: 0.337, green: 0.839, blue: 0.486) // #56D67C
    static let deejStatusRed     = Color(red: 0.878, green: 0.271, blue: 0.271) // #E04545
    static let deejLEDAmber      = Color(red: 1.000, green: 0.722, blue: 0.361) // #FFB85C

    // MARK: Buttons
    static let deejButtonDark    = Color(red: 0.122, green: 0.122, blue: 0.133) // #1F1F22
    static let deejButtonActive  = Color(red: 0.059, green: 0.035, blue: 0.027) // #0F0907
}

// MARK: ShapeStyle shorthand
// Lets call sites write `.foregroundStyle(.deejCream)` instead of `.foregroundStyle(Color.deejCream)`.
extension ShapeStyle where Self == Color {
    static var deejBgCanvas:      Color { .deejBgCanvas }
    static var deejBgPanel:       Color { .deejBgPanel }
    static var deejBgPanelEdge:   Color { .deejBgPanelEdge }
    static var deejBgScreen:      Color { .deejBgScreen }
    static var deejBgScreenEdge:  Color { .deejBgScreenEdge }
    static var deejOrangeHigh:    Color { .deejOrangeHigh }
    static var deejOrangeBright:  Color { .deejOrangeBright }
    static var deejOrangePrimary: Color { .deejOrangePrimary }
    static var deejOrangeMid:     Color { .deejOrangeMid }
    static var deejOrangeLow:     Color { .deejOrangeLow }
    static var deejOrangeDeep:    Color { .deejOrangeDeep }
    static var deejOrangeTrack:   Color { .deejOrangeTrack }
    static var deejCream:         Color { .deejCream }
    static var deejCreamDim:      Color { .deejCreamDim }
    static var deejEngraving:     Color { .deejEngraving }
    static var deejTextFaint:     Color { .deejTextFaint }
    static var deejStatusGreen:   Color { .deejStatusGreen }
    static var deejStatusRed:     Color { .deejStatusRed }
    static var deejLEDAmber:      Color { .deejLEDAmber }
    static var deejButtonDark:    Color { .deejButtonDark }
    static var deejButtonActive:  Color { .deejButtonActive }
}
