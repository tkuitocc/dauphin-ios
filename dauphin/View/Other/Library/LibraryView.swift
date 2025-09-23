//
//  LibraryView.swift
//  dauphin
//
//  Created by \u8b19 on 11/25/24.
//

import Code39
import SwiftUI

struct LibraryView: View {
  @ObservedObject var authViewModel: AuthViewModel
  var body: some View {
    if authViewModel.isLoggedIn {
      ScrollView {
        VStack {
          VStack {
            Code39View("\(authViewModel.ssoStuNo)")
              .frame(width: 296, height: 96)
          }
          .padding(20)
          .background(Color.white)
          Text("stdID:\(authViewModel.ssoStuNo)")
            .padding(5)
        }
        .background(Color.accentColor)
        .cornerRadius(10)
      }
    } else {
      LibSSOLoginView(viewModel: authViewModel)
    }
  }
}

#Preview {
  LibraryView(authViewModel: AuthViewModel())
}
