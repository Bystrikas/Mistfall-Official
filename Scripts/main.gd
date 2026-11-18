extends Node3D

const PlayerScript = preload("res://Scripts/player.gd")
var player: CharacterBody3D
var ui_layer: CanvasLayer
var joystick_touch := -1
var look_touch := -1
var joy_origin := Vector2.ZERO
var joy_value := Vector2.ZERO
var last_look := Vector2.ZERO
var collected := 0
var hud_label: Label

func _ready():
    _build_world()
    _build_player()
    _build_ui()
    _build_controls()

func _mat(color: Color, roughness := 0.9) -> StandardMaterial3D:
    var m = StandardMaterial3D.new()
    m.albedo_color = color
    m.roughness = roughness
    return m

func _box(parent: Node3D, name: String, pos: Vector3, size: Vector3, color: Color, collision := true):
    var mesh_node = MeshInstance3D.new()
    mesh_node.name = name
    var mesh = BoxMesh.new()
    mesh.size = size
    mesh_node.mesh = mesh
    mesh_node.position = pos
    mesh_node.material_override = _mat(color)
    parent.add_child(mesh_node)
    if collision:
        var body = StaticBody3D.new()
        body.position = pos
        var shape_node = CollisionShape3D.new()
        var shape = BoxShape3D.new()
        shape.size = size
        shape_node.shape = shape
        body.add_child(shape_node)
        parent.add_child(body)
    return mesh_node

func _build_world():
    var env = WorldEnvironment.new()
    var e = Environment.new()
    e.background_mode = Environment.BG_SKY
    e.sky = Sky.new()
    var sky_mat = ProceduralSkyMaterial.new()
    sky_mat.sky_top_color = Color(0.015, 0.07, 0.055)
    sky_mat.sky_horizon_color = Color(0.22, 0.34, 0.20)
    sky_mat.ground_bottom_color = Color(0.025, 0.045, 0.025)
    sky_mat.ground_horizon_color = Color(0.15, 0.22, 0.12)
    e.sky.sky_material = sky_mat
    e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    e.ambient_light_color = Color(0.36, 0.48, 0.34)
    e.ambient_light_energy = 0.7
    e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    e.fog_enabled = true
    e.fog_light_color = Color(0.30, 0.52, 0.22)
    e.fog_density = 0.018
    env.environment = e
    add_child(env)

    var sun = DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-48, -32, 0)
    sun.light_energy = 1.1
    sun.shadow_enabled = true
    add_child(sun)

    _box(self, "Jungle floor", Vector3(0,-0.5,0), Vector3(90,1,90), Color(0.10,0.20,0.09))
    # elevated canopy walkways
    _box(self, "Suspended walkway", Vector3(0,5,0), Vector3(26,0.55,3.2), Color(0.32,0.22,0.12))
    _box(self, "Side platform", Vector3(14,5,-5), Vector3(3,0.55,14), Color(0.29,0.20,0.12))
    _box(self, "Research outpost", Vector3(-11,5,-7), Vector3(8,0.55,7), Color(0.22,0.25,0.20))
    _box(self, "Outpost wall", Vector3(-14,7,-10), Vector3(0.4,4,5), Color(0.20,0.28,0.23))
    # trees: trunks and broad leaf crowns
    for i in range(22):
        var x = randf_range(-38,38)
        var z = randf_range(-38,38)
        if abs(x) < 9 and abs(z) < 8:
            continue
        var trunk = MeshInstance3D.new()
        var cyl = CylinderMesh.new()
        cyl.top_radius = 0.38
        cyl.bottom_radius = 0.65
        cyl.height = randf_range(8,13)
        trunk.mesh = cyl
        trunk.position = Vector3(x,cyl.height/2,z)
        trunk.material_override = _mat(Color(0.20,0.12,0.07))
        add_child(trunk)
        var crown = MeshInstance3D.new()
        var sphere = SphereMesh.new()
        sphere.radius = randf_range(3.2,5.0)
        sphere.height = sphere.radius * 1.2
        crown.mesh = sphere
        crown.position = Vector3(x,cyl.height+2,z)
        crown.material_override = _mat(Color(0.07,0.24+randf()*0.12,0.10))
        add_child(crown)
    # glowing toxic mist pools below the canopy
    for p in [Vector3(-18,0.15,10), Vector3(19,0.15,15), Vector3(0,0.15,-23)]:
        var toxic = MeshInstance3D.new()
        var sphere = SphereMesh.new()
        sphere.radius = 7
        sphere.height = 2
        toxic.mesh = sphere
        toxic.position = p
        var tm = _mat(Color(0.35,0.85,0.10,0.40))
        tm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        tm.emission_enabled = true
        tm.emission = Color(0.16,0.55,0.02)
        tm.emission_energy_multiplier = 0.7
        toxic.material_override = tm
        add_child(toxic)
    # collectible supplies
    for p in [Vector3(5,5.9,0), Vector3(-10,5.9,-7), Vector3(13,5.9,-8)]:
        var pickup = Area3D.new()
        pickup.position = p
        pickup.set_meta("pickup", true)
        var visual = MeshInstance3D.new()
        var box = BoxMesh.new()
        box.size = Vector3(0.55,0.55,0.55)
        visual.mesh = box
        visual.material_override = _mat(Color(0.95,0.68,0.12))
        pickup.add_child(visual)
        var cs = CollisionShape3D.new()
        var sh = SphereShape3D.new()
        sh.radius = 1.2
        cs.shape = sh
        pickup.add_child(cs)
        pickup.body_entered.connect(_on_pickup.bind(pickup))
        add_child(pickup)

func _build_player():
    player = CharacterBody3D.new()
    player.name = "Explorer"
    player.set_script(PlayerScript)
    player.position = Vector3(0,6.2,1)
    add_child(player)

func _build_ui():
    ui_layer = CanvasLayer.new()
    add_child(ui_layer)
    var panel = ColorRect.new()
    panel.color = Color(0.015,0.04,0.025,0.68)
    panel.position = Vector2(18,16)
    panel.size = Vector2(330,72)
    ui_layer.add_child(panel)
    hud_label = Label.new()
    hud_label.position = Vector2(32,25)
    hud_label.text = "MISTFALL  |  Rifornimenti: 0/3"
    hud_label.add_theme_font_size_override("font_size", 20)
    hud_label.add_theme_color_override("font_color", Color(0.78,1,0.68))
    ui_layer.add_child(hud_label)
    var hint = Label.new()
    hint.anchor_left = 0.5
    hint.anchor_top = 0.0
    hint.position = Vector2(-190,22)
    hint.text = "ESPLORA LA PIATTAFORMA SOSPESA"
    hint.add_theme_font_size_override("font_size", 17)
    hint.add_theme_color_override("font_color", Color(0.9,0.95,0.8))
    ui_layer.add_child(hint)
    var jump = Button.new()
    jump.text = "SALTA"
    jump.position = Vector2(0,0)
    jump.anchor_left = 1.0
    jump.anchor_top = 1.0
    jump.offset_left = -142
    jump.offset_top = -112
    jump.offset_right = -24
    jump.offset_bottom = -28
    jump.add_theme_font_size_override("font_size", 20)
    jump.button_down.connect(func(): Input.action_press("jump"))
    jump.button_up.connect(func(): Input.action_release("jump"))
    ui_layer.add_child(jump)

func _build_controls():
    InputMap.add_action("jump")
    InputMap.add_action("move_left")
    InputMap.add_action("move_right")
    InputMap.add_action("move_forward")
    InputMap.add_action("move_back")
    InputMap.action_add_event("move_left", _key(KEY_A))
    InputMap.action_add_event("move_right", _key(KEY_D))
    InputMap.action_add_event("move_forward", _key(KEY_W))
    InputMap.action_add_event("move_back", _key(KEY_S))
    InputMap.action_add_event("jump", _key(KEY_SPACE))

func _key(code):
    var ev = InputEventKey.new()
    ev.keycode = code
    return ev

func _input(event):
    var screen = get_viewport().get_visible_rect().size
    if event is InputEventScreenTouch:
        if event.pressed:
            if event.position.x < screen.x * 0.48 and joystick_touch == -1:
                joystick_touch = event.index
                joy_origin = event.position
                joy_value = Vector2.ZERO
            elif event.position.x >= screen.x * 0.48 and look_touch == -1:
                look_touch = event.index
                last_look = event.position
        else:
            if event.index == joystick_touch:
                joystick_touch = -1
                joy_value = Vector2.ZERO
                player.set_move_input(Vector2.ZERO)
            if event.index == look_touch:
                look_touch = -1
    elif event is InputEventScreenDrag:
        if event.index == joystick_touch:
            joy_value = ((event.position - joy_origin) / 65.0).limit_length(1.0)
            player.set_move_input(Vector2(joy_value.x, joy_value.y))
        elif event.index == look_touch:
            player.rotate_camera(event.relative.x, event.relative.y)
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        pass

func _on_pickup(body, pickup):
    if body == player and is_instance_valid(pickup):
        collected += 1
        hud_label.text = "MISTFALL  |  Rifornimenti: %d/3" % collected
        pickup.queue_free()
