/* Toxins, poisons, venoms */

/datum/reagent/toxin
	name = "Toxin"
	id = "toxin"
	description = "A toxic chemical."
	reagent_state = LIQUID
	color = "#CF3600"
	metabolism = REM * 0.1 // 0.02 by default. They last a while and slowly kill you.
	var/strength = 4 // How much damage it deals per unit
	taste_description = "bitterness"
	taste_mult = 1.2
	fallback_specific_heat = 0.75

/datum/reagent/toxin/affect_blood(var/mob/living/carbon/M, var/alien, var/removed)
	if(strength)
		M.adjustToxLoss(strength * removed)

/datum/reagent/toxin/plasticide
	name = "Plasticide"
	id = "plasticide"
	description = "Liquid plastic, do not eat."
	reagent_state = LIQUID
	color = "#CF3600"
	strength = 5
	taste_description = "plastic"

/datum/reagent/toxin/amatoxin
	name = "Amatoxin"
	id = "amatoxin"
	description = "A powerful poison derived from certain species of mushroom."
	reagent_state = LIQUID
	color = "#792300"
	strength = 10
	taste_description = "mushroom"

/datum/reagent/toxin/carpotoxin
	name = "Carpotoxin"
	id = "carpotoxin"
	description = "A deadly neurotoxin produced by the dreaded space carp."
	reagent_state = LIQUID
	color = "#003333"
	strength = 10
	taste_description = "fish"

/datum/reagent/toxin/carpotoxin/affect_ingest(var/mob/living/carbon/M, var/alien, var/removed)
	if(alien && alien != IS_HUMAN)
		return
	..()

/datum/reagent/toxin/panotoxin
	name = "Panotoxin"
	id = "panotoxin"
	description = "A strange poison from the strange panocelium mushroom that causes intense pain when injected."
	reagent_state = LIQUID
	color = "#008844"
	strength = 0
	taste_description = "stinging needles"

/datum/reagent/toxin/panotoxin/affect_blood(var/mob/living/carbon/M, var/alien, var/removed)
	M.adjustHalLoss(removed*15)

/datum/reagent/toxin/phoron
	name = "Phoron"
	id = "phoron"
	description = "Phoron in its liquid form. Twice as potent when breathed in."
	reagent_state = LIQUID
	color = "#9D14DB"
	strength = 30
	touch_met = 5
	taste_mult = 1.5
	breathe_mul = 2
	fallback_specific_heat = 12 //Phoron is very dense and can hold a lot of energy.

/datum/reagent/toxin/phoron/touch_mob(var/mob/living/L, var/amount)
	. = ..()
	if(istype(L))
		L.adjust_fire_stacks(amount / 5)

/datum/reagent/toxin/phoron/affect_touch(var/mob/living/carbon/M, var/alien, var/removed)
	M.take_organ_damage(0, removed * 0.1) //being splashed directly with phoron causes minor chemical burns
	if(prob(50))
		M.pl_effects()

/datum/reagent/toxin/phoron/touch_turf(var/turf/simulated/T)
	if(!istype(T))
		return
	T.assume_gas("phoron", volume, T20C)
	remove_self(volume)

/datum/reagent/toxin/phoron_salt //Remember to exclude in RNG chems.
	name = "Phoron Salts"
	id = "phoron_salt"
	description = "A mysterious molten mixture with strange chemical properties. Incredibly deadly to all lifeforms, especially Vaurca."
	reagent_state = SOLID
	color = "#7C4876"
	strength = 30
	default_temperature = 130 //Kelvin

/datum/reagent/toxin/cyanide //Fast and Lethal
	name = "Cyanide"
	id = "cyanide"
	description = "A highly toxic chemical."
	reagent_state = LIQUID
	color = "#CF3600"
	strength = 20
	metabolism = REM * 2
	taste_description = "bitter almonds"
	taste_mult = 1.5

/datum/reagent/toxin/cyanide/affect_blood(var/mob/living/carbon/M, var/alien, var/removed)
	..()
	var/mob/living/carbon/human/H = M
	if(istype(H) && (H.species.flags & NO_BLOOD))
		return
	M.adjustOxyLoss(20 * removed)

/datum/reagent/toxin/potassium_chloride
	name = "Potassium Chloride"
	id = "potassium_chloride"
	description = "A delicious salt that stops the heart when injected into cardiac muscle."
	reagent_state = SOLID
	color = "#FFFFFF"
	strength = 0
	overdose = REAGENTS_OVERDOSE
	taste_description = "salt"

/datum/reagent/toxin/potassium_chloride/overdose(var/mob/living/carbon/M, var/alien)
	..()
	var/mob/living/carbon/human/H = M
	if(!istype(H) || (H.species.flags & NO_BLOOD))
		return
	if(H.stat != 1)
		if(H.losebreath >= 10)
			H.losebreath = max(10, H.losebreath - 10)
		H.adjustOxyLoss(2)
		H.Weaken(10)

/datum/reagent/toxin/potassium_chlorophoride
	name = "Potassium Chlorophoride"
	id = "potassium_chlorophoride"
	description = "A specific chemical based on Potassium Chloride to stop the heart for surgery. Not safe to eat!"
	reagent_state = SOLID
	color = "#FFFFFF"
	strength = 10
	overdose = 20
	taste_description = "salt"

/datum/reagent/toxin/potassium_chlorophoride/affect_blood(var/mob/living/carbon/M, var/alien, var/removed)
	..()
	var/mob/living/carbon/human/H = M
	if(!istype(H) || (H.species.flags & NO_BLOOD))
		return
	if(H.stat != 1)
		if(H.losebreath >= 10)
			H.losebreath = max(10, M.losebreath-10)
		H.adjustOxyLoss(2)
		H.Weaken(10)

/datum/reagent/toxin/zombiepowder
	name = "Zombie Powder"
	id = "zombiepowder"
	description = "A strong neurotoxin that puts the subject into a death-like state."
	reagent_state = SOLID
	color = "#669900"
	metabolism = REM
	strength = 3
	taste_description = "death"

/datum/reagent/toxin/zombiepowder/affect_blood(var/mob/living/carbon/M, var/alien, var/removed)
	..()
	var/mob/living/carbon/human/H = M
	if(istype(H) && (H.species.flags & NO_SCAN))
		return
	M.status_flags |= FAKEDEATH
	M.adjustOxyLoss(3 * removed)
	M.Weaken(10)
	M.silent = max(M.silent, 10)
	M.tod = worldtime2text()

/datum/reagent/toxin/zombiepowder/Destroy()
	if(holder && holder.my_atom && ismob(holder.my_atom))
		var/mob/M = holder.my_atom
		M.status_flags &= ~FAKEDEATH
	return ..()

/datum/reagent/toxin/fertilizer //Reagents used for plant fertilizers.
	name = "fertilizer"
	id = "fertilizer"
	description = "A chemical mix good for growing plants with."
	reagent_state = LIQUID
	strength = 0.5 // It's not THAT poisonous.
	color = "#664330"
	taste_description = "plant food"
	taste_mult = 0.5
	unaffected_species = IS_MACHINE

/datum/reagent/toxin/fertilizer/eznutrient
	name = "EZ Nutrient"
	id = "eznutrient"

/datum/reagent/toxin/fertilizer/left4zed
	name = "Left-4-Zed"
	id = "left4zed"

/datum/reagent/toxin/fertilizer/robustharvest
	name = "Robust Harvest"
	id = "robustharvest"

/datum/reagent/toxin/fertilizer/monoammoniumphosphate
	name = "Monoammonium Phosphate"
	id = "monoammoniumphosphate"
	strength = 0.25
	description = "Commonly found in fire extinguishers, also works as a fertilizer."
	reagent_state = SOLID
	color = "#CCCCCC"
	taste_description = "salty dirt"
	touch_met = REM * 10
	breathe_mul = 0

/datum/reagent/toxin/fertilizer/monoammoniumphosphate/touch_turf(var/turf/simulated/T)
	if(!istype(T))
		return

	var/hotspot = (locate(/obj/fire) in T)
	if(hotspot && !istype(T, /turf/space))
		var/datum/gas_mixture/lowertemp = T.return_air()
		lowertemp.temperature = max(lowertemp.temperature-2000, lowertemp.temperature / 2, T0C)
		lowertemp.react()
		qdel(hotspot)

	var/amount_to_remove = max(1,round(volume * 0.5))

	new /obj/effect/decal/cleanable/foam(T, amount_to_remove)
	remove_self(amount_to_remove)
	return

/datum/reagent/toxin/fertilizer/monoammoniumphosphate/touch_mob(var/mob/living/L, var/amount)
	. = ..()
	if(istype(L))
		var/needed = min(L.fire_stacks, amount)
		L.ExtinguishMob(3* needed) // Foam is 3 times more efficient at extinguishing
		remove_self(needed)

/datum/reagent/toxin/fertilizer/monoammoniumphosphate/affect_touch(var/mob/living/carbon/slime/S, var/alien, var/removed)
	if(istype(S))
		S.adjustToxLoss( volume * (removed/REM) * 0.23 )
		if(!S.client)
			if(S.Target) // Like cats
				S.Target = null
				++S.Discipline
		if(dose == removed)
			S.visible_message("<span class='warning'>[S]'s flesh sizzles where the foam touches it!</span>", "<span class='danger'>Your flesh burns in the foam!</span>")

/datum/reagent/toxin/plantbgone
	name = "Plant-B-Gone"
	id = "plantbgone"
	description = "A harmful toxic mixture to kill plantlife. Do not ingest!"
	reagent_state = LIQUID
	color = "#49002E"
	strength = 4
	metabolism = REM*1.5
	taste_mult = 1
	unaffected_species = IS_MACHINE

/datum/reagent/toxin/plantbgone/touch_turf(var/turf/T)
	if(istype(T, /turf/simulated/wall))
		var/turf/simulated/wall/W = T
		if(locate(/obj/effect/overlay/wallrot) in W)
			for(var/obj/effect/overlay/wallrot/E in W)
				qdel(E)
			W.visible_message("<span class='notice'>The fungi are completely dissolved by the solution!</span>")

/datum/reagent/toxin/plantbgone/touch_obj(var/obj/O, var/volume)
	if(istype(O, /obj/structure/alien/weeds))
		var/obj/structure/alien/weeds/alien_weeds = O
		alien_weeds.health -= rand(15, 35)
		alien_weeds.healthcheck()
	else if(istype(O, /obj/effect/plant))
		qdel(O)

//Affect touch automatically transfers to affect_blood, so we'll apply the damage there, after accounting for permeability
/datum/reagent/toxin/plantbgone/affect_touch(var/mob/living/carbon/M, var/alien, var/removed)
	removed *= M.reagent_permeability()
	affect_blood(M, alien, removed*0.5)

/datum/reagent/lexorin
	name = "Lexorin"
	id = "lexorin"
	description = "Lexorin temporarily stops respiration. Causes tissue damage."
	reagent_state = LIQUID
	color = "#C8A5DC"
	overdose = REAGENTS_OVERDOSE
	taste_description = "acid"

/datum/reagent/lexorin/affect_blood(var/mob/living/carbon/M, var/alien, var/removed)
	var/mob/living/carbon/human/H = M
	if(istype(H) && (H.species.flags & NO_BLOOD))
		return
	M.adjustOxyLoss(2 * removed)
	if(M.losebreath < 15)
		M.losebreath++

/datum/reagent/mutagen
	name = "Unstable mutagen"
	id = "mutagen"
	description = "Might cause unpredictable mutations. Keep away from children."
	reagent_state = LIQUID
	color = "#13BC5E"
	taste_description = "slime"
	taste_mult = 0.9

/datum/reagent/mutagen/affect_touch(var/mob/living/carbon/M, var/alien, var/removed)
	if(prob(33))
		affect_blood(M, alien, removed)

/datum/reagent/mutagen/affect_ingest(var/mob/living/carbon/M, var/alien, var/removed)
	if(prob(67))
		affect_blood(M, alien, removed)

/datum/reagent/mutagen/affect_blood(var/mob/living/carbon/M, var/alien, var/removed)
	var/mob/living/carbon/human/H = M
	if(istype(H) && (H.species.flags & NO_SCAN))
		return
	if(M.dna)
		if(prob(removed * 10)) // Approx. one mutation per 10 injected/20 ingested/30 touching units
			to_chat(M, "Something feels different about you...")
			randmuti(M)
			if(prob(98))
				randmutb(M)
			else
				randmutg(M)
			domutcheck(M, null)
			M.UpdateAppearance()
	M.apply_effect(10 * removed, IRRADIATE, blocked = 0)

/datum/reagent/slimejelly
	name = "Slime Jelly"
	id = "slimejelly"
	description = "A gooey semi-liquid produced from one of the deadliest lifeforms in existence. SO REAL."
	reagent_state = LIQUID
	color = "#801E28"
	taste_description = "slime"
	taste_mult = 1.3

/datum/reagent/slimejelly/affect_blood(var/mob/living/carbon/M, var/alien, var/removed)
	var/mob/living/carbon/human/H = M
	if(istype(H) && (H.species.flags & NO_BLOOD))
		return
	if(prob(10))
		to_chat(M, "<span class='danger'>Your insides are burning!</span>")
		M.adjustToxLoss(rand(100, 300) * removed)
	else if(prob(40))
		M.heal_organ_damage(25 * removed, 0)

/datum/reagent/soporific
	name = "Soporific"
	id = "stoxin"
	description = "An effective hypnotic used to treat insomnia, can act as a sedative. Lasts three times longer when inhaled."
	reagent_state = LIQUID
	color = "#009CA8"
	metabolism = REM * 0.5
	overdose = REAGENTS_OVERDOSE
	taste_description = "bitterness"
	breathe_met = REM * 0.5 * 0.33
	var/total_strength = 0

/datum/reagent/soporific/affect_blood(var/mob/living/carbon/M, var/alien, var/removed)
	var/mob/living/carbon/human/H = M
	if(istype(H) && (H.species.flags & NO_BLOOD))
		return
	if(dose < 1)
		if(dose == metabolism * 2 || prob(5))
			M.emote("yawn")
	else if(dose < 1.5)
		M.eye_blurry = max(M.eye_blurry, 10)
	else if(dose < 5)
		if(prob(50))
			M.Weaken(2)
		M.drowsyness = max(M.drowsyness, 20)
	else
		M.sleeping = max(M.sleeping, 20)
		M.drowsyness = max(M.drowsyness, 60)

/datum/reagent/chloralhydrate
	name = "Chloral Hydrate"
	id = "chloralhydrate"
	description = "A powerful sedative. Lasts two times longer when inhaled."
	reagent_state = SOLID
	color = "#000067"
	metabolism = REM * 0.5
	overdose = REAGENTS_OVERDOSE * 0.5
	taste_description = "bitterness"
	breathe_met = REM * 0.5 * 0.5

/datum/reagent/chloralhydrate/affect_blood(var/mob/living/carbon/M, var/alien, var/removed)
	var/mob/living/carbon/human/H = M
	if(istype(H) && (H.species.flags & NO_BLOOD))
		return
	if(dose == metabolism)
		M.confused += 2
		M.drowsyness += 2
	else if(dose < 2)
		M.Weaken(30)
		M.eye_blurry = max(M.eye_blurry, 10)
	else
		M.sleeping = max(M.sleeping, 30)

	if(dose > 1)
		M.adjustToxLoss(removed)

/datum/reagent/chloralhydrate/beer2 //disguised as normal beer for use by emagged brobots
	name = "Beer"
	id = "beer2"
	description = "An alcoholic beverage made from malted grains, hops, yeast, and water. The fermentation appears to be incomplete." //If the players manage to analyze this, they deserve to know something is wrong.
	reagent_state = LIQUID
	color = "#664300"
	taste_description = "beer"

	glass_icon_state = "beerglass"
	glass_name = "glass of beer"
	glass_desc = "A freezing pint of beer"
	glass_center_of_mass = list("x"=16, "y"=8)

	fallback_specific_heat = 1.2

/* Transformations */

/datum/reagent/slimetoxin
	name = "Mutation Toxin"
	id = "mutationtoxin"
	description = "A corruptive toxin produced by slimes."
	reagent_state = LIQUID
	color = "#13BC5E"
	taste_description = "sludge"

/datum/reagent/slimetoxin/affect_blood(var/mob/living/carbon/M, var/alien, var/removed)
	if(ishuman(M))
		var/mob/living/carbon/human/H = M
		if(H.species.name != "Slime")
			to_chat(M, "<span class='danger'>Your flesh rapidly mutates!</span>")
			H.set_species("Slime")

/datum/reagent/aslimetoxin
	name = "Advanced Mutation Toxin"
	id = "amutationtoxin"
	description = "An advanced corruptive toxin produced by slimes."
	reagent_state = LIQUID
	color = "#13BC5E"
	taste_description = "sludge"

/datum/reagent/aslimetoxin/affect_blood(var/mob/living/carbon/M, var/alien, var/removed) // TODO: check if there's similar code anywhere else
	if(M.transforming)
		return
	to_chat(M, "<span class='danger'>Your flesh rapidly mutates!</span>")
	M.transforming = 1
	M.canmove = 0
	M.icon = null
	M.cut_overlays()
	M.invisibility = 101
	for(var/obj/item/W in M)
		if(istype(W, /obj/item/weapon/implant)) //TODO: Carn. give implants a dropped() or something
			qdel(W)
			continue
		W.layer = initial(W.layer)
		W.forceMove(M.loc)
		W.dropped(M)
	var/mob/living/carbon/slime/new_mob = new /mob/living/carbon/slime(M.loc)
	new_mob.a_intent = "hurt"
	new_mob.universal_speak = 1
	if(M.mind)
		M.mind.transfer_to(new_mob)
	else
		new_mob.key = M.key
	qdel(M)

/datum/reagent/toxin/undead
	name = "Undead Ichor"
	id = "undead_ichor"
	description = "A wicked liquid with unknown origins and uses."
	color = "#b2beb5"
	strength = 25
	taste_description = "ashes"

/datum/reagent/toxin/undead/affect_blood(var/mob/living/carbon/M, var/alien, var/removed)
	if(alien && alien == IS_UNDEAD)
		M.heal_organ_damage(10 * removed, 15 * removed)
		return
	..()

/datum/reagent/toxin/tobacco
	name = "Space Tobacco"
	id = "tobacco"
	description = "Low-grade space tobacco."
	reagent_state = LIQUID
	color = "#333300"
	data = 0
	taste_description = "low-grade tobacco"
	strength = 0.004
	taste_mult = 10

/datum/reagent/toxin/tobacco/affect_blood(var/mob/living/carbon/human/M, var/alien, var/removed)
	if(istype(M))
		var/obj/item/organ/H = M.internal_organs_by_name["heart"]
		if(istype(H))
			H.take_damage(removed * strength * 0.5,1)
		var/obj/item/organ/L = M.internal_organs_by_name["lungs"]
		if(istype(L))
			L.take_damage(removed * strength,1)
		var/obj/item/organ/A = M.internal_organs_by_name["liver"]
		if(istype(A))
			A.take_damage(removed * strength * 0.25,1)

/datum/reagent/toxin/tobacco/rich
	name = "Earth Tobacco"
	id = "tobaccorich"
	description = "Nicknamed 'Earth Tobacco', this plant is much higher quality than it's space fairing counterpart."
	reagent_state = LIQUID
	data = 0
	taste_description = "quality tobacco"
	strength = 0.002

/datum/reagent/toxin/berserk
	name = "Red Nightshade"
	id = "berserk"
	description = "An illegal chemical enhancer, may cause aggressive and violent behavior."
	reagent_state = LIQUID
	color = "#AF111C"
	strength = 5
	taste_description = "bitterness"
	metabolism = REM * 2
	unaffected_species = IS_MACHINE
	var/datum/modifier/modifier

/datum/reagent/toxin/berserk/affect_blood(var/mob/living/carbon/M, var/removed)
	..()
	if(!modifier)
		modifier = M.add_modifier(/datum/modifier/berserk, MODIFIER_REAGENT, src, _strength = 1, override = MODIFIER_OVERRIDE_STRENGTHEN)
	M.make_jittery(20)
	M.add_chemical_effect(CE_BERSERK, 1)
	if(M.a_intent != I_HURT)
		M.a_intent_change(I_HURT)
	if(prob(20))
		M.adjustBrainLoss(5)

/datum/reagent/toxin/berserk/Destroy()
	QDEL_NULL(modifier)
	return ..()

/datum/reagent/toxin/spectrocybin
	name = "Spectrocybin"
	id = "spectrocybin"
	description = "A hallucinogen chemical, rumored to be used by mystics and religious figures in their rituals."
	reagent_state = LIQUID
	color = "#800080"
	strength = 5
	taste_description = "acid"
	metabolism = REM
	unaffected_species = IS_MACHINE

/datum/reagent/toxin/spectrocybin/affect_blood(var/mob/living/carbon/M, var/removed)
	..()
	M.hallucination = max(M.hallucination, 50)
	if(prob(10))
		M.see_invisible = SEE_INVISIBLE_CULT