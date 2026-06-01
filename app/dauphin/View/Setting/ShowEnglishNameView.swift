import SwiftUI
import WidgetKit

struct ShowEnglishNameView: View {
    @Binding var selection: Bool?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Button(
                action: {
                    selection = nil
                    WidgetCenter.shared.reloadAllTimelines()
                    dismiss()
                }
            ) {
                HStack {
                    Text("System")

                    Spacer()

                    if selection == nil {
                        Image(systemName: "checkmark")
                            .foregroundStyle(.tint)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button(
                action: {
                    selection = true
                    WidgetCenter.shared.reloadAllTimelines()
                    dismiss()
                }
            ) {
                HStack {
                    Text("English")

                    Spacer()

                    if selection == true {
                        Image(systemName: "checkmark")
                            .foregroundStyle(.tint)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button(
                action: {
                    selection = false
                    WidgetCenter.shared.reloadAllTimelines()
                    dismiss()
                }
            ) {
                HStack {
                    Text("Mandarin - Traditional Han script")

                    Spacer()

                    if selection == false {
                        Image(systemName: "checkmark")
                            .foregroundStyle(.tint)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    @Previewable @State var selection: Bool?

    ShowEnglishNameView(selection: $selection)
}
