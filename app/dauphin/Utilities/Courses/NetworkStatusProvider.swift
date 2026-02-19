import Foundation
import Network

protocol NetworkStatusProviding: AnyObject, Sendable {
    var isNetworkAvailable: Bool { get }
    func startMonitoring(_ onUpdate: @escaping @Sendable (Bool) -> Void)
    func stopMonitoring()
}

final class DefaultNetworkStatusProvider: NetworkStatusProviding, @unchecked Sendable {
    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "CourseViewModel.Network")
    private(set) var isNetworkAvailable: Bool = true

    init(monitor: NWPathMonitor = NWPathMonitor()) { self.monitor = monitor }

    func startMonitoring(_ onUpdate: @escaping @Sendable (Bool) -> Void) {
        monitor.pathUpdateHandler = { [weak self] path in
            let available = path.status == .satisfied
            self?.isNetworkAvailable = available
            onUpdate(available)
        }
        monitor.start(queue: queue)
    }

    func stopMonitoring() { monitor.cancel() }
}
