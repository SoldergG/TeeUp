# TeeUp — Golf Companion App for Portugal

<p align="center">
  <img src="https://img.shields.io/badge/Platform-iOS%2017+-green?style=flat-square&logo=apple" />
  <img src="https://img.shields.io/badge/Swift-5.9-orange?style=flat-square&logo=swift" />
  <img src="https://img.shields.io/badge/SwiftUI-5-blue?style=flat-square" />
  <img src="https://img.shields.io/badge/Backend-Supabase-3ECF8E?style=flat-square&logo=supabase" />
</p>

**TeeUp** is a premium iOS golf companion app designed for the Portuguese market. Track rounds hole-by-hole, discover nearby golf courses, calculate your WHS handicap, and compete with friends — all in one beautifully crafted SwiftUI app.

---

## Features

### Rounds & Scoring
- Full 9/18-hole scorecard entry with stroke-by-stroke tracking
- Detailed hole input: putts, fairway hit, penalties, wind conditions, notes
- Real-time score-to-par calculations with color-coded feedback
- Animated score counters with haptic feedback
- Round summary with comprehensive stats
- CSV/JSON export for data backup

### Handicap System
- **World Handicap System (WHS)** compliant calculations
- Score differential, adjusted gross score, course handicap
- Handicap trend analysis (improving / stable / worsening)
- Interactive handicap evolution chart (Swift Charts)
- Historical handicap records

### Course Discovery
- **Google Places API** integration — find golf courses within 50km
- Interactive MapKit map with custom course pins
- Course details: rating, price level, open/closed status, distance
- 24-hour smart caching via SwiftData
- Direct navigation to Apple Maps / Google Maps

### Social & Multiplayer
- Friends system with search, add, accept/reject requests
- Game session scheduling with date, course, and price
- Invite friends to upcoming rounds
- Share round results and game invites
- Real-time participant status tracking

### Profile & Stats
- Handicap display with trend indicators
- Best score, rounds played, average stats
- Score distribution chart (eagles, birdies, pars, bogeys)
- On-device analytics (most played course, rounds this month)
- App Store review prompt after milestone rounds

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| **UI** | SwiftUI 5 + Swift Charts |
| **Data** | SwiftData (offline-first) |
| **Backend** | Supabase (Auth, PostgreSQL, Realtime) |
| **Auth** | Apple Sign-In + Google OAuth (PKCE) |
| **Maps** | MapKit + Google Places API (v1) |
| **Weather** | WeatherKit |
| **Location** | CoreLocation |
| **Networking** | URLSession (optimized, pooled) |

---

## Architecture

```
TeeUp/
├── TeeUpApp.swift              # Entry point + OAuth handler
├── Theme/                      # AppTheme (colors, styling)
├── Models/                     # SwiftData models
│   ├── Course.swift            # Course → Tee → HoleData
│   ├── Round.swift             # Round → HoleScore
│   ├── UserProfile.swift       # Profile + HandicapRecord
│   └── Enums.swift             # CourseRegion, TeeColor, Wind, etc.
├── Services/                   # Business logic
│   ├── SupabaseManager.swift   # Auth + remote sync
│   ├── GooglePlacesService.swift # Course discovery + cache
│   ├── LocationManager.swift   # GPS + permissions
│   ├── FriendsService.swift    # Friend management
│   ├── GameSessionService.swift # Social sessions
│   └── Haptics.swift           # Haptic feedback
├── ViewModels/
│   ├── RoundsViewModel.swift   # Round CRUD + completion
│   └── HandicapCalculator.swift # WHS calculations
├── Views/
│   ├── ContentView.swift       # Tab navigation + auth flow
│   ├── Auth/                   # Login (Apple/Google)
│   ├── Rounds/                 # Scorecard, hole input, summary
│   ├── Courses/                # Course list + detail
│   ├── Map/                    # Interactive map view
│   ├── Friends/                # Friends list + search
│   ├── Social/                 # Game sessions
│   ├── Profile/                # User profile + stats
│   └── Components/             # 18 reusable UI components
├── Extensions/                 # Date, String, View, Double, Collection
└── Utilities/                  # 15 utility modules
    ├── NetworkMonitor.swift    # Connectivity detection
    ├── Debouncer.swift         # Rate limiting (actor-based)
    ├── CacheManager.swift      # NSCache + async image loader
    ├── WeatherHelper.swift     # WeatherKit integration
    ├── ExportManager.swift     # CSV/JSON export
    ├── ShareManager.swift      # Share sheets
    ├── HandicapTrend.swift     # Trend analysis
    ├── QuickStats.swift        # O(n) stats calculation
    ├── PerformanceConfig.swift # URLSession pooling, batching, etc.
    └── ...
```

---

## Performance Optimizations

- **Cached DateFormatters** — static formatters avoid repeated allocations
- **Request deduplication** — in-flight API requests are cancelled and replaced
- **Optimized URLSession** — connection pooling, 50MB disk cache, 15s timeout
- **Image downsampling** — CGImageSource thumbnails to reduce memory usage
- **NSCache with memory warning** — auto-clears on `didReceiveMemoryWarningNotification`
- **Batch SwiftData processing** — yields to main thread between chunks
- **Compiled predicates** — pre-built `#Predicate` for frequent queries
- **Location distance filter** — only updates on 100m+ movement
- **Debounced search** — 300ms actor-based debouncer prevents rapid API calls
- **Lazy navigation destinations** — deferred view creation for list performance
- **Reduced motion support** — respects `UIAccessibility.isReduceMotionEnabled`
- **Deferred startup** — background initialization of formatters, network, audio

---

## Setup

1. Clone the repo
2. Open `TeeUp.xcodeproj` in Xcode 15+
3. Set your **Google Places API key** in `GooglePlacesService.swift`
4. Configure **Supabase** credentials in `SupabaseManager.swift`
5. Add **WeatherKit** capability in Signing & Capabilities
6. Build and run on iOS 17+ device or simulator

---

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+
- Google Places API key
- Supabase project (auth + database)

---

## License

This project is proprietary software. All rights reserved.

---

<p align="center">
  Built with SwiftUI
</p>
