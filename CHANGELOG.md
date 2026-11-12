# Changelog

All notable changes to this project will be documented in this file.

---

## [1.1.0+2] - 2026-06-11

### Added
- **Premium English Voice-overs**: Generated 30 natural, high-quality narration voice-overs using `edge-tts` (US voices: Ava for Horror, Brian for History, Guy for Comedy) saved in `assets/audio/narration/en/`.
- **Concurrent Ambient Audio Loops**: Added a new background audio layer (`_ambientPlayer`) looping weather/pads (e.g., wind for horror, ticking clock for history, synth hum for comedy) at a quiet `_bgmVolume * 0.25` level, maintaining immersion when dynamic BGMs fade or stop.
- **PlayStation-Style Achievement Toast**: Redesigned achievement notifications to animate and slide up from the bottom-center as a sleek capsule with PS5 blue accents, gold trophy badge, and a dynamic reward chime (`coin_reward.mp3`).
- **Environmental Screen Particle Overlays**: Implemented dynamic 60fps particle overlay shaders (drifting red/black mist for horror, golden rising sparks/diamonds for history, twinkling stars for comedy) optimized with `AnimatedBuilder` to bypass rebuilding the child screen.
- **3D Parallax Cover Cards**: Added a `ParallaxCard` widget in the library screen that tilts card graphics in 3D based on gesture touch coordinates (mobile) or mouse hover (web/desktop).
- **Interactive AR Model Sounds & Haptics**: Integrated medium physical haptic feedback and thematic sound chimes (coins, clock warp, pickup) when unlocking or tapping containers in the AR view.

### Changed
- **Typewriter Subtitle Syncing**: Overhauled the dynamic typing engine to compute character speeds from active narration duration, clamped between `15ms` and `120ms` for seamless reading pace.
- **Smooth BGM Volume Fading**: Implemented a 300ms volume fader to smoothly dim music during narration play and return it to full volume afterward.
- **Custom Launcher Icons**: Replaced default mobile launcher icons on Android (`mipmap-*` folders) and iOS (`AppIcon.appiconset`) with a custom magical book 3D design.
- **Arabic Stories Audio Sync**: Realigned Arabic script text nodes in `horror_crypt.json`, `history_timetravel.json`, and `comedy_treasure.json` to match the new spoken Arabic voice narrations.
- **Arabic Narration Audio Files**: Updated and replaced all spoken Arabic narration audio files in `assets/audio/narration/ar/` with the latest voice-over recordings.


### Fixed
- Fixed layout overflows in dynamic theme switching.
- Resolved compilation issues regarding non-existent color properties (`Colors.black85`).

---

## [1.0.0+1] - Initial Release

### Added
- **Clean Architecture Directory Structure**:
  - `core/`: Configured base application configurations, theme setups, localization translations, and local database services.
  - `data/`: Created JSON-based story parser (`StoryLocalDataSource`) and repositories to load regional script files dynamically.
  - `domain/`: Built immutable type-safe entities (`Story`, `StoryNode`, `Choice`, `PlayerState`, `SaveSlot`, `GlobalSaveState`).
  - `presentation/`: Implemented BLoC/Cubit state management (`LanguageCubit`, `ThemeCubit`, `SaveCubit`, `StoryCubit`) and adaptive RTL/LTR layout builder.
- **Multi-Branch Interactive Story Engine**:
  - Branching decision trees with conditional pathways based on active inventory, stats checks (Fear, Health), and locked states.
  - Timed choice events (Quick-Time Events / QTE) displaying interactive countdown overlays.
- **Augmented Reality (AR) Interactive Scanner Screen**:
  - Implemented 3D `.glb` assets rendering inside an AR camera scanner framework (`ar_view_screen.dart`).
  - Tapping interactive models (comedy box, sphinx medallion, horror chest) triggers state changes and item additions to player inventories.
- **Save Slot Cache & Settings Management**:
  - Developed custom `SaveCubit` and `SaveService` leveraging `SharedPreferences` to manage 3 independent manual save slots plus auto-save cache.
  - Keeps track of global user profiles containing ticket balances, unlocked stories, and unlocked gameplay milestones.
- **Interactive Endings Flowchart Screen**:
  - Visual hierarchy flow tree maps showing user endings, story checkpoints, and locked/unlocked nodes.
  - Integrated "Time Rewind" features allowing users to spend game tickets to go back and retry checkpoints from flowchart view.
- **Trophy Achievement System**:
  - Dedicated trophy screen displaying list of locked/unlocked achievement cards, checking criteria from user data.
- **Dynamic Genre-Based UI Themes**:
  - Configured dark-mode gradients, modern typography, and custom icons adapting dynamically based on story genre (Horror red, History bronze, Comedy gold).

