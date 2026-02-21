import SwiftUI

struct LocationListView: View {
    let locations: [L2GData]
    let didClose: () -> Void
    let didSelect: (L2GData) -> Void
    @State private var searchText = ""

    private var filteredLocations: [L2GData] {
        guard !searchText.isEmpty else { return locations }
        return locations.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
                || $0.code.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            List(filteredLocations, id: \.id) { loc in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { didSelect(loc) }
                } label: {
                    HStack {
                        Image(systemName: "building.columns.circle.fill").font(.title3)
                            .foregroundStyle(.tint)
                        Text("\(loc.name) \(loc.code)").font(.headline)
                        Spacer()
                        Image(systemName: "chevron.right").font(.footnote).foregroundStyle(
                            .tertiary)
                    }.padding(2)
                }.accessibilityLabel(Text("\(loc.name) \(loc.code)")).accessibilityHint(
                    Text("Open in Maps")
                ).accessibilityIdentifier("map.location.\(loc.code)")
            }.navigationTitle("Locations").navigationBarTitleDisplayMode(.inline).listStyle(.plain)
                .searchable(text: $searchText).toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: didClose) { Image(systemName: "xmark") }.accessibilityLabel(
                            Text("Close")
                        ).accessibilityIdentifier("map.list.close")
                    }
                }
        }
    }
}

#Preview {
    @Previewable @State var selected: L2GData? = nil

    LocationListView(locations: campusLocations, didClose: {}, didSelect: { loc in selected = loc })
}
