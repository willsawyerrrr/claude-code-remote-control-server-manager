import AppKit
import SwiftUI

/// The popover content shown when the menu bar icon is clicked: the directory list,
/// an add button, and quit.
struct MenuBarContentView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            Divider()

            if model.directories.isEmpty {
                Text("No directories added yet.")
                    .foregroundStyle(.secondary)
                    .font(.callout)
                    .padding(12)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(model.directories) { directory in
                            DirectoryRowView(directory: directory)
                            Divider()
                        }
                    }
                }
                .frame(maxHeight: 480)
            }

            Divider()

            Button("Quit Remote Control Manager") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .padding(12)
        }
        .frame(width: 340)
    }

    private var header: some View {
        HStack {
            Text("Remote Control Manager")
                .font(.headline)

            Spacer()

            Button {
                model.addDirectory()
            } label: {
                Image(systemName: "plus")
            }
            .buttonStyle(.plain)
            .help("Add a directory")
        }
        .padding([.horizontal, .top], 12)
        .padding(.bottom, 8)
    }
}
