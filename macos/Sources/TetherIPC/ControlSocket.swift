import Darwin
import Foundation

/// POSIX helpers for the Unix domain socket the Tether app listens on and `tetherctl` connects to.
public enum ControlSocket {
    /// `~/Library/Application Support/Tether`, where the app keeps its state.
    public static var supportDirectory: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Tether", isDirectory: true)
    }

    public static var path: String {
        supportDirectory.appendingPathComponent("tether.sock", isDirectory: false).path
    }

    /// Requests larger than this are rejected, bounding memory use.
    private static let maxLineBytes = 64 * 1024

    public struct Failure: Error, CustomStringConvertible {
        public let description: String
    }

    /// Creates a stream socket, optionally bound and listening at `path`, or connected to it.
    public static func makeSocket(path: String, mode: Mode) throws -> Int32 {
        let fd = socket(AF_UNIX, SOCK_STREAM, 0)
        guard fd >= 0 else { throw Failure(description: "socket: \(String(cString: strerror(errno)))") }

        var address = sockaddr_un()
        address.sun_family = sa_family_t(AF_UNIX)
        let capacity = MemoryLayout.size(ofValue: address.sun_path)
        guard path.utf8.count < capacity else {
            close(fd)
            throw Failure(description: "socket path is too long")
        }
        withUnsafeMutablePointer(to: &address.sun_path) {
            $0.withMemoryRebound(to: CChar.self, capacity: capacity) { _ = strlcpy($0, path, capacity) }
        }

        let result: Int32 = withUnsafePointer(to: &address) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                let size = socklen_t(MemoryLayout<sockaddr_un>.size)
                switch mode {
                case .listen:
                    unlink(path)
                    guard bind(fd, $0, size) == 0 else { return -1 }
                    chmod(path, 0o600)
                    return listen(fd, 8)
                case .connect:
                    return connect(fd, $0, size)
                }
            }
        }
        guard result == 0 else {
            let reason = String(cString: strerror(errno))
            close(fd)
            throw Failure(description: reason)
        }
        return fd
    }

    public enum Mode {
        case listen, connect
    }

    /// Reads up to the first newline (exclusive), or EOF.
    public static func readLine(from fd: Int32) -> Data? {
        var data = Data()
        var byte: UInt8 = 0
        while data.count < maxLineBytes {
            let count = read(fd, &byte, 1)
            if count < 0 && errno == EINTR { continue }
            if count <= 0 { break }
            if byte == UInt8(ascii: "\n") { return data }
            data.append(byte)
        }
        return data.isEmpty ? nil : data
    }

    /// Writes `data` followed by a newline.
    public static func writeLine(_ data: Data, to fd: Int32) {
        var bytes = data
        bytes.append(UInt8(ascii: "\n"))
        bytes.withUnsafeBytes { buffer in
            var offset = 0
            while offset < buffer.count {
                let count = write(fd, buffer.baseAddress! + offset, buffer.count - offset)
                if count < 0 && errno == EINTR { continue }
                if count <= 0 { return }
                offset += count
            }
        }
    }
}
