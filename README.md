# k-ID Core SDK (iOS)

The k-ID SDK for iOS apps. It adds an age gate with parental consent, adult age verification, and a settings menu
where players manage their permissions, as SwiftUI views, composable pieces, or observable controllers for your own UI.
The web SDK (`@k-id/core-react`) and the Android SDK share its surface, names, and behavior.

## Requirements

iOS 15+. Swift 6 toolchain (Xcode 16+).

## Install

In Xcode, choose **File > Add Package Dependencies...**, enter `https://github.com/kidentify/k-id-core-sdk-ios`, choose
**Up to Next Major Version** from `1.0.0`, and add the `KIDCoreUI` library to your app target. In a `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/kidentify/k-id-core-sdk-ios", from: "1.0.0"),
],
targets: [
    .target(name: "YourApp", dependencies: [.product(name: "KIDCoreUI", package: "k-id-core-sdk-ios")]),
]
```

## Test and live keys

The SDK sends the app's bundle id as `Kid-App-Id`, and k-ID refuses calls from a bundle id not registered in Kai.

- **Test key** (`kgp_test_...`): register the bundle id on the test allowlist. Simulators and CI work.
- **Live key** (`kgp_live_...`): register the bundle id and its Apple Team ID. The SDK verifies the app with App
  Attest, which works only in App Store and TestFlight builds, so use a test key while developing.

## Quick start

```swift
import KIDCoreUI
import SwiftUI

struct Root: View {
    var body: some View {
        KIDCoreProvider(
            publishableKey: "kgp_test_...",
            baseURL: URL(string: "https://kai-api.test.k-id.com/fapi/v1")!,
            declare: KIDDeclare(permissions: [.init(name: .textChatPublic)], supportEmail: "help@example.com")
        ) {
            KIDSessionProvider(jurisdiction: .auto) {
                KIDAgeGate {
                    KIDAgeGatePass { AppView() }
                }
            }
        }
    }
}
```

Later, on your options screen, a standing menu lets the player manage that session's permissions:

```swift
KIDSettingsProvider(sessionId: sessionId) {
    KIDSettings()
}
```

(`KIDSettingsProvider` must sit inside a `KIDCoreProvider`.)

## `KIDCoreProvider` - app-level, wrap once

- `publishableKey` - required. Your k-ID publishable key; safe to ship in the app.
- `baseURL` - required. The k-ID API URL Kai shows for your key: `https://kai-api.k-id.com/fapi/v1` for a live key,
  `https://kai-api.test.k-id.com/fapi/v1` for a test key.
- `appearance` - optional `Appearance`. See [Styling](#styling).
- `localization` - optional `KIDLocalization`: a locale, or partial copy overrides merged over the English
  defaults. See [Localization](#localization).
- `declare` - optional `KIDDeclare`, read once when the provider appears. See [Declare](#declare-test-keys).

Its `KIDCoreContext` is in the environment: `strings` and `jurisdictions`.

## `KIDSessionProvider` - wrap one age gate

- `jurisdiction` - a `JurisdictionCode`: an ISO 3166-1 alpha-2 country or ISO 3166-2 subdivision code (the
  supported ones are static members, such as `.US_CA`; a string literal also works), or `.auto` to resolve it from
  the client IP (falls back to the picker). Omit to show the picker.
- `age` - `AgeSignal` (`.dateOfBirth("YYYY-MM-DD")` or `.age(n)`). Omit to show `KIDCollectAge`.
- `email` - the grownup's email for consent, or the player's own email for adult age verification. Omit to show
  `KIDAskAnAdult` / `KIDVerifyAge`.
- `challengeId` / `sessionId` - resume. The SDK keeps only its device key; it stores no session or challenge ids:
  store the ids from the callbacks below and pass them back.
- `onChallenge` - fires once a challenge's email is sent.
- `onSession` - fires once the session is established.
- `onClaim` - fires once the age check has a result, passed or pending, with a one-time token for your backend.

Age and jurisdiction freeze once the check runs; later changes are ignored with a warning.

## `KIDSettingsProvider` - wrap the settings menu

- `sessionId` - required; the session from the age gate's `onSession`.
- `challengeId` / `onChallenge` - resume an in-flight grownup ask. `onChallenge` fires once the ask's email is sent.

## Integration tiers

Three levels of control, across both surfaces: the age gate (`KIDSessionProvider`) and the settings menu
(`KIDSettingsProvider`). Mix them freely. Every view fills its container's width.

**Tier 1 - drop-in views.** `KIDAgeGate` draws the capture itself while `running`. For the other states it renders the
slot you give it, `KIDAgeGatePending`, `KIDAgeGatePass`, `KIDAgeGateProhibited`, `KIDAgeGateFail` or
`KIDAgeGateError`, and nothing if you leave one out, so provide at least `KIDAgeGatePass`. There is no reset: recover
from `error` by recreating `KIDSessionProvider`, for example by changing its `.id(...)`.

`KIDSettings` is the all-in-one permission menu inside `KIDSettingsProvider`: player-managed permissions get an on/off
control, guardian-managed ones are staged with a tap and asked for together in one request, and prohibited ones are
hidden.

`KIDPermission(.voiceChat) { ... } fallback: { ... }` renders its content when that permission is enabled for the
player, else `fallback` (default: nothing).

**Tier 2 - composable pieces.** Place these inside `KIDSessionProvider`. Each renders only during its own step, and
not at all once you supply the matching provider input. The callbacks only observe; they never take over the flow.

- `KIDSelectJurisdiction(onSelect:)` - the jurisdiction picker. `onSelect` gets the chosen code.
- `KIDCollectAge(methods:onSubmit:)` - `methods` is your preferred order of `.ageSlider` / `.dateOfBirth`, limited to
  what the jurisdiction approves; omit it for age slider, then date of birth. `onSubmit` gets the `AgeSignal`.
- `KIDAskAnAdult(onSent:)` - the grownup's email with a built-in send. `onSent` gets the email once it has gone out.
- `KIDVerifyAge(onSent:)` - for an adults-only product: emails the player a link to verify their age on k-ID.
  `onSent` gets the email once it has gone out.

On an established session, `KIDSessionVerifyAge { KIDSessionVerifyAgePass { ... } }` verifies the player is an adult. See
[Verifying age on a session](#verifying-age-on-a-session).

`KIDPermissionSettings()` is `KIDSettings` without its surrounding card, for your own settings screen.

**Tier 3 - headless.** Hold each value in your own state and pass it as the matching `KIDSessionProvider` input; the
views fill in anything you omit. Read and drive the flow from the controller the provider puts in the environment.
Each web hook is a property:

| Web hook | Swift |
|---|---|
| `useKidAgeGate()` | `@EnvironmentObject var gate: AgeGateController` then `gate.ageGate` |
| `useKidSession()` | `gate.session` |
| `useKidChallenge()` | `gate.challenge` |
| `useKidPermission()` | `gate.permission` |
| `useKidPermissionSettings()` | `@EnvironmentObject var settings: SettingsController` then `settings.permissionSettings` |
| `useKidStrings()` / `useKidJurisdictions()` | `@EnvironmentObject var core: KIDCoreContext` then `core.strings` / `core.jurisdictions` |

- `gate.ageGate` - `status`, `challengeId`, `challengeKind`, `sessionId`, `error`, `requirements` (including the
  jurisdiction's `digitalConsentAge`, `civilAge`, `minimumAge` and `accessAge`), and `submit()`, which
  sends the challenge email once the check has produced a challenge and can be called again to re-send.
  `challengeKind` is `.parentalConsent` when the email goes to a parent and `.ageAssurance` when it goes to the player, or `nil`
  before there is a challenge.
- `gate.session` - `session`, `permissions` (a name to enabled map), `sessionId`, `isLoaded`, `ageVerification`
  (`verifiedAge`, counting birthdays since, and `verifiedAt` once the player has proven an age, else nil),
  `verifyAge`, and `refresh()`, a cheap re-read. The player is a verified adult when
  `ageVerification.verifiedAge >= requirements.civilAge`.
- `gate.session.verifyAge` - the headless form of `KIDSessionVerifyAge`, sharing its flow: `start()` checks the session
  (a no-op until the gate passes; after a fail or error it starts over with a fresh check); `status` is `.pass` once the session's
  `ageVerification.verifiedAge` meets the jurisdiction's civil age, `.fail` when it does not, and `.error` when k-ID
  cannot be reached. While `step` is `.email`, collect the player's email and call `submit(email)`; while `status` is
  `.pending`, call it again to re-send.
- `gate.permission` - `can(.voiceChat)` and `get(.voiceChat)`, the full `Permission` including `managedBy`, so you can
  explain a guardian-managed feature rather than just hide it.
- `gate.challenge` - `challengeId`, `status` and `expiresAt`, for a custom waiting screen. `expiresAt` is only set when
  the challenge has a deadline, like Indonesia's 24-hour consent window. Once it passes, the age gate moves to `fail`;
  recreate the provider to ask again.
- `settings.permissionSettings` - branch each permission on `managedBy`: `.player` -> `change(name, enabled)`, except
  a `.player` permission with a `verifiedAgeThreshold` that is off: ask for it on its own with `upgrade([name])`, which
  turns it on when the player's verified age already covers it and otherwise returns `invalidRequest` because an age
  check is needed; call it again with the player's own email (never the grownup's), `upgrade([name], approverEmail:
  playerEmail)`, and k-ID emails the player a link to verify their age; `.guardian` -> collect a set and `upgrade(names)` (one request,
  emailed to the player's grownup); `.prohibited` -> hide it. One `upgrade` can't mix permissions that have a
  `verifiedAgeThreshold` with ones that don't: k-ID rejects it with `invalidRequest`. When `hasApproverEmail` is false, ask for the grownup's
  email and pass `upgrade(names, approverEmail:)`. `challenge` is the in-flight ask; its `challengeKind` is
  `.parentalConsent` while it waits on the grownup and `.ageAssurance` while it waits on the player's own age check, and
  nil until known. `change` and `upgrade` return a `KIDResult` (see [Errors](#errors)).

Two steps `KIDCollectAge` and `KIDAskAnAdult` handle for you, you drive yourself here:

- Age: `requirements.approvedAgeCollectionMethods` lists the inputs the jurisdiction allows (nil until a jurisdiction is
  set). Collect one and pass it as the `age` input (`date-of-birth` -> `.dateOfBirth`, `age-slider` -> `.age`).
- Consent and adult verification: the `email` input alone does not send. Once a challenge exists, pass `email`, then call `submit()`.

A permission's name is a `PermissionName` value (`.voiceChat`); a session's `Permission` gives it as `permissionName`.
Client-side permissions gate what a player sees. Enforce the real capability server-side.

## Styling

`Appearance(variables:elements:)`. `variables` carries the same tokens as web (`colorPrimary`, `colorOnPrimary`,
`colorText`, `colorTextMuted`, `colorSurface`, `colorSurfaceMuted`, `colorBorder`, `colorDanger`, `fontFamily`,
`radius`); pass only the ones you change. `elements` overrides one element, keyed by `ElementName` (`.card`,
`.title`, `.label`, `.input`, `.button`, `.muted`, `.danger`, `.row`, `.pill` (`.pillAsk` / `.pillAdded`), `.askForm`,
`.controlColumn`, `.verifyAge`, and one per view: `.selectJurisdiction`, `.collectAge`, `.askAnAdult`, `.settings`)
with a `KIDElementStyle`. An override beats every default.

## Localization

The views render in English. Pass a locale to translate them:

```swift
KIDCoreProvider(publishableKey: "kgp_test_...", baseURL: fapiURL, localization: .jaJP) {
    ...
}
```

`getKIDLocalization(Locale.preferredLanguages.first ?? "en")` picks the locale for the player's language, falling
back to English. `KID_LOCALES` lists the supported locales. An Arabic locale lays the views out right to left.

To change individual strings, start from a locale and change the fields you need. Keep any `{token}` placeholders.

```swift
var localization = KIDLocalization.jaJP
localization.age?.submit = "OK"
```

The jurisdiction picker follows the locale; `core.jurisdictions` is the same translated list for a custom picker.
Permission names follow it too: `KIDSettings` shows them, and a custom settings UI reads
`core.strings.permissions[name.rawValue]?.name`.

## Errors

`KIDError` carries `status`, a closed `code` (`KIDErrorCode`: `invalidRequest`, `unauthorized`, `notFound`,
`rateLimited`, `unavailable`), a display-safe `message`, the server `rawCode`, and with `rateLimited`, `retryAfter`:
the whole seconds k-ID asked you to wait, when it said, or, when k-ID rate limited the client token a call needed, the
seconds left before the SDK asks for one again. The SDK never retries a rate-limited call for you. Systemic
failures throw it, and `gate.session.refresh()` throws nothing else apart from cancellation; user-recoverable ones
(`submit`, `change`, `upgrade`) return a `KIDResult` whose `error` is the `KIDError` instead. The `error` of
`gate.ageGate`, `gate.session.verifyAge` and `settings.permissionSettings` is the `KIDError` behind `status == .error`
(or a failed settings load), or nil: a k-ID API error as is, and any other failure, such as a dropped connection, as
`unavailable`. Full detail goes to the console log. `submit()` returns `invalidRequest` when called before a challenge
exists or without an email.

The error slots, `KIDAgeGateError` and `KIDSessionVerifyAgeError`, take no arguments: read the error inside them from
`gate.ageGate.error` or `gate.session.verifyAge.error`. When the settings list fails to load,
`settings.permissionSettings.error` is set; call its `refresh()` to load it again.

## Declared Age Range (iOS 26+)

On iOS 26 and later the age gate first asks for the player's Apple Declared Age Range, with the jurisdiction's
minimum, access and civil ages as the age gates. When the player shares it, the range stands in for the age step and
the player never sees it. It needs the `com.apple.developer.declared-age-range` entitlement: enable the Declared Age
Range capability on your target in Xcode. Without it, or when the player declines, the gate asks for their age as
usual. It is asked only from an app App Attest has verified (a live key in an App Store or TestFlight build), or from
any app on a test key, and never when you pass `age`.

## Declare (test keys)

`declare` on `KIDCoreProvider` is a one-time integration manifest: the capabilities the app uses (which become its
permission set), plus its legal links, icon and support email. What parents read about the app's data is worked out in
Kai, from these capabilities and a few questions Kai asks you there. It applies only while you use a
test key; a live key skips it. The age gate sends no request until it lands; a
transient failure is retried a few times, and if declare still fails the age gate shows `error`.

```swift
KIDDeclare(
    permissions: [.init(name: .textChatPublic), .init(name: .voiceChat)],
    privacyPolicyUrl: "https://example.com/privacy",
    termsOfServiceUrl: "https://example.com/terms",
    iconUrl: .set(Bundle.main.url(forResource: "AppIcon", withExtension: "png")!.absoluteString),
    supportEmail: "help@example.com"
)
```

`permissions` and `supportEmail` are required. Every other field is a `DeclareField`: leave it out to keep what
k-ID already has, pass `nil` (or `.clear`) to clear it, or pass a value to set it.

- `permissions` - required. Each `name` is a `PermissionName`, and `PermissionName.allCases` lists the catalog. An
  unknown name is rejected, and the call fails naming it.
- `privacyPolicyUrl` / `termsOfServiceUrl` - optional http(s) URLs. `nil` resets one to k-ID's default link.
- `iconUrl` - optional app icon, a PNG or JPEG up to 5MB. A public https link is sent for k-ID to fetch; an image in
  the app (a file URL or path, such as a bundle resource) is read by the SDK and sent inline. `nil` removes it.
- `supportEmail` - required email address that k-ID's emails give players and parents to contact for help. A
  missing, empty or invalid address is rejected, and the call fails naming `supportEmail`. Getting a live key also
  needs your own privacy and terms links and an icon.

## Adult age verification (`KIDVerifyAge`)

`KIDVerifyAge` emails the player a link to verify their age on k-ID. The result comes through the SDK's status
check, the same as consent.

## Verifying age on a session

On any product, a player already through the gate can prove they are an adult (the civil age of their jurisdiction)
on their session with age assurance, for example to open an adults-only space. Like `KIDAgeGate`, `KIDSessionVerifyAge`
draws the email form itself and renders whatever you put in the slot matching each outcome, and nothing for a slot
you leave out:

| State | Renders |
|---|---|
| before the gate passes, and while it checks the session | nothing |
| the session is not yet a verified adult | the email form (`onSent` gets the email once the link is sent) |
| link sent, waiting for the player to verify | `KIDSessionVerifyAgePending` |
| the session is a verified adult (straight away when it already was one) | `KIDSessionVerifyAgePass`, and the session carries `ageVerification` |
| the player could not prove they are an adult | `KIDSessionVerifyAgeFail` |
| k-ID could not be reached or rate limited | `KIDSessionVerifyAgeError` |

Showing `KIDSessionVerifyAge` again after a fail or error tries again with a new email.

```swift
KIDSessionVerifyAge {
    KIDSessionVerifyAgePass { AdultsSpace() }
    KIDSessionVerifyAgePending { Text("Check your email to verify your age.") }
    KIDSessionVerifyAgeFail { Text("We could not verify your age.") }
}
```
