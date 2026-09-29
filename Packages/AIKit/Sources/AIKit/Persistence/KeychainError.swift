import Foundation
import Security

struct KeychainError: LocalizedError {
    let status: OSStatus

    var errorDescription: String? {
        let message = SecCopyErrorMessageString(status, nil) as String? ?? "status \(status)"
        return String(localized: .keychainError(message))
    }
}
