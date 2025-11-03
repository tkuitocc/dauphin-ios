import MapKit
import SwiftUI

struct MapView: View {
  @State private var position: MapCameraPosition = .camera(
    .init(centerCoordinate:
        .init(
          latitude: 25.17553,
          longitude: 121.45063),
          distance: 1600,
          heading: 90,
          pitch: 35)
  )
  @State private var lookAroundScene: MKLookAroundScene?
  
  var body: some View {
    VStack(spacing: 8) {
      Map(position: $position) {
        ForEach(Array(letterLocations.values), id: \.name) { item in
          Marker(item.name, coordinate: item.coordinate)
        }
      }
      .mapStyle(.standard)
      .mapControls {
        MapCompass()
        MapUserLocationButton()
        MapPitchToggle()
        MapScaleView()
      }
      .onAppear {
        Task { await loadLookAround() }
      }
    }
  }
  
  // 以 iOS 17 的 MKLookAroundSceneRequest 載入街景
  private func loadLookAround() async {
    let coord = CLLocationCoordinate2D(latitude: 25.033968, longitude: 121.564468)
    let request = MKLookAroundSceneRequest(coordinate: coord)
    self.lookAroundScene = try? await request.scene
  }
}

#Preview{
  MapView()
}
