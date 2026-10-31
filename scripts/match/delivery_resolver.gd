extends RefCounted
class_name DeliveryResolver

static func resolve(input: Dictionary) -> Dictionary:
    var timing := clampf(float(input.get("timing", 0.5)), 0.0, 1.0)
    var power := clampf(float(input.get("power", 0.5)), 0.0, 1.0)
    var skill := clampf(float(input.get("batter_skill", 0.5)), 0.0, 1.0)
    var shot := str(input.get("shot", "DRIVE"))
    var line := float(input.get("line", 0.0))
    var length := float(input.get("length", 0.5))
    var quality := clampf(0.55 * timing + 0.25 * skill + 0.20 * (1.0 - absf(line)), 0.0, 1.0)
    var wicket_chance := 0.035 + (1.0 - quality) * 0.22
    if shot == "LOFT":
        wicket_chance += 0.08
    var wicket := float(input.get("wicket_roll", 1.0)) < wicket_chance
    var runs := 0
    if not wicket:
        if shot == "DEFEND":
            runs = 0 if quality < 0.75 else 1
        elif shot == "LOFT":
            runs = 6 if quality > 0.88 and power > 0.65 else (4 if quality > 0.68 else 1)
        elif shot == "PULL":
            runs = 4 if quality > 0.70 and length > 0.55 else (2 if quality > 0.42 else 0)
        else:
            runs = 4 if quality > 0.76 else (2 if quality > 0.48 else (1 if quality > 0.28 else 0))
    return {"bat_runs": runs, "total_runs": runs, "legal": true, "wicket": wicket, "quality": quality}
