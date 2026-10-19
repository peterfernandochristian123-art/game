class_name AttackData
extends Resource

## Data-Driven Attack Resource untuk Fighting to Zero (Story 3.1)
## Menyediakan definisi parameter jurus mandiri dalam format Godot .tres Resource

@export var attack_name: StringName = &"5L"
@export var startup: int = 5
@export var active: int = 3
@export var recovery: int = 8
@export var damage: int = 40
@export var hitstun: int = 14
@export var blockstun: int = 10
@export var knockback: float = 120.0
@export var heat_cost: float = 0.0
@export var is_energy: bool = false
@export var causes_ground_bounce: bool = false
@export var causes_wall_bounce: bool = false
@export var is_unblockable: bool = false
@export var is_grab: bool = false
@export var is_ledge_stomp: bool = false

## Tingkatan rantai serangan untuk Target Chain Cancel (1 = Normal 1, 2 = Normal 2, 3 = Skill, 4 = Ultimate)
@export var chain_level: int = 1

## Mengonversi Resource ke Dictionary yang kompatibel dengan sistem combat
func to_dict() -> Dictionary:
	return {
		"name": attack_name,
		"startup": startup,
		"active": active,
		"recovery": recovery,
		"damage": damage,
		"hitstun": hitstun,
		"blockstun": blockstun,
		"knockback": knockback,
		"heat_cost": heat_cost,
		"is_energy": is_energy,
		"causes_ground_bounce": causes_ground_bounce,
		"causes_wall_bounce": causes_wall_bounce,
		"is_unblockable": is_unblockable,
		"is_grab": is_grab,
		"is_ledge_stomp": is_ledge_stomp,
		"chain_level": chain_level
	}

static func from_dict(data: Dictionary) -> AttackData:
	var atk := AttackData.new()
	atk.attack_name = data.get("name", &"Normal")
	atk.startup = data.get("startup", 5)
	atk.active = data.get("active", 3)
	atk.recovery = data.get("recovery", 8)
	atk.damage = data.get("damage", 40)
	atk.hitstun = data.get("hitstun", 14)
	atk.blockstun = data.get("blockstun", 10)
	atk.knockback = data.get("knockback", 120.0)
	atk.heat_cost = data.get("heat_cost", 0.0)
	atk.is_energy = data.get("is_energy", false)
	atk.causes_ground_bounce = data.get("causes_ground_bounce", false)
	atk.causes_wall_bounce = data.get("causes_wall_bounce", false)
	atk.is_unblockable = data.get("is_unblockable", false)
	atk.is_grab = data.get("is_grab", false)
	atk.is_ledge_stomp = data.get("is_ledge_stomp", false)
	atk.chain_level = data.get("chain_level", 1)
	return atk
