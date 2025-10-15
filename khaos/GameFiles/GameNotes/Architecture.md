# Khaos - Technical Architecture

## Project Structure

```
khaos/
├── GameFiles/
│   ├── SRC/                    # Main game source code
│   │   ├── Player/             # Player character systems
│   │   │   ├── Scenes/         # Player scene files (.tscn)
│   │   │   └── Scripts/        # Player scripts (.gd)
│   │   ├── Combat/             # Combat mechanics and systems (PLANNED)
│   │   ├── Bosses/             # Boss entities and AI
│   │   │   ├── Scenes/         # Boss scene files
│   │   │   └── Scripts/        # Boss scripts
│   │   ├── Arena/              # Level/arena management
│   │   │   ├── Scenes/         # Arena scene files
│   │   │   └── Scripts/        # Arena management scripts
│   │   ├── UI/                 # User interface (PLANNED)
│   │   ├── Data/               # Data-driven configuration files (PLANNED)
│   │   └── Utils/              # Shared utilities and helpers (PLANNED)
│   └── GameNotes/              # Documentation and design docs
├── addons/                     # Third-party addons
└── demo/                       # Reference implementations

```

## Current Implementation Status

### ✅ Implemented Systems

#### Player Controller System
**Files**:
- `SRC/Player/Scripts/Player.gd` - Basic player class with state machine
- `SRC/Player/Scripts/PlayerController.gd` - Enhanced controller with full combat
- `SRC/Player/Scripts/InputManager.gd` - Comprehensive input mapping

**Current Features**:
- Full state machine (IDLE, MOVING, SPRINTING, JUMPING, FALLING, DODGING, ATTACKING, PARRYING, STUNNED, DEAD)
- Stamina system with drain/regeneration
- Health system with damage handling
- Movement with walk/sprint speeds
- Dodge mechanics with invulnerability frames (0.25s invuln, 0.4s total duration)
- Light/Heavy attack system with combo counter
- Camera control (mouse + gamepad support)
- Target lock system (foundation implemented)

#### Boss/Enemy System
**Files**:
- `SRC/Bosses/Scripts/Boss.gd` - Base boss class with combat mechanics

**Current Features**:
- Health and poise (stagger) system
- Three-phase boss system (transitions at 60% and 30% HP)
- Damage calculation with defense values
- Visual feedback system (hit flashes, damage numbers)
- Stagger mechanics when poise depleted
- Death animations and cleanup
- Proper hitbox detection for player attacks

#### Arena Management
**Files**:
- `SRC/Arena/Scripts/ArenaManager.gd` - Arena state and boundary management

**Current Features**:
- Player and boss spawn points
- Arena boundary detection and clamping
- Combat state management
- Phase change system for environmental effects
- Distance-to-edge calculations

### 🚧 Partially Implemented

#### Animation System
- AnimationPlayer references exist but no animations defined
- Animation callback methods ready (`_on_attack_hit_start`, `_on_attack_hit_end`)
- Model hierarchy established (`$Model`, `$Model/WeaponPivot`)

#### Character Model
- Basic geometric placeholder (likely capsule/cylinder)
- Model node structure in place
- No skeletal rig or bone system yet
- Weapon attachment point exists

### ❌ Not Yet Implemented

- Character skeletal rig and bones
- Hand/arm IK system
- Visual animations for attacks/movement
- UI systems (health bars, stamina bars for player)
- Data configuration files (.tres resources)
- Combat hitbox visualizations
- Behavior trees for boss AI (Beehave addon planned)
- Dialogue system
- Save/load system

## Core Systems

### 1. Player Controller (IMPLEMENTED)
- **Location**: `SRC/Player/`
- **Implementation Files**:
  - `Scripts/PlayerController.gd` - Main player controller
  - `Scripts/Player.gd` - Basic player class
  - `Scripts/InputManager.gd` - Input mapping and handling
- **Components**:
  - ✅ Movement controller (sprint, walk, dodge)
  - ✅ Stamina system with regeneration
  - ⚠️ Input buffer manager (partial - buffer windows planned)
  - ✅ State machine for player states
  - ✅ Camera control system
  - ✅ Health and damage system

### 2. Combat System (PARTIAL)
- **Location**: `SRC/Combat/` (folder structure planned)
- **Currently Integrated in**: `SRC/Player/Scripts/PlayerController.gd`
- **Key Features**:
  - ✅ Attack chain system (light/heavy with combo counter)
  - ⚠️ Parry-cancel mechanic (foundation exists, not fully implemented)
  - ❌ Riposte system (planned)
  - ⚠️ Hitbox management (basic implementation, needs visualization)
  - ✅ Damage calculation with metadata
  - ✅ Poise/stagger tracking (implemented in Boss.gd)

### 3. Boss System (IMPLEMENTED)
- **Location**: `SRC/Bosses/`
- **Implementation Files**:
  - `Scripts/Boss.gd` - Base boss class
  - `Scenes/BasicBoss.tscn` - Boss scene file
- **Architecture**:
  - ✅ Base boss class with shared mechanics
  - ⚠️ Individual boss implementations (base class ready for extension)
  - ❌ Telegraph system for attack readability (planned)
  - ✅ Phase transition management (3 phases at 100%, 60%, 30% HP)
  - ❌ AI behavior trees (Beehave addon planned)
- **Current Features**:
  - Health system with visual feedback
  - Poise/stagger system
  - Damage numbers display
  - Hit flash effects
  - Phase change visual effects

### 4. Camera System (PARTIAL)
- **Location**: Integrated in `SRC/Player/Scripts/PlayerController.gd`
- **Features**:
  - ✅ Mouse and gamepad camera control
  - ⚠️ Soft-lock targeting (foundation exists)
  - ❌ Target switching (planned)
  - ❌ Collision avoidance (planned)
  - ❌ Phantom Camera addon integration (planned)

### 5. Data Management (NOT IMPLEMENTED)
- **Location**: `SRC/Data/` (planned)
- **Purpose**: External configuration for all timing and balance values
- **Planned Files**:
  - ❌ `combat_config.tres` - Attack timings, damage values
  - ❌ `player_config.tres` - Movement speeds, stamina values
  - ❌ `boss_config.tres` - Boss-specific parameters
  - ❌ `parry_config.tres` - Parry windows and riposte settings
- **Current State**: All values are hardcoded in scripts with @export variables

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

### Beehave (Behavior Trees) - NOT YET INTEGRATED
- **Usage**: Boss AI decision making
- **Planned Location**: Boss behavior trees in `SRC/Bosses/BehaviorTrees/`
- **Pattern**: Each boss will have a `.tres` behavior tree resource
- **Current Status**: Boss AI is currently hardcoded, awaiting Beehave integration

### Phantom Camera - NOT YET INTEGRATED
- **Usage**: Advanced camera transitions and targeting
- **Planned Integration**: Wrapped in our camera controller for soft-lock logic
- **Current Status**: Basic camera system implemented in PlayerController

### gdUnit4 - NOT YET INTEGRATED
- **Usage**: Unit testing for combat mechanics
- **Planned Test Location**: `SRC/Tests/`
- **Coverage Goals**: Parry windows, hitbox activation, state transitions
- **Current Status**: No unit tests implemented

### Dialogue Manager - NOT YET INTEGRATED
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

### Implemented Debug Features
- ✅ State display (Label3D showing current player state)
- ✅ Health/Stamina display in debug label
- ✅ Damage number display (floating text on boss)
- ✅ Console output for state changes and damage

### Planned Debug Features
- ❌ Hitbox visualization overlays
- ❌ Frame data logger
- ❌ Parry window indicators
- ❌ State machine visualizer
- ❌ Input buffer display

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

## Character Model & Animation System

### Current Model Status
- **Player Model**: Basic geometric placeholder (capsule/cylinder)
- **Node Structure**:
  ```
  Player (CharacterBody3D)
  ├── Model (Node3D)
  │   ├── MeshInstance3D
  │   └── WeaponPivot
  │       └── Sword
  │           └── AttackHitbox (Area3D)
  ├── CameraMount (Node3D)
  │   └── SpringArm3D
  │       └── Camera3D
  ├── StateDebugLabel (Label3D)
  └── AnimationPlayer
  ```

### Animation System Readiness
- **AnimationPlayer**: Node exists but no animations defined
- **Animation Callbacks**: Methods implemented for attack timing
  - `_on_attack_hit_start()` - Enables attack hitbox
  - `_on_attack_hit_end()` - Disables attack hitbox
- **State-to-Animation Mapping**: Ready in state machine but awaiting animations

### Next Steps for Posable Hands/Arms
1. **Skeleton Setup**:
   - Add Skeleton3D node to Model
   - Create bone hierarchy for arms/hands
   - Set up rest poses

2. **IK Implementation**:
   - Add IK chains for each arm
   - Create hand pose presets (idle, fist, open, grip)
   - Implement dynamic hand positioning

3. **Animation Integration**:
   - Create attack animations with hand poses
   - Add procedural adjustments for weapon gripping
   - Implement finger animations for gestures

4. **State Integration**:
   - Link hand poses to player states
   - Add smooth transitions between poses
   - Implement combat-specific hand positions

## Key Implementation Values

### Movement
- **Walk Speed**: 5.0 units/s
- **Sprint Speed**: 8.0 units/s
- **Dodge Speed**: 12.0 units/s
- **Jump Velocity**: 8.0
- **Acceleration**: 10.0
- **Friction**: 10.0

### Combat
- **Light Attack Damage**: 20.0
- **Heavy Attack Damage**: 40.0
- **Light Attack Stamina**: 10.0
- **Heavy Attack Stamina**: 20.0
- **Dodge Stamina Cost**: 20.0
- **Dodge Duration**: 0.4s
- **Dodge Invulnerability**: 0.25s

### Boss Stats
- **Boss Max Health**: 500.0
- **Boss Defense**: 5.0
- **Boss Max Poise**: 100.0
- **Phase 2 Threshold**: 60% HP
- **Phase 3 Threshold**: 30% HP
- **Stagger Duration**: 2.0s

## Open Questions
- Exact input buffer duration values (currently immediate response)
- Optimal state machine architecture (currently flat)
- Resource loading strategy for bosses
- Save system for account-level progression
- Skeletal rig source (custom vs asset store)
- IK solver choice (built-in vs third-party)

---
*This document is a living reference and will be updated as implementation progresses.*
*Last Updated: Added current implementation status and character model details*