import MapKit
import SwiftUI

struct LandmarkView: View {
  let coordinate: CLLocationCoordinate2D

  @State private var lookAroundScene: MKLookAroundScene?

  var body: some View {
    VStack(spacing: 20) {
      HStack {
        Menu {
          appleMapsLink
          googleMapsLink
        } label: {
          Map(
            initialPosition: .region(
              MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.001, longitudeDelta: 0.001)
              )
            )
          ) {
            Annotation("", coordinate: coordinate) {
              Image(systemName: "mappin")
                .foregroundStyle(.red)
            }
          }
          .aspectRatio(1, contentMode: .fit)
          .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        // 明明有圖資為什麼不給我用？
        LookAroundPreview(
          scene: $lookAroundScene,
          allowsNavigation: true,
          showsRoadLabels: true
        )
        .aspectRatio(1, contentMode: .fit)
        .clipShape(.rect(cornerRadius: 8))
        .task {
          let request = MKLookAroundSceneRequest(coordinate: coordinate)
          lookAroundScene = try? await request.scene
        }
      }

      Button {
        let googleURLString =
          "comgooglemaps://?daddr=\(coordinate.latitude),\(coordinate.longitude)&directionsmode=driving"
        if let googleURL = URL(string: googleURLString),
          UIApplication.shared.canOpenURL(googleURL)
        {
          // 開啟 Google Maps 導航
          UIApplication.shared.open(googleURL)
        } else {
          // fallback: 使用 Apple Maps 導航
          let placemark = MKPlacemark(coordinate: coordinate)
          let mapItem = MKMapItem(placemark: placemark)
          //mapItem.name = name
          mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
          ])
        }
      } label: {
        VStack(alignment: .leading) {
          Label {
            VStack(alignment: .leading) {
              Text("Open in Maps")
            }
          } icon: {
            Image(
              systemName:
                "point.topright.arrow.triangle.backward.to.point.bottomleft.scurvepath.fill")
          }
        }
      }
    }
  }

  private var appleMapsLink: some View {
    Button {
      let placemark = MKPlacemark(coordinate: coordinate)
      let mapItem = MKMapItem(placemark: placemark)
      //mapItem.name = name
      mapItem.openInMaps()
    } label: {
      Label("Open in Apple Maps", systemImage: "map")
    }
  }

  private var googleMapsLink: some View {
    let urlString = "comgooglemaps://?q=\(coordinate.latitude),\(coordinate.longitude)"
    if let url = URL(string: urlString) {
      return AnyView(
        Link(destination: url) {
          Label("Open in Google Maps", systemImage: "globe")
        })
    } else {
      return AnyView(EmptyView())
    }
  }
}

#Preview("LandmarkView") {
  List {
    LandmarkView(
      coordinate: CLLocationCoordinate2D(latitude: 25.17512531057652, longitude: 121.45075846007681)
    )
  }
}
