<div align="center">

# <img src="https://img.icons8.com/color/48/golf.png" width="32" /> TeeUp

### Your Golf Companion — Made for Portugal

[![iOS 17+](https://img.shields.io/badge/iOS-17%2B-000000?style=for-the-badge&logo=apple&logoColor=white)](https://developer.apple.com/ios/)
[![Swift 5.9](https://img.shields.io/badge/Swift-5.9-F05138?style=for-the-badge&logo=swift&logoColor=white)](https://swift.org/)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-5-007AFF?style=for-the-badge&logo=swift&logoColor=white)](https://developer.apple.com/swiftui/)
[![Supabase](https://img.shields.io/badge/Supabase-Backend-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com/)

**Track rounds. Discover courses. Compete with friends.**

*72 Swift files · 100% SwiftUI · Offline-first · WHS compliant*

---

</div>

## What is TeeUp?

TeeUp is a premium iOS golf companion app built for Portuguese golfers. It combines real-time score tracking, course discovery via Google Places, World Handicap System calculations, and a full social layer — all wrapped in a clean, native SwiftUI interface.

<br>

## Features at a Glance

<table>
<tr>
<td width="50%">

### Rounds & Scoring
- Full 9/18-hole scorecard with stroke-by-stroke tracking
- Detailed hole input — putts, fairway hit, penalties, wind, notes
- Real-time score-to-par with color-coded feedback
- Animated counters with haptic & sound feedback
- Undo/redo support for score corrections
- CSV & JSON export for data backup

</td>
<td width="50%">

### Handicap System
- **World Handicap System (WHS)** compliant engine
- Score differential & adjusted gross score
- Course handicap per tee/slope
- Trend analysis — improving, stable, or worsening
- Interactive evolution chart (Swift Charts)
- Full handicap history with per-round records

</td>
</tr>
<tr>
<td width="50%">

### Course Discovery
- **Google Places API (v1)** — find courses within 50km
- Interactive MapKit map with custom pins
- Rating, price level, open/closed, distance
- 24h smart cache via SwiftData
- One-tap directions (Apple Maps / Google Maps)
- Weather conditions via WeatherKit

</td>
<td width="50%">

### Social & Multiplayer
- Friend system — search, add, accept/reject
- Game session scheduling (date, course, price)
- Invite friends to upcoming rounds
- Share results & invites via share sheet
- Real-time participant status tracking
- Push notification reminders

</td>
</tr>
</table>

<br>

## Tech Stack

```
┌─────────────────────────────────────────────────────────┐
│  UI          SwiftUI 5 · Swift Charts · MapKit          │
│  Data        SwiftData (offline-first, cascading)       │
│  Backend     Supabase (Auth · PostgreSQL · Realtime)    │
│  Auth        Apple Sign-In · Google OAuth (PKCE)        │
│  APIs        Google Places v1 · WeatherKit              │
│  Location    CoreLocation (distance-filtered)           │
│  Network     URLSession (pooled, cached, deduplicated)  │
│  Audio       AVFoundation (ambient, non-interrupting)   │
└──────────────────────────────────────────────���──────────┘
```

<br>

## Project Structure

```
TeeUp/
│
├── TeeUpApp.swift                  # Entry point + OAuth callback
├── Theme/AppTheme.swift            # Colors, styling, card modifiers
│
├── Models/                         # SwiftData models (5 entities)
│   ├── Course.swift                #   Course → Tee → HoleData
│   ├── Round.swift                 #   Round → HoleScore
│   ├── UserProfile.swift           #   Profile → HandicapRecord
│   └── Enums.swift                 #   Region, TeeColor, Wind, Units
��
├── Services/                       # Core business logic
│   ├── SupabaseManager.swift       #   Auth + profile sync
│   ├── GooglePlacesService.swift   #   Course discovery + 24h cache
│   ├── LocationManager.swift       #   GPS + permission flow
│   ├���─ FriendsService.swift        #   Friend CRUD (Supabase)
│   ├── GameSessionService.swift    #   Social game sessions
│   └── Haptics.swift               #   Score-aware haptic engine
│
├��─ ViewModels/
│   ├── RoundsViewModel.swift       #   Round lifecycle + stats
│   └── HandicapCalculator.swift    #   WHS algorithm (USGA-based)
│
├── Views/
│   ├── ContentView.swift           #   5-tab navigation + auth gate
│   ├── Auth/LoginView.swift        #   Apple + Google sign-in
│   ├─�� Rounds/                     #   Scorecard, hole input, summary (5)
│   ├── Courses/CoursesView.swift   #   Course list + search
│   ├── Map/MapTabView.swift        #   Map with custom pins + cards
│   ├── Friends/FriendsView.swift   #   Friends + search + requests
│   ��── Social/                     #   Game sessions (3)
│   ���── Profile/ProfileView.swift   #   Stats + settings
│   └── Components/                 #   18 reusable components
│       ├── ToastView.swift         #     Notification toasts
│       ├── AnimatedCounter.swift   #     Score +/- with par colors
│       ├── HandicapChart.swift     #     Evolution line chart
│       ├── ScoreDistribution.swift #     Bar chart by score type
│       ├── ProgressRing.swift      #     Circular score indicator
│       ├── GradientButton.swift    #     Primary/secondary CTAs
│       ├── OfflineBanner.swift     #     Auto connectivity alert
│       ├── SearchBarView.swift     #     Focused search input
│       └── ...                     #     +10 more components
│
├── Extensions/                     # 5 extension files
│   ├─�� Date+Extensions.swift       #   Cached PT formatters, smart display
│   ├── String+Extensions.swift     #   Validation, initials, truncation
│   ├── View+Extensions.swift       #   Shimmer, shake, glow, bounce, keyboard
│   ├── Double+Extensions.swift     #   Distance, score, currency formatting
│   └── Collection+Extensions.swift #   Safe subscript, chunked, upsert
│
└── Utilities/                      # 15 utility modules
    ├── NetworkMonitor.swift        #   NWPathMonitor connectivity
    ├── Debouncer.swift             #   Actor-based debounce + throttle
    ��── CacheManager.swift          #   NSCache images + async loader
    ├── PerformanceConfig.swift     #   URLSession pool, batching, downsample
    ���── WeatherHelper.swift         #   WeatherKit current conditions
    ├── ExportManager.swift         #   CSV/JSON round export
    ├── ShareManager.swift          #   Round/course/invite share sheets
    ├── HandicapTrend.swift         #   Trend direction analysis
    ├── QuickStats.swift            #   Single-pass O(n) stat engine
    ├── NotificationHelper.swift    #   Local push reminders
    ├── AnalyticsTracker.swift      #   On-device event tracking
    ├── FeedbackManager.swift       #   App Store review prompts
    ├── AccessibilityHelper.swift   #   VoiceOver + Dynamic Type
    ├── OpenURLHelper.swift         #   Maps, phone, web, settings
    └── UndoHelper.swift            #   Generic undo/redo stack
```

<br>

## Performance

TeeUp is built with performance in mind from day one:

| Optimization | Impact |
|:---|:---|
| **Static DateFormatters** | Avoid repeated allocations on every cell render |
| **Request deduplication** | Cancel stale API calls, only latest request completes |
| **URLSession pooling** | 4 connections/host, 50MB disk cache, 15s timeout |
| **Image downsampling** | CGImageSource thumbnails — 70% less memory |
| **NSCache + memory warning** | Auto-clears images on `didReceiveMemoryWarning` |
| **Batch SwiftData writes** | Yields to main thread between 50-item chunks |
| **Compiled `#Predicate`** | Pre-built predicates for hot-path queries |
| **Location distance filter** | Only fires on 100m+ movement |
| **Actor-based debouncer** | 300ms search debounce, no race conditions |
| **Lazy navigation** | Deferred destination creation for large lists |
| **Deferred startup** | Formatters, network, audio init on background queue |
| **Reduced motion** | Respects `UIAccessibility.isReduceMotionEnabled` |

<br>

## Getting Started

```bash
# 1. Clone
git clone https://github.com/SoldergG/TeeUp.git
cd TeeUp

# 2. Open in Xcode
open TeeUp.xcodeproj
```

Then:

1. Set your **Google Places API key** in `Services/GooglePlacesService.swift`
2. Configure **Supabase** URL & anon key in `Services/SupabaseManager.swift`
3. Enable **WeatherKit** in Signing & Capabilities
4. Select an iOS 17+ device or simulator
5. Build & Run

<br>

## Requirements

| Requirement | Version |
|:---|:---|
| iOS | 17.0+ |
| Xcode | 15.0+ |
| Swift | 5.9+ |
| Google Places API | v1 (New) |
| Supabase | Any |

<br>

## Codebase Stats

```
 72 Swift files
 ~4,500 lines of code
 5 SwiftData entities
 6 services
 18 reusable components
 15 utility modules
 5 extension files
 12 performance optimizations
```

<br>

---

<div align="center">

**Built with SwiftUI** · Made in Portugal

</div>
