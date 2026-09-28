import Foundation

/// Spawns and supervises one `claude remote-control` child process for a single directory,
/// parsing its stdout/stderr to derive a `SessionStatus`.
final class RemoteControlProcess {
    typealias StatusHandler = (SessionStatus) -> Void

    // Matches ANSI CSI sequences: ESC '[' followed by parameter bytes (0x30-0x3F), intermediate
    // bytes (0x20-0x2F), and a final byte (0x40-0x7E).
    private static let ansiEscapePattern = try! NSRegularExpression(
        pattern: "\u{1B}\\[[0-?]*[ -/]*[@-~]"
    )
    private static let joinURLPattern = try! NSRegularExpression(
        pattern: "https://claude\\.ai/code\\?environment=[A-Za-z0-9_-]+"
    )
    private static let workspaceNotTrustedMarker = "Workspace not trusted"

    /// Diagnostic output is capped to this many characters to bound memory use.
    private static let maxBufferedCharacters = 20_000

    private let directoryURL: URL
    private let name: String
    private let onStatusChange: StatusHandler

    private let process = Process()
    private let stdoutPipe = Pipe()
    private let stderrPipe = Pipe()
    private let stdinPipe = Pipe()

    private var outputBuffer = ""
    private var didReportReady = false
    private var userRequestedStop = false
    private(set) var isRunning = false

    /// The launched process's id, once `start()` has succeeded.
    var pid: pid_t? {
        isRunning ? process.processIdentifier : nil
    }

    init(directoryURL: URL, name: String, onStatusChange: @escaping StatusHandler) {
        self.directoryURL = directoryURL
        self.name = name
        self.onStatusChange = onStatusChange
    }

    /// Launches `claude remote-control` with `directoryURL` as its working directory.
    func start() {
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["claude", "remote-control", "--name", name, "--no-create-session-in-dir"]
        process.currentDirectoryURL = directoryURL

        process.standardInput = stdinPipe
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        stdoutPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            self?.handleOutput(handle.availableData)
        }
        stderrPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            self?.handleOutput(handle.availableData)
        }

        process.terminationHandler = { [weak self] finishedProcess in
            self?.handleTermination(finishedProcess)
        }

        do {
            try process.run()
            isRunning = true
            // stdin is never written to; closing our end immediately makes it behave like /dev/null.
            stdinPipe.fileHandleForWriting.closeFile()
        } catch {
            let message = "Failed to launch claude: \(error.localizedDescription)"
            DispatchQueue.main.async { [onStatusChange] in
                onStatusChange(.error(message: message))
            }
        }
    }

    /// Sends `SIGTERM` and lets the process exit on its own.
    func stop() {
        guard isRunning else { return }
        userRequestedStop = true
        process.terminate()
    }

    private func handleOutput(_ data: Data) {
        guard !data.isEmpty, let chunk = String(data: data, encoding: .utf8) else { return }
        DispatchQueue.main.async { [weak self] in
            self?.appendAndParse(chunk)
        }
    }

    private func appendAndParse(_ chunk: String) {
        outputBuffer += chunk
        if outputBuffer.count > Self.maxBufferedCharacters {
            outputBuffer = String(outputBuffer.suffix(Self.maxBufferedCharacters))
        }

        guard !didReportReady else { return }

        let stripped = Self.stripANSI(outputBuffer)

        if let joinURL = Self.firstMatch(of: Self.joinURLPattern, in: stripped) {
            didReportReady = true
            onStatusChange(.ready(joinURL: joinURL))
            return
        }

        if stripped.contains(Self.workspaceNotTrustedMarker) {
            onStatusChange(.error(message: Self.workspaceNotTrustedLine(in: stripped)))
        }
    }

    private func handleTermination(_ finishedProcess: Process) {
        isRunning = false
        stdoutPipe.fileHandleForReading.readabilityHandler = nil
        stderrPipe.fileHandleForReading.readabilityHandler = nil

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            if self.userRequestedStop {
                self.onStatusChange(.stopped)
                return
            }

            let stripped = Self.stripANSI(self.outputBuffer)

            if stripped.contains(Self.workspaceNotTrustedMarker) {
                self.onStatusChange(.error(message: Self.workspaceNotTrustedLine(in: stripped)))
            } else if finishedProcess.terminationStatus != 0 {
                let tail = stripped.suffix(500)
                self.onStatusChange(
                    .error(
                        message: "claude remote-control exited unexpectedly "
                            + "(code \(finishedProcess.terminationStatus)): \(tail)"
                    )
                )
            } else {
                self.onStatusChange(.stopped)
            }
        }
    }

    private static func workspaceNotTrustedLine(in strippedText: String) -> String {
        strippedText
            .split(separator: "\n")
            .first(where: { $0.contains(workspaceNotTrustedMarker) })
            .map(String.init)
            ?? "Workspace not trusted."
    }

    private static func stripANSI(_ text: String) -> String {
        let range = NSRange(text.startIndex..., in: text)
        return ansiEscapePattern.stringByReplacingMatches(in: text, range: range, withTemplate: "")
    }

    private static func firstMatch(of regex: NSRegularExpression, in text: String) -> String? {
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, range: range),
            let matchRange = Range(match.range, in: text)
        else {
            return nil
        }
        return String(text[matchRange])
    }
}
