# VIN Scanner App — Requirements Document

> **Status:** Draft v0.3  
> **Last Updated:** 2026-04-26  
> **Author:** Dirk Steele  

---

## Project Overview

A mobile barcode scanning application designed to scan vehicle VIN barcodes and retrieve vehicle details such as year, make, and model. The app is built for field use on Android devices. The long-term goal is a commercially distributable, cross-platform product.

---

## Development Strategy

### AI-Assisted Multi-Agent Approach

This project is developed using a multi-agent AI strategy. All agents share this requirements document as their primary source of context. Each agent operates in an isolated scope — architecture, implementation, or QA — coordinated by an orchestrator agent.

**Agent Roles:**

| Role | Responsibility |
|------|---------------|
| Orchestrator | Coordinates agent tasks, manages scope, ensures alignment with requirements |
| Architecture Agent | System design, component structure, technology decisions |
| Implementation Agent | Code generation, feature development, package integration |
| QA Agent | Test strategy, performance validation, regression checks |

**Key Principles:**
- All agents reference this document for shared context
- Tasks are isolated to prevent agents from overwriting each other's work
- A loosely coupled, modular architecture is required so components can be swapped without cascading rewrites

### Tech Stack

| Layer | Choice | Rationale |
|-------|--------|-----------|
| Framework | Flutter | Cross-platform path (Android first, iOS later), manageable learning curve for experienced developers |
| Language | Dart | Required by Flutter |
| Barcode Scanning | `mobile_scanner` (initial) | Actively maintained, uses CameraX + ML Kit on Android, fast and lightweight |
| Target Platform | Android (Phase 1) | Developer's primary device; iOS support planned for later phases |

---

## Phase One — Barcode Scanner Proof of Concept

**Goal:** Validate that barcode scanning technology meets performance requirements before building additional features. The entire purpose of Phase One is a fast, reliable scan. Nothing else.

### Scope

- Scan a VIN barcode using the device camera
- Display the raw scanned value on screen
- Confirm the scan completed within the performance threshold
- No UI polish, no API calls, no persistence

### Functional Requirements

| ID | Requirement |
|----|-------------|
| F-01 | The app must activate the device camera for live barcode scanning |
| F-02 | The app must detect and decode a VIN barcode from the camera feed |
| F-03 | The app must display the raw decoded VIN string on screen after a successful scan |
| F-04 | The app must support Code 39 and Code 128 barcode formats (standard automotive VIN formats) |
| F-05 | The app must handle a failed or unreadable scan gracefully without crashing |
| F-06 | If multiple barcodes are detected in the camera frame simultaneously, use the first decoded result and ignore the rest until a new scan is initiated |

### Performance Requirements

| ID | Requirement |
|----|-------------|
| P-01 | Scan-to-decode time must be under 1 second, measured from the moment `ScannerService.startScan()` is called to the moment a decoded result is returned |
| P-02 | The app must perform consistently across typical outdoor lighting conditions |
| P-03 | Performance must be measured and recorded during Phase One testing to establish a baseline |

> **Benchmark context:** A subsecond scan is achievable. Known reference apps demonstrate scan times around 250ms. Orca Scan is the negative benchmark — its performance is the floor, not the ceiling.

### Error Handling Requirements

| ID | Requirement |
|----|-------------|
| E-01 | If no barcode is detected within 10 seconds, the app must display a user-facing message |
| E-02 | If camera permission is denied, the app must display an appropriate message and not crash |
| E-03 | Unrecognized barcode formats must be handled gracefully |

### Android Platform Requirements

| ID | Requirement |
|----|-------------|
| M-01 | Minimum Android version: Android 8.0 (API level 26) |
| M-02 | Requires camera hardware permission |
| M-03 | Must function on standard smartphone form factor |
| M-04 | Must function in outdoor lighting conditions |

### Architecture Requirements

| ID | Requirement |
|----|-------------|
| A-01 | Barcode scanning logic must be encapsulated in an abstraction layer (interface/service) |
| A-02 | The scanning implementation must be swappable without changes to the rest of the app |
| A-03 | No business logic should be tightly coupled to `mobile_scanner` directly |
| A-04 | Use `get_it` as the Service Locator; no other state management library is permitted in Phase One |

### Dependencies

All Phase One implementations must use these pinned versions. Do not upgrade without explicit approval.

| Package | Version |
|---------|---------|
| Flutter SDK | `>=3.10.0` |
| Dart SDK | `>=3.0.0` |
| `mobile_scanner` | `^5.0.0` |
| `get_it` | `^7.0.0` |
| `google_mlkit_barcode_scanning` *(fallback — activate only if pivot triggered)* | `^0.12.0` |

### Test Directory Structure

The `test/` directory must mirror the `lib/` structure:

```
test/
  services/
    scanner_service_test.dart
    mobile_scanner_service_test.dart
  ui/
    scanner_screen_test.dart
```

### Phase One Exit Criteria

Phase One is complete when:

1. The app successfully decodes a real VIN barcode from a physical vehicle
2. Scan-to-decode time is confirmed under 1 second in field conditions
3. The abstraction layer is in place and a swap to an alternate scanning library has been validated as feasible

---

## Phase Two — UI and Feature Expansion

> **Status:** Placeholder. Details to be defined after Phase One exit criteria are met.

**Anticipated scope:**
- Vehicle lookup via external API using decoded VIN (NHTSA or commercial equivalent)
- Display of vehicle details: year, make, model, and additional fields TBD
- Basic user interface and UX design
- Scan history or session logging
- Error handling improvements

---

## Phase Three — TBD

> **Status:** Placeholder. Scope to be defined after Phase Two is underway.

Likely candidates include:
- iOS support
- User accounts or cloud sync
- Commercial distribution (Google Play Store, App Store)
- Additional barcode format support beyond VIN

---

## Open Questions

- [x] Confirm VIN barcode format specifics — resolved: Code 39 and Code 128 per F-04
- [ ] Confirm `mobile_scanner` performance on actual vehicle door jamb barcodes — initial field test exceeded 1s; further testing required with targeting box and correct orientation
- [ ] Resolve wrong-barcode problem — door jamb stickers contain multiple barcodes; app must identify the VIN specifically (17 alphanumeric chars, no I/O/Q)
- [ ] Identify backup barcode scanning libraries in case `mobile_scanner` fails performance requirements
- [ ] Define Phase Two API strategy (NHTSA free tier vs. commercial provider)
- [ ] Define multi-agent tooling setup (which AI platforms, how context is passed between sessions)

---

## Revision History

| Version | Date | Notes |
|---------|------|-------|
| 0.1 | 2026-04-26 | Initial draft based on discovery session |
| 0.2 | 2026-04-26 | Fixed P-01 timing definition; added A-04, F-06, Dependencies section, test directory structure |
| 0.3 | 2026-04-26 | Closed barcode format open question (resolved by F-04); tightened E-01 timeout to 10 seconds; promoted to canonical REQUIREMENTS.md |
| 0.4 | 2026-04-26 | Field test findings: 59ms on paper, >1s on vehicle barcode (orientation + lighting); wrong barcode decoded (multiple barcodes on door jamb sticker); Phase 1 exit criteria not yet fully met; added two open questions |
