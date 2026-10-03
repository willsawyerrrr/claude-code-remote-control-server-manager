import Darwin
import Foundation
import TetherIPC

/// Listens on a Unix domain socket for `tetherctl` requests and answers each with the result of
/// `handler`.
final class ControlServer {
    private let handler: @Sendable (ControlRequest) async -> ControlResponse
    private var source: DispatchSourceRead?

    init(handler: @escaping @Sendable (ControlRequest) async -> ControlResponse) {
        self.handler = handler
    }

    /// Starts accepting connections. Failure is logged and leaves the app running without a CLI.
    func start() {
        do {
            try FileManager.default.createDirectory(
                at: ControlSocket.supportDirectory, withIntermediateDirectories: true)
            let listener = try ControlSocket.makeSocket(path: ControlSocket.path, mode: .listen)
            let source = DispatchSource.makeReadSource(fileDescriptor: listener, queue: .global())
            source.setEventHandler { [weak self] in self?.accept(on: listener) }
            source.setCancelHandler { close(listener) }
            source.resume()
            self.source = source
        } catch {
            NSLog("Tether: failed to start control socket: \(error)")
        }
    }

    private func accept(on listener: Int32) {
        let client = Darwin.accept(listener, nil, nil)
        guard client >= 0 else { return }
        var enabled: Int32 = 1
        setsockopt(client, SOL_SOCKET, SO_NOSIGPIPE, &enabled, socklen_t(MemoryLayout<Int32>.size))

        let handler = self.handler
        DispatchQueue.global().async {
            guard let line = ControlSocket.readLine(from: client) else {
                close(client)
                return
            }
            Task {
                let response =
                    if let request = try? JSONDecoder().decode(ControlRequest.self, from: line) {
                        await handler(request)
                    } else {
                        ControlResponse(ok: false, message: "Malformed request.")
                    }
                if let data = try? JSONEncoder().encode(response) {
                    ControlSocket.writeLine(data, to: client)
                }
                close(client)
            }
        }
    }
}
