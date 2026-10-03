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

            Group {
                if model.directories.isEmpty {
                    Text("No directories added yet.")
                        .foregroundStyle(.secondary)
                        .font(.callout)
                        .padding(12)
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(sortedDirectories) { directory in
                                DirectoryRowView(directory: directory)
                                Divider()
                            }
                        }
                    }
                }
            }
            // Fixed, not maxHeight, and constant across both branches above: MenuBarExtra's
            // `.window` style doesn't reliably re-measure the popover as this content's
            // height changes while it's open.
            .frame(height: 480)

            Divider()

            Button("Quit Tether") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .padding(12)
        }
        .frame(width: 340)
    }

    private var sortedDirectories: [ManagedDirectory] {
        model.directories.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private var header: some View {
        HStack {
            Text("Tether")
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
