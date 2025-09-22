//
//  LibMainView.swift
//  campuspass_ios
//
//  Created by \u8b19 on 11/17/24.
//

import SwiftUI

struct LibMainView: View {
  @ObservedObject var viewModel: AuthViewModel

  var body: some View {
    Group {
      if viewModel.isLoggedIn {
        VStack(spacing: 20) {
          if viewModel.isLoggedIn {
            Text("Your student ID is \(viewModel.ssoStuNo)")
          }
          Button("Log out") {
            viewModel.logout()
          }.buttonStyle(.borderedProminent).tint(.red)
        }
      } else {
        LibSSOLoginView(viewModel: viewModel)
      }
    }
  }
}

#Preview {
  LibMainView(viewModel: AuthViewModel())
}
