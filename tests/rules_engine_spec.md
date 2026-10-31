# Rules engine test cases

Automate these with GUT or Godot's built-in headless test runner before release.

- A dot ball increments legal balls and adds zero runs.
- A four increments team and batter runs by four.
- A wide adds at least one extra and does not increment legal balls.
- A no-ball adds at least one extra and does not increment legal balls.
- A bye/leg-bye adds extras and counts as a legal delivery.
- A legal wicket increments wickets and records fall of wicket.
- An innings ends at the configured legal-ball limit or ten wickets.
- A chase ends immediately when the target is reached.
- A tied match is reported as tied pending super-over policy.
- T20 innings end after 120 legal balls, not 120 attempted deliveries.
