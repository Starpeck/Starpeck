//Defines for atom layers and planes
//KEEP THESE IN A NICE ACSCENDING ORDER, PLEASE

#define CLICKCATCHER_PLANE -99

#define PLANE_SPACE -95
#define PLANE_SPACE_RENDER_TARGET "PLANE_SPACE"
#define PLANE_SPACE_PARALLAX -90
#define PLANE_SPACE_PARALLAX_RENDER_TARGET "PLANE_SPACE_PARALLAX"


#define OPENSPACE_LAYER 600 //Openspace layer over all
#define OPENSPACE_PLANE -10 //Openspace plane below all turfs
#define OPENSPACE_BACKDROP_PLANE -9 //Black square just over openspace plane to guaranteed cover all in openspace turf


#define FLOOR_PLANE -8
#define FLOOR_PLANE_RENDER_TARGET "FLOOR_PLANE"
#define OVER_TILE_PLANE -7
#define WALL_PLANE -6
#define GAME_PLANE -5
#define GAME_PLANE_RENDER_TARGET "GAME_PLANE"
#define MOUSE_TRANSPARENT_PLANE -4
#define MOUSE_TRANSPARENT_PLANE_RENDER_TARGET "MOUSE_TRANSPARENT_PLANE"
#define UNDER_FRILL_PLANE -3
#define UNDER_FRILL_RENDER_TARGET "UNDER_FRILL_PLANE"
#define FRILL_PLANE -2
#define FRILL_PLANE_RENDER_TARGET "FRILL_PLANE"
#define OVER_FRILL_PLANE -1
#define BLACKNESS_PLANE 0 //To keep from conflicts with SEE_BLACKNESS internals
#define BLACKNESS_PLANE_RENDER_TARGET "BLACKNESS_PLANE"

#define SPACE_LAYER 1.8
#define ROOF_LAYER 1.9
//#define TURF_LAYER 2 //For easy recordkeeping; this is a byond define
#define CULT_OVERLAY_LAYER 2.01
#define MID_TURF_LAYER 2.02
#define HIGH_TURF_LAYER 2.03
#define TURF_PLATING_DECAL_LAYER 2.031
#define TURF_DECAL_LAYER 2.039 //Makes turf decals appear in DM how they will look inworld.
#define ABOVE_OPEN_TURF_LAYER 2.04
#define CLOSED_TURF_LAYER 2.05
#define BULLET_HOLE_LAYER 2.06
#define ABOVE_NORMAL_TURF_LAYER 2.08
#define LATTICE_LAYER 2.2
#define DISPOSAL_PIPE_LAYER 2.3
#define GAS_PIPE_HIDDEN_LAYER 2.35 //layer = initial(layer) + piping_layer / 1000 in atmospherics/update_icon() to determine order of pipe overlap
#define WIRE_LAYER 2.4
#define WIRE_BRIDGE_LAYER 2.41
#define WIRE_TERMINAL_LAYER 2.42
#define UNDER_CATWALK_LAYER 2.44
#define CATWALK_LAYER 2.45
#define GAS_PIPE_VISIBLE_LAYER 2.46 //layer = initial(layer) + piping_layer / 1000 in atmospherics/update_icon() to determine order of pipe overlap
#define GAS_SCRUBBER_LAYER 2.47
#define GAS_FILTER_LAYER 2.48
#define GAS_PUMP_LAYER 2.49
#define PLUMBING_PIPE_VISIBILE_LAYER 2.495//layer = initial(layer) + ducting_layer / 3333 in atmospherics/handle_layer() to determine order of duct overlap
#define LOW_OBJ_LAYER 2.5
#define LOW_SIGIL_LAYER 2.52
#define SIGIL_LAYER 2.54
#define HIGH_PIPE_LAYER 2.55
#define HIGH_SIGIL_LAYER 2.56

#define BELOW_OPEN_DOOR_LAYER 2.6
#define BLASTDOOR_LAYER 2.65
#define OPEN_DOOR_LAYER 2.7
#define DOOR_HELPER_LAYER 2.71 //keep this above OPEN_DOOR_LAYER
#define PROJECTILE_HIT_THRESHHOLD_LAYER 2.75 //projectiles won't hit objects at or below this layer if possible
#define TABLE_LAYER 2.8
#define GATEWAY_UNDERLAY_LAYER 2.85
#define BELOW_OBJ_LAYER 2.9
#define LOW_ITEM_LAYER 2.95
//#define OBJ_LAYER 3 //For easy recordkeeping; this is a byond define
#define CLOSED_BLASTDOOR_LAYER 3.05
#define CLOSED_DOOR_LAYER 3.1
#define CLOSED_FIREDOOR_LAYER 3.11
#define SHUTTER_LAYER 3.12 // HERE BE DRAGONS
#define ABOVE_OBJ_LAYER 3.2
#define SHUTTER_LAYER_CLOSED 3.21
#define CLOSED_BLASTDOOR_LAYER 3.22

#define LOW_WALL_STRIPE_LAYER 3.25

#define ABOVE_WINDOW_LAYER 3.3
#define SIGN_LAYER 3.4
#define CORGI_ASS_PIN_LAYER 3.41
#define NOT_HIGH_OBJ_LAYER 3.5
#define HIGH_OBJ_LAYER 3.6

#define BELOW_MOB_LAYER 3.7
#define LYING_MOB_LAYER 3.8
#define MOB_BELOW_PIGGYBACK_LAYER 3.94
//#define MOB_LAYER 4 //For easy recordkeeping; this is a byond define
#define MOB_SHIELD_LAYER 4.01
#define MOB_ABOVE_PIGGYBACK_LAYER 4.06
#define ABOVE_MOB_LAYER 4.1
#define WALL_OBJ_LAYER 4.25
#define EDGED_TURF_LAYER 4.3
#define ON_EDGED_TURF_LAYER 4.35
#define LARGE_MOB_LAYER 4.4
#define ABOVE_ALL_MOB_LAYER 4.5

#define SPACEVINE_LAYER 4.8
#define SPACEVINE_MOB_LAYER 4.9
//#define FLY_LAYER 5 //For easy recordkeeping; this is a byond define
#define GASFIRE_LAYER 5.05
#define RIPPLE_LAYER 5.1

#define LANDMARK_PLANE 50
#define LOW_LANDMARK_LAYER 1
#define MID_LANDMARK_LAYER 2
#define HIGH_LANDMARK_LAYER 3

#define AREA_PLANE 60
#define MASSIVE_OBJ_PLANE 70
#define GHOST_PLANE 80
#define POINT_PLANE 90

#define RAD_TEXT_PLANE 90

#define FRILL_MASK_PLANE 95
#define FRILL_MASK_RENDER_TARGET "*FRILL_MASK_PLANE"

//---------- LIGHTING -------------
///Normal 1 per turf dynamic lighting underlays
#define LIGHTING_PLANE 100
#define LIGHTING_RENDER_TARGET "LIGHT_PLANE"

#define DAY_NIGHT_LIGHTING_LAYER 100

///Things that should render ignoring lighting
#define ABOVE_LIGHTING_PLANE 110
#define ABOVE_LIGHTING_RENDER_TARGET "ABOVE_LIGHTING_PLANE"

#define ABOVE_LIGHTING_MOUSE_TRANSPARENT_PLANE 111
#define ABOVE_LIGHTING_MOUSE_TRANSPARENT_RENDER_TARGET "ABOVE_LIGHTING_MOUSE_TRANSPARENT_PLANE"

///visibility + hiding of things outside of light source range
#define BYOND_LIGHTING_PLANE 120
#define BYOND_LIGHTING_RENDER_TARGET "BYOND_LIGHTING_PLANE"


//---------- EMISSIVES -------------
//Layering order of these is not particularly meaningful.
//Important part is the seperation of the planes for control via plane_master

/// This plane masks out lighting to create an "emissive" effect, ie for glowing lights in otherwise dark areas.
#define EMISSIVE_PLANE 150
/// The render target used by the emissive layer.
#define EMISSIVE_RENDER_TARGET "*EMISSIVE_PLANE"
/// The layer you should use if you _really_ don't want an emissive overlay to be blocked.
#define EMISSIVE_LAYER_UNBLOCKABLE 9999

///---------------- MISC -----------------------

///AI Camera Static
#define CAMERA_STATIC_PLANE 200
#define CAMERA_STATIC_RENDER_TARGET "CAMERA_STATIC_PLANE"

///Debug Atmos Overlays
#define ATMOS_GROUP_PLANE 450

///--------------- FULLSCREEN IMAGES ------------
#define FULLSCREEN_PLANE 500
#define FULLSCREEN_RENDER_TARGET "FULLSCREEN_PLANE"
#define FLASH_LAYER 1
#define FULLSCREEN_LAYER 2
#define UI_DAMAGE_LAYER 3
#define BLIND_LAYER 4
#define CRIT_LAYER 5
#define CURSE_LAYER 6
#define FOV_EFFECTS_LAYER 10000 //Blindness effects are not layer 4, they lie to you

///Popup Chat Messages
#define RUNECHAT_PLANE 501

/// Plane for balloon text (text that fades up)
#define BALLOON_CHAT_PLANE 502


//-------------------- HUD ---------------------
//HUD layer defines
#define HUD_PLANE 1000
#define HUD_RENDER_TARGET "HUD_PLANE"
#define ABOVE_HUD_PLANE 1100
#define ABOVE_HUD_RENDER_TARGET "ABOVE_HUD_PLANE"

#define RADIAL_BACKGROUND_LAYER 0
///1000 is an unimportant number, it's just to normalize copied layers
#define RADIAL_CONTENT_LAYER 1000

///Plane of the "splash" icon used that shows on the lobby screen. Nothing should ever be above this.
#define SPLASHSCREEN_PLANE 9999
#define SPLASHSCREEN_RENDER_TARGET "SPLASHSCREEN_PLANE"

///cinematics are "below" the splash screen
#define CINEMATIC_LAYER -1

///Plane master controller keys
#define PLANE_MASTERS_GAME "plane_masters_game"
