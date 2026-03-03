# RepoLite

A production-quality iOS app built as a technical assessment. It authenticates with GitHub via OAuth 2.0 and lets you browse your repositories and their branches.

---

## Requirements

- Xcode 15+
- iOS 16+ simulator or physical device
- A GitHub account

---

## Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/Nada8709/RepoLite.git
cd RepoLite
```

### 2. Create a GitHub OAuth App

1. Go to [github.com/settings/developers](https://github.com/settings/developers)
2. Click **New OAuth App**
3. Fill in the form:

| Field | Value |
|---|---|
| Application name | `RepoLite` |
| Homepage URL | `https://github.com` |
| Authorization callback URL | `repolite://oauth/callback` |

4. Click **Register application**
5. Copy your **Client ID**
6. Click **Generate a new client secret** → copy it immediately (shown only once)

### 3. Add your credentials

Create a file called `Secrets.xcconfig` in the project root (next to `RepoLite.xcodeproj`):

```
GITHUB_CLIENT_ID = your_client_id_here
GITHUB_CLIENT_SECRET = your_client_secret_here
```

> ⚠️ No quotes around the values. This file is gitignored and never committed.

### 4. Link Secrets.xcconfig in Xcode

1. Open `RepoLite.xcodeproj`
2. Click the **RepoLite project** (blue icon) in the navigator
3. Select the project under **PROJECT** → **Info** tab
4. Under **Configurations**, assign `Secrets` to both **Debug** and **Release** for the RepoLite target

### 5. Run

Select any iOS 16+ simulator and press **⌘R**.

Tap **Sign in with GitHub**, authorize the app, and your repositories will load.

---

## Running Tests

### Unit Tests

Press **⌘U** or go to **Product → Test**.

To run a specific test file, open it and click the ◆ diamond next to the class name.

### Test Navigator

Open with **⌘6** to see all tests and their pass/fail status.

### Code Coverage

1. **Product → Scheme → Edit Scheme → Test → Options**
2. Enable **Code Coverage** for the RepoLite target
3. Run **⌘U**
4. View results in **Report Navigator** (**⌘9**) → latest run → **Coverage** tab

### Test Summary

| Test File | Tests | What's Covered |
|---|---|---|
| `FetchRepositoriesUseCaseTests` | 7 | Pagination, error propagation, page metadata |
| `FetchBranchesUseCaseTests` | 7 | Owner/repo forwarding, protection flags, perPage fallback |
| `AuthUseCaseTests` | 6 | Sign in/out, empty code guard, error propagation |
| `RepositoryListViewModelTests` | 12 | Loading, empty, error states, search, pagination, sign out |
| `BranchListViewModelTests` | 11 | Branch loading, invalid fullName guard, search, pagination |
| `RepoGatewayTests` | 6 | Cache hit/miss, token loading, hasNextPage logic |
| `RepositoryCacheTests` | 8 | Store/retrieve, TTL expiry, invalidate, page isolation |
| `NetworkErrorTests` | 13 | All error descriptions, isRetryable, Equatable conformance |
| `AuthFlowUITests` | 7 | Sign in screen, auth flow, sign out alert |

---

## Features

- **OAuth 2.0 authentication** via `ASWebAuthenticationSession`
- **Paginated repository list** — name, privacy badge, star count, language chip, last updated
- **Search / filter** repositories by name or description with 300ms debounce
- **Branch list** per repository with protection indicator and default branch badge
- **Paginated branches** with infinite scroll
- **Pull-to-refresh** on both lists
- **Sign out** — clears Keychain token and returns to sign-in screen
- **Loading / empty / error states** on every screen
- **Accessibility labels and identifiers** throughout

---

## Architecture

RepoLite follows **Clean Architecture** with **MVVM** on the presentation layer, organized into four layers with strict dependency rules — outer layers depend on inner layers, never the reverse.

```
┌─────────────────────────────────────────────┐
│         Presentation  (SwiftUI + MVVM)       │
│         Views  ◄──►  ViewModels             │
└──────────────────┬──────────────────────────┘
                   │  Use Cases (via protocols)
┌──────────────────▼──────────────────────────┐
│         Domain                               │
│         Entities  │  Use Cases  │  Protocols │
└──────────────────┬──────────────────────────┘
                   │  Protocol conformance
┌──────────────────▼──────────────────────────┐
│         Data                                 │
│         Gateways  │  DTOs  │  Cache          │
└──────────────────┬──────────────────────────┘
                   │
┌──────────────────▼──────────────────────────┐
│         Core                                 │
│         HTTPClient  │  Keychain  │  DI       │
└─────────────────────────────────────────────┘
```

### Project Structure

```
RepoLite/
├── App/
│   ├── RepoLiteApp.swift               Entry point, auth state routing
│   └── AppConfiguration.swift          Constants read from Info.plist / xcconfig
├── Core/
│   ├── Network/
│   │   ├── HTTPClient.swift             URLSession client with typed error mapping
│   │   ├── APIEndpoint.swift            Protocol + URLRequest builder
│   │   ├── GitHubAPIEndpoints.swift     All GitHub API routes
│   │   └── NetworkError.swift           Typed error enum
│   ├── Security/
│   │   └── KeychainService.swift        Secure token persistence
│   ├── Dependency Injection/
│   │   └── AppContainer.swift           Composition root + ViewModel factories
│   └── Extensions/
│       └── Date+Extensions.swift        Relative date formatting
├── Domain/
│   ├── Entities/                        User, Repository, Branch, Page, AuthToken
│   ├── Repositories/                    AuthRepositoryProtocol, RepoGatewayProtocol, BranchRepositoryProtocol
│   └── UseCases/                        SignIn, SignOut, FetchRepositories, FetchBranches
├── Data/
│   ├── DTOs/                            Decodable DTOs with toDomain() mappers
│   ├── Cache/                           Thread-safe in-memory cache with 5-min TTL
│   └── Repositories/                    AuthRepository, RepoGateway, BranchRepository
└── Presentation/
    ├── Auth/                            SignInView + SignInViewModel
    ├── Repositories/                    RepositoryListView + RepositoryListViewModel
    ├── Branches/                        BranchListView + BranchListViewModel
    └── Common/Components/               LoadingView, ErrorView, EmptyStateView, LanguageChip

RepoLiteTests/
├── TestHelpers.swift                    Shared mocks, stubs, and fakes
├── Core/                                NetworkErrorTests
├── Domain/                              FetchRepositoriesUseCaseTests, FetchBranchesUseCaseTests, AuthUseCaseTests
├── Data/                                RepoGatewayTests, RepositoryCacheTests
├── Presentation/                        RepositoryListViewModelTests, BranchListViewModelTests
└── UI Tests/                            AuthFlowUITests
```

---

## Key Design Decisions

| Decision | Rationale |
|---|---|
| `ASWebAuthenticationSession` | Apple-recommended OAuth flow. `prefersEphemeralWebBrowserSession = true` prevents GitHub cookies persisting between sessions |
| Keychain with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` | Token inaccessible when device is locked and cannot migrate via iCloud backup |
| `keychainService` as `let` in `AppContainer` | Ensures it's available in `init()` for UI test launch argument handling — `lazy var` caused silent failures |
| In-memory cache with 5-min TTL | Reduces API calls during pagination; invalidated on pull-to-refresh for fresh data on demand |
| `async/await` throughout | Structured concurrency keeps Data and Domain layers free of Combine complexity |
| Combine only in ViewModels | Debounced search binding is a natural fit; keeps reactive paradigms at the presentation boundary only |
| Protocol-per-gateway | Enables granular lightweight mocks in tests without fat mock objects |
| `ViewState` enum | Exhaustive state modelling prevents impossible UI states at compile time |
| `AppContainer` composition root | All dependency wiring in one place; Views never instantiate their own dependencies |
| `accessibilityIdentifier` on interactive elements | Decouples UI tests from display text — renaming a label never breaks a test |
| `ProcessInfo.arguments` in `AppContainer.init` | Enables `RESET_AUTH` and `MOCK_AUTHENTICATED` launch flags for reliable UI test isolation |

---

## Security

- OAuth token stored in iOS Keychain with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`
- Client credentials injected at build time via `Secrets.xcconfig` — never hardcoded in source
- `Secrets.xcconfig` is gitignored and excluded from version control
- `ASWebAuthenticationSession` with ephemeral session prevents GitHub cookies from persisting
- Sign out deletes the Keychain entry completely before navigating to sign-in

---

## Dependencies

**Zero third-party dependencies.** Built entirely on native Apple frameworks:

| Framework | Usage |
|---|---|
| `SwiftUI` | UI layer |
| `AuthenticationServices` | OAuth via `ASWebAuthenticationSession` |
| `Security` | Keychain access |
| `Foundation` | Networking via `URLSession`, `async/await` |
| `Combine` | Search debouncing in ViewModels |

SPM is configured and ready for any future dependencies.

---

## Trade-offs

**No offline persistence** — cache is in-memory only. A SwiftData layer under the gateway protocols would add full offline support without breaking changes to any other layer.

**Client secret in the app** — for production, the OAuth code-for-token exchange should happen server-side. A backend proxy or GitHub App (which uses installation tokens instead of client secrets) would eliminate this risk entirely.

**Layered structure vs. modular SPM packages** — the project uses a layered folder structure within a single target. Separate SPM packages per layer would enforce architectural boundaries at the compiler level and improve incremental build times at scale. For an assessment of this scope the added complexity is not justified — this is a deliberate, documented decision.

**No automatic retry on rate-limit** — `NetworkError.rateLimited` surfaces the `Retry-After` value but ViewModels do not auto-retry. Exponential back-off via `Task.sleep` is the natural next step.

---

## Future Work

- SwiftData persistence layer for full offline support
- Deep link routing: `repolite://repo/{owner}/{name}` — the `handleDeepLink` plumbing is already in `AppContainer`
- Snapshot tests via [SnapshotTesting](https://github.com/pointfreeco/swift-snapshot-testing) (SPM) for visual regression on row cells and state views
- Full `XCUIAccessibilityAudit` pass (Xcode 15) for comprehensive VoiceOver coverage
- Repository detail screen: README preview, contributors, recent commits
- Branch protection detail view — expand the shield indicator to show ruleset details

---

## Author

**Nada Ashraf** — iOS Technical Assessment
