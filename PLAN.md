# Live Music Event Tracker — Implementation Plan

**Working name:** TBD (see Open Questions §7)
**Status:** Phase 1 (design) complete. Phase 2 (this plan) in progress.
**Owner:** Shray (ssp6731@stern.nyu.edu)
**Last updated:** 2026-05-14

---

## 0. Where we are

Phase 1 produced 7 screen designs in Pencil with a locked design system:

| # | Screen | File | Style |
|---|--------|------|-------|
| 1 | Onboarding (rate-to-unlock) | `01_Onboarding` | Hardware |
| 2 | Attended list | `02_AttendedList` | iOS-native + hardware accents |
| 3 | Event Ranking (hero) | `03_EventRanking` | Hardware |
| 4 | Event Detail | `04_EventDetail` | Hardware (cassette hero) |
| 5 | Map / Near You | `05_NearYou` | Hardware (radar) |
| 6 | Profile | `06_Profile` | iOS-native + hardware accents |
| 7 | Feed | `07_Feed` | iOS-native + hardware accents (cassette previews) |

Locked aesthetic: dark Teenage Engineering — orange CRT phosphor on near-black, monospaced grotesque, cream for identity/system text, single-accent palette.

---

## 1. Architecture & Tech Stack

### Languages & frameworks
- **Swift 6** with strict concurrency enabled (`SWIFT_STRICT_CONCURRENCY=complete`)
- **SwiftUI** as exclusive UI framework
- **iOS 18+** target (drop to iOS 17 only if a specific reason emerges; iOS 18 unlocks `@Observable` interaction patterns + better SwiftData)
- **Xcode 16+**

### State management
- `@Observable` macro for all model/service state. No `ObservableObject`/`@StateObject` for new code.
- **MV (Model-View) pattern** — no separate ViewModel layer. Each feature has:
  - A view (SwiftUI)
  - A service/store (`@Observable` class) injected via `@Environment` or `@Bindable`
  - Models (value types, `Codable + Sendable`)
- Rationale: simpler than MVVM, matches modern Apple guidance, no premature abstraction. We can introduce VMs only where a screen has heavy interactive state (Event Ranking screen probably qualifies — it'll have a `RankingDraft` model with mutating slider state).

### Concurrency
- All service methods `async throws`
- Services are actors only when shared mutable state is unavoidable; otherwise `@Observable` on the main actor
- Use `Task { @MainActor in ... }` for UI updates from background contexts

### Networking & backend
- **Supabase** (Postgres + Auth + Storage + Realtime)
- Official **Supabase Swift SDK** via Swift Package Manager
- All API calls flow through dedicated services (`EventService`, `FriendService`, etc.)

### Local persistence
- **SwiftData** for offline cache only — read-only mirror of user's own event_logs + friends list, so the Attended list and Profile work offline.
- **Supabase is the source of truth.** SwiftData entities are sync targets, not first-class models. Don't double-write business logic.

### Maps & location
- **MapKit** for the Discover screen
- **CoreLocation** for "Near You" radius queries (foreground only, no always-on tracking)
- Privacy: `NSLocationWhenInUseUsageDescription` only; never request always

### Authentication
- **Sign in with Apple** primary (required by App Store guidelines for apps offering social login)
- Supabase Auth handles the Apple token exchange
- Email/password as fallback (Supabase native)
- No Google/Facebook to start — keep auth surface small for App Review

### Testing
- **Swift Testing** framework (`@Test`, not XCTest, for new code)
- Unit tests for: ranking algorithm, recommendation scoring, event matching, date/format helpers
- Snapshot tests for design-system components (using `swift-snapshot-testing`)
- UI tests minimal (one happy-path login → log first event)

---

## 2. Project Structure

```
LiveMusicTracker/
├── LiveMusicTracker.xcodeproj
├── LiveMusicTracker/
│   ├── App/
│   │   ├── LiveMusicTrackerApp.swift
│   │   ├── RootView.swift              # tab bar router + onboarding gate
│   │   └── Environment+Services.swift   # service injection
│   ├── Features/
│   │   ├── Onboarding/
│   │   │   ├── OnboardingView.swift
│   │   │   ├── OnboardingService.swift
│   │   │   └── SuggestedEventsView.swift
│   │   ├── EventRanking/
│   │   │   ├── EventRankingView.swift
│   │   │   ├── RankingDraft.swift       # @Observable mutating ratings
│   │   │   └── RotaryDialFocusController.swift
│   │   ├── EventDetail/
│   │   ├── Attended/
│   │   ├── Discover/                    # map + near-you list
│   │   ├── Feed/
│   │   └── Profile/                     # used for both own + other
│   ├── DesignSystem/
│   │   ├── Colors.swift                 # semantic color tokens
│   │   ├── Typography.swift             # mono font setup
│   │   ├── Spacing.swift
│   │   └── Components/
│   │       ├── HardwarePanel.swift
│   │       ├── CRTScreen.swift
│   │       ├── RotaryKnob.swift
│   │       ├── DimensionSlider.swift
│   │       ├── OLEDDisplay.swift
│   │       ├── OLEDStatChip.swift
│   │       ├── CassetteCard.swift
│   │       ├── HardwareButton.swift
│   │       ├── HardwareTabBar.swift
│   │       ├── StatusLED.swift
│   │       ├── HighlightStripeCard.swift   # "BEST CAPTURE" pattern
│   │       └── BootStatusRow.swift
│   ├── Models/
│   │   ├── User.swift
│   │   ├── Event.swift                  # canonical event
│   │   ├── EventLog.swift               # user's rating
│   │   ├── Friendship.swift
│   │   ├── FeedActivity.swift
│   │   └── TasteVector.swift
│   ├── Services/
│   │   ├── SupabaseClient.swift         # shared instance
│   │   ├── AuthService.swift
│   │   ├── UserService.swift
│   │   ├── EventService.swift           # search, match, promote
│   │   ├── RankingService.swift         # save log, compute scores
│   │   ├── FriendService.swift
│   │   ├── FeedService.swift
│   │   ├── RecommendationService.swift
│   │   └── LocationService.swift
│   ├── Resources/
│   │   ├── Assets.xcassets
│   │   ├── Fonts/                       # JetBrainsMono-*.ttf
│   │   └── PrivacyInfo.xcprivacy
│   └── Supporting/
│       ├── Logger+.swift
│       └── DateFormatting.swift
├── LiveMusicTrackerTests/
└── supabase/                            # SQL + edge functions (deployed via Supabase CLI)
    ├── migrations/
    │   ├── 0001_initial_schema.sql
    │   ├── 0002_rls_policies.sql
    │   └── 0003_functions.sql
    └── functions/
        └── compute_taste_vector/
```

---

## 3. Data Model

### 3.1 Supabase schema (SQL)

```sql
-- Extension setup
create extension if not exists "uuid-ossp";
create extension if not exists "pgcrypto";

-- USERS
create table public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique not null check (username ~* '^[a-z0-9_.-]{3,30}$'),
  display_name text,
  bio text check (char_length(bio) <= 160),
  avatar_url text,
  location text,
  onboarding_completed boolean not null default false,
  taste_vector jsonb,                          -- 7-element {artist_perf, crowd, ...}
  taste_vector_updated_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- EVENTS (canonical, shared across users)
create table public.events (
  id uuid primary key default uuid_generate_v4(),
  artist_name text not null,
  artist_name_normalized text generated always as (lower(regexp_replace(artist_name, '[^a-z0-9]', '', 'g'))) stored,
  venue_name text not null,
  venue_name_normalized text generated always as (lower(regexp_replace(venue_name, '[^a-z0-9]', '', 'g'))) stored,
  city text,
  event_date date not null,
  start_time timestamptz,
  promoted_by_user_id uuid references public.users(id) on delete set null,
  created_at timestamptz not null default now()
);

-- Fuzzy-match index: events that look like duplicates
create unique index events_dedup_idx on public.events
  (artist_name_normalized, venue_name_normalized, event_date);

-- EVENT LOGS (a user's rating of an event)
create type public.event_log_archive_status as enum ('active', 'archived');

create table public.event_logs (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.users(id) on delete cascade,
  event_id uuid not null references public.events(id) on delete cascade,
  rating_artist_performance smallint not null check (rating_artist_performance between 1 and 10),
  rating_crowd_energy smallint not null check (rating_crowd_energy between 1 and 10),
  rating_venue smallint not null check (rating_venue between 1 and 10),
  rating_lighting_visuals smallint not null check (rating_lighting_visuals between 1 and 10),
  rating_music_selection smallint not null check (rating_music_selection between 1 and 10),
  rating_atmosphere_vibe smallint not null check (rating_atmosphere_vibe between 1 and 10),
  rating_value smallint not null check (rating_value between 1 and 10),
  -- aggregate computed in app (mean of 7 dims, stored for sort perf)
  aggregate_score numeric(3,2) not null,
  notes text check (char_length(notes) <= 1000),
  photo_urls text[] default '{}',
  status public.event_log_archive_status not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, event_id)                    -- one rating per user per event
);

create index event_logs_user_idx on public.event_logs (user_id, created_at desc);
create index event_logs_event_idx on public.event_logs (event_id);

-- FRIENDSHIPS (mutual; requester must be confirmed by recipient)
create type public.friendship_status as enum ('pending', 'accepted', 'blocked');

create table public.friendships (
  id uuid primary key default uuid_generate_v4(),
  requester_id uuid not null references public.users(id) on delete cascade,
  recipient_id uuid not null references public.users(id) on delete cascade,
  status public.friendship_status not null default 'pending',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (requester_id <> recipient_id),
  unique (requester_id, recipient_id)
);

create index friendships_requester_idx on public.friendships (requester_id, status);
create index friendships_recipient_idx on public.friendships (recipient_id, status);

-- ACTIVITY FEED (denormalized for fast friend-feed reads)
create type public.activity_type as enum ('rated_event', 'going_to_event', 'milestone', 'added_to_want', 'friend_joined');

create table public.activity_feed (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.users(id) on delete cascade,
  type public.activity_type not null,
  subject_event_id uuid references public.events(id) on delete cascade,
  subject_user_id uuid references public.users(id) on delete cascade,
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now()
);

create index activity_feed_user_idx on public.activity_feed (user_id, created_at desc);

-- REACTIONS on feed items
create table public.activity_reactions (
  id uuid primary key default uuid_generate_v4(),
  activity_id uuid not null references public.activity_feed(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  emoji text not null,
  created_at timestamptz not null default now(),
  unique (activity_id, user_id, emoji)
);

-- WANT LIST (events you want to attend)
create table public.want_list (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.users(id) on delete cascade,
  event_id uuid not null references public.events(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (user_id, event_id)
);
```

### 3.2 RLS policies (high-level)

```sql
alter table public.users enable row level security;
alter table public.events enable row level security;
alter table public.event_logs enable row level security;
alter table public.friendships enable row level security;
alter table public.activity_feed enable row level security;
alter table public.activity_reactions enable row level security;
alter table public.want_list enable row level security;

-- users: row owner can update, everyone can SELECT public columns
create policy users_self_update on public.users for update using (auth.uid() = id);
create policy users_self_insert on public.users for insert with check (auth.uid() = id);
create policy users_public_read on public.users for select using (true);

-- events: readable by all, insertable by authenticated users (for promotion + auto-create on log)
create policy events_read on public.events for select using (true);
create policy events_insert on public.events for insert with check (auth.uid() is not null);

-- event_logs: owner full access; friends can read; non-friends can read aggregate_score + event_id only (separate view)
create policy event_logs_owner_all on public.event_logs for all using (auth.uid() = user_id);
create policy event_logs_friends_read on public.event_logs for select using (
  exists (
    select 1 from public.friendships f
    where f.status = 'accepted'
      and ((f.requester_id = auth.uid() and f.recipient_id = event_logs.user_id)
        or (f.recipient_id = auth.uid() and f.requester_id = event_logs.user_id))
  )
);

-- friendships: visible only to both parties
create policy friendships_visible on public.friendships for select using (
  auth.uid() = requester_id or auth.uid() = recipient_id
);
create policy friendships_insert on public.friendships for insert with check (auth.uid() = requester_id);
create policy friendships_update on public.friendships for update using (
  auth.uid() = recipient_id or auth.uid() = requester_id
);

-- activity_feed: visible to author + their accepted friends
create policy activity_visible on public.activity_feed for select using (
  auth.uid() = user_id
  or exists (
    select 1 from public.friendships f
    where f.status = 'accepted'
      and ((f.requester_id = auth.uid() and f.recipient_id = activity_feed.user_id)
        or (f.recipient_id = auth.uid() and f.requester_id = activity_feed.user_id))
  )
);
create policy activity_insert on public.activity_feed for insert with check (auth.uid() = user_id);
```

### 3.3 Swift models (sketch)

```swift
struct AppUser: Codable, Sendable, Identifiable, Hashable {
  let id: UUID
  var username: String
  var displayName: String?
  var bio: String?
  var avatarURL: URL?
  var location: String?
  var onboardingCompleted: Bool
  var tasteVector: TasteVector?
  let createdAt: Date
}

struct Event: Codable, Sendable, Identifiable, Hashable {
  let id: UUID
  var artistName: String
  var venueName: String
  var city: String?
  var eventDate: Date
  var startTime: Date?
  var promotedByUserId: UUID?
  let createdAt: Date
}

struct EventLog: Codable, Sendable, Identifiable, Hashable {
  let id: UUID
  let userId: UUID
  let eventId: UUID
  var ratingArtistPerformance: Int
  var ratingCrowdEnergy: Int
  var ratingVenue: Int
  var ratingLightingVisuals: Int
  var ratingMusicSelection: Int
  var ratingAtmosphereVibe: Int
  var ratingValue: Int
  var aggregateScore: Decimal
  var notes: String?
  var photoURLs: [URL]
  var status: ArchiveStatus
  let createdAt: Date
  var updatedAt: Date

  var dimensionRatings: [Dimension: Int] { /* sugar */ }
}

enum Dimension: String, CaseIterable, Codable, Sendable {
  case artistPerformance = "artist_performance"
  case crowdEnergy       = "crowd_energy"
  case venue
  case lightingVisuals   = "lighting_visuals"
  case musicSelection    = "music_selection"
  case atmosphereVibe    = "atmosphere_vibe"
  case value
}

struct TasteVector: Codable, Sendable, Equatable {
  /// Map of dimension -> the user's average rating for that dimension across all logs (1.0-10.0)
  var averages: [Dimension: Double]
  /// How many logs this vector was computed from
  var sampleSize: Int
  var computedAt: Date
}
```

---

## 4. Ranking & Recommendation Algorithm

### 4.1 Aggregate score per event log

Default: equal weights, so `aggregate_score = mean(d1...d7)`.

Future: user-configurable per-dimension weights — but never expose this until we have enough data to know if defaults are bad.

```swift
extension EventLog {
  static func aggregate(_ ratings: [Dimension: Int],
                       weights: [Dimension: Double] = .equal) -> Double {
    let pairs = Dimension.allCases.map { d -> (Double, Double) in
      (Double(ratings[d] ?? 0), weights[d] ?? 1.0)
    }
    let weighted = pairs.reduce(0.0) { $0 + $1.0 * $1.1 }
    let total    = pairs.reduce(0.0) { $0 + $1.1 }
    return total > 0 ? weighted / total : 0
  }
}
```

Stored as `aggregate_score numeric(3,2)` on `event_logs` for fast sort.

### 4.2 Taste vector per user

The user's "what do you reward" profile, used by recommendations. Updated each time they log a new event (cheap: 7 running averages).

```swift
func updateTasteVector(addingLog log: EventLog, to existing: TasteVector?) -> TasteVector {
  let prevSize = existing?.sampleSize ?? 0
  let newSize  = prevSize + 1
  var averages: [Dimension: Double] = [:]

  for d in Dimension.allCases {
    let prevAvg = existing?.averages[d] ?? 0
    let newVal  = Double(log.dimensionRatings[d] ?? 0)
    averages[d] = (prevAvg * Double(prevSize) + newVal) / Double(newSize)
  }

  return TasteVector(averages: averages, sampleSize: newSize, computedAt: .now)
}
```

### 4.3 Event taste profile

For each canonical event, the **event's** taste profile = the mean of all users' ratings per dimension. Computed lazily on-demand (cached in Postgres view or materialized view if it gets slow).

### 4.4 Recommendation score

For each candidate upcoming event, compute:

```
score = α · tasteMatch + β · friendSignal + γ · collabSignal
```

Initial weights: **α = 0.5, β = 0.3, γ = 0.2**. Tune once we have data.

- **tasteMatch** ∈ [0, 1]: cosine similarity between the user's taste vector and the candidate event's average rating profile. Falls back to 0.5 (neutral) when event has < 5 ratings.
- **friendSignal** ∈ [0, 1]: weighted mean of friend ratings for this event, with recency decay (`exp(-days / 90)`). 0 if no friends have rated. Most powerful signal once friend graph exists.
- **collabSignal** ∈ [0, 1]: item-item collaborative — "users who rated event X high also rated this event high". Disabled until corpus > ~500 events. Falls back to 0 below threshold.

### 4.5 Cold start

For a user who just rated one event:
- `tasteMatch` works (taste vector based on 1 log is biased but usable)
- `friendSignal` may not (no friends yet) — auto-suggest 3 mutual contacts from address book during onboarding (with permission)
- `collabSignal` works because it's based on the global corpus, not the user's history

Strategy: weight α higher (0.8) when sampleSize < 5; gradually shift toward β + γ as data grows.

### 4.6 Event matching (fuzzy)

When a user logs an event, find the canonical event row to attach to:

1. Normalize artist + venue names (lower, strip non-alphanumeric).
2. Look up by `(artist_normalized, venue_normalized, event_date)`.
3. If found → attach log to existing event row.
4. If not found → create new canonical event row.

For ambiguity (e.g., misspelled artist), the app shows "did you mean…?" with up to 3 candidates within edit distance 2.

---

## 5. SwiftUI Design-System Components

| Pencil node | SwiftUI component | Key API |
|---|---|---|
| Device housing | `HardwarePanel { content }` | corner radius, inner/outer shadows, bevel |
| CRT screen | `CRTScreen { content }` | radial glow + grid overlay, clip |
| Rotary dial | `RotaryKnob(value:in:onChange:)` | rotational drag gesture, animated rotation, LED dot |
| Dimension slider | `DimensionSlider(label:value:isFocused:)` | tap-to-focus + drag, focus stripe |
| OLED stadium readout | `OLEDDisplay { content }` | inset, glow text |
| OLED stat chip | `OLEDStatChip(label:value:tint:)` | 3-col variant |
| Cassette card | `CassetteCard(artist:venue:date:score:)` | full + mini variants |
| Hardware button | `HardwareButton(.primary/.secondary/.destructive)` | custom `ButtonStyle` |
| Hardware tab bar | `HardwareTabBar(selection:)` | 5 items, glowing center action |
| Status LED | `StatusLED(color:)` | pulsing animation variant |
| Highlight stripe card | `HighlightStripeCard(tint:title:content:)` | left stripe, used for BEST_CAPTURE + onboarding |
| Boot status row | `BootStatusRow(label:state:)` | green/amber/red state |

All components use semantic colors from `Colors.swift`:
```swift
extension Color {
  static let bgCanvas       = Color("BG/Canvas")        // #0E0E10
  static let bgPanel        = Color("BG/Panel")         // #1A1A1C
  static let bgScreen       = Color("BG/Screen")        // #0A0604
  static let crtOrangeHigh  = Color("CRT/OrangeHigh")   // #FFB070
  // ...
}
```

Fonts:
```swift
extension Font {
  static func mono(size: CGFloat, weight: Font.Weight = .regular) -> Font {
    Font.custom("JetBrainsMono-\(weight.suffix)", size: size)
  }
}
```
Bundle JetBrains Mono (OFL — permissive for app bundling, requires copyright credit in About/Legal). Possibly also bundle a single Caveat weight for the cassette accent.

---

## 6. Phase-by-phase build plan

Each phase is one or more focused sessions. After every phase: TestFlight build, run through manually, mark phase complete.

### Phase 3 — Foundation
1. New Xcode project, bundle ID `com.shray.livemusictracker` (placeholder)
2. Enable Swift 6 strict concurrency
3. Add Supabase Swift SDK via SPM
4. Create Supabase project, run `0001_initial_schema.sql`, run RLS policies
5. Implement design system: `Colors`, `Typography`, and ~5 core components (`HardwarePanel`, `CRTScreen`, `HardwareButton`, `HardwareTabBar`, `StatusLED`)
6. Build `RootView` with `HardwareTabBar` skeleton (tabs show placeholder views)
7. Sign in with Apple flow: Apple → Supabase auth → `users` row upsert
8. Onboarding flow: `OnboardingView` with 4 suggested events (hardcoded for now) → tap one → push EventRanking with that event prefilled → on save, set `onboarding_completed = true` and unlock the tab bar

**Definition of done:** can install on device, sign in, see the onboarding screen, tap a suggested event, rate it, see the home (Feed) tab placeholder.

### Phase 4 — Core Ranking
1. Implement remaining design components: `RotaryKnob`, `DimensionSlider`, `OLEDDisplay`, `CassetteCard`
2. `EventRanking` screen: full functional 7-slider + rotary dial UX
3. Event search/log entry flow: text search artists + venues against canonical events, or "manual entry" path
4. Save `event_log` via `RankingService.save(_:)`
5. `Attended` list: query own logs, sort newest-first or by score, render rows
6. `EventDetail` screen: load full log + canonical event + (Phase 5) friends-who-were-here

**Definition of done:** can log 5 events end-to-end, see them in the Attended list, tap one to see the detail screen with the cassette + dimension breakdown.

### Phase 5 — Social
1. `Profile` screen (own profile path): load user, taste vector, friends, recent logs
2. Friend search by username; send friend request; accept/decline
3. `Profile` for other users (same component, different copy per §1.7b memory)
4. `Feed` screen: query `activity_feed` for self + accepted friends, render the 3 item types (rated_event, milestone, added_to_want)
5. On `event_log` insert, also insert into `activity_feed` (via Postgres trigger, simplest)
6. Cross-user event matching surfaces "X friends were here" on Event Detail

**Definition of done:** two test accounts can friend each other; rating an event shows up in the other's feed; visiting their profile shows their public stats.

### Phase 6 — Discovery
1. `Discover` screen with map (MapKit)
2. Location permission flow (when-in-use only)
3. Query upcoming events within radius (Postgres + PostGIS or simple haversine)
4. Pins for events, tap to expand mini cassette tooltip + scroll to event in list
5. "Near You" list below map (same data, different presentation)
6. "Promote an event" flow: create an upcoming `event` row from user input (artist, venue, date, time, description)

**Definition of done:** can see live events on the map, tap a pin, see it in the list, tap to view detail.

### Phase 7 — Recommendations
1. Implement `RecommendationService.candidates(for: user)`:
   - Pull upcoming events within reasonable radius + time window
   - Compute hybrid score for each
   - Return top N
2. Recommended list UI (same row style as Attended for now; can iterate later)
3. Add `Recommended` filter chip on the Discover screen (overlay on the map "show me good matches")
4. Server-side: postgres function `compute_taste_vector(user_id)` and trigger on `event_log` insert to keep it fresh

**Definition of done:** Recommended list returns sensible suggestions for a user with ≥5 ratings.

### Phase 8 — Polish + App Store
1. App icon (~3 concepts: hardware knob, cassette label, ranked dimension stack)
2. Launch screen
3. `PrivacyInfo.xcprivacy` (data collection declarations — see `asc-privacy-nutrition-labels` skill)
4. Privacy policy + terms (host on a simple webpage)
5. App Store screenshots (export from Pencil designs + a few real device captures)
6. App Store description + keywords (see `app-store-optimization` skill)
7. TestFlight beta with ~5 friends — fix issues
8. Submit for App Review

**Definition of done:** approved on the App Store.

---

## 7. Open questions to close before Phase 3

1. **App name + bundle ID.** Candidates: `MOSH`, `CASSETTE`, `LOG.LIVE`, `LIVE_TRACKER`, `EARMARK`, `PIT.LOG`. My pick: **`MOSH`** (short, brand-able, evokes live music). Confirm or pick another.
2. **Subscription / IAP?** Free entirely, or freemium (free: log + rate; premium: deeper stats, unlimited friends, ad-free)? My recommendation: **free for v1**, add IAP in v1.1 once we know what people use.
3. **Apple Music integration?** Could prefill artist data from your library + show "your top played artist this month: did you see them live?" My recommendation: **skip for v1**, add in v1.1.
4. **Push notifications policy.** Send for: friend request, friend rated an event you've also been to, big event near you starts in 2 hours. Confirm scope.
5. **Genre tagging.** Free-form text per event (user can type "deep house, downtempo")? Or fixed taxonomy? My recommendation: **free-form text with autocomplete** from existing tags; lets the data find its own structure.

---

## 8. Key risks

1. **Event matching duplicates.** Two users typing "Four Tet" vs "@four tet" log to different canonical events → "X friends were here" breaks. **Mitigation:** aggressive normalization + a daily admin job that proposes merges to a queue.
2. **Cold start recommendations.** A new user has thin data → bad recs → uninstalls. **Mitigation:** require ≥3 ratings during onboarding (not 1), and bias toward `friendSignal` once they have any friends.
3. **MapKit pin density.** NYC could easily have 100+ live music events on a Friday. **Mitigation:** server-side clustering (return cluster summaries), client-side `Annotation` clustering, hard cap at ~50 visible pins.
4. **JetBrains Mono bundle weight.** ~600KB per weight × 3 weights = 1.8MB. Fine for App Store, but watch the app size. (Caveat font: ~50KB.)
5. **Sign in with Apple email relay.** We won't get the user's real email. Build all account flows assuming the email may be `xyz@privaterelay.appleid.com`.
6. **Supabase RLS pitfalls.** Easy to write a policy that's too permissive. **Mitigation:** integration tests against a local Supabase that assert "user A cannot read user B's logs unless friends".

---

## 9. Out of scope for v1 (parking lot)

- Direct messaging between friends
- Stories/ephemeral content
- Comments on event logs
- Notifications about Spotify/Apple Music releases
- Web app
- Android
- Internationalization (English only at launch)
- Genre-specific recommendation tuning
- "Going to" / RSVP flow (just want-list for now)
- Photo upload via storage (skip — too many failure modes; v1 is text + ratings only). Adds in v1.1.
