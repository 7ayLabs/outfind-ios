# Lapses iOS App

## Overview
Lapses is an iOS app for ephemeral, time-bounded social gatherings called "Epochs". Users can declare presence at locations, join epochs, and interact with others nearby using the 7ay-presence mesh network protocol.

## App Name & Branding
- **App Name**: Lapses
- **Domain**: lapses.me
- **URL Scheme**: lapses://
- **Bundle ID**: the7aylabscompany.lapses

## Tech Stack
- **Language**: Swift 5.0
- **UI Framework**: SwiftUI (iOS 17+)
- **Architecture**: Clean Architecture (Domain/Data/Presentation layers)
- **State Management**: @Observable (iOS 17), @Environment for DI
- **Async**: Swift Concurrency (async/await)

## Project Structure
```
outfind/
├── App/
│   └── OutfindApp.swift          # App entry point (struct name kept as OutfindApp)
├── Core/
│   ├── Configuration/
│   │   └── Environment.swift     # API URLs, config (lapses.me domains)
│   └── Constants/
├── Domain/
│   ├── Entities/
│   │   ├── Epoch.swift           # Time-bounded gathering
│   │   ├── Presence.swift        # User presence declaration
│   │   ├── User.swift
│   │   └── EpochNFT.swift
│   └── Repositories/             # Protocol definitions
├── Data/
│   └── Repositories/             # Repository implementations
├── Infrastructure/
│   ├── Auth/
│   │   └── GoogleAuthService.swift
│   ├── Services/
│   │   └── EpochLifecycleManager.swift
│   └── Web3/
│       └── WalletConnectService.swift
└── Presentation/
    ├── DesignSystem/
    │   ├── Theme.swift           # Colors, spacing, corner radius
    │   ├── Typography.swift      # Font styles
    │   ├── Iconography.swift     # SF Symbols mapping
    │   └── GlassEffect.swift     # Blur/glass modifiers
    ├── Components/
    │   ├── Buttons.swift         # PrimaryButton, SecondaryButton
    │   ├── Cards.swift           # EpochCard, InfoCard, etc.
    │   ├── EmojiReactionBar.swift
    │   ├── MediaGalleryView.swift
    │   └── ListRowComponents.swift
    └── Views/
        ├── Main/
        │   ├── MainTabView.swift
        │   └── HomeView.swift
        ├── Explore/
        │   ├── ExploreSection.swift
        │   ├── ExploreMapView.swift
        │   ├── EpochMapMarker.swift
        │   └── ExploreSearchBar.swift
        ├── Epoch/
        │   ├── EpochDetailView.swift
        │   └── ActiveEpochView.swift
        └── Onboarding/
            ├── OnboardingView.swift
            └── LoginView.swift
```

## Key Concepts

### Epochs
Time-bounded gatherings with states:
- `scheduled` - Future epoch
- `active` - Currently running (LIVE)
- `closed` - Ended, awaiting finalization
- `finalized` - Completed, data cleaned up

### Epoch Capabilities
- `presenceOnly` - Basic presence declaration
- `presenceWithSignals` - Discovery & messaging
- `presenceWithEphemeralData` - Full media support

### Presence
On-chain declaration that user is at an epoch location.

## Design System

### Theme Colors
```swift
Theme.Colors.background          // Main background
Theme.Colors.backgroundSecondary // Card backgrounds
Theme.Colors.textPrimary         // Main text
Theme.Colors.textSecondary       // Secondary text
Theme.Colors.primaryFallback     // Accent color (green)
Theme.Colors.epochActive         // Live/active state
Theme.Colors.epochScheduled      // Scheduled state
Theme.Colors.success / .error / .warning
```

### Spacing
```swift
Theme.Spacing.xxs  // 2pt
Theme.Spacing.xs   // 4pt
Theme.Spacing.sm   // 8pt
Theme.Spacing.md   // 16pt
Theme.Spacing.lg   // 24pt
Theme.Spacing.xl   // 32pt
Theme.Spacing.xxl  // 48pt
```

### Glass Effects
```swift
.frostedGlass(style: .thin)      // Light blur
.glassCard(style: .regular)      // Card with blur
.ultraThinMaterial               // Native SwiftUI material
```

## Navigation
Uses `AppCoordinator` with `@Observable`:
```swift
coordinator.showEpochDetail(epochId: id)
coordinator.enterActiveEpoch(epochId: id)
coordinator.pop()
```

## Environment Dependencies
```swift
@Environment(\.coordinator) private var coordinator
@Environment(\.dependencies) private var dependencies
```

## API Configuration
All API endpoints use `lapses.me` domain:
- API: `https://api.lapses.me`
- WebSocket: `wss://ws.lapses.me`
- IPFS: `https://ipfs.lapses.me`

## Important Notes

### DO NOT COMMIT THIS FILE
This file is for local reference only. Keep it untracked.

### Module Name
The Swift module is still named `outfind` (Xcode target name). Changing it requires renaming the target in Xcode.

### URL Scheme for OAuth
Google OAuth uses `lapses://oauth/callback`. Update Google Console if changing.

### Portrait Only
App is locked to portrait orientation on iPhone.

## Common Tasks

### Adding a new View
1. Create in appropriate `Views/` subfolder
2. Use `@Environment(\.coordinator)` for navigation
3. Use `@Environment(\.dependencies)` for data access
4. Follow existing patterns for loading states

### Adding a Component
1. Create in `Presentation/Components/`
2. Use Theme colors/spacing
3. Add preview at bottom of file

### Updating Branding
Key files for branding:
- `OutfindApp.swift` - Splash screen
- `HomeView.swift` - Header title
- `OnboardingView.swift` - Logo
- `LoginView.swift` - Title
- `project.pbxproj` - CFBundleDisplayName
