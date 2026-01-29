import MapKit
import SwiftUI

struct LocationListView: View {
  let locations: [L2GData]
  let didSelect: (L2GData) -> Void

  var body: some View {
    NavigationStack {
      List(locations, id: \.id) { loc in
        HStack {
          Image(systemName: "building.columns.circle.fill")
            .font(.title)
          VStack(alignment: .leading, spacing: 2) {
            Text(loc.name)
              .font(.title3)
            Text(loc.code)
              .font(.callout)
              .fontWeight(.thin)
          }
        }
        .padding(2)
        .onTapGesture {
          withAnimation(.easeInOut(duration: 0.2)) { didSelect(loc) }
        }
      }
      .navigationTitle("Locations")
    }
  }
}

#Preview {
  @Previewable @State var selected: L2GData? = nil

  return LocationListView(
    locations: Array(letterLocations.values).sorted { $0.name < $1.name },
    didSelect: { loc in
      selected = loc
    }
  )
}
