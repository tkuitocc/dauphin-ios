// AboutUsView.swift
import SwiftUI

struct AboutUsView: View {
  var appVersion: String {
    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
    return "\(version) (\(build))"
  }

  let packages = [
    ("KeychainSwift", "https://github.com/evgenyneu/keychain-swift"),
    ("Lottie", "https://github.com/airbnb/lottie-ios"),
    ("swiftui-code39", "https://github.com/jiahan-wu/swiftui-code39"),
    ("Reachability", "https://github.com/ashleymills/Reachability.swift"),
  ]

  let usefulLinks = [
    ("淡江i生活", "https://app.tku.edu.tw/"),
    ("淡江大學教務處", "https://acad.tku.edu.tw/"),
    ("淡江大學覺生紀念圖書館", "https://www.lib.tku.edu.tw/"),
    ("Source Code", "https://github.com/tkuitocc/dauphin"),
    ("Discord", "https://discord.gg/ruDpjr3ZHk"),
  ]

  var body: some View {
    Form {
      Section(header: Text("App Information")) {
        HStack {
          Text("Version")
          Spacer()
          Text(appVersion)
            .foregroundColor(.secondary)
            .accessibilityIdentifier("about_version_value")
        }
      }
      Section(header: Text("Third-Party Packages")) {
        ForEach(packages, id: \.0) { package in
          Link(destination: URL(string: package.1)!) {
            Label(package.0, systemImage: "shippingbox.fill")
          }
          .accessibilityIdentifier("pkg_\(package.0)")
        }
      }
      Section(header: Text("Data Sources and Resources")) {
        ForEach(usefulLinks, id: \.0) { link in
          Link(destination: URL(string: link.1)!) {
            Label(link.0, systemImage: "globe")
          }
          .accessibilityIdentifier("link_\(link.0)")
        }
      }
    }
  }
}

#Preview {
  AboutUsView()
}
