import Foundation
import Network
import Observation

@Observable
final class NetworkMonitor {
    static let shared = NetworkMonitor()

    private(set) var isConnected = true
    private(set) var connectionType: ConnectionType = .unknown

    enum ConnectionType {
        case wifi, cellular, wiredEthernet, unknown
    }

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor", qos: .utility)

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.connectionType = self?.type(from: path) ?? .unknown
            }
        }
        monitor.start(queue: queue)
    }

    private func type(from path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) { return .wifi }
        if path.usesInterfaceType(.cellular) { return .cellular }
        if path.usesInterfaceType(.wiredEthernet) { return .wiredEthernet }
        return .unknown
    }

    deinit { monitor.cancel() }
}
