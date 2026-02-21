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

    private var studentIDText: String {
        String.localizedStringWithFormat(
            NSLocalizedString("Student ID: %@", comment: ""), authViewModel.ssoStuNo)
    }

    var body: some View {
        if authViewModel.isLoggedIn {
            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    VStack {
                        Code39View("\(authViewModel.ssoStuNo)").cornerRadius(0).frame(
                            width: 296, height: 96)
                    }.padding(20).background(Color.white)
                    Text(studentIDText).padding([.vertical], 8).foregroundColor(.white)
                }.background(Color.accentColor).cornerRadius(16).background(
                    RoundedRectangle(cornerRadius: 16).shadow(
                        color: Color.black.opacity(0.2), radius: 8, x: 0, y: 0))

                Spacer()
            }

        } else {
            LibSSOLoginView(viewModel: authViewModel)
        }
    }
}

#Preview {
    LibraryView(authViewModel: AuthViewModel())
    LibraryView(authViewModel: AuthViewModel())
}
