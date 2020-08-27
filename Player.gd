extends KinematicBody

const MAX_SPEED = 25
const MAX_FALL_SPEED = 30
const ACCEL_TIME = 0.2
const DECEL_TIME = 0.1
const COYOTE_TIME = 0.2
const JUMP_BUFFERING_TIME = 0.15
const GRAVITY = 1
const JUMP_SPEED = 30
const SPRINT_MODIFIER = 1.25
const CROUCH_MODIFIER = 0.6
const SLIDE_MODIFIER = 2

onready var tween = $Tween
onready var cam = $Camera
onready var acel_timer = $AcelTimer
onready var jump_buffer = $JumpBuffer
onready var slide_timer = $SlideTimer
onready var coyote_time = $CoyoteJump
onready var collision_shape = $CollisionShape
onready var crouch = $Crouching.transform.origin
onready var standing = $StandingUp.transform.origin
onready var roof_check = $CheckForRoof


var speed = 0
var vert_speed = 0
var stopped_crouching = false
var sliding = false
var crouching = false
var running = false

# Called when the node enters the scene tree for the first time.
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventMouseMotion:
		cam.rotation_degrees.x -= event.relative.y
		cam.rotation_degrees.x = clamp(cam.rotation_degrees.x, -87, 87)
		rotation_degrees.y -= event.relative.x

func _physics_process(delta):
	_move()

func _move():
	var movement = Vector3()
	movement.x = int(Input.is_action_pressed("right"))-int(Input.is_action_pressed("left"))
	movement.z = int(Input.is_action_pressed("backwards"))-int(Input.is_action_pressed("forwards"))
	speed = 20
#	if movement.x != 0 or movement.z != 0:
#		if acel_timer.is_stopped():
#			acel_timer.start()
#		tween.interpolate_property(self, "speed", 0, MAX_SPEED, ACCEL_TIME)
#		tween.start()
#	else:
#		if movement.x == 0 and movement.z == 0:
#			tween.stop_all()
#			tween.interpolate_property(self, "speed", speed, 0, DECEL_TIME)
#			tween.start()
#	print(speed)
	speed = speed*SLIDE_MODIFIER if sliding else speed*CROUCH_MODIFIER if crouching else speed*SPRINT_MODIFIER if running else speed
	movement = movement.normalized().rotated(Vector3.UP, rotation.y)*speed
	movement.y = vert_speed
	move_and_slide(movement, Vector3.UP)
	vert_speed -= GRAVITY
	var grounded = is_on_floor()
	if Input.is_action_just_pressed("jump"):
		jump_buffer.start(JUMP_BUFFERING_TIME)
	if grounded:
		coyote_time.start(COYOTE_TIME)
		vert_speed = -0.1
	if jump_buffer.time_left > 0 and coyote_time.time_left > 0:
		vert_speed = JUMP_SPEED
	else:
		# !! OPTIONAL || # 
		#if vert_speed > 1:
		#	if Input.is_action_just_released("jump"):
		#		vert_speed*=0.3
		vert_speed = -MAX_FALL_SPEED if vert_speed < - MAX_FALL_SPEED else vert_speed
	if Input.is_action_just_pressed("crouch"):
		tween.remove_all()
		#tween.interpolate_property(cam, "transform:origin", transform.origin, crouch, 0.2)
		cam.transform.origin = crouch
		tween.interpolate_property(collision_shape.shape, "height", collision_shape.shape.height, 0.5, 0.2)
		tween.interpolate_property(collision_shape.shape, "radius", collision_shape.shape.height, 0.3, 0.2)
		tween.start()
		if Input.is_action_pressed("run"):
			sliding = true
			slide_timer.start()
			print("Sliding",sliding)
		crouching = true
	elif Input.is_action_just_released("crouch"):
		stopped_crouching = true
	if roof_check.is_colliding() and vert_speed > 1:
		vert_speed*=0
	if stopped_crouching and !roof_check.is_colliding():
		tween.remove_all()
		#tween.interpolate_property(cam, "transform:origin", transform.origin, standing, 0.2)
		cam.transform.origin = standing
		tween.interpolate_property(collision_shape.shape, "height", collision_shape.shape.height, 1, 0.2)
		tween.interpolate_property(collision_shape.shape, "radius", collision_shape.shape.height, 1, 0.2)
		stopped_crouching = false
		crouching = false
	if Input.is_action_just_pressed("run") and !crouching:
		tween.interpolate_property(cam, "fov", cam.fov, 90, 0.2)
		running = true
	elif Input.is_action_just_released("run"):
		tween.interpolate_property(cam, "fov", cam.fov, 70, 0.1)
		running = false
	tween.start()


func _on_SlideTimer_timeout():
	sliding = false
