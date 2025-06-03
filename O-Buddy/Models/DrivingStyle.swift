//
//  DrivingStyle.swift
//  O-Buddy
//
//  Created by Daniele Fontana on 03/06/25.
//

import Foundation
import  SwiftUI

enum DrivingStyle: String {
  case smooth = "Smooth"
  case normal = "Normal"
  case nervous = "Nervous"
  case aggressive = "Aggressive"

  var color: Color {
      switch self {
      case .smooth: return .black
      case .normal: return .green
      case .nervous: return .orange
      case .aggressive: return .red
      }
  }
}
