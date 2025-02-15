var/datum/antagonist/revolutionary/revs

/datum/antagonist/revolutionary
	id = MODE_REVOLUTIONARY
	role_text = "Head Revolutionary"
	role_text_plural = "Revolutionaries"
	bantype = "revolutionary"
	feedback_tag = "rev_objective"
	antag_indicator = "rev_head"
	welcome_text = "Down with the capitalists! Down with the Bourgeoise!"
	victory_text = "The heads of staff were relieved of their posts! The revolutionaries win!"
	loss_text = "The heads of staff managed to stop the revolution!"
	victory_feedback_tag = "win - heads killed"
	loss_feedback_tag = "loss - rev heads killed"
	flags = ANTAG_SUSPICIOUS | ANTAG_VOTABLE
	antaghud_indicator = "hudrevolutionary"

	hard_cap = 2
	hard_cap_round = 4
	initial_spawn_req = 2
	initial_spawn_target = 4

	//Inround revs.
	faction_role_text = "Revolutionary"
	faction_descriptor = "Revolution"
	faction_verb = /mob/living/proc/convert_to_rev
	faction_welcome = "Help the cause overturn the ruling class. Do not harm your fellow freedom fighters."
	faction_indicator = "rev"
	faction_invisible = 1

	restricted_jobs = list("AI", "Cyborg")
	protected_jobs = list("Security Officer", "Security Cadet", "Warden", "Detective", "Forensic Technician", "Head of Personnel", "Chief Engineer", "Research Director", "Chief Medical Officer", "Captain", "Head of Security", "Internal Affairs Agent")

/datum/antagonist/revolutionary/New()
	..()
	revs = src

/datum/antagonist/revolutionary/can_become_antag(var/datum/mind/player)
	if(!..())
		return 0
	for(var/obj/item/weapon/implant/loyalty/L in player.current)
		if(L && (L.imp_in == player.current))
			return 0
	return 1

/datum/antagonist/revolutionary/equip(var/mob/living/carbon/human/player)

	if(!..())
		return 0

	player.equip_to_slot_or_del(new /obj/item/device/announcer(player), slot_in_backpack)

	give_codewords(player)
	return 1
