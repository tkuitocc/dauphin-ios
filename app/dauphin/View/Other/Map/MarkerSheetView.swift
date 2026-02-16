import MapKit
import SwiftUI

struct MarkerSheetView: View {
    let location: L2GData

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(location.name).font(.title2).fontWeight(.semibold).frame(
                maxWidth: .infinity, alignment: .leading)
            Text(location.code).font(.title3).fontWeight(.thin)

            LandmarkView(coordinate: location.coordinate)
        }.padding(24)
    }
}

#Preview("MarkerSheetView") {
    MarkerSheetView(
        location: L2GData(
            code: "A", name: "書卷廣場",
            coordinate: CLLocationCoordinate2D(latitude: 25.17553, longitude: 121.45063)))
}
