// 'basic' language; spoken by default.
/datum/language/kobold
	name = LANGUAGE_KOBOLD
	desc = "The common language of Kobolds, similar to what would be considered a romance language on Earth, typically considered poetic by elves."
	speech_verb = "says"
	whisper_verb = "whispers"
	key = "0"
	flags = TCOMSSIM
	space_chance = 40
	syllables = list(
		"za", "az", "ze", "ez", "zi", "iz", "zo", "oz", "zu", "uz", "zs", "sz",
		"ha", "ah", "he", "eh", "hi", "ih", "ho", "oh", "hu", "uh", "hs", "sh",
		"la", "al", "le", "el", "li", "il", "lo", "ol", "lu", "ul", "ls", "sl",
		"ka", "ak", "ke", "ek", "ki", "ik", "ko", "ok", "ku", "uk", "ks", "sk",
		"sa", "as", "se", "es", "si", "is", "so", "os", "su", "us", "ss", "ss",
		"ra", "ar", "re", "er", "ri", "ir", "ro", "or", "ru", "ur", "rs", "sr",
		"a",  "a",  "e",  "e",  "i",  "i",  "o",  "o",  "u",  "u",  "s",  "s"
	)
	partial_understanding = list(LANGUAGE_DRAGON = 70)

/datum/language/kobold/get_spoken_verb(var/msg_end)
	switch(msg_end)
		if("!")
			return pick("exclaims","shouts","yells") //TODO: make the basic proc handle lists of verbs.
		if("?")
			return ask_verb
	return speech_verb


// human-specific language
/datum/language/human
	name = LANGUAGE_HUMAN
	desc = "The common language of humans, known for being dry and bland. Just like the creatures themselves!"
	speech_verb = "deadpans"
	whisper_verb = "snarks"
	key = "h"
	flags = TCOMSSIM

/datum/language/human/get_spoken_verb(var/msg_end)
	switch(msg_end)
		if("!")
			return pick("exclaims","shouts","yells") //TODO: make the basic proc handle lists of verbs.
		if("?")
			return ask_verb
	return speech_verb

/datum/language/dragon
	name = LANGUAGE_DRAGON
	desc = "An elaborate, high-context language spoken universally by dragons and widely by magicians, regarded as the ideal form of language by most of the former."
	speech_verb = "hisses"
	ask_verb = "hisses"
	exclaim_verb = "roars"
	key = "d"
	flags = TCOMSSIM
	syllables = list("azs","zis","zau","azua","skiu","zuakz","izo","aei","ki","kut","zo")
