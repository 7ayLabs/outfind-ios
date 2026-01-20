# Lapses iOS

**The Official iOS Client for the 7ay Presence Protocol**

[![Build Status](https://github.com/7aylabs/outfind-ios/actions/workflows/ci.yml/badge.svg)](https://github.com/7aylabs/outfind-ios/actions)
[![iOS 18+](https://img.shields.io/badge/iOS-18%2B-blue.svg)](https://developer.apple.com/ios/)
[![Swift 6.0](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org/)
[![License](https://img.shields.io/badge/License-Proprietary-red.svg)](./LICENSE)

---

## Overview

Lapses is the flagship iOS application for the **7ay Network**, implementing the [7ay-presence Protocol v0.6.7](https://docs.7ay.network/protocol). It enables ephemeral, blockchain-verified social interactions through time-bounded events called **Epochs**.

### What is 7ay Network?

7ay Network is a decentralized social infrastructure layer that introduces **ephemeral presence** as a primitive for trustless, time-bounded interactions. Unlike traditional social platforms where data persists indefinitely, 7ay Network ensures all interaction data is automatically purged when epochs close—enforcing privacy by design at the protocol level.

### Core Concepts

| Concept | Description |
|---------|-------------|
| **Epoch** | A time-bounded event with a defined lifecycle (Scheduled → Active → Closed → Finalized) |
| **Presence** | Blockchain-verified participation in an epoch, declared on-chain via smart contracts |
| **Capability** | Feature gates that unlock based on epoch type (PresenceOnly, WithSignals, WithEphemeralData) |
| **Ephemerality** | All user data, messages, and media are cryptographically purged when epochs close |

---

## Features

### Current (v1.0)

- **Wallet Authentication** — Connect via MetaMask, Rainbow, Trust Wallet, Coinbase Wallet, or Phantom using WalletConnect v2
- **Epoch Discovery** — Browse, search, and filter live and upcoming epochs
- **Presence Declaration** — On-chain presence verification via Ethereum Sepolia testnet
- **Ephemeral Messaging** — End-to-end encrypted, epoch-scoped conversations
- **Media Sharing** — Capture and share photos/videos that auto-delete on epoch close
- **Real-time Updates** — WebSocket-based live epoch state and presence updates
- **Capability Gating** — Features unlock dynamically based on epoch and presence state

### Roadmap

- [ ] Mainnet deployment (Ethereum L2)
- [ ] Push notifications for epoch events
- [ ] Staking and validator participation
- [ ] Cross-platform sync via 7ay Cloud
- [ ] Enhanced media editing tools

---

## Architecture

Lapses follows **Clean Architecture** with **MVVM** presentation pattern:

```
┌─────────────────────────────────────────────────────────────┐
│                      Presentation Layer                      │
│   SwiftUI Views · ViewModels · Coordinators · Components    │
├─────────────────────────────────────────────────────────────┤
│                        Domain Layer                          │
│      Entities · Value Objects · Repository Protocols        │
├─────────────────────────────────────────────────────────────┤
│                         Data Layer                           │
│  Repository Implementations · DTOs · Remote/Local Sources   │
├─────────────────────────────────────────────────────────────┤
│                    Infrastructure Layer                      │
│   Network · Web3 · Storage · Services · WalletConnect       │
└─────────────────────────────────────────────────────────────┘
```

### Tech Stack

| Component | Technology |
|-----------|------------|
| UI Framework | SwiftUI (iOS 18+) |
| State Management | @Observable, Environment |
| Blockchain | Ethereum Sepolia (Chain ID: 11155111) |
| Wallet Connection | WalletConnect v2 |
| Networking | URLSession, WebSocket |
| Local Storage | SwiftData (memory-only, ephemeral) |
| CI/CD | GitHub Actions |

---

## Protocol Invariants

Lapses strictly enforces the 7ay-presence Protocol invariants:

| ID | Invariant | Enforcement |
|----|-----------|-------------|
| INV1 | One finalized presence per (actor, epoch) | Duplicate declaration prevention |
| INV4 | Only actor can declare own presence | Wallet signature verification |
| INV14 | Ephemeral data only during Active epoch | Automatic purge on epoch close |
| INV21 | Discovery is epoch-scoped | Node list cleared per epoch |
| INV22 | Presence gates discovery | Feature gating on presence state |
| INV23 | Messages require PresenceWithSignals | Capability check before chat |
| INV27 | Media requires PresenceWithEphemeralData | Capability check before media |
| INV29 | Media inaccessible after epoch close | Cryptographic deletion on close |

---

## Smart Contracts

Lapses interacts with the following 7ay Protocol smart contracts on Sepolia:

| Contract | Purpose |
|----------|---------|
| **EpochRegistry** | Epoch lifecycle management and capability tracking |
| **PresenceRegistry** | Presence declarations, validation, and finalization |
| **ValidatorRegistry** | Validator set management and quorum calculation |

> Contract addresses and ABIs are managed by 7aylabs and subject to change during testnet phase.

---

## Requirements

- **iOS 18.0** or later
- **Xcode 16.1** or later
- **Swift 6.0**
- Active internet connection
- Ethereum-compatible wallet (for presence declaration)

---

## Building

```bash
# Clone the repository
git clone https://github.com/7aylabs/outfind-ios.git
cd outfind-ios

# Build
xcodebuild build \
  -project outfind/outfind.xcodeproj \
  -scheme outfind \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5' \
  -configuration Debug

# Run tests
xcodebuild test \
  -project outfind/outfind.xcodeproj \
  -scheme outfind \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5'
```

---

## Testing

Lapses includes comprehensive test coverage:

| Test Type | Location | Description |
|-----------|----------|-------------|
| **Unit Tests** | `outfindTests/` | Domain entities, repositories, state management |
| **UI Tests** | `outfindUITests/` | Component-level UI verification |
| **E2E Tests** | `outfindUITests/NavigationE2ETests.swift` | Full user journey testing |

### Test Categories

- **Domain Tests** — Message, Conversation, Epoch, Presence entities
- **Repository Tests** — Data layer protocol implementations
- **Integration Tests** — DependencyContainer, service interactions
- **Accessibility Tests** — VoiceOver compatibility
- **Performance Tests** — Tab switching, list scrolling benchmarks

---

## Configuration

### Environment Variables

| Variable | Description |
|----------|-------------|
| `SEPOLIA_RPC_URL` | Ethereum Sepolia RPC endpoint |
| `WALLETCONNECT_PROJECT_ID` | WalletConnect Cloud project ID |
| `API_BASE_URL` | 7ay API base URL |
| `WEBSOCKET_URL` | 7ay WebSocket endpoint |

### Build Configurations

- **Debug** — Mock services, verbose logging, Sepolia testnet
- **Release** — Production services, optimized builds

---

## Contributing

**This is a proprietary project.** External contributions are not accepted at this time.

For partnership inquiries or enterprise licensing, contact: **legal@7aylabs.com**

---

## Security

### Reporting Vulnerabilities

If you discover a security vulnerability, please report it responsibly:

**Email:** security@7aylabs.io

Do NOT create public GitHub issues for security vulnerabilities.

### Security Practices

- All on-chain transactions require explicit wallet signature
- No private keys stored on device
- Ephemeral data encrypted at rest and purged on epoch close
- Certificate pinning for API communications
- Regular third-party security audits

---

## Legal

### Intellectual Property

The 7ay-presence Protocol, Lapses application, and all associated source code, documentation, designs, and trademarks are the exclusive intellectual property of **7aylabs Inc.**

### Compliance

Lapses is designed to comply with:
- GDPR (data minimization via ephemerality)
- CCPA (no persistent personal data)
- App Store Guidelines

---

## License

**Copyright 2024-2026 7aylabs S.A de C.V. All Rights Reserved.**

This software is proprietary and confidential. Unauthorized copying, distribution, modification, public display, or public performance of this software is strictly prohibited.

See [LICENSE](./LICENSE) for full terms.

---

## Contact

| Purpose | Contact |
|---------|---------|
| General Inquiries | hello@7aylabs.com |
| Enterprise Licensing | legal@7aylabs.com |
| Security Issues | security@7aylabs.com |
| Press & Media | press@7aylabs.com |

---

<p align="center">
  <strong>Built with conviction by 7aylabs</strong><br>
  <sub>Ephemeral by design. Private by default.</sub>
</p>
