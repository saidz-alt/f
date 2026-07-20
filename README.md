# Kabylingo 🟢

A Duolingo-style, **offline-first** language-learning game for children, built
to teach **French to Kabyle (Taqbaylit) kids** and **Kabyle to French-speaking
kids** — bidirectionally, from a single curriculum.

Built with **Flutter** (single codebase → Android APK, and also runs on the
web). Designed for young learners: high-contrast colors, big tap targets,
emoji pictures, motivational sounds, hearts, XP, streaks, and a gem shop.

---

## Status & what's verified

| Area | Status |
|------|--------|
| `flutter analyze` | ✅ **No issues found** |
| Unit tests (`flutter test`) | ✅ **17/17 passing** |
| App builds & runs | ✅ Verified via the web target driven in headless Chromium (home path, shop, profile, lesson intro, and a full picture-match exercise with heart deduction) |
| Android build config | ✅ Complete & production-ready (manifest, gradle, signing, ProGuard) |
| `.apk` compiled here | ⚠️ Not in this sandbox — the Android SDK / Android Gradle Plugin are hosted on `dl.google.com`, which this environment's network policy blocks. Build it in any normal environment with the one command below. |

> **Content provenance.** The learning content in
> `assets/curriculum/curriculum.json` is built from the **Tatoeba**
> French–Kabyle corpus (`KabyleAI/KabTatoebaCorpus`, Tatoeba.org open data,
> CC-BY 2.0) — every Kabyle word/sentence is a real human translation
> (see `tools/build_curriculum.py`). The **interface** strings in
> `lib/l10n/app_text.dart` (buttons, menus) are French-authoritative with
> best-effort Kabyle that a fluent Taqbaylit speaker should review before
> release.

---

## Onboarding & fully bilingual interface

On first launch the child taps the language they **speak** — **Français** or
**Taqbaylit** (ⵣ). That single choice:

- sets the **entire interface language** (every menu, button, and instruction
  re-localizes), so a Kabyle child sees a Kabyle app and a French child sees a
  French app; and
- derives **what they learn** (the other language).

It can be changed anytime from **Profile → Langue / Tutlayt**. Localization
lives in `lib/l10n/app_text.dart` (`context.t.*`), and the Tifinagh yaz is
bundled as a fallback font (`assets/fonts/NotoSansTifinagh-Regular.ttf`) so it
renders on every platform.

## The 5-stage architecture

### Stage 1 — Foundation & gamification engine
- 4-tab shell: **Home / Progress / Shop / Profile** (`lib/screens/main_navigation.dart`).
- `GameStateProvider` (`lib/services/game_state_provider.dart`) — the single
  source of truth, backed by **Hive** so every change survives restarts:
  - **Hearts**: start at 5, deplete on error, auto-regenerate 1 every 4h
    (persisted, so regen continues while the app is closed).
  - **XP** + levels (100 XP/level), with a purchasable double-XP window.
  - **Daily streaks** with real calendar logic: same-day idempotency,
    consecutive-day increments, and a streak-freeze that bridges one missed day.
  - **Gems** (Lingots) currency + guarded spending.

### Stage 2 — Kid-friendly UI & Kabyle↔French mapping
- **Learning path**: a winding snake of 3D circular lesson nodes with
  locked / unlocked / completed states and cultural unit banners
  (`lib/screens/path_view.dart`, `lib/widgets/lesson_node.dart`).
- **Strict curriculum JSON schema** (`lib/models/curriculum.dart` +
  `assets/curriculum/curriculum.json`): bidirectional by design — each item
  stores **both** languages once, and the engine picks prompt vs. answer from
  the active direction. Includes **Tifinagh** script fields and culturally
  themed units (olive, jewelry, tea, greetings).

### Stage 3 — Interactive lesson engine
Four exercise types (`lib/widgets/exercises/`):
1. **Picture matching** — word → emoji picture.
2. **Word-bank builder** — assemble a sentence from scattered tiles.
3. **Listen & tap** — hear the word (TTS), pick the text.
4. **Text input** — a **forgiving** spell-check (`lib/utils/answer_check.dart`)
   that folds French accents *and* Kabyle special letters, plus a Levenshtein
   typo tolerance — so kids without special keyboards still pass.

The **check-answer panel** (`lib/screens/lesson_screen.dart`) slides up green
for success (praise + sound) or red for failure (shows the correct answer,
plays a sound, **deducts a heart**). Wrong answers are requeued; running out of
hearts offers a gem refill or quit; finishing fires **confetti** and awards
XP + gems and unlocks the next lesson.

### Stage 4 — Audio, local storage & offline mode
- **`AudioService`** (`lib/services/audio_service.dart`):
  - **French** → on-device **Text-To-Speech** (`fr-FR`), slowed for clarity.
  - **Kabyle** → played **only** from real bundled recordings
    (`assets/audio/kab/<key>.mp3`); it is **never** spoken by a wrong-language
    voice (which would teach wrong pronunciation). Drop in native-speaker clips
    and they light up automatically. Until then Kabyle shows as text + Tifinagh.
  - Correct/wrong **feedback sounds** are synthesized tones bundled as assets —
    fully offline, no network.
- **Storage**: all progress, streaks, and unlocked lessons persist instantly in
  **Hive** (app-private). Curriculum is bundled. **No network calls anywhere.**

### Stage 5 — Build config & kid-safety
- Complete **`AndroidManifest.xml`**, `build.gradle.kts`, signing config, and
  ProGuard rules (see below).
- **COPPA-minded, offline-first**: see the next section.

---

## 🔒 Kid-safety / privacy (COPPA-minded)

- **Zero network permission in the release build.** The release
  `AndroidManifest.xml` declares **no permissions at all** — no `INTERNET`, no
  storage, no microphone, no camera. `INTERNET` exists *only* in the debug
  manifest (for Flutter hot-reload) and never ships.
- **No trackers, no analytics, no ads, no third-party SDKs** of any kind.
- **No data collection & no accounts.** Everything is stored locally in
  app-private storage; nothing ever leaves the device.
- `usesCleartextTraffic="false"`.

---

## Build the APK (one command, on a machine with the Android SDK)

Prerequisites: the [Flutter SDK](https://docs.flutter.dev/get-started/install)
and Android SDK (via Android Studio or `sdkmanager`) on a network that can reach
`dl.google.com` (the normal default).

```bash
# 1. Get dependencies
flutter pub get

# 2. (Optional) create a release keystore for a Play-Store-signable build.
#    Skip this and you still get an installable, debug-signed APK.
keytool -genkey -v -keystore kabylingo-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias kabylingo
#    Then create android/key.properties (git-ignored):
#      storeFile=../kabylingo-release.jks
#      storePassword=<your password>
#      keyAlias=kabylingo
#      keyPassword=<your password>

# 3. Build the release APK
flutter build apk --release

# Output:
#   build/app/outputs/flutter-apk/app-release.apk
```

Install it on a device with:

```bash
flutter install                       # to a connected device, or:
adb install build/app/outputs/flutter-apk/app-release.apk
```

Prefer smaller, per-architecture APKs (or an App Bundle for Play):

```bash
flutter build apk --release --split-per-abi      # 3 smaller APKs
flutter build appbundle --release                # .aab for Google Play
```

### Run it right now without Android (web)

```bash
flutter run -d chrome            # dev, or:
flutter build web --release      # then serve build/web/ with any static server
```

---

## Tests

```bash
flutter test        # 17 unit tests: gamification state, forgiving answer
                    # checking, and exercise generation.
```

## Project layout

```
lib/
  main.dart                     app bootstrap + provider wiring
  models/                       curriculum, exercises, learning direction, shop
  services/                     game state, progress, curriculum loader, audio
  screens/                      nav shell + Home/Progress/Shop/Profile + lesson
  widgets/                      stat badge, lesson node, 4 exercise views
  utils/answer_check.dart       forgiving spell-check
  theme/                        colors, theme, icon mapping
assets/
  curriculum/curriculum.json    the bidirectional curriculum (draft content)
  audio/sfx/                    synthesized correct/wrong tones
  audio/kab/                    (drop native-speaker Kabyle recordings here)
android/                        production build config + kid-safe manifest
test/                           unit tests
```

## Roadmap to a public release
1. **Validate all Kabyle content** with a fluent speaker (highest priority).
2. Record native-speaker Kabyle audio into `assets/audio/kab/`.
3. Expand the curriculum (more units/lessons/phrases).
4. Optional: enable R8 shrinking (`isMinifyEnabled = true` in
   `android/app/build.gradle.kts`) once tested on-device, and add real
   illustrations to complement the emoji.
