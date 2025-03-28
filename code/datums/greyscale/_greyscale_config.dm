#define MAX_SANE_LAYERS 50

/// A datum tying together a greyscale configuration and dmi file. Required for using GAGS and handles the code interactions.
/datum/greyscale_config
	/// User friendly name used in the debug menu
	var/name

	/// Reference to the json config file
	var/json_config

	/// Reference to the dmi file for this config
	var/icon_file

	/// An optional var to set that tells the material system what material this configuration is for.
	/// Use a typepath here, not an instance.
	var/datum/material/material_skin

	///////////////////////////////////////////////////////////////////////////////////////////
	// Do not set any further vars, the json file specified above is what generates the object

	/// Spritesheet width of the icon_file
	var/width

	/// Spritesheet height of the icon_file
	var/height

	/// String path to the json file, used for reloading
	var/string_json_config

	/// String path to the icon file, used for reloading
	var/string_icon_file

	/// A list of icon states and their layers
	var/list/icon_states

	/// How many colors are expected to be given when building the sprite
	var/expected_colors = 0

	/// Generated icons keyed by their color arguments
	var/list/icon_cache

// There's more sanity checking here than normal because this is designed for spriters to work with
// Sensible error messages that tell you exactly what's wrong is the best way to make this easy to use
/datum/greyscale_config/New()
	if(!json_config)
		stack_trace("Greyscale config object [DebugName()] is missing a json configuration, make sure `json_config` has been assigned a value.")
	string_json_config = "[json_config]"
	if(!icon_file)
		stack_trace("Greyscale config object [DebugName()] is missing an icon file, make sure `icon_file` has been assigned a value.")
	string_icon_file = "[icon_file]"
	if(!name)
		stack_trace("Greyscale config object [DebugName()] is missing a name, make sure `name` has been assigned a value.")

/datum/greyscale_config/proc/Refresh(loadFromDisk=FALSE)
	if(loadFromDisk)
		json_config = FILE_LOAD_PATH(string_json_config)
		icon_file = FILE_LOAD_PATH(string_icon_file)

	var/list/raw = JSON_LOAD_RSCPATH(json_config)
	//if(istext(json_config))
	//	raw = JSON_LOAD_PATH(json_config)
	//else
	//	raw = JSON_LOAD_FILE(json_config)
	ReadIconStateConfiguration(raw)

	if(!length(icon_states))
		CRASH("The json configuration [DebugName()] doesn't have any icon states.")

	icon_cache = list()

	ReadMetadata()

/// Gets the name used for debug purposes
/datum/greyscale_config/proc/DebugName()
	var/display_name = name || "MISSING_NAME"
	return "[display_name] ([icon_file]|[json_config])"

/// Takes the json icon state configuration and puts it into a more processed format
/datum/greyscale_config/proc/ReadIconStateConfiguration(list/data)
	icon_states = list()
	for(var/state in data)
		var/list/state_information = data[state]
		var/list/raw_layers = state_information["layers"]
		var/bitmask_config = state_information["bitmask_config"] ? text2num(state_information["bitmask_config"]) : NONE
		var/default_state_if_bitmask = state_information["default_state_if_bitmask"] ? TRUE : FALSE
		if(!length(raw_layers))
			stack_trace("The json configuration [DebugName()] for icon state '[state]' is missing any layers.")
			continue
		if(icon_states[state])
			stack_trace("The json configuration [DebugName()] has a duplicate icon state '[state]' and is being overriden.")
		icon_states[state] = new /datum/greyscale_state(ReadLayersFromJson(raw_layers), bitmask_config, default_state_if_bitmask)

/// Takes the json layers configuration and puts it into a more processed format
/datum/greyscale_config/proc/ReadLayersFromJson(list/data)
	var/list/output = ReadLayerGroup(data)
	return output[1]

/datum/greyscale_config/proc/ReadLayerGroup(list/data)
	if(!islist(data[1]))
		var/layer_type = SSgreyscale.layer_types[data["type"]]
		if(!layer_type)
			CRASH("An unknown layer type was specified in the json of greyscale configuration [DebugName()]: [data["layer_type"]]")
		return new layer_type(icon_file, data.Copy()) // We don't want anything in there touching our version of the data
	var/list/output = list()
	for(var/list/group as anything in data)
		output += ReadLayerGroup(group)
	if(length(output)) // Adding lists to lists unwraps the top level so here we are
		output = list(output)
	return output

/// Reads layer configurations to take out some useful overall information
/datum/greyscale_config/proc/ReadMetadata()
	var/icon/source = icon(icon_file)
	height = source.Height()
	width = source.Width()

	var/list/datum/greyscale_layer/all_layers = list()
	var/list/to_process = list()
	for(var/state in icon_states)
		var/datum/greyscale_state/gags_state = icon_states[state]
		to_process += gags_state.layers
	while(length(to_process))
		var/current = to_process[length(to_process)]
		to_process.len--
		if(islist(current))
			to_process += current
		else
			all_layers += current

	if(length(all_layers) > MAX_SANE_LAYERS)
		stack_trace("[DebugName()] has [length(all_layers)] layers which is larger than the max of [MAX_SANE_LAYERS].")

	var/list/color_groups = list()
	var/largest_id = 0
	for(var/datum/greyscale_layer/layer as anything in all_layers)
		for(var/id in layer.color_ids)
			if(!isnum(id))
				continue
			largest_id = max(id, largest_id)
			color_groups["[id]"] = TRUE

	for(var/i in 1 to largest_id)
		if(color_groups["[i]"])
			continue
		stack_trace("Color Ids are required to be sequential and start from 1. [DebugName()] has a max id of [largest_id] but is missing [i].")

	expected_colors = length(color_groups)

/// Actually create the icon and color it in, handles caching
/datum/greyscale_config/proc/Generate(color_string)
	var/key = color_string
	var/icon/new_icon = icon_cache[key]
	if(new_icon)
		return icon(new_icon)

	var/icon/icon_bundle = GenerateBundle(color_string)

	// This block is done like this because generated icons are unable to be scaled before getting added to the rsc
	icon_bundle = fcopy_rsc(icon_bundle)
	icon_bundle = icon(icon_bundle)
	icon_bundle.Scale(width, height)
	icon_bundle = fcopy_rsc(icon_bundle)

	icon_cache[key] = icon_bundle
	var/icon/output = icon(icon_bundle)
	return output

/// Handles the actual icon manipulation to create the spritesheet
/datum/greyscale_config/proc/GenerateBundle(list/colors, list/render_steps)
	if(!istype(colors))
		colors = color_string_to_list(colors)
	if(length(colors) < expected_colors)
		CRASH("[DebugName()] expected [expected_colors] color arguments but only received [length(colors)]")

	var/list/generated_icons = list()
	for(var/icon_state in icon_states)
		var/datum/greyscale_state/gags_state = icon_states[icon_state]
		var/list/layers = gags_state.layers
		var/bitmask_config = gags_state.bitmask_config
		var/default_state_if_bitmask = gags_state.default_state_if_bitmask
		// Generate the default icon state if we are not bitmasking, or we want to do so despite bitmasking
		if(bitmask_config == NONE || default_state_if_bitmask == TRUE)
			var/icon/generated_icon = GenerateLayerGroup(colors, layers, render_steps)
			// We read a pixel to force the icon to be fully generated before we let it loose into the world
			// I hate this
			generated_icon.GetPixel(1, 1)
			generated_icons[icon_state] = generated_icon

		// Also generate bitmasked states if the config tells us to.
		if(bitmask_config != NONE)
			var/list/steps = list()
			for(var/potential_step in 0 to 255)
				if(!(bitmask_config & GAGS_CARDINAL_SMOOTH))
					if(potential_step & (NORTH_JUNCTION|SOUTH_JUNCTION|EAST_JUNCTION|WEST_JUNCTION))
						continue
				if(potential_step & (NORTHEAST_JUNCTION|SOUTHEAST_JUNCTION|SOUTHWEST_JUNCTION|NORTHWEST_JUNCTION))
					if(!(bitmask_config & GAGS_DIAGONAL_SMOOTH))
						continue
					else if (bitmask_config & GAGS_DIAGONAL_NEED_ADJACENT_CARDINAL)
						if(potential_step & NORTHEAST_JUNCTION && !(potential_step & NORTH_JUNCTION && potential_step & EAST_JUNCTION))
							continue
						if(potential_step & SOUTHEAST_JUNCTION && !(potential_step & SOUTH_JUNCTION && potential_step & EAST_JUNCTION))
							continue
						if(potential_step & SOUTHWEST_JUNCTION && !(potential_step & SOUTH_JUNCTION && potential_step & WEST_JUNCTION))
							continue
						if(potential_step & NORTHWEST_JUNCTION && !(potential_step & NORTH_JUNCTION && potential_step & WEST_JUNCTION))
							continue

				steps += potential_step
			for(var/bit_step in steps)
				var/icon/generated_icon = GenerateLayerGroup(colors, layers, render_steps, TRUE, bit_step)
				// Same as above.
				generated_icon.GetPixel(1, 1)
				generated_icons["[icon_state]-[bit_step]"] = generated_icon

	var/icon/icon_bundle = icon('icons/testing/greyscale_error.dmi')
	for(var/icon_state in generated_icons)
		icon_bundle.Insert(generated_icons[icon_state], icon_state)

	return icon_bundle

/// Internal recursive proc to handle nested layer groups
/datum/greyscale_config/proc/GenerateLayerGroup(list/colors, list/group, list/render_steps, do_bitmasking = FALSE, bitmask_step)
	var/icon/new_icon
	for(var/datum/greyscale_layer/layer as anything in group)
		var/icon/layer_icon
		if(islist(layer))
			layer_icon = GenerateLayerGroup(colors, layer, render_steps, do_bitmasking, bitmask_step)
			layer = layer[1] // When there are multiple layers in a group like this we use the first one's blend mode
		else
			layer_icon = layer.Generate(colors, render_steps, do_bitmasking, bitmask_step)

		if(!new_icon)
			new_icon = layer_icon
		else
			new_icon.Blend(layer_icon, layer.blend_mode)

		// These are so we can see the result of every step of the process in the preview ui
		if(render_steps)
			var/list/icon_data = list()
			render_steps[icon(layer_icon)] = icon_data
			icon_data["config_name"] = name
			icon_data["result"] = icon(new_icon)
	return new_icon

/datum/greyscale_config/proc/GenerateDebug(colors)
	var/list/output = list()
	var/list/debug_steps = list()
	output["steps"] = debug_steps

	output["icon"] = GenerateBundle(colors, debug_steps)
	return output

#undef MAX_SANE_LAYERS
