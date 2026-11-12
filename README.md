# 🎮 Nexus 3D — Interactive Branching Storyscapes & Narrative Engine

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![Architecture](https://img.shields.io/badge/Architecture-BLoC%20%2F%20Cubit-teal)](#)
[![3D Engine](https://img.shields.io/badge/Engine-Native%203D%20Scenes-blueviolet)](#)

> **Next-Generation Interactive Fiction Platform**: Real-time branching narrative trees, 3D ambient game scenes, multi-ending discovery visualizers, glassmorphism UI, and gamified player progression.

---

## 🏛️ System Architecture

```mermaid
graph TD
    UI[Presentation Layer] --> State[BLoC / Cubit Orchestrator]
    
    subgraph "Visual & Audio Experience"
        UI --> Scene3D[Native 3D Scene View]
        UI --> StoryEngine[Dynamic Typewriter Storyteller]
        UI --> Flowchart[Interactive Endings Flowchart Screen]
        UI --> FX[Visual Effect Overlays & Haptics]
    end

    subgraph "State & Business Logic"
        State --> StoryCubit[StoryCubit - Choice Matrix]
        State --> SaveCubit[SaveCubit - Persistent Checkpoints]
        State --> AuthCubit[AuthCubit - Player Identity]
    end

    subgraph "Data & Persistence"
        State --> Repo[Story & Game Repositories]
        Repo --> Local[(Local Encrypted Storage)]
        Repo --> Remote[(Cloud Story Registry)]
    end
```

---

## 🌟 Key Features

1. **Dynamic Narrative Branching Matrix**:
   - Complex decision trees where every player choice alters narrative vectors, unlocking hidden paths and divergent outcomes.
   - Real-time flowchart visualizer (`EndingsFlowchartScreen`) displaying completed and locked story endings.

2. **Native 3D Scene Integration (`Native3DSceneWidget`)**:
   - Embedded 3D viewport delivering environmental immersion and interactive spatial props.

3. **Modern Visual Aesthetics**:
   - Custom Glassmorphism design system (`GlassContainer`) with fluid ambient particle animations.
   - Paced typewriter dialog rendering (`TypewriterText`) with auditory punctuation cues.

4. **Robust Clean Architecture**:
   - Clear separation of concerns: Presentation (Cubits/Screens), Domain (Entities/Contracts), and Data (Local/Remote datasources).
   - Instant checkpoint recovery (`SaveService`) preserving player inventory, karma score, and unlocked paths.

---

## 🛠️ Build & Run

### 1. Prerequisites
- Flutter SDK 3.16+
- Android Studio / VS Code

### 2. Setup
```bash
flutter pub get
flutter run
```
