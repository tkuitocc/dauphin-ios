//
//  OtherView.swift
//  dauphin
//
//  Created by \u8b19 on 11/25/24.
//

import SwiftUI

struct OtherView: View {
    @ObservedObject var authViewModel: AuthViewModel
    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: EventView()) {
                    Label(
                        title: { Text("Calendar") },
                        icon: { Image(systemName: "calendar")}
                    )
                }

                NavigationLink(destination: LibraryView(authViewModel: authViewModel)) {
                    Label(
                        title: { Text("Library") },
                        icon: { Image(systemName: "books.vertical.fill") }
                    )
                }

//                NavigationLink(destination: WifiView()) {
//                    Label(
//                        title: { Text("無線網路") },
//                        icon: { Image(systemName: "wifi")}
//                    )
//                }

                NavigationLink(destination: WifiView()) {
                    Label(
                        title: { Text("Campus Map") },
                        icon: { Image(systemName: "map.fill")}
                    )
                }
            }
            .navigationTitle("Browse")
            
            EventView()
        }
    }
}

#Preview {
    OtherView(authViewModel: AuthViewModel())
}
