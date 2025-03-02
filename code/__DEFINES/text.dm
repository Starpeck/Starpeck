/// Prepares a text to be used for maptext. Use this so it doesn't look hideous.
#define MAPTEXT(text) {"<span class='maptext'>[##text]</span>"}

/// Macro from Lummox used to get height from a MeasureText proc
#define WXH_TO_HEIGHT(x) text2num(copytext(x, findtextEx(x, "x") + 1))

/// Removes characters incompatible with file names.
#define SANITIZE_FILENAME(text) (GLOB.filename_forbidden_chars ? GLOB.filename_forbidden_chars.Replace(text, "") : text)

/// Simply removes the < and > characters, and limits the length of the message.
#define STRIP_HTML_SIMPLE(text, limit) (GLOB.angular_brackets.Replace(copytext(text, 1, limit), ""))

///Index access defines for paper/var/add_info_style
#define ADD_INFO_COLOR 1
#define ADD_INFO_FONT 2
#define ADD_INFO_SIGN 3

///Adds a html style to a text string. Hacky, but that's how inputted text appear on paper sheets after going through the UI.
#define PAPER_MARK_TEXT(text, color, font) "<span style=\"color:[color];font-family:'[font]';\">[text]</span>\n \n"

/// Folder directory for strings
#define STRING_DIRECTORY "strings"

#define FILE_LOAD_PATH(path) file(sanitize_filepath(path))
#define FILE_LOAD_RSCPATH(rscpath) file(sanitize_rscpath(rscpath))

#define FILE2TEXT_PATH(path) file2text(sanitize_filepath(path))
#define FILE2TEXT_RSCPATH(path) file2text(sanitize_rscpath(path))

#define TEXT2FILE_PATH(content, path) text2file(content, sanitize_filepath(path))
#define TEXT2FILE_FILE(content, file) world.text2file_file(content, file)

/world/proc/text2file_file(content, file)
	return text2file(content, file)

/proc/sanitize_rscpath(rscpath)
	if(!isfile(rscpath))
		return null
	return rscpath
