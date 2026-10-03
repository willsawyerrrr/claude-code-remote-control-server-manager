import AppKit
import SwiftUI

/// One directory's row in the menu bar list: name, status, and its controls.
struct DirectoryRowView: View {
    @ObservedObject var directory: ManagedDirectory
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(directory.name)
                        .font(.body)
                        .lineLimit(1)
                    Text(directory.path.path)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Spacer()

                statusIcon

                Button {
                    toggleRunning()
                } label: {
                    Image(systemName: directory.status.isRunning ? "stop.fill" : "play.fill")
                }
                .buttonStyle(.plain)
                .help(directory.status.isRunning ? "Stop" : "Start")

                Button {
                    model.remove(directory)
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.plain)
                .help("Remove")
            }

            if case .ready(let joinURL) = directory.status {
                HStack {
                    Text(joinURL)
                        .font(.caption)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .textSelection(.enabled)

                    Spacer()

                    Button("Copy") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(joinURL, forType: .string)
                    }
                    .controlSize(.small)
                }
            }

            if case .error(let message) = directory.status {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .lineLimit(3)
                    .textSelection(.enabled)
            }
        }
        .padding(12)
    }

    private func toggleRunning() {
        if directory.status.isRunning {
            directory.stop()
        } else {
            directory.start()
        }
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch directory.status {
        case .stopped:
            Image(systemName: "circle")
                .foregroundStyle(.secondary)
                .help("Stopped")
        case .connecting:
            ProgressView()
                .controlSize(.small)
                .help("Connecting")
        case .ready:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .help("Ready")
        case .error:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
                .help("Error")
        case .runningUntracked:
            Image(systemName: "questionmark.circle.fill")
                .foregroundStyle(.orange)
                .help("Running from a previous launch — its join URL isn't available")
        }
    }
}
