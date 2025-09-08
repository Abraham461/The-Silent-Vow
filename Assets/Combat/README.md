# 2D Combat System

A comprehensive 2D combat system for Godot 4 with melee and ranged combat, hit detection, and visual feedback.

## Features

- **Melee Combat**: Dynamic hitboxes and hurtboxes with proper flipping
- **Ranged Combat**: Projectile system with team-based collision
- **Damage System**: Health management with damage calculation
- **Visual Feedback**: Hit effects, screen shake, and damage numbers
- **Team-Based Combat**: Prevent friendly fire with team filtering
- **Debug Visualization**: Visualize hitboxes and hurtboxes during development

## Core Components

### CombatEntity
Base class for all combat entities with health, hitbox/hurtbox management, and team support.

### CombatHitBox
Attack hitbox with damage calculation, knockback, and critical hits.

### CombatHurtBox
Vulnerable area that can receive damage with invincibility and counter hit support.

### Projectile
Ranged projectile with directional movement and team-based collision.

## Setup

1. Add combat components to your entities
2. Configure hitbox and hurtbox collision shapes
3. Set team identifiers to prevent friendly fire
4. Connect to signals for custom behavior

## Usage

### Player Combat
```gdscript
# Extend PlayerCombat for player-specific behavior
extends "res://Assets/Combat/PlayerCombat.gd"

func _ready():
	super._ready()
	# Custom player setup
```

### Enemy Combat
```gdscript
# Extend EnemyCombat for enemy-specific AI
extends "res://Assets/Combat/EnemyCombat.gd"

func _ready():
	super._ready()
	# Custom enemy setup
```

## Input Actions

- `Atk`: Melee attack
- `RangedAtk`: Ranged attack
- `Jump`: Jump
- `Roll`: Roll/dodge
- `Pray`: Special animation

## Documentation

See [CombatSystemDocumentation.md](CombatSystemDocumentation.md) for detailed information.

## Examples

Check [CombatDemo.tscn](CombatDemo.tscn) for a complete example scene.
