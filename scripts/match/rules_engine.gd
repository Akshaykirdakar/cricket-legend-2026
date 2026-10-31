extends RefCounted
class_name CricketRulesEngine

enum ExtraType { NONE, WIDE, NO_BALL, BYE, LEG_BYE }

static func normalize_delivery(bat_runs: int, extra_type: ExtraType, extra_runs: int = 1, wicket: bool = false) -> Dictionary:
    var legal := true
    var extras := 0
    match extra_type:
        ExtraType.WIDE:
            legal = false
            extras = maxi(1, extra_runs)
        ExtraType.NO_BALL:
            legal = false
            extras = maxi(1, extra_runs)
        ExtraType.BYE, ExtraType.LEG_BYE:
            extras = maxi(0, extra_runs)
    return {"bat_runs": bat_runs, "extras": extras, "total_runs": bat_runs + extras, "legal": legal, "wicket": wicket and extra_type != ExtraType.WIDE and extra_type != ExtraType.NO_BALL, "extra_type": extra_type}

static func is_innings_over(legal_balls: int, wickets: int, overs_limit: int, all_out: bool) -> bool:
    return all_out or wickets >= 10 or legal_balls >= overs_limit * 6
