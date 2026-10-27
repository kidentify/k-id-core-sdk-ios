import Foundation

#if canImport(DeclaredAgeRange) && canImport(UIKit)
    import DeclaredAgeRange
    import UIKit
#endif

package typealias PlatformAgeSignal = Components.Schemas.PlatformAgeSignal

/// Asks the device's platform for the player's age range, which stands in for the age gate when it is shared.
package protocol PlatformAgeSignalProvider: Sendable {
    /// Returns nil when the platform has no range to give or the person declines to share it.
    @MainActor func signal(ageGates: [Int]) async -> PlatformAgeSignal?
}

/// Apple's Declared Age Range on iOS 26 and later; nil where it is unavailable.
package func defaultPlatformAgeSignalProvider() -> (any PlatformAgeSignalProvider)? {
    #if canImport(DeclaredAgeRange) && canImport(UIKit)
        if #available(iOS 26, *) { return DeclaredAgeRangeProvider() }
    #endif
    return nil
}

/// The jurisdiction's minimum, access and civil ages, as the age gates to ask the platform for.
///
/// Apple rejects a range shorter than two years, so a minimum age too close to its neighbour is dropped (the check
/// still enforces it). Empty when the ages still cannot make valid gates.
func platformAgeGates(_ requirements: Requirements) -> [Int] {
    func gates(_ ages: [Int?]) -> [Int]? {
        let sorted = Array(Set(ages.compactMap { $0 }.filter { $0 > 0 })).sorted()
        return zip([0] + sorted, sorted).allSatisfy { $1 - $0 >= 2 } ? sorted : nil
    }
    return gates([requirements.minimumAge, requirements.accessAge, requirements.civilAge])
        ?? gates([requirements.accessAge, requirements.civilAge]) ?? []
}

#if canImport(DeclaredAgeRange) && canImport(UIKit)
    /// It needs the app's `com.apple.developer.declared-age-range` entitlement; without it the request throws and no
    /// range is shared.
    @available(iOS 26, *)
    struct DeclaredAgeRangeProvider: PlatformAgeSignalProvider {
        func signal(ageGates: [Int]) async -> PlatformAgeSignal? {
            guard let first = ageGates.first, let presenter = topViewController(),
                case .sharing(let range)? = try? await AgeRangeService.shared.requestAgeRange(
                    ageGates: first, ageGates.dropFirst().first, ageGates.dropFirst(2).first, in: presenter)
            else { return nil }
            return PlatformAgeSignal(
                name: .appleIos,
                ageLow: range.lowerBound ?? 0,
                ageHigh: range.upperBound ?? -1,
                // The case names are the server's declaration types; describing them avoids switching over the
                // deprecated ones.
                declarationType: range.ageRangeDeclaration.map { String(describing: $0) }
            )
        }
    }

    @MainActor
    private func topViewController() -> UIViewController? {
        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)
        var top = window?.rootViewController
        while let presented = top?.presentedViewController { top = presented }
        return top
    }
#endif
