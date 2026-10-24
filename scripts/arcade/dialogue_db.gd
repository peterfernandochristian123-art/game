class_name DialogueDB
extends RefCounted

## Basis Data Dialog & Lore Arcade Gauntlet (Story 15.2 & 15.4)
## Menyediakan dialog clash sebelum bertanding, kutipan kemenangan pasca ronde,
## dan epilog naratif untuk setiap petarung saat menaklukkan Unit-0.

const PORTRAITS: Dictionary = {
	&"viper": {
		"name": "APEX-0 VIPER",
		"title": "The Phantom Blade of Orbit",
		"theme_color": Color(0.2, 0.95, 1.0, 1.0),
		"bust_symbol": "⚡"
	},
	&"bulwark": {
		"name": "TITAN-V BULWARK",
		"title": "The Iron Juggernaut",
		"theme_color": Color(1.0, 0.5, 0.15, 1.0),
		"bust_symbol": "⚓"
	},
	&"pulsar": {
		"name": "RAY-X PULSAR",
		"title": "The Solar Technomancer",
		"theme_color": Color(0.75, 0.35, 1.0, 1.0),
		"bust_symbol": "☀️"
	},
	&"kage": {
		"name": "PHANTOM-9 KAGE",
		"title": "The Shadow Shinobi",
		"theme_color": Color(0.95, 0.15, 0.25, 1.0),
		"bust_symbol": "刃"
	},
	&"unit_zero": {
		"name": "UNIT-0 SHADOW CORE",
		"title": "Unbound Overclock Proto-Core",
		"theme_color": Color(1.0, 0.1, 0.2, 1.0),
		"bust_symbol": "☠"
	}
}

const MATCHUP_INTROS: Dictionary = {
	# P1: Viper
	"viper_vs_bulwark": {
		"p1": "Target locked. You won't even see the blade strike.",
		"p2": "Steel against flesh! Let's see how long your fancy chrome lasts!"
	},
	"viper_vs_pulsar": {
		"p1": "Cryogenic blade primed. Your photons won't pierce absolute zero.",
		"p2": "Align your mind with the solar light. The duel begins."
	},
	"viper_vs_kage": {
		"p1": "A fellow blade in the dark. Only one shadow leaves this platform.",
		"p2": "Speed without silence is merely noise, Viper. Prepare to be erased."
	},

	# P1: Bulwark
	"bulwark_vs_viper": {
		"p1": "Buzzing around won't save you, mosquito! Stand still and take a hit!",
		"p2": "Heavy armor just makes a bigger target. Initiating dissection."
	},
	"bulwark_vs_pulsar": {
		"p1": "Keep shooting your fireworks, monk! My shields eat lasers for breakfast!",
		"p2": "Brute force without harmony is like stone against solar flare. Yield."
	},
	"bulwark_vs_kage": {
		"p1": "Quit hiding in the smoke and fight like a real machine of iron!",
		"p2": "The bigger the colossus, the deeper the katana carves."
	},

	# P1: Pulsar
	"pulsar_vs_viper": {
		"p1": "Cold cannot extinguish true illumination. Witness the photon matrix.",
		"p2": "Your light casts long shadows. That's where I strike."
	},
	"pulsar_vs_bulwark": {
		"p1": "Your geothermal heart trembles. Find balance or be dispersed.",
		"p2": "Geothermal power built this city, Shen! Time to test your faith!"
	},
	"pulsar_vs_kage": {
		"p1": "Deception cannot hide from the dawn of pure solar harmony.",
		"p2": "Even the brightest sun casts shadows, Master. Step into mine."
	},

	# P1: Kage
	"kage_vs_viper": {
		"p1": "Dual stance calibrated. Show me the reach of your rapier.",
		"p2": "You'll find my cryogenic thrust arrives faster than your feint."
	},
	"kage_vs_bulwark": {
		"p1": "Heavy hydraulics are loud. I can hear your gears grinding from a mile away.",
		"p2": "Come close enough to hear them, ninja, and I'll crush you into scrap!"
	},
	"kage_vs_pulsar": {
		"p1": "Your floating drones will make fine shuriken practice.",
		"p2": "Illusion crumbles before true clarity. Draw your sword."
	},

	# Final Boss Intros (vs Unit-0)
	"viper_vs_unit_zero": {
		"p1": "The syndicate's rogue prototype... Absolute Zero Protocol engaged!",
		"p2": "ERROR 000: OVERCLOCK PROTOCOL UNBOUND. PURGING ALL LIFE."
	},
	"bulwark_vs_unit_zero": {
		"p1": "I've hammered runaway magma drills tougher than you, rustbucket!",
		"p2": "THERMAL RUNAWAY 99.9%. TARGET DESIGNATED: INDUSTRIAL TRASH."
	},
	"pulsar_vs_unit_zero": {
		"p1": "Your unstable reactor threatens the megalopolis. Return to harmony!",
		"p2": "CORE OVERRIDE. HARMONY REJECTED. CATACLYSM IMMINENT."
	},
	"kage_vs_unit_zero": {
		"p1": "A mindless phantom machine. Time to sever your neural circuits.",
		"p2": "ANOMALY DETECTED. EXECUTE TSUKUYOMI COUNTERMEASURE."
	}
}

const VICTORY_QUOTES: Dictionary = {
	&"viper": [
		"Absolute zero achieved. System deactivated.",
		"Too slow. The blade was already sheathed before you fell.",
		"Reflexes augmented to perfection. You never stood a chance."
	],
	&"bulwark": [
		"Down for the count! That's the power of industrial iron!",
		"Four tons of hydraulic steel doesn't bend for anyone!",
		"Tell the orbital syndicate that Marcus Vance still holds the floor!"
	],
	&"pulsar": [
		"The light disperses all darkness. Walk the path of balance.",
		"Solar harmony maintained. May your circuits find tranquility.",
		"Focus and precision transcend mere metal."
	],
	&"kage": [
		"Dust to dust, shadow to shadow. You were outmaneuvered.",
		"The katana speaks in silence. Your technique was found wanting.",
		"A dance of blades ended in a heartbeat."
	],
	&"unit_zero": [
		"ERROR: INSUFFICIENT BIOMASS RESISTANCE. PURGE CONTINUES."
	]
}

const EPILOGUES: Dictionary = {
	&"viper": {
		"headline": "THE ABSOLUTE ZERO ASCENSION",
		"body": "With Unit-0 shattered and its corrupted core frozen into inert cryo-crystals, Ren Hayabusa severs the syndicate's master orbital link. The Phantom Blade of Orbit melts back into the glowing neon skyline of New Babel-01, leaving behind only the legend of the champion who defied the corporate gods."
	},
	&"bulwark": {
		"headline": "THE IRON REIGN OF THE UNDER-CORE",
		"body": "Marcus Vance drives his hydraulic fists through the final overclock core with an earth-shaking piledriver. From the subterranean geothermal depths to the highest orbital towers, the roar of the working class echoes across the city. The arena belt belongs to the Under-Core at last."
	},
	&"pulsar": {
		"headline": "SOLAR HARMONY RESTORED",
		"body": "Master Kaelen Shen channels the dispersing thermal storm into harmonious solar currents, calming the volatile energy grid of New Babel-01. As dawn breaks over the 2,500m stratosphere temple, the eternal flame burns brighter than ever before."
	},
	&"kage": {
		"headline": "THE SHADOW DISPERSAL",
		"body": "Phantom-9 Kage calmly sheathes the crimson katana as Unit-0 dissolves into glowing crimson embers. Without claiming fame or trophy, the ninja fades into the digital darknet—the silent protector awaiting the next tremor beneath the steel megalopolis."
	}
}

static func get_matchup_intro(p1_id: StringName, p2_id: StringName) -> Dictionary:
	var key := "%s_vs_%s" % [p1_id, p2_id]
	if MATCHUP_INTROS.has(key):
		return MATCHUP_INTROS[key]

	# Default fallback intro
	return {
		"p1": "Prepare your circuits. The Zero-G arena awaits!",
		"p2": "Commencing duel protocol. Show me what you've got!"
	}

static func get_random_victory_quote(char_id: StringName) -> String:
	if VICTORY_QUOTES.has(char_id):
		var list: Array = VICTORY_QUOTES[char_id]
		if list.size() > 0:
			return list[randi() % list.size()]
	return "Victory achieved. Superior combat parameters confirmed."

static func get_epilogue(char_id: StringName) -> Dictionary:
	if EPILOGUES.has(char_id):
		return EPILOGUES[char_id]
	return {
		"headline": "THE ZERO GLADIATOR CHAMPION",
		"body": "Through relentless combat against the greatest mecha warriors in New Babel-01, the pilot stands victorious at the summit of the Zero-G Duel Circuit."
	}
