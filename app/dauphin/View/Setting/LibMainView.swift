//
//  LibMainView.swift
//  campuspass_ios
//
//  Created by \u8b19 on 11/17/24.
//

import SwiftUI

struct LibMainView: View {
    @ObservedObject var viewModel: AuthViewModel

    private var studentIDText: String {
        String.localizedStringWithFormat(
            NSLocalizedString("Your student ID is %@", comment: ""), viewModel.ssoStuNo)
    }

    var body: some View {
        Group {
            if viewModel.isLoggedIn {
                VStack(spacing: 20) {
                    if viewModel.isLoggedIn { Text(studentIDText) }
                    Button(action: { viewModel.logout() }) {
                        Label("Logout", systemImage: "person.crop.circle")
                    }.buttonStyle(.borderedProminent).tint(.red)
                }
            } else {
                LibSSOLoginView(viewModel: viewModel)
            }
        }
    }
}

#Preview { LibMainView(viewModel: AuthViewModel()) }
