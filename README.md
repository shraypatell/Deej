# Deej

iOS app for logging and ranking live music events. Beli-style mechanics
for concerts, club nights, festivals — with a dark Teenage Engineering
aesthetic and a 7-dimension rating system tied to a rotary dial.

## Quick start

```bash
# Generate the Xcode project from project.yml (only after pulling fresh
# changes to project.yml — Deej.xcodeproj is committed for convenience)
xcodegen generate

# Open in Xcode
open Deej.xcodeproj

# Or build from the command line
xcodebuild -project Deej.xcodeproj \
  -scheme Deej \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

### Local Supabase setup

1. Set the anon key in `Deej/Resources/Secrets.swift` (gitignored — see
   `Secrets.swift.example`).
2. Apply migrations in order via the Supabase SQL editor:
   - `supabase/migrations/0001_initial_schema.sql`
   - `supabase/migrations/0002_rls_policies.sql`
   - `supabase/migrations/0003_triggers.sql`
3. In **Supabase Dashboard → Authentication → Providers**, enable
   **Anonymous Sign-Ins**.

The app bootstraps an anonymous user on first launch and seeds 5 demo
events into `public.events` if the table is empty.

## Architecture

- **Swift 6** with strict concurrency enabled (`SWIFT_STRICT_CONCURRENCY=complete`)
- **SwiftUI** as the exclusive UI framework
- **`@Observable`** macro for all state; MV (Model-View) pattern, no VMs
- **Supabase Swift SDK** (Postgres + Auth + Realtime) for the backend
- **MapKit** for Discover (real Apple Maps in dark mode)
- **iOS 18+** deployment target

See `PLAN.md` for the full implementation plan, schema, and algorithm
spec.

## Project layout

```
Deej/
├── App/                # entry + tab router
├── DesignSystem/       # color/font tokens + reusable hardware components
├── Features/           # one folder per screen
├── Models/             # Codable structs that mirror the Supabase schema
├── Resources/          # Assets.xcassets, Secrets.swift (gitignored)
└── Services/           # AppServices (Supabase) + SupabaseClient
supabase/migrations/    # SQL migrations in order
```

## Features (v0)

- **Onboarding**: must rate one event to unlock the app.
- **Event ranking**: 7 dimensions on a 1-10 scale, controllable via tap,
  drag, or the on-screen rotary knob.
- **Attended list**: every log you've made, with a BEST_CAPTURE
  highlight for your top-rated event.
- **Event detail**: cassette-tape hero (cream label + blue marker artist
  name + OLED stats panel) and a per-dimension breakdown.
- **Discover**: real Apple Map (dark mode) with orange event pins and a
  ranked NEAREST_EVENTS / BEST_MATCH list. Tap a pin to rate.
- **Promote event**: add an upcoming show that appears on everyone
  else's map.
- **Feed**: friend activity stream — each `rated_event` row renders as a
  mini cassette preview.
- **Profile**: your live taste profile computed from logged ratings,
  friend count, friend avatars; navigates into:
  - **Friends**: search by username, send / accept / decline requests.
  - **Settings**: edit username + display name + bio + location, plus a
    RESET_ACCOUNT button.
- **Recommendations**: cosine similarity between your taste vector and
  the candidate event's average rating profile, with a BEST_MATCH sort
  on Discover.

## Roadmap

- **v0.1**: Sign in with Apple (requires Apple Dev account + Supabase
  Apple provider configuration on your side).
- **v0.1**: Bundled JetBrains Mono + Caveat fonts (replacing system
  monospace + serif italic placeholders).
- **v0.1**: Photo uploads via Supabase Storage.
- **v0.2**: Real lat/lon columns on events + geocoding at promotion
  time (currently uses a static venue → coords table).
- **v0.2**: Comments and reactions on activity feed items.

## License

TBD.
