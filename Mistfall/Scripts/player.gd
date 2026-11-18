extends CharacterBody3D

@export var move_speed := 5.5
@export var jump_velocity := 5.0
@export var gravity := 18.0
var move_input := Vector2.ZERO
var camera_pivot: Node3D
var yaw := 0.0
var pitch := -0.22

func _ready():
    camera_pivot = Node3D.new()
    camera_pivot.position = Vector3(0, 1.5, 0)
    add_child(camera_pivot)
    var cam = Camera3D.new()
    cam.position = Vector3(0, 1.0, 5.2)
    cam.rotation.x = -0.12
    cam.current = true
    camera_pivot.add_child(cam)
    var body = MeshInstance3D.new()
    var capsule = CapsuleMesh.new()
    capsule.radius = 0.38
    capsule.height = 1.75
    body.mesh = capsule
    body.position.y = 0.88
    var mat = StandardMaterial3D.new()
    mat.albedo_color = Color(0.18, 0.52, 0.32)
    mat.metallic = 0.08
    body.material_override = mat
    add_child(body)
    var collider = CollisionShape3D.new()
    var shape = CapsuleShape3D.new()
    shape.radius = 0.38
    shape.height = 1.75
    collider.shape = shape
    collider.position.y = 0.88
    add_child(collider)

func set_move_input(v: Vector2):
    move_input = v.limit_length(1.0)

func rotate_camera(delta_x: float, delta_y: float):
    yaw -= delta_x * 0.006
    pitch = clamp(pitch - delta_y * 0.004, -0.85, 0.25)
    camera_pivot.rotation = Vector3(pitch, yaw, 0)

func _physics_process(delta):
    var input_vec = move_input
    if input_vec.length() < 0.05:
        input_vec = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var basis_yaw = Basis(Vector3.UP, yaw)
    var direction = basis_yaw * Vector3(input_vec.x, 0, input_vec.y)
    direction.y = 0
    direction = direction.normalized()
    velocity.x = direction.x * move_speed
    velocity.z = direction.z * move_speed
    if not is_on_floor():
        velocity.y -= gravity * delta
    elif Input.is_action_just_pressed("jump"):
        velocity.y = jump_velocity
    if Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = jump_velocity
    move_and_slide()
