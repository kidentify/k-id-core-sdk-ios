let MAX_DECLARE_ATTEMPTS = 4

private let baseDelayMs = 250
private let maxDelayMs = 2000

private let retryableCodes: Set<KIDErrorCode> = [.unavailable, .rateLimited]

func isRetryableDeclareError(_ error: Error?) -> Bool {
    guard let error = error as? KIDError else { return false }
    return retryableCodes.contains(error.code)
}

func declareRetryDelayMs(_ attempt: Int) -> Int {
    min(baseDelayMs << min(max(attempt - 1, 0), 16), maxDelayMs)
}

func isLiveKey(_ publishableKey: String) -> Bool {
    publishableKey.hasPrefix("kgp_live_")
}
