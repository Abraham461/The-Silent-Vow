# 2D Combat System Documentation

## Overview

This combat system provides a comprehensive framework for implementing 2D combat in Godot 4. It includes support for melee attacks, ranged attacks, hit detection, damage calculation, and visual feedback.

## Core Components

### 1. CombatEntity (Base Class)
The base class for all combat entities (players and enemies).

**Key Features:**
- Health management with damage calculation
- Hitbox/Hurtbox system with automatic flipping
- Team-based combat support
- Invincibility frames
- Knockback resistance
- Debug visualization support
- Ranged combat support with projectiles

**Properties:**
- `max_health`: Maximum health points
- `current_health`: Current health points
- `base_defense`: Damage reduction value
- `invincibility_duration`: Duration of invincibility after taking damage
- `knockback_resistance`: Resistance to knockback (0.0 to 1.0)
- `team`: Team identifier for team-based combat
- `show_debug_visuals`: Enable debug visualization

### 2. CombatHitBox
Represents an attack hitbox that can damage other entities.

**Key Features:**
- Damage calculation with critical hits
- Knockback force application
- Team-based collision filtering
- Automatic activation/deactivation
- Attack type classification

**Properties:**
- `base_damage`: Base damage value
- `knockback_force`: Knockback force applied to targets
- `attack_type`: Type of attack (normal, heavy, special)
- `critical_chance`: Chance of critical hit
- `critical_multiplier`: Damage multiplier for critical hits
- `team`: Team this hitbox belongs to

### 3. CombatHurtBox
Represents a vulnerable area that can receive damage.

**Key Features:**
- Damage reception with multipliers
- Invincibility state management
- Team-based collision filtering
- Counter hit support
- Duplicate hit prevention

**Properties:**
- `damage_multiplier`: Damage multiplier for this hurtbox
- `can_be_hit`: Whether this hurtbox can be hit
- `counter_hit_multiplier`: Damage multiplier for counter hits

### 4. Projectile
Base class for ranged projectiles.

**Key Features:**
- Directional movement
- Team-based collision filtering
- Piercing support
- Lifetime management
- Visual effects support

**Properties:**
- `speed`: Movement speed
- `damage`: Damage value
- `team`: Team this projectile belongs to
- `lifetime`: Time before expiration
- `pierce_count`: Number of targets that can be hit

## Usage Examples

### Creating a Player Combat Entity

```gdscript
extends CombatEntity

# Set up player-specific properties
func _ready():
	super._ready()
	max_health = 100
	current_health = 100
	team = 0  # Player team
```

### Creating an Enemy Combat Entity

```gdscript
extends CombatEntity

# Set up enemy-specific properties
func _ready():
	super._ready()
	max_health = 50
	current_health = 50
	team = 1  # Enemy team
```

### Firing a Projectile

```gdscript
# In a combat entity
var projectile_scene = preload("res://Assets/Combat/Projectile.tscn")
var direction = Vector2.RIGHT

# Fire projectile
var projectile = fire_projectile(projectile_scene, direction, 200, 10)
```

### Handling Damage

```gdscript
# Override take_damage to customize behavior
func take_damage(damage: int, attacker: Node = null, knockback_force: Vector2 = Vector2.ZERO):
	# Call parent implementation
	super.take_damage(damage, attacker, knockback_force)
	
	# Add custom behavior (e.g., screen shake, sound effects)
	if combat_effects:
		combat_effects.play_hit_effect(damage, global_position)
```

## Input Handling

The system supports the following input actions:
- `Atk`: Melee attack
- `RangedAtk`: Ranged attack
- `Jump`: Jump
- `Roll`: Roll/dodge
- `Pray`: Special animation

## Visual Feedback

The system includes several visual feedback mechanisms:
- Hit flash effect
- Screen shake
- Hit stop (freeze frame)
- Damage numbers
- Particle effects
- Death animations

## Team-Based Combat

Entities can belong to different teams to prevent friendly fire:
- Team 0: Player
- Team 1: Enemies
- Team 2: Neutrals

Hitboxes and hurtboxes automatically filter collisions based on team membership.

## Debug Features

Enable `show_debug_visuals` to visualize hitboxes and hurtboxes during development.

## Extending the System

### Adding New Attack Types

1. Create a new attack type in CombatHitBox
2. Modify damage calculation logic
3. Add visual effects for the new attack type

### Adding New Entity Types

1. Extend CombatEntity
2. Override relevant methods
3. Add entity-specific properties and behaviors

### Customizing Visual Effects

1. Modify CombatEffects class
2. Add new effect methods
3. Override effect methods in specific entities

## Performance Considerations

- Use object pooling for projectiles
- Limit the number of active hitboxes
- Optimize collision shapes
- Use efficient visual effects

## Troubleshooting

### Hitboxes Not Detecting Collisions
- Ensure hitbox and hurtbox are in the correct groups
- Check team settings for collision filtering
- Verify collision shapes are properly configured

### Visual Effects Not Appearing
- Check if CombatEffects node is present
- Verify sprite references are correct
- Ensure camera is properly configured

### Performance Issues
- Reduce number of active projectiles
- Optimize animation complexity
- Limit visual effect duration
