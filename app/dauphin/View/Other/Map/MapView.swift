import MapKit
import SwiftUI

struct MapView: View {
    @State private var position: MapCameraPosition = .camera(
        .init(
            centerCoordinate: .init(latitude: 25.17553, longitude: 121.45063), distance: 1600,
            heading: 90, pitch: 35))
    @State private var lookAroundScene: MKLookAroundScene?
    @State private var selectedLocation: L2GData?
    @State private var isSheetPresented = true  // 無選中時顯示列表用

    var body: some View {
        VStack(spacing: 8) {
            Map(position: $position) {
                ForEach(Array(letterLocations.values), id: \.id) { location in
                    let isSelected = selectedLocation?.id == location.id

                    Annotation(location.name, coordinate: location.coordinate, anchor: .bottom) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedLocation = location
                                isSheetPresented = true
                            }
                        } label: {
                            ZStack {
                                Circle().fill(Color.white).scaleEffect(
                                    isSelected ? 5.0 : 1.0, anchor: .bottom
                                ).animation(.easeInOut(duration: 0.2), value: isSelected)

                                Image(systemName: "mappin.circle.fill").font(.title2)
                                    .foregroundStyle(.red).scaleEffect(
                                        isSelected ? 5.0 : 1.0, anchor: .bottom
                                    ).animation(.easeInOut(duration: 0.2), value: isSelected)
                            }
                        }.buttonStyle(.plain)
                    }
                }
            }.mapStyle(.standard).mapControls {
                MapCompass()
                MapPitchToggle()
                MapScaleView()
            }.sheet(isPresented: $isSheetPresented) {
                Group {
                    if let location = selectedLocation {
                        MarkerSheetView(location: location)
                    } else {
                        LocationListView(
                            locations: Array(letterLocations.values).sorted { $0.name < $1.name },
                            didSelect: { loc in selectedLocation = loc })
                    }
                }.presentationDetents([.fraction(0.5), .medium]).presentationDragIndicator(.visible)
            }.onAppear {
                isSheetPresented = true  // 初次進入就顯示清單
                Task { await loadLookAround() }
            }
        }
    }

    private func loadLookAround() async {
        let coord = CLLocationCoordinate2D(latitude: 25.033968, longitude: 121.564468)
        let request = MKLookAroundSceneRequest(coordinate: coord)
        self.lookAroundScene = try? await request.scene
    }
}

#Preview { MapView() }
