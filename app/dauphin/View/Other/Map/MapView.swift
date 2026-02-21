@preconcurrency import MapKit
import SwiftUI

struct MapView: View {
    @State private var position: MapCameraPosition = .camera(
        .init(
            centerCoordinate: .init(latitude: 25.17553, longitude: 121.45063), distance: 1600,
            heading: 90, pitch: 35))
    @State private var selectedLocation: L2GData?
    @State private var overviewPosition: MapCameraPosition?
    @State private var isLocationListPresented = false
    @State private var detailSheetDetent: PresentationDetent = .fraction(0.39)
    @State private var shouldRestoreOverviewOnDetailDismiss = true

    var body: some View {
        Map(position: $position) {
            ForEach(campusLocations) { location in
                let isSelected = selectedLocation?.id == location.id

                Annotation(location.name, coordinate: location.coordinate, anchor: .bottom) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if selectedLocation == nil { overviewPosition = position }
                            shouldRestoreOverviewOnDetailDismiss = true
                            selectedLocation = location
                            position = focusedPosition(for: location)
                        }
                    } label: {
                        Image(systemName: "mappin.circle.fill").font(isSelected ? .title : .title2)
                            .foregroundStyle(isSelected ? .red : .secondary).shadow(
                                radius: isSelected ? 3 : 1)
                    }.accessibilityLabel(Text("\(location.name) \(location.code)"))
                        .accessibilityHint(Text("Open in Maps")).accessibilityIdentifier(
                            "map.annotation.\(location.code)"
                        ).buttonStyle(.plain)
                }
            }
        }.mapStyle(.standard).mapControls {
            MapCompass()
            MapPitchToggle()
            MapScaleView()
        }.safeAreaInset(edge: .bottom) {
            HStack {
                Spacer()
                Button {
                    isLocationListPresented = true
                } label: {
                    Label("Locations", systemImage: "list.bullet")
                }.buttonStyle(.borderedProminent).padding(.horizontal, 16).padding(.bottom, 12)
            }
        }.sheet(item: $selectedLocation, onDismiss: restoreOverviewCamera) { location in
            MarkerSheetView(
                location: location, didClearSelection: { selectedLocation = nil },
                didReturnToList: returnToLocationList
            ).presentationDetents([.fraction(0.39), .medium], selection: $detailSheetDetent)
                .presentationDragIndicator(.hidden)
        }.sheet(isPresented: $isLocationListPresented) {
            LocationListView(
                locations: campusLocations, didClose: { isLocationListPresented = false },
                didSelect: { location in
                    isLocationListPresented = false
                    selectLocation(location)
                }
            ).presentationDragIndicator(.hidden)
        }
    }

    private func selectLocation(_ location: L2GData) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if selectedLocation == nil { overviewPosition = position }
            detailSheetDetent = .fraction(0.39)
            selectedLocation = location
            position = focusedPosition(for: location)
        }
    }

    private func focusedPosition(for location: L2GData) -> MapCameraPosition {
        .camera(.init(centerCoordinate: location.coordinate, distance: 500, heading: 0, pitch: 35))
    }

    private func restoreOverviewCamera() {
        if shouldRestoreOverviewOnDetailDismiss, let overviewPosition {
            withAnimation(.easeInOut(duration: 0.2)) { position = overviewPosition }
        }
        shouldRestoreOverviewOnDetailDismiss = true
        self.overviewPosition = nil
    }

    private func returnToLocationList() {
        shouldRestoreOverviewOnDetailDismiss = false
        selectedLocation = nil
        isLocationListPresented = true
    }
}

#Preview { MapView() }
