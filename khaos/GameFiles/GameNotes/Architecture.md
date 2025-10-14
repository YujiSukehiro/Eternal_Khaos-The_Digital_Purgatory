# Khaos - Technical Architecture

## Project Structure

```
khaos/
├── GameFiles/
│   ├── SRC/                    # Main game source code
│   │   ├── Player/             # Player character systems
│   │   ├── Combat/             # Combat mechanics and systems
│   │   ├── Bosses/             # Boss entities and AI
│   │   ├── Arena/              # Level/arena management
│   │   ├── UI/                 # User interface
│   │   ├── Data/               # Data-driven configuration files
│   │   └── Utils/              # Shared utilities and helpers
│   └── GameNotes/              # Documentation and design docs
├── addons/                     # Third-party addons
└── demo/                       # Reference implementations

```

## Core Systems

### 1. Player Controller
- **Location**: `SRC/Player/`
- **Components**:
  - Movement controller (sprint, walk, dodge)
  - Stamina system
  - Input buffer manager
  - State machine for player states

### 2. Combat System
- **Location**: `SRC/Combat/`
- **Key Features**:
  - Attack chain system (light/heavy)
  - Parry-cancel mechanic
  - Riposte system
  - Hitbox management
  - Damage calculation
  - Poise/stagger tracking

### 3. Boss System
- **Location**: `SRC/Bosses/`
- **Architecture**:
  - Base boss class with shared mechanics
  - Individual boss implementations
  - Telegraph system for attack readability
  - Phase transition management
  - AI behavior trees (using Beehave addon)

### 4. Camera System
- **Location**: `SRC/Player/Camera/`
- **Features**:
  - Soft-lock targeting
  - Target switching
  - Collision avoidance
  - Integration with Phantom Camera addon

### 5. Data Management
- **Location**: `SRC/Data/`
- **Purpose**: External configuration for all timing and balance values
- **Files**:
  - `combat_config.tres` - Attack timings, damage values
  - `player_config.tres` - Movement speeds, stamina values
  - `boss_config.tres` - Boss-specific parameters
  - `parry_config.tres` - Parry windows and riposte settings

## Technical Decisions

### Input Handling
- Centralized input buffer system with configurable window sizes
- Actions queued during illegal states are discarded
- Small buffer windows (~100-200ms) for responsive feel

### State Management
- Hierarchical state machines for both player and bosses
- States handle their own transitions and validity checks
- Clear separation between animation states and gameplay states

### Combat Frame Data
- All hitboxes are frame-activated, not duration-based
- Hit confirmation happens on exact frame overlap
- Data-driven frame windows for easy tuning

### Visual Feedback Rules
- Parryable attacks: Blue emissive tint + floor ring
- Unparryable attacks: Red emissive tint + distinct audio cue
- Area attacks: Floor projections (cones, rings, lines)
- Hit confirmation: 1-frame white flash + micro camera shake

## Addon Integration

### Beehave (Behavior Trees)
- **Usage**: Boss AI decision making
- **Location**: Boss behavior trees in `SRC/Bosses/BehaviorTrees/`
- **Pattern**: Each boss has a `.tres` behavior tree resource

### Phantom Camera
- **Usage**: Advanced camera transitions and targeting
- **Integration**: Wrapped in our camera controller for soft-lock logic

### gdUnit4
- **Usage**: Unit testing for combat mechanics
- **Test Location**: `SRC/Tests/`
- **Coverage Goals**: Parry windows, hitbox activation, state transitions

### Dialogue Manager
- **Future Usage**: Tutorial system, death summaries
- **Current Status**: Not yet implemented

## Performance Targets
- **Frame Rate**: Locked 60 FPS in arena
- **Input Latency**: < 1 frame from input to animation start
- **Loading**: < 2 seconds from death to retry

## Data-Driven Design Philosophy

All gameplay-critical values are external to code:
- Animation frame windows
- Damage and poise values
- Movement speeds and acceleration
- Stamina costs and regeneration rates
- Parry and riposte windows
- Boss phase thresholds

This enables rapid iteration without recompilation and allows designers to tune feel independently.

## Coding Standards

### GDScript Conventions
- Use static typing where possible
- Signal names in SCREAMING_SNAKE_CASE
- Private methods prefixed with underscore
- Resource files use `.tres` format for human readability

### Scene Organization
- One scene file per major component
- Inherited scenes for variants (e.g., different bosses)
- UI scenes separate from gameplay scenes

### Node Naming
- PascalCase for all nodes
- Descriptive names (PlayerHitbox not Hitbox2)
- Group nodes logically in the scene tree

## Debug Systems

### Planned Debug Features
- Hitbox visualization overlays
- Frame data logger
- Parry window indicators
- State machine visualizer
- Input buffer display
- Damage number display

## Version Control Notes
- Binary files (.tscn, .tres) may cause merge conflicts
- Prefer external resource files over inline resources
- Keep scenes small and modular

## Future Considerations

### Multiplayer Architecture (Post-MVP)
- Server-authoritative combat
- Client-side prediction for movement
- Rollback for parry validation
- Lag compensation window (~150ms)

### Content Pipeline
- Boss authoring tools
- Attack pattern editor
- Telegraph shape library
- Automated testing for boss patterns

## Open Questions
- Exact input buffer duration values
- Optimal state machine architecture (flat vs hierarchical)
- Resource loading strategy for bosses
- Save system for account-level progression

---
*This document is a living reference and will be updated as implementation progresses.*