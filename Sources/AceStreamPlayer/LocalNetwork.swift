import Foundation

enum LocalNetwork {
    /// Best-effort primary IPv4 LAN address (Wi-Fi/Ethernet). AirPlay
    /// receivers fetch the stream URL themselves, so it must be reachable
    /// over the LAN rather than 127.0.0.1.
    static func primaryIPv4Address() -> String? {
        var ifaddrPtr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddrPtr) == 0, let first = ifaddrPtr else { return nil }
        defer { freeifaddrs(ifaddrPtr) }

        var fallback: String?
        for ptr in sequence(first: first, next: { $0.pointee.ifa_next }) {
            let interface = ptr.pointee
            guard interface.ifa_addr.pointee.sa_family == UInt8(AF_INET) else { continue }

            let name = String(cString: interface.ifa_name)
            guard name.hasPrefix("en") else { continue }

            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                        &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST)
            let ip = String(cString: hostname)
            guard ip != "127.0.0.1" else { continue }

            if name == "en0" { return ip }
            if fallback == nil { fallback = ip }
        }
        return fallback
    }
}
