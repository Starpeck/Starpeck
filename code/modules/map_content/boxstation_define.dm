/datum/map_config/boxstation
	map_name = "Box Station"
	map_path = "map_files/BoxStation"
	map_file = "BoxStation.dmm"

	traits = null
	space_ruin_levels = 2

	minetype = "lavaland"

	allow_custom_shuttles = TRUE
	shuttles = list(
		"cargo" = "cargo_box",
		"ferry" = "ferry_fancy",
		"whiteship" = "whiteship_box",
		"emergency" = "emergency_box",
	)

	job_changes = list()

	overmap_object_type = /datum/overmap_object/shuttle/station
