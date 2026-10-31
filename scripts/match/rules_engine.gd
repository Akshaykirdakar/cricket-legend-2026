extends RefCounted
class_name CricketRulesEngine

enum ExtraType { NONE, WIDE, NO_BALL, BYE, LEG_BYE, PENALTY }
enum Dismissal { NONE, BOWLED, CAUGHT, LBW, RUN_OUT, STUMPED, HIT_WICKET, RETIRED_OUT, OBSTRUCTING_FIELD, HIT_BALL_TWICE, TIMED_OUT }

const BOWLER_CREDITED_DISMISSALS := [
	Dismissal.BOWLED,
	Dismissal.CAUGHT,
	Dismissal.LBW,
	Dismissal.STUMPED,
	Dismissal.HIT_WICKET
]

static func normalize_delivery(bat_runs: int, extra_type: ExtraType, extra_runs: int = 1, wicket: bool = false, dismissal: Dismissal = Dismissal.BOWLED) -> Dictionary:
	var safe_bat_runs := maxi(0, bat_runs)
	var extras := maxi(0, extra_runs)
	var legal := true
	match extra_type:
		ExtraType.WIDE:
			legal = false
			extras = maxi(1, extras)
		ExtraType.NO_BALL:
			legal = false
			extras = maxi(1, extras)
		ExtraType.BYE, ExtraType.LEG_BYE:
			extras = maxi(0, extras)
		ExtraType.PENALTY:
			legal = true
			extras = maxi(0, extras)
	var valid_wicket := wicket and dismissal != Dismissal.NONE
	if extra_type == ExtraType.WIDE:
		valid_wicket = valid_wicket and dismissal in [Dismissal.BOWLED, Dismissal.CAUGHT, Dismissal.STUMPED, Dismissal.RUN_OUT, Dismissal.HIT_WICKET, Dismissal.OBSTRUCTING_FIELD]
	elif extra_type == ExtraType.NO_BALL:
		valid_wicket = valid_wicket and dismissal in [Dismissal.RUN_OUT, Dismissal.OBSTRUCTING_FIELD, Dismissal.HIT_BALL_TWICE]
	var total := safe_bat_runs + extras
	return {
		"bat_runs": safe_bat_runs,
		"extras": extras,
		"total_runs": total,
		"legal": legal,
		"wicket": valid_wicket,
		"extra_type": extra_type,
		"dismissal": dismissal,
		"bowler_credited": valid_wicket and dismissal in BOWLER_CREDITED_DISMISSALS,
		"byes_or_leg_byes": extras if extra_type in [ExtraType.BYE, ExtraType.LEG_BYE] else 0
	}

static func is_innings_over(legal_balls: int, wickets: int, overs_limit: int, all_out: bool) -> bool:
	return all_out or wickets >= 10 or legal_balls >= overs_limit * 6

static func is_bowler_credited_dismissal(dismissal: Dismissal) -> bool:
	return dismissal in BOWLER_CREDITED_DISMISSALS

static func overs_text(legal_balls: int) -> String:
	return "%d.%d" % [int(legal_balls / 6), int(legal_balls % 6)]
