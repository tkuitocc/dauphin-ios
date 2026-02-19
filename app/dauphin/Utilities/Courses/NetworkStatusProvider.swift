import Foundation
import Network

protocol NetworkStatusProvider: AnyObject, Sendable {
    var isNetworkAvailable: Bool { get }
    func startMonitoring(_ onUpdate: @escaping @Sendable (Bool) -> Void)
    func stopMonitoring()
}

final class DefaultNetworkStatusProvider: NetworkStatusProvider, @unchecked Sendable {
    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "CourseViewModel.Network")
    private let lock = NSLock()
    private var _isNetworkAvailable: Bool = true

    var isNetworkAvailable: Bool {
        lock.lock()
        defer { lock.unlock() }
        return _isNetworkAvailable
    }

    init(monitor: NWPathMonitor = NWPathMonitor()) { self.monitor = monitor }

    func startMonitoring(_ onUpdate: @escaping @Sendable (Bool) -> Void) {
        monitor.pathUpdateHandler = { [weak self] path in
            let available = path.status == .satisfied
            self?.setNetworkAvailable(available)
            onUpdate(available)
        }
        monitor.start(queue: queue)
    }

    func stopMonitoring() { monitor.cancel() }

    private func setNetworkAvailable(_ available: Bool) {
        lock.lock()
        _isNetworkAvailable = available
        lock.unlock()
    }
}
