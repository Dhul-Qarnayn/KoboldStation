
//Not to be confused with /obj/item/weapon/reagent_containers/food/drinks/bottle

/obj/item/weapon/reagent_containers/glass/bottle
	name = "bottle"
	desc = "A small bottle."
	icon = 'icons/obj/chemical.dmi'
	icon_state = null
	item_state = "atoxinbottle"
	amount_per_transfer_from_this = 10
	possible_transfer_amounts = list(5,10,15,25,30,60)
	flags = 0
	volume = 60

/obj/item/weapon/reagent_containers/glass/bottle/on_reagent_change()
	update_icon()

/obj/item/weapon/reagent_containers/glass/bottle/pickup(mob/user)
	..()
	update_icon()

/obj/item/weapon/reagent_containers/glass/bottle/dropped(mob/user)
	..()
	update_icon()

/obj/item/weapon/reagent_containers/glass/bottle/attack_hand()
	..()
	update_icon()

/obj/item/weapon/reagent_containers/glass/bottle/Initialize()
	. = ..()
	if(!icon_state)
		icon_state = "bottle-[rand(1,4)]"

	update_icon()

/obj/item/weapon/reagent_containers/glass/bottle/update_icon()
	cut_overlays()

	if(reagents.total_volume && (icon_state == "bottle-1" || icon_state == "bottle-2" || icon_state == "bottle-3" || icon_state == "bottle-4"))
		var/image/filling = image('icons/obj/reagentfillings.dmi', src, "[icon_state]10")

		var/percent = round((reagents.total_volume / volume) * 100)
		switch(percent)
			if(0 to 9)		filling.icon_state = "[icon_state]--10"
			if(10 to 24) 	filling.icon_state = "[icon_state]-10"
			if(25 to 49)	filling.icon_state = "[icon_state]-25"
			if(50 to 74)	filling.icon_state = "[icon_state]-50"
			if(75 to 79)	filling.icon_state = "[icon_state]-75"
			if(80 to 90)	filling.icon_state = "[icon_state]-80"
			if(91 to INFINITY)	filling.icon_state = "[icon_state]-100"

		filling.color = reagents.get_color()
		add_overlay(filling)

	if (!is_open_container())
		add_overlay("lid_bottle")

/obj/item/weapon/reagent_containers/glass/bottle/inaprovaline
	name = "inaprovaline bottle"
	desc = "A small bottle. Contains inaprovaline - used to stabilize patients."
	icon_state = "bottle-4"
	reagents_to_add = list("inaprovaline" = 60)


/obj/item/weapon/reagent_containers/glass/bottle/toxin
	name = "toxin bottle"
	desc = "A small bottle of toxins. Do not drink, it is poisonous."
	icon_state = "bottle-3"
	reagents_to_add = list("toxin" = 60)

/obj/item/weapon/reagent_containers/glass/bottle/cyanide
	name = "cyanide bottle"
	desc = "A small bottle of cyanide. Bitter almonds?"
	icon_state = "bottle-3"
	reagents_to_add = list("cyanide" = 30)

/obj/item/weapon/reagent_containers/glass/bottle/stoxin
	name = "soporific bottle"
	desc = "A small bottle of soporific. Just the fumes make you sleepy."
	icon_state = "bottle-3"
	reagents_to_add = list("stoxin" = 60)

/obj/item/weapon/reagent_containers/glass/bottle/chloralhydrate
	name = "chloral hydrate bottle"
	desc = "A small bottle of Choral Hydrate. Mickey's Favorite!"
	icon_state = "bottle-3"
	reagents_to_add = list("chloralhydrate" = 30)

/obj/item/weapon/reagent_containers/glass/bottle/antitoxin
	name = "dylovene bottle"
	desc = "A small bottle of dylovene. Counters poisons, and repairs damage. A wonder drug."
	icon_state = "bottle-4"
	reagents_to_add = list("anti_toxin" = 60)

/obj/item/weapon/reagent_containers/glass/bottle/mutagen
	name = "unstable mutagen bottle"
	desc = "A small bottle of unstable mutagen. Randomly changes the DNA structure of whoever comes in contact."
	icon_state = "bottle-1"
	reagents_to_add = list("mutagen" = 60)

/obj/item/weapon/reagent_containers/glass/bottle/ammonia
	name = "ammonia bottle"
	desc = "A small bottle."
	icon_state = "bottle-1"
	reagents_to_add = list("ammonia" = 60)

/obj/item/weapon/reagent_containers/glass/bottle/diethylamine
	name = "diethylamine bottle"
	desc = "A small bottle."
	icon_state = "bottle-4"
	reagents_to_add = list("diethylamine" = 60)

/obj/item/weapon/reagent_containers/glass/bottle/pacid
	name = "Polytrinic Acid Bottle"
	desc = "A small bottle. Contains a small amount of Polytrinic Acid"
	icon_state = "bottle-4"
	reagents_to_add = list("pacid" = 60)

/obj/item/weapon/reagent_containers/glass/bottle/adminordrazine
	name = "Adminordrazine Bottle"
	desc = "A small bottle. Contains the liquid essence of the gods."
	icon = 'icons/obj/drinks.dmi'
	icon_state = "holyflask"
	reagents_to_add = list("adminordrazine" = 60)

/obj/item/weapon/reagent_containers/glass/bottle/capsaicin
	name = "capsaicin bottle"
	desc = "A small bottle. Contains hot sauce."
	icon_state = "bottle-4"
	reagents_to_add = list("capsaicin" = 60)

/obj/item/weapon/reagent_containers/glass/bottle/frostoil
	name = "frost oil bottle"
	desc = "A small bottle. Contains cold sauce."
	icon_state = "bottle-4"
	reagents_to_add = list("frostoil" = 60)

/obj/item/weapon/reagent_containers/glass/bottle/pyrosilicate
	name = "pyrosilicate bottle"
	desc = "A small bottle. Contains pyrosilicate - used to heat up reagents."
	icon_state = "bottle-4"
	reagents_to_add = list("pyrosilicate" = 60)

/obj/item/weapon/reagent_containers/glass/bottle/cryosurfactant
	name = "cryosurfactant bottle"
	desc = "A small bottle. Contains cryosurfactant - used to cool down reagents."
	icon_state = "bottle-4"
	reagents_to_add = list("cryosurfactant" = 60)

/obj/item/weapon/reagent_containers/glass/bottle/phoron_salt
	name = "phoron salt bottle"
	desc = "A small bottle. Contains phoron salt - a mysterious and unstable chemical."
	icon_state = "bottle-4"
	reagents_to_add = list("phoron_salt" = 60)

/obj/item/weapon/reagent_containers/glass/bottle/epinephrine
	name = "epinephrine bottle"
	desc = "A small bottle. Contains epinephrine, also known as adrenaline, is a super strength stimulant and painkiller intended to keep a patient alive while in critical condition. Overdose causes heart damage and an energy boost equivelent to hyperzine."
	icon_state = "bottle-4"
	reagents_to_add = list("epinephrine" = 60)

/obj/item/weapon/reagent_containers/glass/bottle/dexalin_plus
	name = "dexalin plus bottle"
	desc = "A small bottle. Contains Dexalin Plus that is used in the treatment of oxygen deprivation. It is highly effective, and is twice as powerful and lasts twice as long when inhaled."
	icon_state = "bottle-4"
	reagents_to_add = list("dexalinp" = 60)

/obj/item/weapon/reagent_containers/glass/bottle/spaceacillin
	name = "spaceacillin bottle"
	desc = "A small bottle. Contains spaceacillin. An all-purpose antiviral agent."
	icon_state = "bottle-4"
	reagents_to_add = list("spaceacillin" = 60)

/obj/item/weapon/reagent_containers/glass/bottle/coughsyrup
	name = "cough syrup bottle"
	desc = "A small bottle of cough syrup. Don't take too much!"
	icon_state = "bottle-3"
	reagents_to_add = list("coughsyrup" = 60)

/obj/item/weapon/reagent_containers/glass/bottle/thetamycin
	name = "thetamycin bottle"
	desc = "A small bottle of thetamycin. Used for disinfecting whatever wounds security caused."
	icon_state = "bottle-4"
	reagents_to_add = list("thetamycin" = 60)