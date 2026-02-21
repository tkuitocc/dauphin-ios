import MapKit
import SwiftUI

struct MarkerSheetView: View {
    let location: L2GData
    let didClearSelection: () -> Void
    let didReturnToList: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(location.code).font(.subheadline).foregroundStyle(.secondary)
                    LandmarkView(coordinate: location.coordinate, didReturnToList: didReturnToList)
                }.padding(.horizontal, 24).padding(.top, 12)
            }.navigationTitle(location.name).navigationBarTitleDisplayMode(.inline).toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: didClearSelection) { Image(systemName: "xmark") }
                        .accessibilityLabel(Text("Close")).accessibilityIdentifier(
                            "map.detail.close")
                }
            }
        }.accessibilityIdentifier("map.markerSheet.\(location.code)")
    }
}

#Preview("MarkerSheetView") {
    MarkerSheetView(
        location: L2GData(
            code: "A", name: "書卷廣場",
            coordinate: CLLocationCoordinate2D(latitude: 25.17553, longitude: 121.45063)),
        didClearSelection: {}, didReturnToList: {})
}
