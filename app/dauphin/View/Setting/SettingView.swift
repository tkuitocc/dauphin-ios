//
//  SettingView.swift
//  campuspass_ios
//
//  Created by \u8b19 on 11/14/24.
//

import SwiftUI

enum SettingsSection: String, CaseIterable {
    case account
    case about
    case cache
}

struct SettingView: View {
    @ObservedObject var viewModel: AuthViewModel
    @State private var selectedSection: SettingsSection? = .account
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @AppStorage(
        Constants.userInterfaceStyle
    )
    var userInterfaceStyle = UIUserInterfaceStyle.unspecified
    @AppStorage(
        Constants.showEnglishCourseName,
        store: UserDefaults(suiteName: Constants.appGroupSuiteName)
    )
    private var showEnglishCourseName: Bool?
    @AppStorage(
        Constants.showEnglishTeacherName,
        store: UserDefaults(suiteName: Constants.appGroupSuiteName)
    )
    private var showEnglishTeacherName: Bool?

    var body: some View {
        if horizontalSizeClass == .regular {
            // iPad/Mac layout with sidebar
            NavigationSplitView {
                List(selection: $selectedSection) {
                    Label("Account", systemImage: "person.crop.circle").tag(SettingsSection.account)

                    Label("About Us", systemImage: "figure.wave").tag(SettingsSection.about)

                    Section("Appearance") {
                        Picker(
                            selection: $userInterfaceStyle,
                            content: {
                                Text("System").tag(UIUserInterfaceStyle.unspecified)
                                Text("Light").tag(UIUserInterfaceStyle.light)
                                Text("Dark").tag(UIUserInterfaceStyle.dark)
                            },
                            label: {
                                Label("Color Scheme", systemImage: "sun.horizon.fill")
                            }
                        )
                    }

                    Section("Data Management") {
                        Label("Clear Cache", systemImage: "trash").tag(SettingsSection.cache)
                    }

                    Section("Course") {
                        NavigationLink(
                            destination: ShowEnglishNameView(selection: $showEnglishCourseName)
                        ) {
                            Label("Show English Course Name", systemImage: "character.book.closed")
                        }
                        NavigationLink(
                            destination: ShowEnglishNameView(selection: $showEnglishTeacherName)
                        ) {
                            Label("Show English Teacher Name", systemImage: "person.text.rectangle")
                        }
                    }
                }.navigationTitle("Settings").listStyle(SidebarListStyle())
            } detail: {
                Group {
                    switch selectedSection {
                    case .account: LibMainView(viewModel: viewModel)
                    case .about: AboutUsView()
                    case .cache: ClearCacheView()
                    case .none:
                        VStack(spacing: 20) {
                            Image(systemName: "gear").font(.system(size: 60)).foregroundColor(.gray)
                            Text("Select a setting").font(.title2).foregroundColor(.gray)
                        }.frame(maxWidth: .infinity, maxHeight: .infinity).background(
                            Color(UIColor.systemGroupedBackground))
                    }
                }
            }
        } else {
            // iPhone layout with navigation stack
            NavigationView {
                List {
                    NavigationLink(destination: LibMainView(viewModel: viewModel)) {
                        Label("Account", systemImage: "person.crop.circle")
                    }

                    NavigationLink(destination: AboutUsView()) {
                        Label("About Us", systemImage: "figure.wave")
                    }

                    Section("Appearance") {
                        Picker(
                            selection: $userInterfaceStyle,
                            content: {
                                Text("System").tag(UIUserInterfaceStyle.unspecified)
                                Text("Light").tag(UIUserInterfaceStyle.light)
                                Text("Dark").tag(UIUserInterfaceStyle.dark)
                            },
                            label: {
                                Label("Color Scheme", systemImage: "sun.horizon.fill")
                            }
                        )
                    }

                    Section("Data Management") {
                        NavigationLink(destination: ClearCacheView()) {
                            Label("Clear Cache", systemImage: "trash")
                        }
                    }

                    Section("Course") {
                        NavigationLink(
                            destination: ShowEnglishNameView(selection: $showEnglishCourseName)
                        ) {
                            Label("Show English Course Name", systemImage: "character.book.closed")
                        }
                        NavigationLink(
                            destination: ShowEnglishNameView(selection: $showEnglishTeacherName)
                        ) {
                            Label("Show English Teacher Name", systemImage: "person.text.rectangle")
                        }
                    }
                }.navigationTitle("Settings")
            }
        }
    }
}

#Preview {
    SettingView(viewModel: AuthViewModel())
}
