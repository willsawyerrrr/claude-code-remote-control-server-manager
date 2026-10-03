import Darwin
import Foundation
import TetherIPC

let usage = """
    Usage: tether [<add|remove|start|stop> [directory]]

    With no arguments, launches the Tether app. Otherwise controls the running app;
    `directory` defaults to the current directory.
    """

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data((message + "\n").utf8))
    exit(1)
}

/// Opens the `Tether.app` this executable lives in (or, outside a bundle, the one registered with
/// Launch Services), then exits.
func launchApp() -> Never {
    let bundle = Bundle.main.executableURL?.resolvingSymlinksInPath()
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
    process.arguments =
        bundle?.pathExtension == "app" ? [bundle!.path] : ["-b", "dev.willsawyerrrr.Tether"]
    do {
        try process.run()
        process.waitUntilExit()
    } catch {
        fail("Can't launch Tether: \(error)")
    }
    exit(process.terminationStatus)
}

let arguments = CommandLine.arguments.dropFirst()

if arguments.isEmpty {
    launchApp()
}

guard let name = arguments.first, let command = ControlCommand(rawValue: name), arguments.count <= 2 else {
    fail(usage)
}

let directory = arguments.dropFirst().first ?? "."
let path = URL(
    fileURLWithPath: (directory as NSString).expandingTildeInPath,
    isDirectory: true
).standardizedFileURL.path

let fd: Int32
do {
    fd = try ControlSocket.makeSocket(path: ControlSocket.path, mode: .connect)
} catch {
    fail("Can't reach Tether (\(error)). Is the app running?")
}
signal(SIGPIPE, SIG_IGN)

let request = try JSONEncoder().encode(ControlRequest(command: command, path: path))
ControlSocket.writeLine(request, to: fd)

guard let line = ControlSocket.readLine(from: fd),
    let response = try? JSONDecoder().decode(ControlResponse.self, from: line)
else {
    fail("Tether sent no valid response.")
}
close(fd)

if response.ok {
    print(response.message)
} else {
    fail(response.message)
}
