extends RefCounted
class_name CricketBallistics
## Deterministic fixed-step cricket ball model with gravity, Magnus drift,
## seam/swing movement, pitch restitution and ground friction.

const GRAVITY := 9.81
const AIR_DENSITY_FACTOR := 0.0022
const BALL_RADIUS := 0.036
const PITCH_RESTITUTION := 0.48
const PITCH_FRICTION := 0.82

var position := Vector3.ZERO
var velocity := Vector3.ZERO
var spin_axis := Vector3.UP
var spin_rate := 0.0
var swing_factor := 0.0
var seam_factor := 0.0
var bounced := false
var active := false

func launch(origin: Vector3, initial_velocity: Vector3, spin: float = 0.0, swing: float = 0.0, seam: float = 0.0) -> void:
	position = origin
	velocity = initial_velocity
	spin_rate = spin
	swing_factor = swing
	seam_factor = seam
	bounced = false
	active = true

func step(delta: float, pitch_y: float = 0.0) -> Dictionary:
	if not active:
		return {"active": false, "bounced": bounced}
	var dt := minf(delta, 1.0 / 30.0)
	var speed := velocity.length()
	var lateral := Vector3.UP.cross(velocity).normalized()
	var magnus := lateral * spin_rate * AIR_DENSITY_FACTOR * speed
	var swing := Vector3.RIGHT * swing_factor * speed * 0.018
	var seam := Vector3.RIGHT * seam_factor * speed * 0.006 if bounced else Vector3.ZERO
	velocity += (Vector3.DOWN * GRAVITY + magnus + swing + seam) * dt
	position += velocity * dt
	var did_bounce := false
	if position.y <= pitch_y + BALL_RADIUS and velocity.y < 0.0:
		position.y = pitch_y + BALL_RADIUS
		velocity.y = absf(velocity.y) * PITCH_RESTITUTION
		velocity.x *= PITCH_FRICTION
		velocity.z *= PITCH_FRICTION
		bounced = true
		did_bounce = true
	if velocity.length() < 0.35:
		velocity = Vector3.ZERO
		active = false
	return {"active": active, "bounced": did_bounce, "position": position, "velocity": velocity}

func segment_sphere_contact(a: Vector3, b: Vector3, center: Vector3, radius: float) -> Dictionary:
	var segment := b - a
	var length_sq := segment.length_squared()
	var t := 0.0 if length_sq <= 0.000001 else clampf((center - a).dot(segment) / length_sq, 0.0, 1.0)
	var closest := a + segment * t
	var distance := closest.distance_to(center)
	return {"hit": distance <= radius, "time": t, "point": closest, "distance": distance}

func apply_bat_impulse(incoming: Vector3, bat_normal: Vector3, bat_speed: float, restitution: float = 0.72) -> Vector3:
	var normal := bat_normal.normalized()
	var relative := incoming - normal * bat_speed
	var reflected := relative - (1.0 + restitution) * relative.dot(normal) * normal
	return reflected + normal * bat_speed
