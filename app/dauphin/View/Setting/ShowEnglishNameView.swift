import SwiftUI

struct ShowEnglishNameView: View {
    @Binding var selection: Bool?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Button(
                action: {
                    selection = nil
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
            }
            .buttonStyle(.plain)

            Button(
                action: {
                    selection = true
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
            }
            .buttonStyle(.plain)

            Button(
                action: {
                    selection = false
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
            }
            .buttonStyle(.plain)


        }
    }
}

#Preview {
    @Previewable @State var selection: Bool?

    ShowEnglishNameView(selection: $selection)
}
