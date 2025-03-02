#define pick_list(FILE, KEY) (pick(strings(FILE, KEY)))
#define pick_list_weighted(FILE, KEY) (pickweight(strings(FILE, KEY)))
#define pick_list_replacements(FILE, KEY) (strings_replacement(FILE, KEY))
#define JSON_LOAD_PATH(path) json_decode(FILE2TEXT_PATH(path))
#define JSON_LOAD_RSCPATH(rscpath) json_decode(FILE2TEXT_RSCPATH(rscpath))
#define JSON_LOAD_FILE(file) json_decode(FILE2TEXT_RSCPATH(file))

GLOBAL_LIST(string_cache)
GLOBAL_VAR(string_filename_current_key)


/proc/strings_replacement(filename, key, directory = "strings")
	load_strings_file(filename, directory)

	if((filename in GLOB.string_cache) && (key in GLOB.string_cache[filename]))
		var/response = pick(GLOB.string_cache[filename][key])
		var/regex/r = regex("@pick\\((\\D+?)\\)", "g")
		response = r.Replace(response, GLOBAL_PROC_REF(strings_subkey_lookup))
		return response
	else
		CRASH("strings list not found: [directory]/[filename], index=[key]")

/proc/strings(filename as text, key as text, directory = "strings")
	load_strings_file(filename, directory)
	if((filename in GLOB.string_cache) && (key in GLOB.string_cache[filename]))
		return GLOB.string_cache[filename][key]
	else
		CRASH("strings list not found: [directory]/[filename], index=[key]")

/proc/strings_subkey_lookup(match, group1)
	return pick_list(GLOB.string_filename_current_key, group1)

/proc/load_strings_file(filename, directory = "strings")
	GLOB.string_filename_current_key = filename
	if(filename in GLOB.string_cache)
		return //no work to do

	if(!GLOB.string_cache)
		GLOB.string_cache = new

	var/fin_path = "[directory]/[filename]"
	if(fexists(fin_path))
		GLOB.string_cache[filename] = JSON_LOAD_PATH(fin_path)
	else
		CRASH("file not found: [fin_path]")
