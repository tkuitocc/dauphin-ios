//
//  SettingView.swift
//  campuspass_ios
//
//  Created by \u8b19 on 11/14/24.
//

import SwiftUI

struct SettingView: View {
    @ObservedObject var viewModel: AuthViewModel

    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: LibMainView(viewModel: viewModel)) {
                    Label(
                        title: { Text("Account") },
                        icon: { Image(systemName: "person.crop.circle")}
                    )
                }

                NavigationLink(destination: AboutUsView()) {
                    Label(
                        title: { Text("About Us") },
                        icon: { Image(systemName: "figure.wave")}
                    )
                }
            }
            .navigationTitle("Setting")
            
            LibMainView(viewModel: viewModel)
        }
    }
}

#Preview {
    SettingView(viewModel: AuthViewModel())
}
