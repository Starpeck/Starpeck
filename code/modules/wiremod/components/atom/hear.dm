/**
 * # Hear Component
 *
 * Listens for messages. Requires a shell.
 */
/obj/item/circuit_component/hear
	display_name = "Voice Activator"
	desc = "A component that listens for messages. Requires a shell."
	category = "Entity"

	flags_1 = HEAR_1

	/// The message heard
	var/datum/port/output/message_port
	/// The language heard
	var/datum/port/output/language_port
	/// The speaker name port, usually the name of the person who spoke.
	var/datum/port/output/speaker_name
	/// The speaker entity that is currently speaking. Not necessarily the person who is speaking.
	var/datum/port/output/speaker_port
	/// The trigger sent when this event occurs
	var/datum/port/output/trigger_port

/obj/item/circuit_component/hear/populate_ports()
	message_port = add_output_port("Message", PORT_TYPE_STRING)
	language_port = add_output_port("Language", PORT_TYPE_STRING)
	speaker_port = add_output_port("Speaker", PORT_TYPE_ATOM)
	speaker_name = add_output_port("Speaker Name", PORT_TYPE_STRING)
	trigger_port = add_output_port("Triggered", PORT_TYPE_SIGNAL)

/obj/item/circuit_component/hear/register_shell(atom/movable/shell)
	if(parent.loc != shell)
		RegisterSignal(shell, COMSIG_MOVABLE_HEAR, PROC_REF(on_shell_hear))

/obj/item/circuit_component/hear/unregister_shell(atom/movable/shell)

/obj/item/circuit_component/hear/proc/on_shell_hear(datum/source, list/arguments)
	return Hear(arglist(arguments))

/obj/item/circuit_component/hear/Hear(message, atom/movable/speaker, datum/language/message_language, raw_message, radio_freq, list/spans, list/message_mods)
	if(speaker == parent?.shell)
		return

	message_port.set_output(raw_message)
	if(message_language)
		language_port.set_output(initial(message_language.name))
	speaker_port.set_output(speaker)
	speaker_name.set_output(speaker.GetVoice())
	trigger_port.set_output(COMPONENT_SIGNAL)
