//
//  PROVAOBDServiceApp.swift
//  PROVAOBDService
//
//  Created by Daniele Fontana on 13/05/25.
//

import SwiftUI

@main
struct OBuddyApp: App {
  @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false

  var body: some Scene {
      WindowGroup {
          if hasCompletedOnboarding {
              MainView()
          } else {
              OnboardingView()
          }
      }
  }
}
