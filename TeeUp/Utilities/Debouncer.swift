import Foundation

/// Debounces rapid calls — only the last call within the interval executes.
actor Debouncer {
    private let duration: Duration
    private var task: Task<Void, Never>?

    init(duration: Duration = .milliseconds(300)) {
        self.duration = duration
    }

    func debounce(action: @Sendable @escaping () async -> Void) {
        task?.cancel()
        task = Task {
            try? await Task.sleep(for: duration)
            guard !Task.isCancelled else { return }
            await action()
        }
    }

    func cancel() {
        task?.cancel()
        task = nil
    }
}

/// Throttles calls — executes at most once per interval.
actor Throttler {
    private let interval: Duration
    private var lastExecution: ContinuousClock.Instant?

    init(interval: Duration = .seconds(1)) {
        self.interval = interval
    }

    func throttle(action: @Sendable @escaping () async -> Void) {
        let now = ContinuousClock.now
        if let last = lastExecution, now - last < interval { return }
        lastExecution = now
        Task { await action() }
    }
}
