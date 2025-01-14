//
//  Colors.swift
//  RoundTimer Watch App
//
//  Created by Javier Calartrava on 9/2/24.
//

import SwiftUI
struct AppUIConstants {
    static let opacityWhenLuminanceReduced = 0.33
}

extension Color {
    static let buttonTextColor = Color("White_ET")
    
    static let splashText = Color("ElectricRed")
    static let roundColor = Color("ElectricBlue")
    static let roundColorLuminanceReduced = Color("Gray_ET")
    static let timerStartedColor =  Color("ElectricRed")
    static let timerNotStartedColor = Color("Gray_ET")
    static let timerRestStartedColor = Color("ElectricYellow")
    static let timerFinishedBackgroundColor = Color("ElectricRedBack")
    
    static let paragrahColor = Color("White_ET")
    static let defaultBackgroundColor = Color("Black_ET")
    static let countdownColor = Color("ElectricBlue")
    static let countdownInminentColor =  Color("ElectricRed")
    static let heartRateZone1 = Color("Zone1")
    static let heartRateZone2 = Color("Zone2")
    static let heartRateZone3 = Color("Zone3")
    static let heartRateZone4 = Color("Zone4")
    static let heartRateZone5 = Color("Zone5")
    static let heartRateZoneText = Color("Black_ET")
    static let heartRateText = Color("White_ET")
}

extension Font {
    
    static let alertMessageFont =  Font.system(size: 20, weight: .black)
    static let alertMessageButtonFont =  Font.system(size: 20, weight: .black)
    
    static let splashAppFont =  Font.system(size: 75, weight: .black)
    
    static let timerAndRoundLargeFont =  Font.system(size: 50, weight: .black)
    static let timerAndRoundMediumFont =  Font.system(size: 45, weight: .black)
    static let timerAndRoundSmallFont =  Font.system(size: 40, weight: .black)
    static let timerAndRoundLRLargeFont =  Font.system(size: 30, weight: .black)
    static let timerAndRoundLRMediumFont =  Font.system(size: 20, weight: .black)
    static let timerAndRoundLRSmallFont =  Font.system(size: 15, weight: .black)
    static let messageFont =  Font.system(size: 20, weight: .black)
    static let buttonTitleFont =  Font.system(size: 20, weight: .black)
    static let buttonSubtitleFont =  Font.system(size: 15, weight: .black)
    static let roundInputFont =  Font.system(size: 70, weight: .black)
    static let pickerSelectionFont = Font.system(size: 40, weight: .black)
    static let countDownFont = Font.system(size: 120, weight: .black)
    static let emomRounds = Font.system(size: 25, weight: .black)
    static let paragraph = Font.system(size: 25, weight: .black)
    
    static let timerAndRoundiOSAppFont =  Font.system(size: 175, weight: .black)
    static let emomRoundsiOSAppFont = Font.system(size: 80, weight: .black)
    static let messageiOSAppFont =  Font.system(size: 40, weight: .black)
    static let buttoniOSAppFont =  Font.system(size: 40, weight: .black)

    static let heartRateZone =  Font.system(size: 15 + 5, weight: .black)
    static let heartRate =  Font.system(size: 20, weight: .black)
}


struct CornerRadius {
    static let regular: CGFloat = 15
}
