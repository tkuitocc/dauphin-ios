//
//  IntroScreenView.swift
//  dauphin
//
//  Created by \u8b19 on 12/18/24.
//

import SwiftUI

struct IntroScreen: View {
  // Visibility Status
  @AppStorage("isFirstTime") private var isFirstTime: Bool = true
  var body: some View {
    VStack(spacing: 15) {
      Text("Welcome to Dauphin")
        .font(.largeTitle.bold())
        .multilineTextAlignment(.center)
        .padding(.top, 65)
        .padding(.bottom, 35)

      // Points View
      VStack(
        alignment: .leading, spacing: 25,
        content: {
          HStack(spacing: 20) {
            Image(systemName: "laptopcomputer.trianglebadge.exclamationmark")
              .font(.largeTitle)
              .foregroundStyle(Color.blue.gradient)
              .frame(width: 40)
            VStack(
              alignment: .leading, spacing: 6,
              content: {
                Text("Open Source")
                  .font(.title3)
                  .fontWeight(.semibold)

                Text(
                  "We're open-sourcing our code. If you're not satisfied with the current version, feel free to fork it on GitHub."
                )
                .font(.caption)
                .foregroundStyle(.gray)
              })
          }
          HStack(spacing: 20) {
            Image(systemName: "list.bullet.rectangle")
              .font(.largeTitle)
              .foregroundStyle(Color.blue.gradient)
              .frame(width: 40)
            VStack(
              alignment: .leading, spacing: 6,
              content: {
                Text("Local First")
                  .font(.title3)
                  .fontWeight(.semibold)

                Text(
                  "We securely cache some redundant data locally, so you can still access your schedule without connecting to the school's server."
                )
                .font(.caption)
                .foregroundStyle(.gray)
              })
          }
          HStack(spacing: 20) {
            Image(systemName: "widget.large.badge.plus")
              .font(.largeTitle)
              .foregroundStyle(Color.blue.gradient)
              .frame(width: 40)
            VStack(
              alignment: .leading, spacing: 6,
              content: {
                Text("iOS Feature Support")
                  .font(.title3)
                  .fontWeight(.semibold)

                Text(
                  "We support many iOS features like Widgets, and we'll update further as inspiration strikes."
                )
                .font(.caption)
                .foregroundStyle(.gray)
              })
          }
        }
      )
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, 15)

      Spacer(minLength: 10)
      Text("⚠️This app isn’t developed by Tamkang University Office of Information Services. Use at your own risk.")
        .font(.system(size: 8))

      Button(
        action: {
          isFirstTime = false
        },
        label: {
          Text("Continue")
            .fontWeight(.bold)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.blue.gradient, in: .rect(cornerRadius: 12))
            .contentShape(.rect)
        })
    }
    .padding(15)
  }
}

#Preview {
  IntroScreen()
}
