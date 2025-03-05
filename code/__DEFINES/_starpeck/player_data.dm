GLOBAL_LIST_EMPTY(ckey_player_data)
GLOBAL_PROTECT(ckey_player_data)
GLOBAL_VAR_INIT(server_data, get_server_data())
GLOBAL_PROTECT(server_data)
GLOBAL_LIST_INIT(tiers_list, list("Rank 1 - Carrion" = 1, "Rank 2 - Meat" = 2, "Rank 3 - Vulture" = 3))
GLOBAL_PROTECT(tiers_list)

#define NOTE_TYPE_NOTE "Note"
#define NOTE_TYPE_COMMEND "Commend"
#define NOTE_TYPE_COMPLAINT "Complaint"
#define NOTE_TYPE_AUTO "Auto"
#define NOTE_TYPE_ACTION "Action"

#define NOTE_TYPES list(NOTE_TYPE_NOTE, NOTE_TYPE_COMMEND, NOTE_TYPE_COMPLAINT, NOTE_TYPE_AUTO, NOTE_TYPE_ACTION)

#define PLAYER_TIER_MIN 1
#define PLAYER_TIER_MAX 3

#define INSPIRATION_MAX 3

#define MAX_DONATOR_TIER 3
