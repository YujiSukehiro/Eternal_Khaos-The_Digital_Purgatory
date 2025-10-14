Elevator pitch

A third-person action RPG that plays like a “tower run.” You enter an instanced floor, fight a boss with clear yet punishing mechanics, and if you die the character is gone forever. Combat blends the aggression and pace of a Berserker-style brawler with the readability of Lost Ark raids and the weight and clarity of Elden Ring. The signature mechanic is a high-skill parry-cancel into riposte that lets experts cut into enemy turns if they can read a split-second cue.

Core pillars

• Combat first. Every system serves responsiveness, timing, and clarity.
• Readable but ruthless bosses. Telegraphs are honest, punishments are real.
• Permadeath for the character, account-level cosmetics and small unlocks only.
• Greybox production. Placeholder visuals, high frame rate, fast iteration.
• Data-driven tuning so timing, stamina, poise, and windows are editable without code.

Player fantasy and feel

You are a fast, heavy melee fighter. Movement is grounded and deliberate. Dodges have a small band of invulnerability. Light chains are crisp, heavy hits are anchored and commit you. The camera supports a soft lock and clean target swapping. Hits land with short hit stop, a micro FOV pulse, and a tight sound set that makes successes pop and failures sting.

Signature mechanic: parry-cancel into riposte

Intention
Let skilled players interrupt their own attack to parry during a tiny enemy cue, then riposte into a guaranteed punish if they succeed.

Flow

Player begins an attack.

Boss begins an attack that contains a brief parryable cue. A subtle hue shift on the boss and a short floor ring appear for roughly one sixth of a second.

During the early portion of the player’s attack, a parry input will cancel the attack and start a fast parry.

If the parry’s active frames overlap the boss impact during the cue window, the boss is staggered and becomes ripostable for a short window.

Player confirms the riposte for a high-damage finisher, snapping to a defined weak point with a short, capped nudge so there is no foot sliding.

Accessibility option
An optional time-dilation pulse briefly slows global time at the instant a parryable cue appears. It widens human reaction space without changing correctness. Off by default, not intended for future multiplayer.

Anti-abuse guardrails
A small cooldown on the parry cancel prevents mashing. Some moves are explicitly unparryable and use a distinct telegraph language. Multi-hit strings either allow only the first hit to open a riposte or require perfect chained parries with diminishing return.

Boss design language

Each boss has three core moves in phase one and a phase shift around sixty percent health. Examples: a wide sweep that is always unparryable, a straight thrust that is the primary parryable move, and a vertical slam that produces a donut-shaped hazard. Telegraphs use simple shapes and emissive color rules. Parryable cues have one color and sound, unparryable attacks use another. The goal is instant recognition before mastery.

Level structure

The game is built around instanced floors rather than an open world. The vertical slice contains a single arena designed to showcase dodge lines, pillar line-of-sight breaks, and knockback risk near edges. Long term the tower has many floors with increasing complexity. A small hub exists later for matchmaking and social features, but the first milestone does not require it.

Progression and permadeath

When a character dies, that slot is erased. The account persists cosmetics, trophies, and narrow meta unlocks that widen options without overwhelming permadeath stakes. There is no exponential power creep across runs. The obituary records cause of death and time survived to make loss meaningful.

Systems overview

Inputs and buffering
Each action has a small input buffer so the game feels responsive without eating stray presses. Buffers only resolve during legal windows.

Movement and dodge
Sprint, stamina drain and regen with a short grace delay after heavy costs. Dodges last roughly a third of a second with invulnerability centered in the motion. Recovery is long enough that panic spamming loses to reading.

Attacks and hit logic
Light and heavy chains are authored animations or placeholders that toggle hitboxes only during active frames. Hit stop is very short and always tied to confirmed contact. Damage, stamina costs, and poise damage are data values.

Parry
Parry has startup, active, and recovery. Only overlaps during active count. Failures add a bit of extra recovery to prevent rolling the dice.

Poise and stagger
Both sides track poise. Heavy hits and perfect parries add poise damage. At threshold the target staggers; bosses that are staggered expose a defined riposte window.

Camera and lock
A soft lock prioritizes the target in front of the player and supports clean swaps. Camera collision avoids jitter and keeps silhouettes readable.

Feedback
Clarity beats flash. One-frame brighten on weapon trails at impact, concise camera shakes, and a consistent audio family. Parry cues have a crisp ping. Failed parries have a dull thud and a small controller buzz.

Readability rules

• Honest cones, rings, lines, and “pizza slices” on the floor for area attacks.
• Distinct emissive hue for parryable moments, never reused anywhere else.
• Anticipation, impact, and recovery are visually different so players can learn.

Data-driven tuning

All crucial timings and costs live in a simple data file. Examples
• Parry startup, active length, recovery
• Latest time you can parry-cancel out of your own attack
• Riposte window length
• Dodge duration and invulnerability bounds
• Stamina capacities and regen
• Per-attack damage and poise

This makes iteration fast and lets designers balance without code changes.

Production approach

Greybox first. Placeholder characters and free animation packs are fine. Use simple meshes and untextured materials for telegraphs. Target a locked sixty frames in the arena. Build tools and scripts that expose dials and log windows opening and closing. Expect several full days where the only output is better numbers.

Vertical slice definition of done

• Start to arena to win or loss back to start works every time.
• Dodge invulnerability prevents damage only inside the configured band.
• Parry-cancel to riposte is teachable within minutes and repeatable under pressure.
• The boss demonstrates at least one parryable move and one clearly unparryable check.
• The game holds a steady frame rate on the target machine.

Roadmap to the slice

Week one
Project scaffold, movement, stamina, dodge with invulnerability, soft lock camera, basic arena.

Week two
Light and heavy chains, hitboxes on animation events, hit stop and sound, first pass poise and stagger.

Week three
Parry with cancel from early attack frames, success opens riposte with a short nudge to target, failure recovery and logging.

Week four
Boss with three moves, distinct telegraphs, phase shift, minimal HUD, death and retry loop, tuning and capture.

Optional weeks five to six
Tutorial room, clean UI toggle for capture, performance sweep, small bug bash.

Risks and how you plan to handle them

Feel drift
Guard against it with explicit window logging, debug overlays for hitboxes and invulnerability, and a limited set of tunable dials.

Frustration from permadeath
Make deaths comprehensible. Provide replays or death summaries, keep telegraphs honest, and avoid random spikes.

Content treadmill
Invest in a boss authoring pipeline. Add moves by editing data and reuse timing scaffolds so design can ship without heavy engineering.

Networking later
The slice is single player. If you add cooperative play, resolve parry on the server with lag compensation and replay hit tests in a short rewind window.

What this prototype proves

• The combat loop is fun without art
• The parry-cancel into riposte mechanic creates a unique, learnable skill test
• Bosses are readable and fair while remaining deadly
• Permadeath creates stakes without requiring grindy progression

That is the essence of the project: a tuned, legible, high-stakes melee game where expert timing lets you steal turns and carve openings, and where every death teaches you something real.