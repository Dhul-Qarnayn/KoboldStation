#define NUTRIMENT_GOOD "nutriment"
#define NUTRIMENT_BAD  "synnutriment"

//Food items that are eaten normally and don't leave anything behind.
/obj/item/weapon/reagent_containers/food/snacks
	name = "snack"
	desc = "Yummy!"
	icon = 'icons/obj/food.dmi'
	icon_state = null
	var/bitesize = 1
	var/bitecount = 0
	var/trash = null
	var/slice_path
	var/slices_num
	var/dried_type = null
	var/dry = 0
	reagents_to_add = list(NUTRIMENT_GOOD = 0)
	reagent_data = list(NUTRIMENT_GOOD = list("food" = 1))
	center_of_mass = list("x"=16, "y"=16)
	w_class = 2
	var/datum/reagent/nutriment/coating/coating = null
	var/icon/flat_icon = null //Used to cache a flat icon generated from dipping in batter. This is used again to make the cooked-batter-overlay
	var/do_coating_prefix = 1
	//If 0, we wont do "battered thing" or similar prefixes. Mainly for recipes that include batter but have a special name

	var/cooked_icon = null
	//Used for foods that are "cooked" without being made into a specific recipe or combination.
	//Generally applied during modification cooking with oven/fryer
	//Used to stop deepfried meat from looking like slightly tanned raw meat, and make it actually look cooked

	//Placeholder for effect that trigger on eating that aren't tied to reagents.
	var/flavor = null // set_flavor()

/obj/item/weapon/reagent_containers/food/snacks/standard_splash_mob(var/mob/user, var/mob/target)
	return 1 //Returning 1 will cancel everything else in a long line of things it should do.

/obj/item/weapon/reagent_containers/food/snacks/proc/on_consume(var/mob/eater, var/mob/feeder = null)
	if(!reagents.total_volume)
		eater.visible_message("<span class='notice'>[eater] finishes eating \the [src].</span>","<span class='notice'>You finish eating \the [src].</span>")

		if (!feeder)
			feeder = eater

		feeder.drop_from_inventory(src)	//so icons update :[ //what the fuck is this????

		if(trash)
			if(ispath(trash,/obj/item))
				var/obj/item/TrashItem = new trash(feeder)
				feeder.put_in_hands(TrashItem)
			else if(istype(trash,/obj/item))
				feeder.put_in_hands(trash)
		qdel(src)
	return

/obj/item/weapon/reagent_containers/food/snacks/attack_self(mob/user as mob)
	return

/obj/item/weapon/reagent_containers/food/snacks/standard_feed_mob(var/mob/user, var/mob/target)

	user.setClickCooldown(DEFAULT_ATTACK_COOLDOWN)

	if(!istype(target))
		return

	if(!reagents.total_volume)
		to_chat(user,span("warning","There is none of \the [src] left to eat!"))
		qdel(src)
		return

	if (isanimal(target))
		var/mob/living/simple_animal/SA = target
		if(!(reagents && SA.reagents))
			return

		var/m_bitesize = bitesize * SA.bite_factor//Modified bitesize based on creature size
		var/amount_eaten = m_bitesize
		SA.scan_interval = SA.min_scan_interval//Feeding an animal will make it suddenly care about food
		m_bitesize = min(m_bitesize, reagents.total_volume)

		if (!SA.can_eat() || ((user.reagents.maximum_volume - user.reagents.total_volume) < m_bitesize * 0.5))
			to_chat(user,span("danger","\The [target.name] can't stomach anymore food!"))
			return

		amount_eaten = reagents.trans_to_mob(SA, min(reagents.total_volume,m_bitesize), CHEM_INGEST)

		if (amount_eaten)
			bitecount++
			if (amount_eaten >= m_bitesize)
				user.visible_message(span("notice","\The [user] feeds \the [target] \the [src]."))
				if (!istype(target.loc, /turf))//held mobs don't see visible messages
					to_chat(target,span("notice","\The [user] feeds you \the [src]."))
			else
				user.visible_message(span("notice","\The [user] feeds \the [target] a tiny bit of \the [src]. <b>It looks full.</b>"))
				if (!istype(target.loc, /turf))
					to_chat(target,span("notice","\The [user] feeds you a tiny bit of \the [src]. <b>You feel pretty full!</b>"))
			return 1
	else

		var/expected_fullness = user.max_nutrition > 0 ? (user.nutrition + (user.reagents.get_reagent_amount("nutriment") * 25)) / user.max_nutrition : CREW_NUTRITION_OVEREATEN + 0.01
		expected_fullness += (user.overeatduration/600)*0.5
		var/is_full = (expected_fullness >= 1)

		if(user == target)
			if(!user.can_eat(src))
				return

			var/feedback_message

			if(is_full)
				feedback_message = "You cannot force any more of \the [src] to go down your throat!"
			else if(expected_fullness <= CREW_NUTRITION_VERYHUNGRY)
				feedback_message = "You hungrily chew out a piece of \the [src] and gobble it!"
			else if(expected_fullness <= CREW_NUTRITION_HUNGRY)
				feedback_message = "You hungrily begin to eat \the [src]."
			else if(expected_fullness <= CREW_NUTRITION_SLIGHTLYHUNGRY)
				feedback_message = "You take a bite of \the [src]."
			else if(expected_fullness <= CREW_NUTRITION_FULL)
				feedback_message = "You take a bite of \the [src]."
			else if(expected_fullness <= CREW_NUTRITION_OVEREATEN)
				feedback_message = "You unwillingly chew a bit of \the [src]."


			if(is_full)
				to_chat(user,span("danger",feedback_message))
				return
			reagents.trans_to_mob(target, min(reagents.total_volume,bitesize), CHEM_INGEST)
		else
			if(!target.can_force_feed(user, src))
				return
			if(is_full)
				to_chat(user,span("warning","\The [target] can't stomach any more food!"))
				return

			other_feed_message_start(user,target)
			if(!do_mob(user, target))
				return
			other_feed_message_finish(user,target)

			var/contained = reagentlist()
			target.attack_log += text("\[[time_stamp()]\] <font color='orange'>Has been fed [name] by [key_name(user)] Reagents: [contained]</font>")
			user.attack_log += text("\[[time_stamp()]\] <font color='red'>Fed [name] to [key_name(target)] Reagents: [contained]</font>")
			msg_admin_attack("[key_name_admin(user)] fed [key_name_admin(target)] with [name] Reagents: [contained] (INTENT: [uppertext(user.a_intent)]) (<A HREF='?_src_=holder;adminplayerobservecoodjump=1;X=[user.x];Y=[user.y];Z=[user.z]'>JMP</a>)",ckey=key_name(user),ckey_target=key_name(target))
			reagents.trans_to_mob(target, min(reagents.total_volume,bitesize), CHEM_INGEST)

	feed_sound(user)
	bitecount++
	on_consume(target,user)

	return 1

/obj/item/weapon/reagent_containers/food/snacks/examine(mob/user)
	if(!..(user, 1))
		return
	if(name != initial(name))
		to_chat(user, "<span class='notice'>You know the item as [initial(name)], however a little piece of propped up paper indicates it's \a [name].</span>")
	if (coating)
		to_chat(user, "<span class='notice'>It's coated in [coating.name]!</span>")
	if (bitecount==0)
		return
	else if (bitecount==1)
		to_chat(user, "<span class='notice'>\The [src] was bitten by someone!</span>")
	else if (bitecount<=3)
		to_chat(user, "<span class='notice'>\The [src] was bitten [bitecount] time\s!</span>")
	else
		to_chat(user, "<span class='notice'>\The [src] was bitten multiple times!</span>")

/obj/item/weapon/reagent_containers/food/snacks/attackby(obj/item/weapon/W as obj, mob/user as mob)

	if(istype(W,/obj/item/weapon/pen))

		var/selection = alert(user,"Which attribute do you wish to edit?","Food Editor","Name","Description","Cancel")
		if(selection == "Name")
			var/input_clean_name = sanitize(input(user,"What is the name of this food?", "Set Food Name") as text|null, MAX_LNAME_LEN)
			if(input_clean_name)
				user.visible_message("<span class='notice'>\The [user] labels \the [name] as \"[input_clean_name]\".</span>")
				name = input_clean_name
			else
				name = initial(name)
		else if(selection == "Description")
			var/input_clean_desc = sanitize(input(user,"What is the description of this food?", "Set Food Description") as text|null, MAX_MESSAGE_LEN)
			if(input_clean_desc)
				user.visible_message("<span class='notice'>\The [user] adds a note to \the [name].</span>")
				desc = input_clean_desc
			else
				desc = initial(desc)
		return

	if(istype(W,/obj/item/weapon/storage))
		..() // -> item/attackby()
		return

	// Eating with forks
	if(istype(W,/obj/item/weapon/material/kitchen/utensil))
		var/obj/item/weapon/material/kitchen/utensil/U = W
		if(U.scoop_food)
			if(!U.reagents)
				U.create_reagents(5)

			if (U.reagents.total_volume > 0)
				to_chat(user, "<span class='warning'>You already have something on your [U].</span>")
				return

			user.visible_message( \
				"\The [user] scoops up some [src] with \the [U]!", \
				"<span class='notice'>You scoop up some [src] with \the [U]!</span>" \
			)

			src.bitecount++
			U.cut_overlays()
			U.loaded = "[src]"
			var/image/I = new(U.icon, "loadedfood")
			I.color = src.filling_color
			U.add_overlay(I)

			reagents.trans_to_obj(U, min(reagents.total_volume,5))

			if (reagents.total_volume <= 0)
				qdel(src)
			return

	if (is_sliceable())
		//these are used to allow hiding edge items in food that is not on a table/tray
		var/can_slice_here = isturf(src.loc) && ((locate(/obj/structure/table) in src.loc) || (locate(/obj/machinery/optable) in src.loc) || (locate(/obj/item/weapon/tray) in src.loc))
		var/hide_item = !has_edge(W) || !can_slice_here

		if (hide_item)
			if (W.w_class >= src.w_class || is_robot_module(W))
				return

			to_chat(user, "<span class='warning'>You slip \the [W] inside \the [src].</span>")
			user.remove_from_mob(W)
			W.dropped(user)
			add_fingerprint(user)
			contents += W
			return

		if (has_edge(W))
			if (!can_slice_here)
				to_chat(user, "<span class='warning'>You cannot slice \the [src] here! You need a table or at least a tray to do it.</span>")
				return

			var/slices_lost = 0
			if (W.w_class > 3)
				user.visible_message("<span class='notice'>\The [user] crudely slices \the [src] with [W]!</span>", "<span class='notice'>You crudely slice \the [src] with your [W]!</span>")
				slices_lost = rand(1,min(1,round(slices_num/2)))
			else
				user.visible_message("<span class='notice'>\The [user] slices \the [src]!</span>", "<span class='notice'>You slice \the [src]!</span>")

			var/reagents_per_slice = reagents.total_volume/slices_num
			for(var/i=1 to (slices_num-slices_lost))
				var/obj/slice = new slice_path (src.loc)
				reagents.trans_to_obj(slice, reagents_per_slice)
			qdel(src)
			return

/obj/item/weapon/reagent_containers/food/snacks/proc/is_sliceable()
	return (slices_num && slice_path && slices_num > 0)

/obj/item/weapon/reagent_containers/food/snacks/Destroy()
	if(contents)
		for(var/atom/movable/something in contents)
			something.forceMove(get_turf(src))
	return ..()


//Code for dipping food in batter
/obj/item/weapon/reagent_containers/food/snacks/afterattack(obj/O as obj, mob/user as mob, proximity)
	if(O.is_open_container() && O.reagents && !(istype(O, /obj/item/weapon/reagent_containers/food)) && proximity)
		for (var/r in O.reagents.reagent_list)

			var/datum/reagent/R = r
			if (istype(R, /datum/reagent/nutriment/coating))
				if (apply_coating(R, user))
					return 1

	return ..()

//This proc handles drawing coatings out of a container when this food is dipped into it
/obj/item/weapon/reagent_containers/food/snacks/proc/apply_coating(var/datum/reagent/nutriment/coating/C, var/mob/user)
	if (coating)
		to_chat(user, "The [src] is already coated in [coating.name]!")
		return 0

	//Calculate the reagents of the coating needed
	var/req = 0
	for (var/r in reagents.reagent_list)
		var/datum/reagent/R = r
		if (istype(R, /datum/reagent/nutriment))
			req += R.volume * 0.2
		else
			req += R.volume * 0.1

	req += w_class*0.5

	if (!req)
		//the food has no reagents left, its probably getting deleted soon
		return 0

	if (C.volume < req)
		to_chat(user, span("warning", "There's not enough [C.name] to coat the [src]!"))
		return 0

	var/id = C.id

	//First make sure there's space for our batter
	if (reagents.get_free_space() < req+5)
		var/extra = req+5 - reagents.get_free_space()
		reagents.maximum_volume += extra

	//Suck the coating out of the holder
	C.holder.trans_to_holder(reagents, req)

	//We're done with C now, repurpose the var to hold a reference to our local instance of it
	C = reagents.get_reagent(id)
	if (!C)
		return

	coating = C
	//Now we have to do the witchcraft with masking images
	//var/icon/I = new /icon(icon, icon_state)

	if (!flat_icon)
		flat_icon = getFlatIcon(src)
	var/icon/I = flat_icon
	color = "#FFFFFF" //Some fruits use the color var. Reset this so it doesnt tint the batter
	I.Blend(new /icon('icons/obj/food_custom.dmi', rgb(255,255,255)),ICON_ADD)
	I.Blend(new /icon('icons/obj/food_custom.dmi', coating.icon_raw),ICON_MULTIPLY)
	var/image/J = image(I)
	J.alpha = 200
	J.blend_mode = BLEND_OVERLAY
	J.tag = "coating"
	add_overlay(J)

	if (user)
		user.visible_message(span("notice", "[user] dips \the [src] into \the [coating.name]"), span("notice", "You dip \the [src] into \the [coating.name]"))

	return 1


//Called by cooking machines. This is mainly intended to set properties on the food that differ between raw/cooked
/obj/item/weapon/reagent_containers/food/snacks/proc/cook()
	if (coating)
		var/list/temp = overlays.Copy()
		for (var/i in temp)
			if (istype(i, /image))
				var/image/I = i
				if (I.tag == "coating")
					temp.Remove(I)
					break

		overlays = temp
		//Carefully removing the old raw-batter overlay

		if (!flat_icon)
			flat_icon = getFlatIcon(src)
		var/icon/I = flat_icon
		color = "#FFFFFF" //Some fruits use the color var
		I.Blend(new /icon('icons/obj/food_custom.dmi', rgb(255,255,255)),ICON_ADD)
		I.Blend(new /icon('icons/obj/food_custom.dmi', coating.icon_cooked),ICON_MULTIPLY)
		var/image/J = image(I)
		J.alpha = 200
		J.tag = "coating"
		add_overlay(J)


		if (do_coating_prefix == 1)
			name = "[coating.coated_adj] [name]"

	for (var/r in reagents.reagent_list)
		var/datum/reagent/R = r
		if (istype(R, /datum/reagent/nutriment/coating))
			var/datum/reagent/nutriment/coating/C = R
			C.data["cooked"] = 1
			C.name = C.cooked_name

// A proc for setting various flavors of the same type of food instead of creating new foods with the only difference being a flavor
/obj/item/weapon/reagent_containers/food/snacks/proc/set_flavor()
	if(!flavor)
		flavor = pick("flavored") // Use flavor = pick("option 1", "option 2", "etc") to define possible flavors before using .=..()
	name = "[flavor] [name]"

////////////////////////////////////////////////////////////////////////////////
/// FOOD END
////////////////////////////////////////////////////////////////////////////////
/obj/item/weapon/reagent_containers/food/snacks/attack_generic(var/mob/living/user)
	if(!isanimal(user) && !isalien(user))
		return

	var/amount_eaten = bitesize
	var/m_bitesize = bitesize

	if (isanimal(user))
		var/mob/living/simple_animal/SA = user
		m_bitesize = bitesize * SA.bite_factor//Modified bitesize based on creature size
		amount_eaten = m_bitesize
		if (!SA.can_eat())
			to_chat(user, "<span class='danger'>You're too full to eat anymore!</span>")
			return

	if(reagents && user.reagents)
		m_bitesize = min(m_bitesize, reagents.total_volume)
		//If the creature can't even stomach half a bite, then it eats nothing
		if (((user.reagents.maximum_volume - user.reagents.total_volume) < m_bitesize * 0.5))
			amount_eaten = 0
		else
			amount_eaten = reagents.trans_to_mob(user, m_bitesize, CHEM_INGEST)
	if (amount_eaten)
		bitecount++
		if (amount_eaten < m_bitesize)
			user.visible_message("<span class='notice'><b>[user]</b> reluctantly nibbles a tiny part of \the [src].</span>","<span class='notice'>You reluctantly nibble a tiny part of \the [src]. <b>You can't stomach much more!</b>.</span>")
		animate_shake()
		var/toplay = pick(list('sound/effects/creatures/nibble1.ogg','sound/effects/creatures/nibble2.ogg'))
		playsound(loc, toplay, 30, 1)
	else
		to_chat(user, "<span class='danger'>You're too full to eat anymore!</span>")

	spawn(5)
		if(!src && !user.client)
			user.custom_emote(1,"[pick("burps", "cries for more", "burps twice", "looks at the area where the food was")]")
			qdel(src)

	if (reagents)
		on_consume(user)

//////////////////////////////////////////////////
////////////////////////////////////////////Snacks
//////////////////////////////////////////////////
//Items in the "Snacks" subcategory are food items that people actually eat. The key points are that they are created
//	already filled with reagents and are destroyed when empty. Additionally, they make a "munching" noise when eaten.

//Notes by Darem: Food in the "snacks" subtype can hold a maximum of 50 units Generally speaking, you don't want to go over 40
//	total for the item because you want to leave space for extra condiments. If you want effect besides healing, add a reagent for
//	it. Try to stick to existing reagents when possible (so if you want a stronger healing effect, just use Tricordrazine). On use
//	effect (such as the old officer eating a donut code) requires a unique reagent (unless you can figure out a better way).

//The nutriment reagent and bitesize variable replace the old heal_amt and amount variables. Each unit of nutriment is equal to
//	2 of the old heal_amt variable. Bitesize is the rate at which the reagents are consumed. So if you have 6 nutriment and a
//	bitesize of 2, then it'll take 3 bites to eat. Unlike the old system, the contained reagents are evenly spread among all
//	the bites. No more contained reagents = no more bites.

/obj/item/weapon/reagent_containers/food/snacks/salad/aesirsalad
	name = "aesir salad"
	desc = "Probably too incredible for mortal men to fully enjoy."
	icon_state = "aesirsalad"
	trash = /obj/item/trash/snack_bowl
	filling_color = "#468C00"
	bitesize = 3
	reagents_to_add = list("nutriment" = 8, "doctorsdelight" = 8, "tricordrazine" = 8)
	reagent_data = list("nutriment" = list("apples" = 3, "salad" = 5))

/obj/item/weapon/reagent_containers/food/snacks/candy
	name = "candy"
	desc = "Nougat, love it or hate it. Made with real sugar, and no artificial preservatives!"
	icon_state = "candy"
	trash = /obj/item/trash/candy
	filling_color = "#7D5F46"
	reagents_to_add = list(NUTRIMENT_GOOD = 3)
	reagent_data = list(NUTRIMENT_GOOD = list("chocolate" = 2, "nougat" = 1))
	bitesize = 2
	reagents_to_add = list("nutriment" = 3, "sugar" = 3)
	reagent_data = list("nutriment" = list("chocolate" = 2, "nougat" = 1))

/obj/item/weapon/reagent_containers/food/snacks/candy/donor
	name = "donor candy"
	desc = "A little treat for blood donors. Made with real sugar!"
	trash = /obj/item/trash/candy
	bitesize = 5
	reagents_to_add = list("nutriment" = 10, "sugar" = 3)
	reagent_data = list("nutriment" = list("candy" = 10))

/obj/item/weapon/reagent_containers/food/snacks/candy_corn
	name = "candy corn"
	desc = "It's a handful of candy corn. Cannot be stored in a detective's hat, alas."
	icon_state = "candy_corn"
	filling_color = "#FFFCB0"
	bitesize = 2
	reagents_to_add = list("nutriment" = 4, "sugar" = 2)
	reagent_data = list("nutriment" = list("candy corn" = 4))

/obj/item/weapon/reagent_containers/food/snacks/chips
	name = "chips"
	desc = "Commander Riker's What-The-Crisps."
	icon_state = "chips"
	trash = /obj/item/trash/chips
	filling_color = "#E8C31E"
	reagents_to_add = list(NUTRIMENT_BAD = 3)
	reagent_data = list(NUTRIMENT_BAD = list("chips" = 3))
	bitesize = 1

/obj/item/weapon/reagent_containers/food/snacks/cookie
	name = "cookie"
	desc = "COOKIE!!!"
	icon_state = "COOKIE!!!"
	filling_color = "#DBC94F"
	reagents_to_add = list(NUTRIMENT_GOOD = 5)
	reagent_data = list(NUTRIMENT_GOOD = list("sweetness" = 3, "cookie" = 2))
	bitesize = 1

/obj/item/weapon/reagent_containers/food/snacks/chocolatebar
	name = "chocolate bar"
	desc = "Such sweet, fattening food."
	icon_state = "chocolatebar"
	filling_color = "#7D5F46"
	bitesize = 2
	reagents_to_add = list(NUTRIMENT_GOOD = 2)
	reagent_data = list(NUTRIMENT_GOOD = list("chocolate" = 5))

/obj/item/weapon/reagent_containers/food/snacks/chocolateegg
	name = "chocolate egg"
	desc = "Eggcellent."
	icon_state = "chocolateegg"
	filling_color = "#7D5F46"
	reagents_to_add = list(NUTRIMENT_GOOD = 3)
	reagent_data = list(NUTRIMENT_GOOD = list("chocolate" = 5))
	bitesize = 2

//a random egg that can spawn only on easter. It has really good food values because it's rare
/obj/item/weapon/reagent_containers/food/snacks/goldenegg
	name = "golden egg"
	desc = "It's the golden egg!"
	icon_state = "goldenegg"
	filling_color = "#7D5F46"
	reagents_to_add = list(NUTRIMENT_GOOD = 12)
	reagent_data = list(NUTRIMENT_GOOD = list("chocolate" = 5))
	bitesize = 6

/obj/item/weapon/reagent_containers/food/snacks/donut
	name = "donut"
	desc = "Goes great with Robust Coffee."
	icon_state = "donut1"
	filling_color = "#D9C386"
	overlay_state = "box-donut1"
	reagent_data = list(NUTRIMENT_GOOD = list("sweetness" = 1, "donut" = 2))

/obj/item/weapon/reagent_containers/food/snacks/donut/normal
	name = "donut"
	desc = "Goes great with Robust Coffee."
	icon_state = "donut1"
	reagents_to_add = list(NUTRIMENT_GOOD = 3)
	bitesize = 3

/obj/item/weapon/reagent_containers/food/snacks/donut/normal/psdonut
	name = "pumpkin spice donut"
	desc = "A limited edition seasonal pastry."
	icon_state = "donut_ps"
	reagents_to_add = list(NUTRIMENT_GOOD = 3, "sprinkles" = 1)
	reagent_data = list(NUTRIMENT_GOOD = list("pumpkin spice" = 1, "donut" = 2))

/obj/item/weapon/reagent_containers/food/snacks/donut/normal/Initialize()
	. = ..()
	if(prob(30))
		src.icon_state = "donut2"
		src.overlay_state = "box-donut2"
		src.name = "frosted donut"
		reagents.add_reagent("sprinkles", 1)

/obj/item/weapon/reagent_containers/food/snacks/donut/chaos
	name = "chaos donut"
	desc = "Like life, it never quite tastes the same."
	icon_state = "donut1"
	filling_color = "#ED11E6"
	reagents_to_add = list(NUTRIMENT_GOOD = 5, "sprinkles" = 1)
	reagent_data = list(NUTRIMENT_GOOD = list("sweetness" = 1, "donut" = 2))
	bitesize = 10

/obj/item/weapon/reagent_containers/food/snacks/donut/chaos/Initialize()
	. = ..()
	var/chaosselect = pick(1,2,3,4,5,6,7,8,9,10)
	switch(chaosselect)
		if(1)
			reagents.add_reagent("nutriment", 3)
		if(2)
			reagents.add_reagent("capsaicin", 3)
		if(3)
			reagents.add_reagent("frostoil", 3)
		if(4)
			reagents.add_reagent("sprinkles", 3)
		if(5)
			reagents.add_reagent("phoron", 3)
		if(6)
			reagents.add_reagent("coco", 3)
		if(7)
			reagents.add_reagent("slimejelly", 3)
		if(8)
			reagents.add_reagent("banana", 3)
		if(9)
			reagents.add_reagent("berryjuice", 3)
		if(10)
			reagents.add_reagent("tricordrazine", 3)
	if(prob(30))
		src.icon_state = "donut2"
		src.overlay_state = "box-donut2"
		src.name = "Frosted Chaos Donut"
		reagents.add_reagent("sprinkles", 2)


/obj/item/weapon/reagent_containers/food/snacks/donut/jelly
	name = "jelly donut"
	desc = "You jelly?"
	icon_state = "jdonut1"
	filling_color = "#ED1169"	
	bitesize = 5
	reagents_to_add = list(NUTRIMENT_GOOD = 3, "sprinkles" = 1, "berryjuice" = 5)
	reagent_data = list(NUTRIMENT_GOOD = list("sweetness" = 1, "donut" = 2))

/obj/item/weapon/reagent_containers/food/snacks/donut/jelly/Initialize()
	. = ..()
	if(prob(30))
		src.icon_state = "jdonut2"
		src.overlay_state = "box-donut2"
		src.name = "Frosted Jelly Donut"
		reagents.add_reagent("sprinkles", 2)

/obj/item/weapon/reagent_containers/food/snacks/donut/slimejelly
	name = "jelly donut"
	desc = "You jelly?"
	icon_state = "jdonut1"
	filling_color = "#ED1169"
	reagent_data = list(NUTRIMENT_GOOD = list("sweetness" = 1, "donut" = 2))
	bitesize = 5
	reagents_to_add = list(NUTRIMENT_GOOD = 3, "sprinkles" = 1, "slimejelly" = 5)

/obj/item/weapon/reagent_containers/food/snacks/donut/slimejelly/Initialize()
	. = ..()
	if(prob(30))
		src.icon_state = "jdonut2"
		src.overlay_state = "box-donut2"
		src.name = "Frosted Jelly Donut"
		reagents.add_reagent("sprinkles", 2)

/obj/item/weapon/reagent_containers/food/snacks/donut/cherryjelly
	name = "jelly donut"
	desc = "You jelly?"
	icon_state = "jdonut1"
	filling_color = "#ED1169"
	bitesize = 5
	reagents_to_add = list(NUTRIMENT_GOOD = 6, "sprinkles" = 1, "cherryjelly" = 5)
	reagent_data = list(NUTRIMENT_GOOD = list("sweetness" = 1, "donut" = 2))

/obj/item/weapon/reagent_containers/food/snacks/donut/cherryjelly/Initialize()
	. = ..()
	if(prob(30))
		src.icon_state = "jdonut2"
		src.overlay_state = "box-donut2"
		src.name = "Frosted Jelly Donut"
		reagents.add_reagent("sprinkles", 2)

/obj/item/weapon/reagent_containers/food/snacks/funnelcake
	name = "funnel cake"
	desc = "Funnel cakes rule!"
	icon_state = "funnelcake"
	filling_color = "#Ef1479"
	do_coating_prefix = 0
	bitesize = 2
	reagents_to_add = list("batter" = 10, "sugar" = 5)

/obj/item/weapon/reagent_containers/food/snacks/egg
	name = "egg"
	desc = "Can I offer you a nice egg in this trying time?"
	icon_state = "egg"
	filling_color = "#FDFFD1"
	volume = 10
	reagents_to_add = list("egg" = 3)

/obj/item/weapon/reagent_containers/food/snacks/egg/afterattack(obj/O as obj, mob/user as mob, proximity)
	if(istype(O,/obj/machinery/microwave))
		return ..()
	if(!(proximity && O.is_open_container()))
		return ..()
	to_chat(user, "You crack \the [src] into \the [O].")
	reagents.trans_to(O, reagents.total_volume)
	qdel(src)

/obj/item/weapon/reagent_containers/food/snacks/egg/throw_impact(atom/hit_atom)
	..()
	new/obj/effect/decal/cleanable/egg_smudge(src.loc)
	src.reagents.splash(hit_atom, reagents.total_volume)
	src.visible_message("<span class='warning'>\The [src] has been squashed!</span>","<span class='warning'>You hear a smack.</span>")
	qdel(src)

/obj/item/weapon/reagent_containers/food/snacks/egg/attackby(obj/item/weapon/W as obj, mob/user as mob)
	if(istype( W, /obj/item/weapon/pen/crayon ))
		var/obj/item/weapon/pen/crayon/C = W
		var/clr = C.colourName

		if(!(clr in list("blue","green","mime","orange","purple","rainbow","red","yellow")))
			to_chat(usr, "<span class='notice'>The egg refuses to take on this color!</span>")
			return

		to_chat(usr, "<span class='notice'>You color \the [src] [clr]</span>")
		icon_state = "egg-[clr]"
	else
		..()

/obj/item/weapon/reagent_containers/food/snacks/egg/blue
	icon_state = "egg-blue"

/obj/item/weapon/reagent_containers/food/snacks/egg/green
	icon_state = "egg-green"

/obj/item/weapon/reagent_containers/food/snacks/egg/mime
	icon_state = "egg-mime"

/obj/item/weapon/reagent_containers/food/snacks/egg/orange
	icon_state = "egg-orange"

/obj/item/weapon/reagent_containers/food/snacks/egg/purple
	icon_state = "egg-purple"

/obj/item/weapon/reagent_containers/food/snacks/egg/rainbow
	icon_state = "egg-rainbow"

/obj/item/weapon/reagent_containers/food/snacks/egg/red
	icon_state = "egg-red"

/obj/item/weapon/reagent_containers/food/snacks/egg/yellow
	icon_state = "egg-yellow"

/obj/item/weapon/reagent_containers/food/snacks/friedegg
	name = "fried egg"
	desc = "A fried egg, with a touch of salt and pepper."
	icon_state = "friedegg"
	filling_color = "#FFDF78"
	bitesize = 1
	reagents_to_add = list("egg" = 3, "sodiumchloride" = 1, "blackpepper" = 1)

/obj/item/weapon/reagent_containers/food/snacks/boiledegg
	name = "boiled egg"
	desc = "Hard to beat, aren't they?"
	icon_state = "egg"
	filling_color = "#FFFFFF"
	reagents_to_add = list("egg" = 2)

/obj/item/weapon/reagent_containers/food/snacks/organ
	name = "organ"
	desc = "Sorry, this isn't the instrument."
	icon = 'icons/obj/surgery.dmi'
	icon_state = "appendix"
	filling_color = "#E00D34"
	bitesize = 3
	reagents_to_add = list(NUTRIMENT_GOOD = 3, "protein" = 1)
	reagent_data = list(NUTRIMENT_GOOD = list("offal" = 3))

/obj/item/weapon/reagent_containers/food/snacks/organ/Initialize()
	. = ..()
	reagents.add_reagent("protein", rand(0,2))

/obj/item/weapon/reagent_containers/food/snacks/tofu
	name = "tofu"
	icon_state = "tofu"
	desc = "We all love tofu."
	filling_color = "#FFFEE0"
	center_of_mass = list("x"=17, "y"=10)
	bitesize = 3
	reagents_to_add = list("tofu" = 3)

/obj/item/weapon/reagent_containers/food/snacks/tofurkey
	name = "tofurkey"
	desc = "A fake turkey made from tofu."
	icon_state = "tofurkey"
	filling_color = "#FFFEE0"
	bitesize = 3
	reagents_to_add = list(NUTRIMENT_GOOD = 6, "tofu" = 6, "stoxin" = 3)
	reagent_data = list(NUTRIMENT_GOOD = list("turkey" = 3))

/obj/item/weapon/reagent_containers/food/snacks/stuffing
	name = "stuffing"
	desc = "Moist, peppery breadcrumbs for filling the body cavities of dead birds. Dig in!"
	icon_state = "stuffing"
	filling_color = "#C9AC83"
	reagents_to_add = list(NUTRIMENT_GOOD = 3)
	reagent_data = list(NUTRIMENT_GOOD = list("dryness" = 2, "bread" = 2))
	bitesize = 1

/obj/item/weapon/reagent_containers/food/snacks/carpmeat
	name = "carp fillet"
	desc = "A fillet of spess carp meat."
	icon_state = "fishfillet"
	filling_color = "#FFDEFE"
	bitesize = 6
	reagents_to_add = list("seafood" = 3, "carpotoxin" = 3)

/obj/item/weapon/reagent_containers/food/snacks/dwellermeat
	name = "worm fillet"
	desc = "A fillet of electrifying cavern meat."
	icon_state = "fishfillet"
	filling_color = "#FFDEFE"
	bitesize = 6
	reagents_to_add = list("seafood" = 6, "hyperzine" = 15, "pacid" = 6)

/obj/item/weapon/reagent_containers/food/snacks/fishfingers
	name = "fish fingers"
	desc = "A finger of fish."
	icon_state = "fishfingers"
	filling_color = "#FFDEFE"
	bitesize = 3
	reagents_to_add = list("seafood" = 4, "carpotoxin" = 3)

/obj/item/weapon/reagent_containers/food/snacks/hugemushroomslice
	name = "huge mushroom slice"
	desc = "There wasn't much room for that mushroom."
	icon_state = "hugemushroomslice"
	filling_color = "#E0D7C5"
	bitesize = 6
	reagents_to_add = list(NUTRIMENT_GOOD = 3, "psilocybin" = 3)
	reagent_data = list(NUTRIMENT_GOOD = list("raw meat" = 2, "mushroom" = 2))

/obj/item/weapon/reagent_containers/food/snacks/tomatomeat
	name = "tomato slice"
	desc = "A slice from a huge tomato."
	icon_state = "tomatomeat"
	filling_color = "#DB0000"
	reagents_to_add = list(NUTRIMENT_GOOD = 3)
	reagent_data = list(NUTRIMENT_GOOD = list("raw meat" = 2, "tomato" = 3))
	bitesize = 6

/obj/item/weapon/reagent_containers/food/snacks/bearmeat
	name = "bear meat"
	desc = "I can bearly control myself."
	icon_state = "bearmeat"
	filling_color = "#DB0000"
	bitesize = 3
	reagents_to_add = list("protein" = 12, "hyperzine" = 5)

/obj/item/weapon/reagent_containers/food/snacks/xenomeat
	name = "meat"
	desc = "A slab of green meat. Smells like acid."
	icon_state = "xenomeat"
	filling_color = "#43DE18"
	bitesize = 6
	reagents_to_add = list("protein" = 6, "pacid" = 6)

/obj/item/weapon/reagent_containers/food/snacks/meatball
	name = "meatball"
	desc = "A great meal all round."
	icon_state = "meatball"
	filling_color = "#DB0000"
	bitesize = 2
	reagents_to_add = list("protein" = 3)

/obj/item/weapon/reagent_containers/food/snacks/sausage
	name = "sausage"
	desc = "A piece of mixed, long meat."
	icon_state = "sausage"
	filling_color = "#DB0000"
	bitesize = 2
	reagents_to_add = list("protein" = 6)

/obj/item/weapon/reagent_containers/food/snacks/sausage/battered
	name = "battered sausage"
	desc = "A piece of mixed, long meat, battered and then deepfried"
	icon_state = "batteredsausage"
	filling_color = "#DB0000"
	do_coating_prefix = 0
	bitesize = 2
	reagents_to_add = list("protein" = 6, "batter" = 1.7, "oil" = 1.5)

/obj/item/weapon/reagent_containers/food/snacks/jalapeno_poppers
	name = "jalapeno popper"
	desc = "A battered, deep-fried chilli pepper"
	icon_state = "popper"
	filling_color = "#00AA00"
	do_coating_prefix = 0
	reagents_to_add = list(NUTRIMENT_GOOD = 2, "batter" = 2, "oil" = 2)
	reagent_data = list(NUTRIMENT_GOOD = list("spicy peppers" = 2))
	bitesize = 1

/obj/item/weapon/reagent_containers/food/snacks/donkpocket
	name = "Donk-pocket"
	desc = "The cold, reheatable food of choice for the seasoned spaceman."
	icon_state = "donkpocket"
	filling_color = "#DEDEAB"
	center_of_mass = list("x"=16, "y"=10)
	reagent_data = list(NUTRIMENT_GOOD = list("heartiness" = 1, "dough" = 2))
	reagents_to_add = list(NUTRIMENT_GOOD = 2)
	reagents_to_add = list(NUTRIMENT_GOOD = 2, "protein" = 2)
	reagent_data = list(NUTRIMENT_GOOD = list("heartiness" = 1, "dough" = 2))

/obj/item/weapon/reagent_containers/food/snacks/donkpocket/warm
	name = "cooked Donk-pocket"
	desc = "The cooked, reheatable food of choice for the seasoned spaceman."
	reagents_to_add = list(NUTRIMENT_GOOD = 3, "protein" = 2, "tricordrazine" = 5)
	reagent_data = list(NUTRIMENT_GOOD = list("warm heartiness" = 1, "dough" = 2))

/obj/item/weapon/reagent_containers/food/snacks/donkpocket/sinpocket
	name = "\improper Sin-pocket"
	desc = "The food of choice for the veteran. Do <B>NOT</B> overconsume. Use it in hand to heat and release chemicals."
	filling_color = "#6D6D00"
	reagents_to_add = list(NUTRIMENT_GOOD = 3, "protein" = 1)
	reagent_data = list(NUTRIMENT_GOOD = list("delicious cruelty" = 1, "dough" = 2))
	var/has_been_heated = FALSE

/obj/item/weapon/reagent_containers/food/snacks/donkpocket/sinpocket/attack_self(mob/user)
	if(has_been_heated)
		to_chat(user, "<span class='notice'>The heating chemicals have already been spent.</span>")
		return
	has_been_heated = TRUE
	user.visible_message("<span class='notice'>[user] crushes \the [src] package.</span>", "You crush \the [src] package and feel it rapidly heat up.")
	name = "cooked Sin-pocket"
	desc = "The food of choice for the veteran. Do <B>NOT</B> overconsume."
	reagents.add_reagent("doctorsdelight", 5)
	reagents.add_reagent("hyperzine", 1.5)
	reagents.add_reagent("synaptizine", 1.25)

/obj/item/weapon/reagent_containers/food/snacks/burger/brain
	name = "brainburger"
	desc = "A strange looking burger. It looks almost sentient."
	icon_state = "brainburger"
	filling_color = "#F2B6EA"
	center_of_mass = list("x"=15, "y"=11)
	bitesize = 2
	reagents_to_add = list("protein" = 6, "alkysine" = 6)

/obj/item/weapon/reagent_containers/food/snacks/burger/ghost
	name = "ghost burger"
	desc = "Spooky! It doesn't look very filling."
	icon_state = "ghostburger"
	filling_color = "#FFF2FF"
	center_of_mass = list("x"=16, "y"=11)
	reagents_to_add = list(NUTRIMENT_GOOD = 2)
	reagent_data = list(NUTRIMENT_GOOD = list("buns" = 3, "spookiness" = 3))
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/human
	var/hname = ""
	var/job = null
	filling_color = "#D63C3C"

/obj/item/weapon/reagent_containers/food/snacks/human/burger
	name = "-burger"
	desc = "A bloody burger."
	icon_state = "hburger"
	center_of_mass = list("x"=16, "y"=11)
	bitesize = 2
	reagents_to_add = list("protein" = 6)

/obj/item/weapon/reagent_containers/food/snacks/burger/cheese
	name = "cheeseburger"
	desc = "The cheese adds a good flavor."
	icon_state = "cheeseburger"
	center_of_mass = list("x"=16, "y"=11)
	reagents_to_add = list(NUTRIMENT_GOOD = 4, "cheese" = 2)
	reagent_data = list(NUTRIMENT_GOOD = list("bun" = 2))

/obj/item/weapon/reagent_containers/food/snacks/burger/monkey
	name = "burger"
	desc = "The cornerstone of every nutritious breakfast."
	icon_state = "hburger"
	filling_color = "#D63C3C"
	center_of_mass = list("x"=16, "y"=11)
	reagents_to_add = list(NUTRIMENT_GOOD = 2, "protein" = 3)
	reagent_data = list(NUTRIMENT_GOOD = list("bun" = 2))
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/burger/fish
	name = "fillet -o- carp sandwich"
	desc = "Almost like a carp is yelling somewhere... Give me back that fillet -o- carp, give me that carp."
	icon_state = "fishburger"
	filling_color = "#FFDEFE"
	center_of_mass = list("x"=16, "y"=10)
	bitesize = 3
	reagents_to_add = list("seafood" = 6, "carpotoxin" = 3)

/obj/item/weapon/reagent_containers/food/snacks/burger/tofu
	name = "tofu burger"
	desc = "What.. is that meat?"
	icon_state = "tofuburger"
	filling_color = "#FFFEE0"
	center_of_mass = list("x"=16, "y"=10)
	reagents_to_add = list(NUTRIMENT_GOOD = 3, "tofu" = 3)
	reagent_data = list(NUTRIMENT_GOOD = list("bun" = 2))
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/burger/robo
	name = "roburger"
	desc = "The lettuce is the only organic component. Beep."
	icon_state = "roburger"
	filling_color = "#CCCCCC"
	center_of_mass = list("x"=16, "y"=11)
	reagents_to_add = list(NUTRIMENT_GOOD = 2)
	reagent_data = list(NUTRIMENT_GOOD = list("bun" = 2, "metal" = 3))
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/burger/robo/Initialize()
	. = ..()
	if(prob(5))
		reagents.add_reagent("nanites", 2)

/obj/item/weapon/reagent_containers/food/snacks/burger/robobig
	name = "roburger"
	desc = "This massive patty looks like poison. Beep."
	icon_state = "roburger"
	filling_color = "#CCCCCC"
	volume = 100
	center_of_mass = list("x"=16, "y"=11)
	bitesize = 0.1
	reagents_to_add = list(NUTRIMENT_GOOD = 3, "nanites" = 100)
	reagent_data = list(NUTRIMENT_GOOD = list("bun" = 2, "metal" = 3))

/obj/item/weapon/reagent_containers/food/snacks/burger/xeno
	name = "xenoburger"
	desc = "Smells caustic. Tastes like heresy."
	icon_state = "xburger"
	filling_color = "#43DE18"
	center_of_mass = list("x"=16, "y"=11)
	bitesize = 2
	reagents_to_add = list("protein" = 8)

/obj/item/weapon/reagent_containers/food/snacks/burger/clown
	name = "clown burger"
	desc = "This tastes funny..."
	icon_state = "clownburger"
	filling_color = "#FF00FF"
	center_of_mass = list("x"=17, "y"=12)
	reagents_to_add = list(NUTRIMENT_GOOD = 6)
	reagent_data = list(NUTRIMENT_GOOD = list("bun" = 2, "crayons" = 3))
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/burger/mime
	name = "mime burger"
	desc = "Its taste defies language."
	icon_state = "mimeburger"
	filling_color = "#FFFFFF"
	center_of_mass = list("x"=16, "y"=11)
	reagents_to_add = list(NUTRIMENT_GOOD = 6)
	reagent_data = list(NUTRIMENT_GOOD = list("bun" = 2, "paint" = 3))
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/burger/mouse
	name = "rat burger"
	desc = "Squeaky and a little furry. Do you see any cows around here, Detective?"
	icon_state = "ratburger"
	center_of_mass = list("x"=16, "y"=11)
	bitesize = 2
	reagents_to_add = list(NUTRIMENT_GOOD = 3, "protein" = 5)
	reagent_data = list(NUTRIMENT_GOOD = list("bun" = 2))

/obj/item/weapon/reagent_containers/food/snacks/omelette
	name = "omelette du fromage"
	desc = "That's all you can say!"
	icon_state = "omelette"
	trash = /obj/item/trash/plate
	filling_color = "#FFF9A8"
	center_of_mass = list("x"=16, "y"=13)
	bitesize = 1
	reagents_to_add = list("egg" = 8)

/obj/item/weapon/reagent_containers/food/snacks/muffin
	name = "muffin"
	desc = "A delicious and spongy little cake."
	icon_state = "muffin"
	filling_color = "#E0CF9B"
	center_of_mass = list("x"=17, "y"=4)
	reagents_to_add = list(NUTRIMENT_GOOD = 6)
	reagent_data = list(NUTRIMENT_GOOD = list("sweetness" = 3, "muffin" = 3))
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/pie
	name = "banana cream pie"
	desc = "Just like back home, on clown planet! HONK!"
	icon_state = "pie"
	trash = /obj/item/trash/plate
	filling_color = "#FBFFB8"
	center_of_mass = list("x"=16, "y"=13)
	reagents_to_add = list(NUTRIMENT_GOOD = 4, "banana" = 5)
	reagent_data = list(NUTRIMENT_GOOD = list("pie" = 3, "cream" = 2))
	bitesize = 3

/obj/item/weapon/reagent_containers/food/snacks/pie/throw_impact(atom/hit_atom)
	..()
	new/obj/effect/decal/cleanable/pie_smudge(src.loc)
	src.visible_message("<span class='danger'>\The [src.name] splats.</span>","<span class='danger'>You hear a splat.</span>")
	qdel(src)

/obj/item/weapon/reagent_containers/food/snacks/berryclafoutis
	name = "berry clafoutis"
	desc = "No black birds, this is a good sign."
	icon_state = "berryclafoutis"
	trash = /obj/item/trash/plate
	center_of_mass = list("x"=16, "y"=13)
	reagents_to_add = list(NUTRIMENT_GOOD = 4, "berryjuice" = 5)
	reagent_data = list(NUTRIMENT_GOOD = list("sweetness" = 2, "pie" = 3))
	bitesize = 3

/obj/item/weapon/reagent_containers/food/snacks/waffles
	name = "waffles"
	desc = "Mmm, waffles."
	icon_state = "waffles"
	trash = /obj/item/trash/waffles
	filling_color = "#E6DEB5"
	center_of_mass = list("x"=15, "y"=11)
	reagents_to_add = list(NUTRIMENT_GOOD = 8)
	reagent_data = list(NUTRIMENT_GOOD = list("waffle" = 8))
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/soylentgreen
	name = "soylent green"
	desc = "Not made of people. Honest." //Totally people.
	icon_state = "soylent_green"
	trash = /obj/item/trash/waffles
	filling_color = "#B8E6B5"
	center_of_mass = list("x"=15, "y"=11)
	bitesize = 2
	reagents_to_add = list("protein" = 10)

/obj/item/weapon/reagent_containers/food/snacks/soylenviridians
	name = "soylen virdians"
	desc = "Not made of people. Honest." //Actually honest for once.
	icon_state = "soylent_yellow"
	trash = /obj/item/trash/waffles
	filling_color = "#E6FA61"
	center_of_mass = list("x"=15, "y"=11)
	reagents_to_add = list("protein" = 10)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/meatpie
	name = "meat-pie"
	icon_state = "meatpie"
	desc = "An old barber recipe, very delicious!"
	trash = /obj/item/trash/plate
	filling_color = "#948051"
	center_of_mass = list("x"=16, "y"=13)
	bitesize = 2
	reagents_to_add = list("protein" = 10)

/obj/item/weapon/reagent_containers/food/snacks/tofupie
	name = "tofu-pie"
	icon_state = "meatpie"
	desc = "A delicious tofu pie."
	trash = /obj/item/trash/plate
	filling_color = "#FFFEE0"
	center_of_mass = list("x"=16, "y"=13)
	reagents_to_add = list(NUTRIMENT_GOOD = 8, "tofu" = 3)
	reagent_data = list(NUTRIMENT_GOOD = list("pie" = 8))
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/amanita_pie
	name = "amanita pie"
	desc = "Sweet and tasty poison pie."
	icon_state = "amanita_pie"
	filling_color = "#FFCCCC"
	center_of_mass = list("x"=17, "y"=9)
	reagent_data = list(NUTRIMENT_GOOD = list("sweetness" = 3, "mushroom" = 3, "pie" = 2))
	reagents_to_add = list(NUTRIMENT_GOOD = 5, "amatoxin" = 3, "psilocybin" = 1)

/obj/item/weapon/reagent_containers/food/snacks/plump_pie
	name = "plump pie"
	desc = "I bet you love stuff made out of plump helmets!"
	icon_state = "plump_pie"
	filling_color = "#B8279B"
	center_of_mass = list("x"=17, "y"=9)
	reagent_data = list(NUTRIMENT_GOOD = list("heartiness" = 3, "mushroom" = 3, "pie" = 2))
	reagents_to_add = list(NUTRIMENT_GOOD = 8)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/plump_pie/Initialize()
	. = ..()
	if(prob(10))
		name = "exceptional plump pie"
		desc = "Microwave is taken by a fey mood! It has cooked an exceptional plump pie!"
		reagents.add_reagent("tricordrazine", 5)

/obj/item/weapon/reagent_containers/food/snacks/xemeatpie
	name = "xeno-pie"
	icon_state = "xenomeatpie"
	desc = "A delicious meatpie. Probably heretical."
	trash = /obj/item/trash/plate
	filling_color = "#43DE18"
	center_of_mass = list("x"=16, "y"=13)
	bitesize = 2
	reagents_to_add = list("protein" = 10)

/obj/item/weapon/reagent_containers/food/snacks/wingfangchu
	name = "wing fang chu"
	desc = "A savory dish of alien wing wang in soy."
	icon_state = "wingfangchu"
	trash = /obj/item/trash/snack_bowl
	filling_color = "#43DE18"
	center_of_mass = list("x"=17, "y"=9)
	bitesize = 2
	reagents_to_add = list("protein" = 6)

/obj/item/weapon/reagent_containers/food/snacks/human/kabob
	name = "-kabob"
	icon_state = "kabob"
	desc = "A human meat, on a stick."
	trash = /obj/item/stack/rods
	filling_color = "#A85340"
	center_of_mass = list("x"=17, "y"=15)
	bitesize = 2
	reagents_to_add = list("protein" = 8)

/obj/item/weapon/reagent_containers/food/snacks/monkeykabob
	name = "meat-kabob"
	icon_state = "kabob"
	desc = "Delicious meat, on a stick."
	trash = /obj/item/stack/rods
	filling_color = "#A85340"
	center_of_mass = list("x"=17, "y"=15)
	bitesize = 2
	reagents_to_add = list("protein" = 8)

/obj/item/weapon/reagent_containers/food/snacks/tofukabob
	name = "tofu-kabob"
	icon_state = "kabob"
	desc = "Vegan meat, on a stick."
	trash = /obj/item/stack/rods
	filling_color = "#FFFEE0"
	center_of_mass = list("x"=17, "y"=15)
	bitesize = 2
	reagents_to_add = list("tofu" = 8)

/obj/item/weapon/reagent_containers/food/snacks/cubancarp
	name = "cuban carp"
	desc = "A sandwich that burns your tongue and then leaves it numb!"
	icon_state = "cubancarp"
	trash = /obj/item/trash/plate
	filling_color = "#E9ADFF"
	center_of_mass = list("x"=12, "y"=5)
	bitesize = 3
	reagents_to_add = list("seafood" = 3, NUTRIMENT_GOOD = 3, "carpotoxin" = 3, "capsaicin" = 3)
	reagent_data = list(NUTRIMENT_GOOD = list("revolutionary fish" = 6))

/obj/item/weapon/reagent_containers/food/snacks/chickenkatsu
	name = "chicken katsu"
	desc = "A terran delicacy consisting of chicken fried in a light beer batter."
	icon_state = "katsu"
	trash = /obj/item/trash/plate
	filling_color = "#E9ADFF"
	center_of_mass = list("x"=16, "y"=16)
	do_coating_prefix = 0
	bitesize = 1.5
	reagents_to_add = list("protein" = 6, "beerbatter" = 2, "oil" = 1)

/obj/item/weapon/reagent_containers/food/snacks/popcorn
	name = "popcorn"
	desc = "Now let's find some cinema."
	icon_state = "popcorn"
	trash = /obj/item/trash/popcorn
	var/unpopped = 0
	filling_color = "#FFFAD4"
	center_of_mass = list("x"=16, "y"=8)
	reagents_to_add = list(NUTRIMENT_BAD = 2)
	reagent_data = list(NUTRIMENT_BAD = list("popcorn" = 3))
	bitesize = 0.1 //this snack is supposed to be eating during looooong time. And this it not dinner food! --rastaf0

/obj/item/weapon/reagent_containers/food/snacks/sosjerky
	name = "Scaredy's Private Reserve beef jerky"
	icon_state = "sosjerky"
	desc = "Beef jerky made from the finest space cows."
	trash = /obj/item/trash/sosjerky
	filling_color = "#631212"
	center_of_mass = list("x"=15, "y"=9)
	reagents_to_add = list(protein = 4, "sodiumchloride" = 3)
	bitesize = 3

/obj/item/weapon/reagent_containers/food/snacks/no_raisin
	name = "4no Raisins"
	icon_state = "4no_raisins"
	desc = "Best raisins in the universe. Not sure why."
	trash = /obj/item/trash/raisins
	filling_color = "#343834"
	center_of_mass = list("x"=15, "y"=4)
	reagents_to_add = list(NUTRIMENT_GOOD = 6)
	reagent_data = list(NUTRIMENT_GOOD = list("dried raisins" = 6))
	bitesize = 3

/obj/item/weapon/reagent_containers/food/snacks/spacetwinkie
	name = "space twinkie"
	icon_state = "space_twinkie"
	desc = "Guaranteed to survive longer then you will."
	trash = /obj/item/trash/space_twinkie
	filling_color = "#FFE591"
	center_of_mass = list("x"=15, "y"=11)
	reagents_to_add = list(NUTRIMENT_BAD = 4, "sugar" = 4)
	reagent_data = list(NUTRIMENT_BAD = list("cake" = 3, "cream filling" = 1))
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/cheesiehonkers
	name = "Cheesie Honkers"
	icon_state = "cheesie_honkers"
	desc = "Bite sized cheesie snacks that will honk all over your mouth"
	trash = /obj/item/trash/cheesie
	filling_color = "#FFA305"
	center_of_mass = list("x"=15, "y"=9)
	reagents_to_add = list(NUTRIMENT_BAD = 4, "cheese" = 3, "sodiumchloride" = 6)
	reagent_data = list(NUTRIMENT_BAD = list("chips" = 2))
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/syndicake
	name = "Syndi-Cakes"
	icon_state = "syndi_cakes"
	desc = "An extremely moist snack cake that tastes just as good after being nuked."
	filling_color = "#FF5D05"
	center_of_mass = list("x"=16, "y"=10)
	trash = /obj/item/trash/syndi_cakes
	reagent_data = list(NUTRIMENT_GOOD = list("cake" = 1,"cream filling" = 3))
	reagents_to_add = list(NUTRIMENT_GOOD = 4, "doctorsdelight" = 5)
	bitesize = 3

/obj/item/weapon/reagent_containers/food/snacks/loadedbakedpotato
	name = "loaded baked potato"
	desc = "Totally baked."
	icon_state = "loadedbakedpotato"
	filling_color = "#9C7A68"
	center_of_mass = list("x"=16, "y"=10)
	reagents_to_add = list(NUTRIMENT_GOOD = 3, "protein" = 3, "cheese" = 3)
	reagent_data = list(NUTRIMENT_GOOD = list("baked potato" = 3))
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/fries
	name = "space fries"
	desc = "AKA: French Fries, Freedom Fries, etc."
	icon_state = "fries"
	trash = /obj/item/trash/plate
	filling_color = "#EDDD00"
	center_of_mass = list("x"=16, "y"=11)
	reagents_to_add = list(NUTRIMENT_GOOD = 4, "oil" = 1.2)
	reagent_data = list(NUTRIMENT_GOOD = list("fresh fries" = 4))
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/microchips
	name = "micro chips"
	desc = "Soft and rubbery, should have fried them."
	icon_state = "microchips"
	trash = /obj/item/trash/plate
	filling_color = "#EDDD00"
	center_of_mass = list("x"=16, "y"=11)
	reagents_to_add = list(NUTRIMENT_GOOD = 3)
	reagent_data = list(NUTRIMENT_GOOD = list("fresh fries" = 3))
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/ovenchips
	name = "oven chips"
	desc = "Dark and crispy, but a bit dry"
	icon_state = "ovenchips"
	trash = /obj/item/trash/plate
	filling_color = "#EDDD00"
	center_of_mass = list("x"=16, "y"=11)
	reagents_to_add = list(NUTRIMENT_GOOD = 4)
	reagent_data = list(NUTRIMENT_GOOD = list("fresh fries" = 4))
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/soydope
	name = "soy dope"
	desc = "Dope from a soy."
	icon_state = "soydope"
	trash = /obj/item/trash/plate
	filling_color = "#C4BF76"
	center_of_mass = list("x"=16, "y"=10)
	reagents_to_add = list(NUTRIMENT_GOOD = 2)
	reagent_data = list(NUTRIMENT_GOOD = list("soy" = 2))
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/spagetti
	name = "spaghetti"
	desc = "A bundle of raw spaghetti."
	icon_state = "spagetti"
	filling_color = "#EDDD00"
	center_of_mass = list("x"=16, "y"=16)
	reagents_to_add = list(NUTRIMENT_BAD = 1)
	reagent_data = list(NUTRIMENT_BAD = list("dry noodles" = 2))
	bitesize = 1

/obj/item/weapon/reagent_containers/food/snacks/cheesyfries
	name = "cheesy fries"
	desc = "Fries. Covered in cheese. Duh."
	icon_state = "cheesyfries"
	trash = /obj/item/trash/plate
	filling_color = "#EDDD00"
	center_of_mass = list("x"=16, "y"=11)
	reagent_data = list(NUTRIMENT_GOOD = list("fresh fries" = 3))
	reagents_to_add = list(NUTRIMENT_GOOD = 4, "cheese" = 3)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/fortunecookie
	name = "fortune cookie"
	desc = "A true prophecy in each cookie!"
	icon_state = "fortune_cookie"
	filling_color = "#E8E79E"
	center_of_mass = list("x"=15, "y"=14)
	reagents_to_add = list(NUTRIMENT_BAD = 2, "sugar" = 2)
	reagent_data = list(NUTRIMENT_BAD = list("fried crackers" = 2))
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/badrecipe
	name = "burned mess"
	desc = "Someone should be demoted from chef for this."
	icon_state = "badrecipe"
	filling_color = "#211F02"
	center_of_mass = list("x"=16, "y"=12)
	bitesize = 2
	reagents_to_add = list("toxin" = 1, "carbon" = 3)

/obj/item/weapon/reagent_containers/food/snacks/meatsteak
	name = "meat steak"
	desc = "A piece of hot spicy meat."
	icon_state = "meatstake"
	trash = /obj/item/trash/plate
	filling_color = "#7A3D11"
	center_of_mass = list("x"=16, "y"=13)
	bitesize = 2
	reagents_to_add = list("protein" = 6, "triglyceride" = 2, "sodiumchloride" = 1, "blackpepper" = 1)

/obj/item/weapon/reagent_containers/food/snacks/spacylibertyduff
	name = "spacy liberty duff"
	desc = "Jello gelatin, from Alfred Hubbard's cookbook."
	icon_state = "spacylibertyduff"
	trash = /obj/item/trash/snack_bowl
	filling_color = "#42B873"
	center_of_mass = list("x"=16, "y"=8)
	reagents_to_add = list(NUTRIMENT_GOOD = 6, "psilocybin" = 6)
	reagent_data = list(NUTRIMENT_GOOD = list("mushroom" = 6))
	bitesize = 3

/obj/item/weapon/reagent_containers/food/snacks/amanitajelly
	name = "amanita jelly"
	desc = "Looks curiously toxic."
	icon_state = "amanitajelly"
	trash = /obj/item/trash/snack_bowl
	filling_color = "#ED0758"
	center_of_mass = list("x"=16, "y"=5)
	reagents_to_add = list(NUTRIMENT_GOOD = 6, "amatoxin" = 6, "psilocybin" = 3)
	reagent_data = list(NUTRIMENT_GOOD = list("jelly" = 3, "mushroom" = 3))
	bitesize = 3

/obj/item/weapon/reagent_containers/food/snacks/poppypretzel
	name = "poppy pretzel"
	desc = "It's all twisted up!"
	icon_state = "poppypretzel"
	bitesize = 2
	filling_color = "#916E36"
	center_of_mass = list("x"=16, "y"=10)
	reagent_data = list(NUTRIMENT_GOOD = list("poppy seeds" = 2, "pretzel" = 3))
	reagents_to_add = list(NUTRIMENT_GOOD = 5)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/soup/meatball
	name = "meatball soup"
	desc = "You've got balls kid, BALLS!"
	icon_state = "meatballsoup"
	trash = /obj/item/trash/snack_bowl
	filling_color = "#785210"
	center_of_mass = list("x"=16, "y"=8)
	bitesize = 5
	reagents_to_add = list("protein" = 8, "water" = 5)

/obj/item/weapon/reagent_containers/food/snacks/soup/slime
	name = "slime soup"
	desc = "If no water is available, you may substitute tears."
	icon_state = "slimesoup" //nonexistant?
	filling_color = "#C4DBA0"
	bitesize = 5
	reagents_to_add = list("slimejelly" = 5, "water" = 10)

/obj/item/weapon/reagent_containers/food/snacks/soup/blood
	name = "tomato soup"
	desc = "Smells like iron."
	icon_state = "tomatosoup"
	filling_color = "#FF0000"
	center_of_mass = list("x"=16, "y"=7)
	bitesize = 5
	reagents_to_add = list("protein" = 2, "blood" = 10, "water" = 5)

/obj/item/weapon/reagent_containers/food/snacks/clownstears
	name = "clown's tears"
	desc = "Not very funny."
	icon_state = "clownstears"
	filling_color = "#C4FBFF"
	center_of_mass = list("x"=16, "y"=7)
	reagent_data = list(NUTRIMENT_GOOD = list("salt" = 1, "the worst joke" = 3))
	reagents_to_add = list(NUTRIMENT_GOOD = 4, "banana" = 5, "water" = 10)
	bitesize = 5

/obj/item/weapon/reagent_containers/food/snacks/soup/vegetable
	name = "vegetable soup"
	desc = "A true vegan meal" //TODO
	icon_state = "vegetablesoup"
	trash = /obj/item/trash/snack_bowl
	filling_color = "#AFC4B5"
	center_of_mass = list("x"=16, "y"=8)
	reagent_data = list(NUTRIMENT_GOOD = list("carrot" = 2, "corn" = 2, "eggplant" = 2, "potato" = 2))
	reagents_to_add = list(NUTRIMENT_GOOD = 8, "water" = 5)
	bitesize = 5

/obj/item/weapon/reagent_containers/food/snacks/soup/nettle
	name = "nettle soup"
	desc = "To think, the botanist would've beat you to death with one of these."
	icon_state = "nettlesoup"
	trash = /obj/item/trash/snack_bowl
	filling_color = "#AFC4B5"
	center_of_mass = list("x"=16, "y"=7)
	reagent_data = list(NUTRIMENT_GOOD = list("salad" = 4, "egg" = 2, "potato" = 2))
	reagents_to_add = list(NUTRIMENT_GOOD = 8, "water" = 5, "tricordrazine" = 5)
	bitesize = 5

/obj/item/weapon/reagent_containers/food/snacks/soup/mystery
	name = "mystery soup"
	desc = "The mystery is, why aren't you eating it?"
	icon_state = "mysterysoup"
	trash = /obj/item/trash/snack_bowl
	filling_color = "#F082FF"
	center_of_mass = list("x"=16, "y"=6)
	reagent_data = list(NUTRIMENT_GOOD = list("backwash" = 1))
	reagents_to_add = list(NUTRIMENT_GOOD = 1)
	bitesize = 5

/obj/item/weapon/reagent_containers/food/snacks/soup/mystery/Initialize()
	. = ..()
	switch(rand(1,10))
		if(1)
			reagents.add_reagent("nutriment", 6)
			reagents.add_reagent("capsaicin", 3)
			reagents.add_reagent("tomatojuice", 2)
		if(2)
			reagents.add_reagent("nutriment", 6)
			reagents.add_reagent("frostoil", 3)
			reagents.add_reagent("tomatojuice", 2)
		if(3)
			reagents.add_reagent("nutriment", 5)
			reagents.add_reagent("water", 5)
			reagents.add_reagent("tricordrazine", 5)
		if(4)
			reagents.add_reagent("nutriment", 5)
			reagents.add_reagent("water", 10)
		if(5)
			reagents.add_reagent("nutriment", 2)
			reagents.add_reagent("banana", 10)
		if(6)
			reagents.add_reagent("nutriment", 6)
			reagents.add_reagent("blood", 10)
		if(7)
			reagents.add_reagent("slimejelly", 10)
			reagents.add_reagent("water", 10)
		if(8)
			reagents.add_reagent("carbon", 10)
			reagents.add_reagent("toxin", 10)
		if(9)
			reagents.add_reagent("nutriment", 5)
			reagents.add_reagent("tomatojuice", 10)
		if(10)
			reagents.add_reagent("nutriment", 6)
			reagents.add_reagent("tomatojuice", 5)
			reagents.add_reagent("imidazoline", 5)

/obj/item/weapon/reagent_containers/food/snacks/soup/wish
	name = "wish soup"
	desc = "I wish this was soup."
	icon_state = "wishsoup"
	trash = /obj/item/trash/snack_bowl
	filling_color = "#D1F4FF"
	center_of_mass = list("x"=16, "y"=11)
	bitesize = 5
	reagents_to_add = list("water" = 10)

/obj/item/weapon/reagent_containers/food/snacks/soup/wish/Initialize()
	. = ..()
	if(prob(25))
		src.desc = "A wish come true!"
		reagents.add_reagent("nutriment", 8, list("something good" = 8))

/obj/item/weapon/reagent_containers/food/snacks/hotchili
	name = "hot chili"
	desc = "A five alarm Texan Chili!"
	icon_state = "hotchili"
	trash = /obj/item/trash/snack_bowl
	filling_color = "#FF3C00"
	center_of_mass = list("x"=15, "y"=9)
	reagent_data = list(NUTRIMENT_GOOD = list("chilli peppers" = 3))
	reagents_to_add = list(NUTRIMENT_GOOD = 3, "capsaicin" = 3, "tomatojuice" = 2)
	bitesize = 5

/obj/item/weapon/reagent_containers/food/snacks/coldchili
	name = "cold chili"
	desc = "This slush is barely a liquid!"
	icon_state = "coldchili"
	filling_color = "#2B00FF"
	center_of_mass = list("x"=15, "y"=9)
	trash = /obj/item/trash/snack_bowl
	reagent_data = list(NUTRIMENT_GOOD = list("ice peppers" = 3))
	reagents_to_add = list(NUTRIMENT_GOOD = 3, "frostoil" = 3, "tomatojuice" = 2)
	bitesize = 5

/obj/item/weapon/reagent_containers/food/snacks/monkeycube
	name = "monkey cube"
	desc = "Just add water!"
	flags = 0
	icon_state = "monkeycube"
	bitesize = 12
	filling_color = "#ADAC7F"
	center_of_mass = list("x"=16, "y"=14)

	var/wrapped = 0
	var/monkey_type = "Monkey"
	reagents_to_add = list("protein" = 10)

/obj/item/weapon/reagent_containers/food/snacks/monkeycube/afterattack(obj/O as obj, var/mob/living/carbon/human/user as mob, proximity)
	if(!proximity) return
	if(( istype(O, /obj/structure/reagent_dispensers/watertank) || istype(O,/obj/structure/sink) ) && !wrapped)
		to_chat(user, "You place \the [name] under a stream of water...")
		if(istype(user))
			user.unEquip(src)
		src.forceMove(get_turf(src))
		return Expand()
	..()

/obj/item/weapon/reagent_containers/food/snacks/monkeycube/attack_self(mob/user as mob)
	if(wrapped)
		Unwrap(user)

/obj/item/weapon/reagent_containers/food/snacks/monkeycube/proc/Expand()
	src.visible_message("<span class='notice'>\The [src] expands!</span>")
	if(istype(loc, /obj/item/weapon/gripper)) // fixes ghost cube when using syringe
		var/obj/item/weapon/gripper/G = loc
		G.drop_item()
	var/mob/living/carbon/human/H = new(src.loc)
	H.set_species(monkey_type)
	H.real_name = H.species.get_random_name()
	H.name = H.real_name
	src.forceMove(null)
	qdel(src)
	return 1

/obj/item/weapon/reagent_containers/food/snacks/monkeycube/proc/Unwrap(mob/user as mob)
	icon_state = "monkeycube"
	desc = "Just add water!"
	to_chat(user, "You unwrap the cube.")
	wrapped = 0
	return

/obj/item/weapon/reagent_containers/food/snacks/monkeycube/wrapped
	desc = "Still wrapped in some paper."
	icon_state = "monkeycubewrap"
	wrapped = 1

/obj/item/weapon/reagent_containers/food/snacks/monkeycube/farwacube
	name = "farwa cube"
	monkey_type = "Farwa"

/obj/item/weapon/reagent_containers/food/snacks/monkeycube/wrapped/farwacube
	name = "farwa cube"
	monkey_type = "Farwa"

/obj/item/weapon/reagent_containers/food/snacks/monkeycube/stokcube
	name = "stok cube"
	monkey_type = "Stok"

/obj/item/weapon/reagent_containers/food/snacks/monkeycube/wrapped/stokcube
	name = "stok cube"
	monkey_type = "Stok"

/obj/item/weapon/reagent_containers/food/snacks/monkeycube/neaeracube
	name = "neaera cube"
	monkey_type = "Neaera"

/obj/item/weapon/reagent_containers/food/snacks/monkeycube/wrapped/neaeracube
	name = "neaera cube"
	monkey_type = "Neaera"

/obj/item/weapon/reagent_containers/food/snacks/monkeycube/vkrexicube
	name = "v'krexi cube"
	monkey_type = "V'krexi"

/obj/item/weapon/reagent_containers/food/snacks/monkeycube/wrapped/vkrexicube
	name = "v'krexi cube"
	monkey_type = "V'krexi"


/obj/item/weapon/reagent_containers/food/snacks/burger/spell
	name = "spell burger"
	desc = "This is absolutely Ei Nath."
	icon_state = "spellburger"
	filling_color = "#D505FF"
	reagent_data = list(NUTRIMENT_GOOD = list("magic" = 3, "buns" = 3))
	reagents_to_add = list(NUTRIMENT_GOOD = 6)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/burger/bigbite
	name = "big bite burger"
	desc = "Forget the Big Mac. THIS is the future!"
	icon_state = "bigbiteburger"
	filling_color = "#E3D681"
	center_of_mass = list("x"=16, "y"=11)
	reagent_data = list(NUTRIMENT_GOOD = list("buns" = 4))
	reagents_to_add = list(NUTRIMENT_GOOD = 4, "protein" = 10)
	bitesize = 3

/obj/item/weapon/reagent_containers/food/snacks/enchiladas
	name = "enchiladas"
	desc = "Viva La Mexico!"
	icon_state = "enchiladas"
	trash = /obj/item/trash/tray
	filling_color = "#A36A1F"
	center_of_mass = list("x"=16, "y"=13)
	reagent_data = list(NUTRIMENT_GOOD = list("tortilla" = 3, "corn" = 3))
	reagents_to_add = list(NUTRIMENT_GOOD = 2, "protein" = 6, "capsaicin" = 6)
	bitesize = 4

/obj/item/weapon/reagent_containers/food/snacks/monkeysdelight
	name = "monkey's delight"
	desc = "Eeee Eee!"
	icon_state = "monkeysdelight"
	trash = /obj/item/trash/tray
	filling_color = "#5C3C11"
	center_of_mass = list("x"=16, "y"=13)
	bitesize = 6
	reagents_to_add = list("protein" = 10, "banana" = 5, "blackpepper" = 1, "sodiumchloride" = 1)

/obj/item/weapon/reagent_containers/food/snacks/baguette
	name = "baguette"
	desc = "Bon appetit!"
	icon_state = "baguette"
	filling_color = "#E3D796"
	center_of_mass = list("x"=18, "y"=12)
	reagent_data = list(NUTRIMENT_GOOD = list("french bread" = 6))
	reagents_to_add = list(NUTRIMENT_GOOD = 6, "blackpepper" = 1, "sodiumchloride" = 1)
	bitesize = 3

/obj/item/weapon/reagent_containers/food/snacks/fishandchips
	name = "fish and chips"
	desc = "I do say so myself chap."
	icon_state = "fishandchips"
	filling_color = "#E3D796"
	center_of_mass = list("x"=16, "y"=16)
	reagent_data = list(NUTRIMENT_GOOD = list("salt" = 1, "chips" = 3))
	reagents_to_add = list(NUTRIMENT_GOOD = 3, "seafood" = 3, "carpotoxin" = 3)
	bitesize = 3

/obj/item/weapon/reagent_containers/food/snacks/sandwich
	name = "sandwich"
	desc = "A grand creation of meat, cheese, bread, and several leaves of lettuce! Arthur Dent would be proud."
	icon_state = "sandwich"
	trash = /obj/item/trash/plate
	filling_color = "#D9BE29"
	center_of_mass = list("x"=16, "y"=4)
	reagent_data = list(NUTRIMENT_GOOD = list("bread" = 3, "cheese" = 3))
	reagents_to_add = list(NUTRIMENT_GOOD = 3, "protein" = 3)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/toastedsandwich
	name = "toasted sandwich"
	desc = "Now if you only had a pepper bar."
	icon_state = "toastedsandwich"
	trash = /obj/item/trash/plate
	filling_color = "#D9BE29"
	center_of_mass = list("x"=16, "y"=4)
	reagent_data = list(NUTRIMENT_GOOD = list("toasted bread" = 3, "cheese" = 3))
	reagents_to_add = list(NUTRIMENT_GOOD = 3, "protein" = 3, "carbon" = 2)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/grilledcheese
	name = "grilled cheese sandwich"
	desc = "Goes great with Tomato soup!"
	icon_state = "toastedsandwich"
	trash = /obj/item/trash/plate
	filling_color = "#D9BE29"
	reagent_data = list(NUTRIMENT_GOOD = list("toasted bread" = 3, "cheese" = 3))
	reagents_to_add = list(NUTRIMENT_GOOD = 3, "protein" = 4)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/soup/tomato
	name = "tomato soup"
	desc = "Drinking this feels like being a vampire! A tomato vampire..."
	icon_state = "tomatosoup"
	trash = /obj/item/trash/snack_bowl
	filling_color = "#D92929"
	center_of_mass = list("x"=16, "y"=7)
	reagent_data = list(NUTRIMENT_GOOD = list("soup" = 5))
	reagents_to_add = list(NUTRIMENT_GOOD = 5, "tomatojuice" = 10)
	bitesize = 3

/obj/item/weapon/reagent_containers/food/snacks/soup/bluespace
	name = "bluespace tomato soup"
	desc = "A scientific experiment turned into a possibly unsafe meal."
	icon_state = "spiral_soup"
	trash = /obj/item/trash/snack_bowl
	filling_color = "#0066FF"
	reagent_data = list(NUTRIMENT_GOOD = list("soup" = 5))
	reagents_to_add = list(NUTRIMENT_GOOD = 5, "bluespace_dust" = 5)
	bitesize = 3

/obj/item/weapon/reagent_containers/food/snacks/rofflewaffles
	name = "roffle waffles"
	desc = "Waffles from Roffle. Co."
	icon_state = "rofflewaffles"
	trash = /obj/item/trash/waffles
	filling_color = "#FF00F7"
	center_of_mass = list("x"=15, "y"=11)
	reagent_data = list(NUTRIMENT_GOOD = list("waffle" = 7, "sweetness" = 1))
	reagents_to_add = list(NUTRIMENT_GOOD = 8, "psilocybin" = 8)
	bitesize = 4

/obj/item/weapon/reagent_containers/food/snacks/stew
	name = "Stew"
	desc = "A nice and warm stew. Healthy and strong."
	icon_state = "stew"
	filling_color = "#9E673A"
	center_of_mass = list("x"=16, "y"=5)
	reagent_data = list(NUTRIMENT_GOOD = list("potato" = 2, "carrot" = 2, "eggplant" = 2, "mushroom" = 2))
	reagents_to_add = list(NUTRIMENT_GOOD = 6, "protein" = 4, "tomatojuice" = 5, "imidazoline" = 5, "water" = 5)
	bitesize = 10

/obj/item/weapon/reagent_containers/food/snacks/jelliedtoast
	name = "jellied toast"
	desc = "A slice of bread covered with delicious jam."
	icon_state = "jellytoast"
	trash = /obj/item/trash/plate
	filling_color = "#B572AB"
	center_of_mass = list("x"=16, "y"=8)
	reagent_data = list(NUTRIMENT_GOOD = list("toasted bread" = 2))
	reagents_to_add = list(NUTRIMENT_GOOD = 1)
	bitesize = 3

/obj/item/weapon/reagent_containers/food/snacks/jelliedtoast/cherry
	reagents_to_add = list(NUTRIMENT_GOOD = 1, "cherryjelly" = 5)

/obj/item/weapon/reagent_containers/food/snacks/jelliedtoast/slime
	reagents_to_add = list(NUTRIMENT_GOOD = 1, "slimejelly" = 5)

/obj/item/weapon/reagent_containers/food/snacks/burger/jelly
	name = "jelly burger"
	desc = "Culinary delight..?"
	icon_state = "jellyburger"
	filling_color = "#B572AB"
	center_of_mass = list("x"=16, "y"=11)
	reagent_data = list(NUTRIMENT_GOOD = list("buns" = 5))
	reagents_to_add = list(NUTRIMENT_GOOD = 5)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/burger/jelly/slime
	reagents_to_add = list(NUTRIMENT_GOOD = 5, "slimejelly" = 5)

/obj/item/weapon/reagent_containers/food/snacks/burger/jelly/cherry
	reagents_to_add = list(NUTRIMENT_GOOD = 5, "cherryjelly" = 5)

/obj/item/weapon/reagent_containers/food/snacks/soup/milo
	name = "milosoup"
	desc = "The universes best soup! Yum!!!"
	icon_state = "milosoup"
	trash = /obj/item/trash/snack_bowl
	center_of_mass = list("x"=16, "y"=7)
	reagent_data = list(NUTRIMENT_GOOD = list("soy" = 8))
	reagents_to_add = list(NUTRIMENT_GOOD = 8, "water" = 5)
	bitesize = 4

/obj/item/weapon/reagent_containers/food/snacks/stewedsoymeat
	name = "stewed soy meat"
	desc = "Even non-vegetarians will LOVE this!"
	icon_state = "stewedsoymeat"
	trash = /obj/item/trash/plate
	center_of_mass = list("x"=16, "y"=10)
	reagent_data = list(NUTRIMENT_GOOD = list("soy" = 4, "tomato" = 4))
	reagents_to_add = list(NUTRIMENT_GOOD = 8)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/boiledspagetti
	name = "boiled spaghetti"
	desc = "A plain dish of noodles, this sucks."
	icon_state = "spagettiboiled"
	trash = /obj/item/trash/plate
	filling_color = "#FCEE81"
	center_of_mass = list("x"=16, "y"=10)
	reagent_data = list(NUTRIMENT_GOOD = list("noodles" = 2))
	reagents_to_add = list(NUTRIMENT_GOOD = 2)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/boiledrice
	name = "boiled rice"
	desc = "A boring dish of boring rice."
	icon_state = "boiledrice"
	trash = /obj/item/trash/snack_bowl
	filling_color = "#FFFBDB"
	center_of_mass = list("x"=17, "y"=11)
	reagent_data = list(NUTRIMENT_GOOD = list("rice" = 2))
	reagents_to_add = list(NUTRIMENT_GOOD = 2)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/ricepudding
	name = "rice pudding"
	desc = "Where's the jam?"
	icon_state = "rpudding"
	trash = /obj/item/trash/snack_bowl
	filling_color = "#FFFBDB"
	center_of_mass = list("x"=17, "y"=11)
	reagent_data = list(NUTRIMENT_GOOD = list("rice" = 2))
	reagents_to_add = list(NUTRIMENT_GOOD = 4)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/pudding
	name = "figgy pudding"
	icon_state = "pudding"
	desc = "Bring it to me."
	trash = /obj/item/trash/plate
	filling_color = "#FFFEE0"
	reagent_data = list(NUTRIMENT_GOOD = list("fruit cake" = 4))
	reagents_to_add = list(NUTRIMENT_GOOD = 4)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/pastatomato
	name = "spaghetti"
	desc = "Spaghetti and crushed tomatoes. Just like your abusive father used to make!"
	icon_state = "pastatomato"
	trash = /obj/item/trash/plate
	filling_color = "#DE4545"
	center_of_mass = list("x"=16, "y"=10)
	reagent_data = list(NUTRIMENT_GOOD = list("tomato" = 3, "noodles" = 3))
	reagents_to_add = list(NUTRIMENT_GOOD = 6, "tomatojuice" = 10)
	bitesize = 4

/obj/item/weapon/reagent_containers/food/snacks/meatballspagetti
	name = "spaghetti and meatballs"
	desc = "Now thats a nic'e meatball!"
	icon_state = "meatballspagetti"
	trash = /obj/item/trash/plate
	filling_color = "#DE4545"
	center_of_mass = list("x"=16, "y"=10)
	reagent_data = list(NUTRIMENT_GOOD = list("noodles" = 4))
	reagents_to_add = list(NUTRIMENT_GOOD = 4, "protein" = 4)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/spesslaw
	name = "spesslaw"
	desc = "A lawyer's favourite."
	icon_state = "spesslaw"
	filling_color = "#DE4545"
	center_of_mass = list("x"=16, "y"=10)
	reagent_data = list(NUTRIMENT_GOOD = list("noodles" = 4))
	reagents_to_add = list(NUTRIMENT_GOOD = 4, "protein" = 4)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/carrotfries
	name = "carrot fries"
	desc = "Tasty fries from fresh Carrots."
	icon_state = "carrotfries"
	trash = /obj/item/trash/plate
	filling_color = "#FAA005"
	center_of_mass = list("x"=16, "y"=11)
	reagent_data = list(NUTRIMENT_GOOD = list("carrot" = 3, "salt" = 1))
	reagents_to_add = list(NUTRIMENT_GOOD = 3, "imidazoline" = 3)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/burger/superbite
	name = "super bite burger"
	desc = "This is a mountain of a burger. FOOD!"
	icon_state = "superbiteburger"
	filling_color = "#CCA26A"
	center_of_mass = list("x"=16, "y"=3)
	reagent_data = list(NUTRIMENT_GOOD = list("buns" = 25))
	reagents_to_add = list(NUTRIMENT_GOOD = 25, "protein" = 25)
	bitesize = 10

/obj/item/weapon/reagent_containers/food/snacks/candiedapple
	name = "candied apple"
	desc = "An apple coated in sugary sweetness."
	icon_state = "candiedapple"
	filling_color = "#F21873"
	center_of_mass = list("x"=15, "y"=13)
	reagent_data = list(NUTRIMENT_GOOD = list("apple" = 3, "caramel" = 3, "sweetness" = 2))
	reagents_to_add = list(NUTRIMENT_GOOD = 3)
	bitesize = 3

/obj/item/weapon/reagent_containers/food/snacks/applepie
	name = "apple pie"
	desc = "A pie containing sweet sweet love... or apple."
	icon_state = "applepie"
	filling_color = "#E0EDC5"
	center_of_mass = list("x"=16, "y"=13)
	reagent_data = list(NUTRIMENT_GOOD = list("sweetness" = 2, "apple" = 2, "pie" = 2))
	reagents_to_add = list(NUTRIMENT_GOOD = 4)
	bitesize = 3

/obj/item/weapon/reagent_containers/food/snacks/cherrypie
	name = "cherry pie"
	desc = "Taste so good, make a grown man cry."
	icon_state = "cherrypie"
	filling_color = "#FF525A"
	center_of_mass = list("x"=16, "y"=11)
	reagent_data = list(NUTRIMENT_GOOD = list("sweetness" = 2, "cherry" = 2, "pie" = 2))
	reagents_to_add = list(NUTRIMENT_GOOD = 4)
	bitesize = 3

/obj/item/weapon/reagent_containers/food/snacks/twobread
	name = "two bread"
	desc = "It is very bitter and winy."
	icon_state = "twobread"
	filling_color = "#DBCC9A"
	center_of_mass = list("x"=15, "y"=12)
	reagent_data = list(NUTRIMENT_GOOD = list("sourness" = 2, "bread" = 2))
	reagents_to_add = list(NUTRIMENT_GOOD = 2)
	bitesize = 3

/obj/item/weapon/reagent_containers/food/snacks/jellysandwich
	name = "jelly sandwich"
	desc = "You wish you had some peanut butter to go with this..."
	icon_state = "jellysandwich"
	trash = /obj/item/trash/plate
	filling_color = "#9E3A78"
	center_of_mass = list("x"=16, "y"=8)
	reagent_data = list(NUTRIMENT_GOOD = list("bread" = 2))
	reagents_to_add = list(NUTRIMENT_GOOD = 2)
	bitesize = 3

/obj/item/weapon/reagent_containers/food/snacks/jellysandwich/slime
	reagents_to_add = list(NUTRIMENT_GOOD = 2, "slimejelly" = 5)

/obj/item/weapon/reagent_containers/food/snacks/jellysandwich/cherry
	reagents_to_add = list(NUTRIMENT_GOOD = 2, "cherryjelly" = 5)

/obj/item/weapon/reagent_containers/food/snacks/boiledslimecore
	name = "boiled slime core"
	desc = "A boiled red thing."
	icon_state = "boiledslimecore" //nonexistant?
	bitesize = 3
	reagents_to_add = list("slimejelly" = 5)

/obj/item/weapon/reagent_containers/food/snacks/mint
	name = "mint"
	desc = "It is only wafer thin."
	icon_state = "mint"
	filling_color = "#F2F2F2"
	center_of_mass = list("x"=16, "y"=14)
	bitesize = 1
	reagents_to_add = list("mint" = 1)

/obj/item/weapon/reagent_containers/food/snacks/soup/mushroom
	name = "chantrelle soup"
	desc = "A delicious and hearty mushroom soup."
	icon_state = "mushroomsoup"
	trash = /obj/item/trash/snack_bowl
	filling_color = "#E386BF"
	center_of_mass = list("x"=17, "y"=10)
	reagent_data = list(NUTRIMENT_GOOD = list("mushroom" = 8, "milk" = 2))
	reagents_to_add = list(NUTRIMENT_GOOD = 8)
	bitesize = 3

/obj/item/weapon/reagent_containers/food/snacks/plumphelmetbiscuit
	name = "plump helmet biscuit"
	desc = "This is a finely-prepared plump helmet biscuit. The ingredients are exceptionally minced plump helmet, and well-minced dwarven wheat flour."
	icon_state = "phelmbiscuit"
	filling_color = "#CFB4C4"
	center_of_mass = list("x"=16, "y"=13)
	reagent_data = list(NUTRIMENT_GOOD = list("mushroom" = 4))
	reagents_to_add = list(NUTRIMENT_GOOD = 5)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/plumphelmetbiscuit/Initialize()
	. = ..()
	if(prob(10))
		name = "exceptional plump helmet biscuit"
		desc = "Microwave is taken by a fey mood! It has cooked an exceptional plump helmet biscuit!"
		reagents.add_reagent("nutriment", 8)
		reagents.add_reagent("tricordrazine", 5)

/obj/item/weapon/reagent_containers/food/snacks/chawanmushi
	name = "chawanmushi"
	desc = "A legendary egg custard that makes friends out of enemies. Probably too hot for a cat to eat."
	icon_state = "chawanmushi"
	trash = /obj/item/trash/snack_bowl
	filling_color = "#F0F2E4"
	center_of_mass = list("x"=17, "y"=10)
	bitesize = 1
	reagents_to_add = list("protein" = 5)

/obj/item/weapon/reagent_containers/food/snacks/soup/beet
	name = "beet soup"
	desc = "Wait, how do you spell it again..?"
	icon_state = "beetsoup"
	trash = /obj/item/trash/snack_bowl
	filling_color = "#FAC9FF"
	center_of_mass = list("x"=15, "y"=8)
	reagent_data = list(NUTRIMENT_GOOD = list("tomato" = 4, "beet" = 4))
	reagents_to_add = list(NUTRIMENT_GOOD = 8)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/soup/beet/Initialize()
	. = ..()
	name = pick(list("borsch","bortsch","borstch","borsh","borshch","borscht"))

/obj/item/weapon/reagent_containers/food/snacks/salad/tossedsalad
	name = "tossed salad"
	desc = "A proper salad, basic and simple, with little bits of carrot, tomato and apple intermingled. Vegan!"
	icon_state = "herbsalad"
	trash = /obj/item/trash/snack_bowl
	filling_color = "#76B87F"
	center_of_mass = list("x"=17, "y"=11)
	reagent_data = list(NUTRIMENT_GOOD = list("salad" = 2, "tomato" = 2, "carrot" = 2, "apple" = 2))
	reagents_to_add = list(NUTRIMENT_GOOD = 8)
	bitesize = 3

/obj/item/weapon/reagent_containers/food/snacks/salad/validsalad
	name = "valid salad"
	desc = "It's just a salad of questionable 'herbs' with meatballs and fried potato slices. Nothing suspicious about it."
	icon_state = "validsalad"
	trash = /obj/item/trash/snack_bowl
	filling_color = "#76B87F"
	center_of_mass = list("x"=17, "y"=11)
	reagent_data = list(NUTRIMENT_GOOD = list("potato" = 4, "herbs" = 4))
	reagents_to_add = list(NUTRIMENT_GOOD = 6, "protein" = 2)
	bitesize = 3

/obj/item/weapon/reagent_containers/food/snacks/appletart
	name = "golden apple streusel tart"
	desc = "A tasty dessert that won't make it through a metal detector."
	icon_state = "gappletart"
	trash = /obj/item/trash/plate
	filling_color = "#FFFF00"
	center_of_mass = list("x"=16, "y"=18)
	reagent_data = list(NUTRIMENT_GOOD = list("apple" = 8))
	reagents_to_add = list(NUTRIMENT_GOOD = 8, "gold" = 5)
	bitesize = 3

/obj/item/weapon/reagent_containers/food/snacks/redcurry
	name = "red curry"
	gender = PLURAL
	desc = "A bowl of creamy red curry with meat and rice. This one looks savory."
	icon_state = "redcurry"
	trash = /obj/item/trash/snack_bowl
	filling_color = "#f73333"
	center_of_mass = list("x"=16, "y"=8)
	reagent_data = list(NUTRIMENT_GOOD = list("rice" = 4, "curry" = 4))
	reagents_to_add = list(NUTRIMENT_GOOD = 8, "protein" = 7, "spacespice" = 2)
	bitesize = 3

/obj/item/weapon/reagent_containers/food/snacks/greencurry
	name = "green curry"
	gender = PLURAL
	desc = "A bowl of creamy green curry with tofu, hot peppers and rice. This one looks spicy!"
	icon_state = "greencurry"
	trash = /obj/item/trash/snack_bowl
	filling_color = "#58b76c"
	center_of_mass = list("x"=16, "y"=8)
	reagent_data = list(NUTRIMENT_GOOD = list("rice" = 2, "curry" = 4, "tofu" = 4))
	reagents_to_add = list(NUTRIMENT_GOOD = 8, "tofu" = 5, "spacespice" = 2, "capsaicin" = 2)
	bitesize = 3

/obj/item/weapon/reagent_containers/food/snacks/yellowcurry
	name = "yellow curry"
	gender = PLURAL
	desc = "A bowl of creamy yellow curry with potatoes, peanuts and rice. This one looks mild."
	icon_state = "yellowcurry"
	trash = /obj/item/trash/snack_bowl
	filling_color = "#bc9509"
	center_of_mass = list("x"=16, "y"=8)
	reagent_data = list(NUTRIMENT_GOOD = list("rice" = 2, "curry" = 2, "potato" = 2, "peanut" = 2))
	reagents_to_add = list(NUTRIMENT_GOOD = 8, "spacespice" = 2)
	bitesize = 3

/obj/item/weapon/reagent_containers/food/snacks/burger/bear
	name = "bearburger"
	desc = "The solution to your unbearable hunger."
	icon_state = "bearburger"
	filling_color = "#5d5260"
	center_of_mass = list("x"=15, "y"=11)
	bitesize = 3
	reagents_to_add = list("protein" = 10, "hyperzine" = 5)

/obj/item/weapon/reagent_containers/food/snacks/bearchili
	name = "bear chili"
	gender = PLURAL
	desc = "A dark, hearty chili. Can you bear the heat?"
	icon_state = "bearchili"
	trash = /obj/item/trash/snack_bowl
	filling_color = "#702708"
	center_of_mass = list("x"=15, "y"=9)
	reagent_data = list(NUTRIMENT_GOOD = list("chilli peppers" = 3))
	reagents_to_add = list(NUTRIMENT_GOOD = 3, "protein" = 3, "capsaicin" = 3, "tomatojuice" = 2, "hyperzine" = 5)
	bitesize = 5

/obj/item/weapon/reagent_containers/food/snacks/bearstew
	name = "bear stew"
	gender = PLURAL
	desc = "A thick, dark stew of bear meat and vegetables."
	icon_state = "stew"
	filling_color = "#9E673A"
	center_of_mass = list("x"=16, "y"=5)
	reagent_data = list(NUTRIMENT_GOOD = list("mushroom" = 2, "potato" = 2, "carrot" = 2))
	reagents_to_add = list(NUTRIMENT_GOOD = 6, "protein" = 4, "hyperzine" = 5, "tomatojuice" = 5, "imidazoline" = 5, "water" = 5)
	bitesize = 6

/obj/item/weapon/reagent_containers/food/snacks/bibimbap
	name = "bibimbap bowl"
	desc = "A traditional Korean meal of meat and mixed vegetables. It's served on a bed of rice, and topped with a fried egg."
	icon_state = "bibimbap"
	trash = /obj/item/trash/snack_bowl
	filling_color = "#4f2100"
	center_of_mass = list("x"=15, "y"=9)
	reagent_data = list(NUTRIMENT_GOOD = list("rice" = 2, "mushroom" = 2, "carrot" = 2))
	reagents_to_add = list(NUTRIMENT_GOOD = 6, "protein" = 6, "imidazoline" = 3, "spacespice" = 2, "egg" = 3)
	bitesize = 4

/obj/item/weapon/reagent_containers/food/snacks/lomein
	name = "lo mein"
	gender = PLURAL
	desc = "A popular Chinese noodle dish. Chopsticks optional."
	icon_state = "lomein"
	trash = /obj/item/trash/plate
	filling_color = "#FCEE81"
	center_of_mass = list("x"=16, "y"=10)
	reagent_data = list(NUTRIMENT_GOOD = list("rice" = 2, "mushroom" = 2, "cabbage" = 2))
	reagents_to_add = list(NUTRIMENT_GOOD = 8, "protein" = 2, "carrotjuice" = 3, "imidazoline" = 1)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/friedrice
	name = "fried rice"
	gender = PLURAL
	desc = "A less-boring dish of less-boring rice!"
	icon_state = "friedrice"
	trash = /obj/item/trash/snack_bowl
	filling_color = "#FFFBDB"
	center_of_mass = list("x"=17, "y"=11)
	reagent_data = list(NUTRIMENT_GOOD = list("soy" = 2))
	reagents_to_add = list(NUTRIMENT_GOOD = 8, "rice" = 5, "carrotjuice" = 3, "imidazoline" = 1)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/chickenfillet
	name = "chicken fillet sandwich"
	desc = "Fried chicken, in sandwich format. Beauty is simplicity."
	icon_state = "chickenfillet"
	filling_color = "#E9ADFF"
	center_of_mass = list("x"=16, "y"=16)
	reagent_data = list(NUTRIMENT_GOOD = list("buns" = 2))
	reagents_to_add = list(NUTRIMENT_GOOD = 4, "protein" = 8)
	bitesize = 3

/obj/item/weapon/reagent_containers/food/snacks/chilicheesefries
	name = "chili cheese fries"
	gender = PLURAL
	desc = "A mighty plate of fries, drowned in hot chili and cheese sauce. Because your arteries are overrated."
	icon_state = "chilicheesefries"
	trash = /obj/item/trash/plate
	filling_color = "#EDDD00"
	center_of_mass = list("x"=16, "y"=11)
	reagent_data = list(NUTRIMENT_GOOD = list("fresh fries" = 4, "chilli peppers" = 2))
	reagents_to_add = list(NUTRIMENT_GOOD = 6, "protein" = 2, "capsaicin" = 2, "cheese" = 2)
	bitesize = 4

/obj/item/weapon/reagent_containers/food/snacks/friedmushroom
	name = "fried mushroom"
	desc = "A tender, beer-battered plump helmet, fried to crispy perfection."
	icon_state = "friedmushroom"
	filling_color = "#EDDD00"
	center_of_mass = list("x"=16, "y"=11)
	reagent_data = list(NUTRIMENT_GOOD = list("fried mushroom" = 4))
	reagents_to_add = list(NUTRIMENT_GOOD = 4, "protein" = 2)
	bitesize = 5

/obj/item/weapon/reagent_containers/food/snacks/pisanggoreng
	name = "pisang goreng"
	gender = PLURAL
	desc = "Crispy, starchy, sweet banana fritters. Popular street food in parts of Sol."
	icon_state = "pisanggoreng"
	trash = /obj/item/trash/plate
	filling_color = "#301301"
	center_of_mass = list("x"=16, "y"=11)
	reagent_data = list(NUTRIMENT_GOOD = list("fried bananas" = 4))
	reagents_to_add = list(NUTRIMENT_GOOD = 8)
	bitesize = 3

/obj/item/weapon/reagent_containers/food/snacks/meatbun
	name = "meat bun"
	desc = "A soft, fluffy flour bun also known as baozi. This one is filled with a spiced meat filling."
	icon_state = "meatbun"
	filling_color = "#edd7d7"
	center_of_mass = list("x"=16, "y"=11)
	reagent_data = list(NUTRIMENT_GOOD = list("buns" = 2, "spices" = 2))
	reagents_to_add = list(NUTRIMENT_GOOD = 5, "protein" = 3)
	bitesize = 5

/obj/item/weapon/reagent_containers/food/snacks/custardbun
	name = "custard bun"
	desc = "A soft, fluffy flour bun also known as baozi. This one is filled with an egg custard."
	icon_state = "meatbun"
	filling_color = "#ebedc2"
	center_of_mass = list("x"=16, "y"=11)
	reagent_data = list(NUTRIMENT_GOOD = list("buns" = 2, "spices" = 2))
	reagents_to_add = list(NUTRIMENT_GOOD = 6, "egg" = 2, "protein" = 2)
	bitesize = 6

/obj/item/weapon/reagent_containers/food/snacks/chickenmomo
	name = "chicken momo"
	gender = PLURAL
	desc = "A plate of spiced and steamed chicken dumplings. The style originates from south Asia."
	icon_state = "momo"
	trash = /obj/item/trash/snacktray
	filling_color = "#edd7d7"
	center_of_mass = list("x"=15, "y"=9)
	reagent_data = list(NUTRIMENT_GOOD = list("buns" = 4))
	reagents_to_add = list(NUTRIMENT_GOOD = 9, "protein" = 6, "spacespice" = 2)
	bitesize = 3

/obj/item/weapon/reagent_containers/food/snacks/veggiemomo
	name = "veggie momo"
	gender = PLURAL
	desc = "A plate of spiced and steamed vegetable dumplings. The style originates from south Asia."
	icon_state = "momo"
	trash = /obj/item/trash/snacktray
	filling_color = "#edd7d7"
	center_of_mass = list("x"=15, "y"=9)
	reagent_data = list(NUTRIMENT_GOOD = list("buns" = 2, "cabbage" = 4))
	reagents_to_add = list(NUTRIMENT_GOOD = 13, "spacespice" = 4, "carrotjuice" = 3, "imidazoline" = 1)
	bitesize = 3

/obj/item/weapon/reagent_containers/food/snacks/risotto
	name = "risotto"
	gender = PLURAL
	desc = "A creamy, savory rice dish from southern Europe, typically cooked slowly with wine and broth. This one has bits of mushroom."
	icon_state = "risotto"
	trash = /obj/item/trash/snack_bowl
	filling_color = "#edd7d7"
	center_of_mass = list("x"=15, "y"=9)
	reagent_data = list(NUTRIMENT_GOOD = list("rice" = 2, "mushroom" = 4))
	reagents_to_add = list(NUTRIMENT_GOOD = 7, "protein" = 1, "spacespice" = 2)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/risottoballs
	name = "risotto balls"
	gender = PLURAL
	desc = "Mushroom risotto that has been battered and deep fried. The best use of leftovers!"
	icon_state = "risottoballs"
	trash = /obj/item/trash/snack_bowl
	filling_color = "#edd7d7"
	center_of_mass = list("x"=15, "y"=9)
	reagent_data = list(NUTRIMENT_GOOD = list("mushroom" = 2))
	reagents_to_add = list(NUTRIMENT_GOOD = 2, "spacespice" = 2, "sodiumchloride" = 1, "blackpepper" = 1, "rice" = 4)
	bitesize = 3

/obj/item/weapon/reagent_containers/food/snacks/honeytoast
	name = "piece of honeyed toast"
	desc = "For those who like their breakfast sweet."
	icon_state = "honeytoast"
	trash = /obj/item/trash/plate
	filling_color = "#EDE5AD"
	center_of_mass = list("x"=16, "y"=9)
	reagent_data = list(NUTRIMENT_GOOD = list("bread" = 3))
	reagents_to_add = list(NUTRIMENT_GOOD = 1, "honey" = 2)
	bitesize = 4

/obj/item/weapon/reagent_containers/food/snacks/poachedegg
	name = "poached egg"
	desc = "A delicately poached egg with a runny yolk. Healthier than its fried counterpart."
	icon_state = "poachedegg"
	trash = /obj/item/trash/plate
	filling_color = "#FFDF78"
	center_of_mass = list("x"=16, "y"=14)
	reagent_data = list(NUTRIMENT_GOOD = list("egg" = 3))
	reagents_to_add = list(NUTRIMENT_GOOD = 1, "blackpepper" = 1)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/ribplate
	name = "plate of ribs"
	desc = "A half-rack of ribs, brushed with some sort of honey-glaze. Why are there no napkins on board?"
	icon_state = "ribplate"
	trash = /obj/item/trash/plate
	filling_color = "#7A3D11"
	center_of_mass = list("x"=16, "y"=13)
	bitesize = 4
	reagents_to_add = list("protein" = 6, "triglyceride" = 2, "blackpepper" = 1, "honey" = 5)


/////////////////////////////////////////////////Sliceable////////////////////////////////////////
// All the food items that can be sliced into smaller bits like Meatbread and Cheesewheels

// sliceable is just an organization type path, it doesn't have any additional code or variables tied to it.

/obj/item/weapon/reagent_containers/food/snacks/sliceable
	w_class = 3 //Whole pizzas and cakes shouldn't fit in a pocket, you can slice them if you want to do that.

/obj/item/weapon/reagent_containers/food/snacks/sliceable/meatbread
	name = "meatbread loaf"
	desc = "The culinary base of every self-respecting eloquent gentleman."
	icon_state = "meatbread"
	slice_path = /obj/item/weapon/reagent_containers/food/snacks/meatbreadslice
	slices_num = 5
	filling_color = "#FF7575"
	center_of_mass = list("x"=16, "y"=9)
	reagent_data = list(NUTRIMENT_GOOD = list("bread" = 10))
	reagents_to_add = list(NUTRIMENT_GOOD = 10, "protein" = 20)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/meatbreadslice
	name = "meatbread slice"
	desc = "A slice of delicious meatbread."
	icon_state = "meatbreadslice"
	trash = /obj/item/trash/plate
	filling_color = "#FF7575"
	bitesize = 2
	center_of_mass = list("x"=16, "y"=13)

/obj/item/weapon/reagent_containers/food/snacks/meatbreadslice/filled
	reagent_data = list(NUTRIMENT_GOOD = list("bread" = 5))
	reagents_to_add = list(NUTRIMENT_GOOD = 4, "protein" = 4)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/sliceable/xenomeatbread
	name = "xenomeatbread loaf"
	desc = "The culinary base of every self-respecting eloquent gentleman. Extra Heretical."
	icon_state = "xenomeatbread"
	slice_path = /obj/item/weapon/reagent_containers/food/snacks/xenomeatbreadslice
	slices_num = 5
	filling_color = "#8AFF75"
	center_of_mass = list("x"=16, "y"=9)
	reagent_data = list(NUTRIMENT_GOOD = list("bread" = 10))
	reagents_to_add = list(NUTRIMENT_GOOD = 10, "protein" = 20)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/xenomeatbreadslice
	name = "xenomeatbread slice"
	desc = "A slice of delicious meatbread. Extra Heretical."
	icon_state = "xenobreadslice"
	trash = /obj/item/trash/plate
	filling_color = "#8AFF75"
	bitesize = 2
	center_of_mass = list("x"=16, "y"=13)

/obj/item/weapon/reagent_containers/food/snacks/xenomeatbreadslice/filled
	reagent_data = list(NUTRIMENT_GOOD = list("bread" = 5))
	reagents_to_add = list(NUTRIMENT_GOOD = 2, "protein" = 4)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/sliceable/bananabread
	name = "banana-nut bread"
	desc = "A heavenly and filling treat."
	icon_state = "bananabread"
	slice_path = /obj/item/weapon/reagent_containers/food/snacks/bananabreadslice
	slices_num = 5
	filling_color = "#EDE5AD"
	center_of_mass = list("x"=16, "y"=9)
	reagent_data = list(NUTRIMENT_GOOD = list("bread" = 10))
	reagents_to_add = list(NUTRIMENT_GOOD = 20, "banana" = 20)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/bananabreadslice
	name = "banana-nut bread slice"
	desc = "A slice of delicious banana bread."
	icon_state = "bananabreadslice"
	trash = /obj/item/trash/plate
	filling_color = "#EDE5AD"
	bitesize = 2
	center_of_mass = list("x"=16, "y"=8)

/obj/item/weapon/reagent_containers/food/snacks/bananabreadslice/filled
	reagent_data = list(NUTRIMENT_GOOD = list("bread" = 5))
	reagents_to_add = list(NUTRIMENT_GOOD = 4, "banana" = 4)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/sliceable/tofubread
	name = "tofubread"
	icon_state = "Like meatbread but for vegetarians. Not guaranteed to give superpowers."
	icon_state = "tofubread"
	slice_path = /obj/item/weapon/reagent_containers/food/snacks/tofubreadslice
	slices_num = 5
	filling_color = "#F7FFE0"
	center_of_mass = list("x"=16, "y"=9)
	reagent_data = list(NUTRIMENT_GOOD = list("bread" = 10))
	reagents_to_add = list(NUTRIMENT_GOOD = 20, "tofu" = 10)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/tofubreadslice
	name = "tofubread slice"
	desc = "A slice of delicious tofubread."
	icon_state = "tofubreadslice"
	trash = /obj/item/trash/plate
	filling_color = "#F7FFE0"
	bitesize = 2
	center_of_mass = list("x"=16, "y"=13)

/obj/item/weapon/reagent_containers/food/snacks/tofubreadslice/filled
	reagent_data = list(NUTRIMENT_GOOD = list("bread" = 5))
	reagents_to_add = list(NUTRIMENT_GOOD = 6, "tofu" = 4)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/sliceable/cake/carrot
	name = "carrot cake"
	desc = "A favorite desert of a certain wascally wabbit. Not a lie."
	icon_state = "carrotcake"
	slice_path = /obj/item/weapon/reagent_containers/food/snacks/cakeslice/carrot
	slices_num = 5
	filling_color = "#FFD675"
	center_of_mass = list("x"=16, "y"=10)
	reagent_data = list(NUTRIMENT_GOOD = list("cake" = 10, "sweetness" = 10, "carrot" = 15))
	reagents_to_add = list(NUTRIMENT_GOOD = 25, "imidazoline" = 10)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/cakeslice/carrot
	name = "carrot cake slice"
	desc = "Carrotty slice of Carrot Cake, carrots are good for your eyes! Also not a lie."
	icon_state = "carrotcake_slice"
	trash = /obj/item/trash/plate
	filling_color = "#FFD675"
	bitesize = 2
	center_of_mass = list("x"=16, "y"=14)

/obj/item/weapon/reagent_containers/food/snacks/cakeslice/carrot/filled
	reagent_data = list(NUTRIMENT_GOOD = list("cake" = 5, "sweetness" = 5, "carrot" = 5))
	reagents_to_add = list(NUTRIMENT_GOOD = 5, "imidazoline" = 1)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/sliceable/cake/brain
	name = "brain cake"
	desc = "A squishy cake-thing."
	icon_state = "braincake"
	slice_path = /obj/item/weapon/reagent_containers/food/snacks/cakeslice/brain
	slices_num = 5
	filling_color = "#E6AEDB"
	center_of_mass = list("x"=16, "y"=10)
	reagent_data = list(NUTRIMENT_GOOD = list("cake" = 10, "sweetness" = 10, "slime" = 15))
	reagents_to_add = list(NUTRIMENT_GOOD = 5, "protein" = 25, "alkysine" = 10)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/cakeslice/brain
	name = "brain cake slice"
	desc = "Lemme tell you something about prions. THEY'RE DELICIOUS."
	icon_state = "braincakeslice"
	trash = /obj/item/trash/plate
	filling_color = "#E6AEDB"
	bitesize = 2
	center_of_mass = list("x"=16, "y"=12)

/obj/item/weapon/reagent_containers/food/snacks/cakeslice/brain/filled
	reagent_data = list(NUTRIMENT_GOOD = list("cake" = 2, "sweetness" = 2, "slime" = 3))
	reagents_to_add = list(NUTRIMENT_GOOD = 1, "protein" = 5, "alkysine" = 2)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/sliceable/cake/cheese
	name = "cheesecake"
	desc = "DANGEROUSLY cheesy."
	icon_state = "cheesecake"
	slice_path = /obj/item/weapon/reagent_containers/food/snacks/cakeslice/cheese
	slices_num = 5
	filling_color = "#FAF7AF"
	center_of_mass = list("x"=16, "y"=10)
	reagent_data = list(NUTRIMENT_GOOD = list("cake" = 10, "cream" = 10))
	reagents_to_add = list(NUTRIMENT_GOOD = 10, "cheese" = 15)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/cakeslice/cheese
	name = "cheesecake slice"
	desc = "Slice of pure cheestisfaction"
	icon_state = "cheesecake_slice"
	trash = /obj/item/trash/plate
	filling_color = "#FAF7AF"
	bitesize = 2
	center_of_mass = list("x"=16, "y"=14)

/obj/item/weapon/reagent_containers/food/snacks/cakeslice/cheese/filled
	reagent_data = list(NUTRIMENT_GOOD = list("cake" = 5, "cream" = 5))
	reagents_to_add = list(NUTRIMENT_GOOD = 2, "cheese" = 3)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/sliceable/cake/plain
	name = "vanilla cake"
	desc = "A plain cake, not a lie."
	icon_state = "plaincake"
	slice_path = /obj/item/weapon/reagent_containers/food/snacks/cakeslice/plain
	slices_num = 5
	filling_color = "#F7EDD5"
	center_of_mass = list("x"=16, "y"=10)
	reagent_data = list(NUTRIMENT_GOOD = list("cake" = 10, "sweetness" = 10, "vanilla" = 15))
	reagents_to_add = list(NUTRIMENT_GOOD = 20)

/obj/item/weapon/reagent_containers/food/snacks/cakeslice/plain
	name = "vanilla cake slice"
	desc = "Just a slice of cake, it is enough for everyone."
	icon_state = "plaincake_slice"
	trash = /obj/item/trash/plate
	filling_color = "#F7EDD5"
	bitesize = 2
	center_of_mass = list("x"=16, "y"=14)

/obj/item/weapon/reagent_containers/food/snacks/cakeslice/plain/filled
	reagent_data = list(NUTRIMENT_GOOD = list("cake" = 5, "sweetness" = 5, "vanilla" = 5))
	reagents_to_add = list(NUTRIMENT_GOOD = 4)

/obj/item/weapon/reagent_containers/food/snacks/sliceable/cake/orange
	name = "orange cake"
	desc = "A cake with added orange."
	icon_state = "orangecake"
	slice_path = /obj/item/weapon/reagent_containers/food/snacks/cakeslice/orange
	slices_num = 4
	filling_color = "#FADA8E"
	center_of_mass = list("x"=16, "y"=10)
	reagent_data = list(NUTRIMENT_GOOD = list("cake" = 10, "sweetness" = 10))
	reagents_to_add = list(NUTRIMENT_GOOD = 12, "orangejuice" = 8)

/obj/item/weapon/reagent_containers/food/snacks/cakeslice/orange
	name = "orange cake slice"
	desc = "Just a slice of cake, it is enough for everyone."
	icon_state = "orangecake_slice"
	trash = /obj/item/trash/plate
	filling_color = "#FADA8E"
	bitesize = 2
	center_of_mass = list("x"=16, "y"=14)

/obj/item/weapon/reagent_containers/food/snacks/cakeslice/orange/filled
	reagent_data = list(NUTRIMENT_GOOD = list("cake" = 5, "sweetness" = 5))
	reagents_to_add = list(NUTRIMENT_GOOD = 3, "orangejuice" = 2)

/obj/item/weapon/reagent_containers/food/snacks/sliceable/cake/lime
	name = "lime cake"
	desc = "A cake with added lime."
	icon_state = "limecake"
	slice_path = /obj/item/weapon/reagent_containers/food/snacks/cakeslice/lime
	slices_num = 4
	filling_color = "#CBFA8E"
	center_of_mass = list("x"=16, "y"=10)
	reagent_data = list(NUTRIMENT_GOOD = list("cake" = 10, "sweetness" = 10))
	reagents_to_add = list(NUTRIMENT_GOOD = 12, "limejuice" = 15)

/obj/item/weapon/reagent_containers/food/snacks/cakeslice/lime
	name = "lime cake slice"
	desc = "Just a slice of cake, it is enough for everyone."
	icon_state = "limecake_slice"
	trash = /obj/item/trash/plate
	filling_color = "#CBFA8E"
	bitesize = 2
	center_of_mass = list("x"=16, "y"=14)

/obj/item/weapon/reagent_containers/food/snacks/cakeslice/lime/filled
	reagent_data = list(NUTRIMENT_GOOD = list("cake" = 5, "sweetness" = 5))
	reagents_to_add = list(NUTRIMENT_GOOD = 3, "limejuice" = 2)

/obj/item/weapon/reagent_containers/food/snacks/sliceable/cake/lemon
	name = "lemon cake"
	desc = "A cake with added lemon."
	icon_state = "lemoncake"
	slice_path = /obj/item/weapon/reagent_containers/food/snacks/cakeslice/lemon
	slices_num = 4
	filling_color = "#FAFA8E"
	center_of_mass = list("x"=16, "y"=10)
	reagent_data = list(NUTRIMENT_GOOD = list("cake" = 10, "sweetness" = 10))
	reagents_to_add = list(NUTRIMENT_GOOD = 12, "lemonjuice" = 8)

/obj/item/weapon/reagent_containers/food/snacks/cakeslice/lemon
	name = "lemon cake slice"
	desc = "Just a slice of cake, it is enough for everyone."
	icon_state = "lemoncake_slice"
	trash = /obj/item/trash/plate
	filling_color = "#FAFA8E"
	bitesize = 2
	center_of_mass = list("x"=16, "y"=14)

/obj/item/weapon/reagent_containers/food/snacks/cakeslice/lemon/filled
	reagent_data = list(NUTRIMENT_GOOD = list("cake" = 5, "sweetness" = 5))
	reagents_to_add = list(NUTRIMENT_GOOD = 3, "lemonjuice" = 2)

/obj/item/weapon/reagent_containers/food/snacks/sliceable/cake/chocolate
	name = "chocolate cake"
	desc = "A cake with added chocolate."
	icon_state = "chocolatecake"
	slice_path = /obj/item/weapon/reagent_containers/food/snacks/cakeslice/chocolate
	slices_num = 4
	filling_color = "#805930"
	center_of_mass = list("x"=16, "y"=10)
	reagent_data = list(NUTRIMENT_GOOD = list("cake" = 10, "sweetness" = 10, "chocolate" = 15))
	reagents_to_add = list(NUTRIMENT_GOOD = 12, "coco" = 8)

/obj/item/weapon/reagent_containers/food/snacks/cakeslice/chocolate
	name = "chocolate cake slice"
	desc = "Just a slice of cake, it is enough for everyone."
	icon_state = "chocolatecake_slice"
	trash = /obj/item/trash/plate
	filling_color = "#805930"
	bitesize = 2
	center_of_mass = list("x"=16, "y"=14)

/obj/item/weapon/reagent_containers/food/snacks/cakeslice/chocolate/filled
	reagent_data = list(NUTRIMENT_GOOD = list("cake" = 5, "sweetness" = 5))
	reagents_to_add = list(NUTRIMENT_GOOD = 3, "coco" = 2)

/obj/item/weapon/reagent_containers/food/snacks/sliceable/cheesewheel
	name = "cheese wheel"
	desc = "A big wheel of delcious Cheddar."
	icon_state = "cheesewheel"
	slice_path = /obj/item/weapon/reagent_containers/food/snacks/cheesewedge
	slices_num = 8
	filling_color = "#FFF700"
	center_of_mass = list("x"=16, "y"=10)
	bitesize = 2
	reagents_to_add = list("cheese" = 32)

/obj/item/weapon/reagent_containers/food/snacks/cheesewedge
	name = "cheese wedge"
	desc = "A wedge of delicious Cheddar. The cheese wheel it was cut from can't have gone far."
	icon_state = "cheesewedge"
	filling_color = "#FFF700"
	bitesize = 2
	center_of_mass = list("x"=16, "y"=10)

/obj/item/weapon/reagent_containers/food/snacks/cheesewedge/filled
	reagents_to_add = list("cheese" = 4)

/obj/item/weapon/reagent_containers/food/snacks/sliceable/cake/birthday
	name = "birthday cake"
	desc = "Happy Birthday..."
	icon_state = "birthdaycake"
	slice_path = /obj/item/weapon/reagent_containers/food/snacks/cakeslice/birthday
	slices_num = 5
	filling_color = "#FFD6D6"
	center_of_mass = list("x"=16, "y"=10)
	reagent_data = list(NUTRIMENT_GOOD = list("cake" = 10, "sweetness" = 10))
	reagents_to_add = list(NUTRIMENT_GOOD = 20, "sprinkles" = 10)
	bitesize = 3

/obj/item/weapon/reagent_containers/food/snacks/cakeslice/birthday
	name = "birthday cake slice"
	desc = "A slice of your birthday."
	icon_state = "birthdaycakeslice"
	trash = /obj/item/trash/plate
	filling_color = "#FFD6D6"
	bitesize = 2
	center_of_mass = list("x"=16, "y"=14)

/obj/item/weapon/reagent_containers/food/snacks/cakeslice/birthday/filled
	reagent_data = list(NUTRIMENT_GOOD = list("cake" = 5, "sweetness" = 5))
	reagents_to_add = list(NUTRIMENT_GOOD = 4, "sprinkles" = 2)
	bitesize = 3

/obj/item/weapon/reagent_containers/food/snacks/sliceable/bread
	name = "bread"
	icon_state = "Some plain old Loamer bread, about as plain as Loamers themselves."
	icon_state = "bread"
	slice_path = /obj/item/weapon/reagent_containers/food/snacks/breadslice
	slices_num = 8
	filling_color = "#FFE396"
	center_of_mass = list("x"=16, "y"=9)
	reagent_data = list(NUTRIMENT_GOOD = list("bland bread" = 12))
	reagents_to_add = list(NUTRIMENT_GOOD = 24, "protein" = 8)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/breadslice
	name = "bread slice"
	desc = "A slice of the dead center of the political compass. Why can't you just be nice?"
	icon_state = "breadslice"
	trash = /obj/item/trash/plate
	filling_color = "#D27332"
	bitesize = 2
	center_of_mass = list("x"=16, "y"=4)

/obj/item/weapon/reagent_containers/food/snacks/breadslice/filled
	reagent_data = list(NUTRIMENT_GOOD = list("bland bread" = 2))
	reagents_to_add = list(NUTRIMENT_GOOD = 2, "protein" = 1)

/obj/item/weapon/reagent_containers/food/snacks/sliceable/creamcheesebread
	name = "cream cheese bread"
	desc = "Bread with cream cheese! It's an Elvish thing."
	icon_state = "creamcheesebread"
	slice_path = /obj/item/weapon/reagent_containers/food/snacks/creamcheesebreadslice
	slices_num = 5
	filling_color = "#FFF896"
	center_of_mass = list("x"=16, "y"=9)
	reagent_data = list(NUTRIMENT_GOOD = list("bread" = 6, "cream" = 3))
	reagents_to_add = list(NUTRIMENT_GOOD = 5, "cheese" = 15)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/creamcheesebreadslice
	name = "cream cheese bread slice"
	desc = "An individual, separate slice of leftist unity! Wait, what?"
	icon_state = "creamcheesebreadslice"
	trash = /obj/item/trash/plate
	filling_color = "#FFF896"
	bitesize = 2
	center_of_mass = list("x"=16, "y"=13)

/obj/item/weapon/reagent_containers/food/snacks/creamcheesebreadslice/filled
	reagent_data = list(NUTRIMENT_GOOD = list("bread" = 3, "cream" = 2))
	reagents_to_add = list(NUTRIMENT_GOOD = 1, "cheese" = 3)

/obj/item/weapon/reagent_containers/food/snacks/watermelonslice
	name = "watermelon slice"
	desc = "A slice of watery goodness."
	icon_state = "watermelonslice"
	filling_color = "#FF3867"
	bitesize = 2
	center_of_mass = list("x"=16, "y"=10)

/obj/item/weapon/reagent_containers/food/snacks/watermelonslice/filled
	reagent_data = list(NUTRIMENT_GOOD = list("watermelon" = 1))
	reagents_to_add = list(NUTRIMENT_GOOD = 1, "watermelonjuice" = 3)

/obj/item/weapon/reagent_containers/food/snacks/sliceable/cake/apple
	name = "apple cake"
	desc = "A cake centred with apples."
	icon_state = "applecake"
	slice_path = /obj/item/weapon/reagent_containers/food/snacks/cakeslice/apple
	slices_num = 5
	filling_color = "#EBF5B8"
	center_of_mass = list("x"=16, "y"=10)
	reagent_data = list(NUTRIMENT_GOOD = list("cake" = 10, "sweetness" = 10))
	reagents_to_add = list(NUTRIMENT_GOOD = 15, "applejuice" = 5)

/obj/item/weapon/reagent_containers/food/snacks/cakeslice/apple
	name = "apple cake slice"
	desc = "A slice of heavenly cake."
	icon_state = "applecakeslice"
	trash = /obj/item/trash/plate
	filling_color = "#EBF5B8"
	bitesize = 2
	center_of_mass = list("x"=16, "y"=14)

/obj/item/weapon/reagent_containers/food/snacks/cakeslice/apple/filled
	reagent_data = list(NUTRIMENT_GOOD = list("cake" = 5, "sweetness" = 5))
	reagents_to_add = list(NUTRIMENT_GOOD = 3, "applejuice" = 1)

/obj/item/weapon/reagent_containers/food/snacks/sliceable/pumpkinpie
	name = "pumpkin pie"
	desc = "A delicious treat for the autumn months."
	icon_state = "pumpkinpie"
	slice_path = /obj/item/weapon/reagent_containers/food/snacks/pumpkinpieslice
	slices_num = 5
	filling_color = "#F5B951"
	center_of_mass = list("x"=16, "y"=10)
	reagent_data = list(NUTRIMENT_GOOD = list("pie" = 5, "cream" = 5))
	reagents_to_add = list(NUTRIMENT_GOOD = 15, "pumpkinspice" = 5)

/obj/item/weapon/reagent_containers/food/snacks/pumpkinpieslice
	name = "pumpkin pie slice"
	desc = "A slice of pumpkin pie, with whipped cream on top. Perfection."
	icon_state = "pumpkinpieslice"
	trash = /obj/item/trash/plate
	filling_color = "#F5B951"
	bitesize = 2
	center_of_mass = list("x"=16, "y"=12)

/obj/item/weapon/reagent_containers/food/snacks/pumpkinpieslice/filled
	reagent_data = list(NUTRIMENT_GOOD = list("pie" = 2, "cream" = 2))
	reagents_to_add = list(NUTRIMENT_GOOD = 2, "pumpkinspice" = 2)

/obj/item/weapon/reagent_containers/food/snacks/cracker
	name = "cracker"
	desc = "It's a salted cracker."
	icon_state = "cracker"
	filling_color = "#F5DEB8"
	center_of_mass = list("x"=17, "y"=6)
	reagent_data = list(NUTRIMENT_GOOD = list("cracker" = 2))
	reagents_to_add = list(NUTRIMENT_GOOD = 1, "sodiumchloride" = 4)

/obj/item/weapon/reagent_containers/food/snacks/sliceable/keylimepie
	name = "key lime pie"
	desc = "A tart, sweet dessert. What's a key lime, anyway?"
	icon_state = "keylimepie"
	slice_path = /obj/item/weapon/reagent_containers/food/snacks/keylimepieslice
	slices_num = 5
	filling_color = "#F5B951"
	center_of_mass = list("x"=16, "y"=10)
	reagent_data = list(NUTRIMENT_GOOD = list("pie" = 10, "cream" = 10))
	reagents_to_add = list(NUTRIMENT_GOOD = 16, "limejuice" = 4)

/obj/item/weapon/reagent_containers/food/snacks/keylimepieslice
	name = "slice of key lime pie"
	desc = "A slice of tart pie, with whipped cream on top."
	icon_state = "keylimepieslice"
	trash = /obj/item/trash/plate
	filling_color = "#F5B951"
	center_of_mass = list("x"=16, "y"=12)

/obj/item/weapon/reagent_containers/food/snacks/keylimepieslice/filled
	reagent_data = list(NUTRIMENT_GOOD = list("pie" = 5, "cream" = 5))
	reagents_to_add = list(NUTRIMENT_GOOD = 3, "limejuice" = 1)

/obj/item/weapon/reagent_containers/food/snacks/sliceable/quiche
	name = "quiche"
	desc = "Real men eat this, contrary to popular belief."
	icon_state = "quiche"
	slice_path = /obj/item/weapon/reagent_containers/food/snacks/quicheslice
	slices_num = 5
	filling_color = "#F5B951"
	center_of_mass = list("x"=16, "y"=10)
	reagent_data = list(NUTRIMENT_GOOD = list("eggy pie" = 10))
	reagents_to_add = list(NUTRIMENT_GOOD = 10, "cheese" = 10)

/obj/item/weapon/reagent_containers/food/snacks/quicheslice
	name = "slice of quiche"
	desc = "A slice of delicious quiche. Eggy, cheesy goodness."
	icon_state = "quicheslice"
	trash = /obj/item/trash/plate
	filling_color = "#F5B951"
	bitesize = 3
	center_of_mass = list("x"=16, "y"=12)

/obj/item/weapon/reagent_containers/food/snacks/quicheslice/filled
	reagent_data = list(NUTRIMENT_GOOD = list("eggy pie" = 2))
	reagents_to_add = list(NUTRIMENT_GOOD = 2, "cheese" = 2)

/obj/item/weapon/reagent_containers/food/snacks/sliceable/brownies
	name = "brownies"
	gender = PLURAL
	desc = "Halfway to fudge, or halfway to cake? Who cares!"
	icon_state = "brownies"
	slice_path = /obj/item/weapon/reagent_containers/food/snacks/browniesslice
	slices_num = 4
	trash = /obj/item/trash/brownies
	filling_color = "#301301"
	center_of_mass = list("x"=15, "y"=9)
	reagent_data = list(NUTRIMENT_GOOD = list("brownies" = 5))
	reagents_to_add = list(NUTRIMENT_GOOD = 8, "browniemix" = 2)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/browniesslice
	name = "brownie"
	desc = "a dense, decadent chocolate brownie."
	icon_state = "browniesslice"
	trash = /obj/item/trash/plate
	filling_color = "#F5B951"
	bitesize = 2
	center_of_mass = list("x"=16, "y"=12)

/obj/item/weapon/reagent_containers/food/snacks/browniesslice/filled
	reagent_data = list(NUTRIMENT_GOOD = list("brownies" = 2))
	reagents_to_add = list(NUTRIMENT_GOOD = 1, "browniemix" = 1)

/obj/item/weapon/reagent_containers/food/snacks/sliceable/cosmicbrownies
	name = "cosmic brownies"
	gender = PLURAL
	desc = "Like, ultra-trippy. Brownies HAVE no gender, man." //Except I had to add one!
	icon_state = "cosmicbrownies"
	slice_path = /obj/item/weapon/reagent_containers/food/snacks/cosmicbrowniesslice
	slices_num = 4
	trash = /obj/item/trash/brownies
	filling_color = "#301301"
	center_of_mass = list("x"=15, "y"=9)
	reagent_data = list(NUTRIMENT_GOOD = list("brownies" = 5))
	reagents_to_add = list(NUTRIMENT_GOOD = 8, "browniemix" = 4, "space_drugs" = 4, "bicaridine" = 2, "kelotane" = 2, "toxin" = 2)
	bitesize = 3

/obj/item/weapon/reagent_containers/food/snacks/cosmicbrowniesslice
	name = "cosmic brownie"
	desc = "A dense, decadent and fun-looking chocolate brownie."
	icon_state = "cosmicbrowniesslice"
	trash = /obj/item/trash/plate
	filling_color = "#F5B951"
	bitesize = 3
	center_of_mass = list("x"=16, "y"=12)

/obj/item/weapon/reagent_containers/food/snacks/cosmicbrowniesslice/filled
	reagent_data = list(NUTRIMENT_GOOD = list("brownies" = 2))
	reagents_to_add = list(NUTRIMENT_GOOD = 1, "browniemix" = 1, "space_drugs" = 1, "bicaridine" = 1, "kelotane" = 1, "toxin" = 1)

/////////////////////////////////////////////////PIZZA////////////////////////////////////////

/obj/item/weapon/reagent_containers/food/snacks/sliceable/pizza
	slices_num = 6
	filling_color = "#BAA14C"

/obj/item/weapon/reagent_containers/food/snacks/sliceable/pizza/margherita
	name = "margherita"
	desc = "The golden standard of pizzas."
	icon_state = "pizzamargherita"
	slice_path = /obj/item/weapon/reagent_containers/food/snacks/margheritaslice
	slices_num = 6
	center_of_mass = list("x"=16, "y"=11)
	reagent_data = list(NUTRIMENT_GOOD = list("pizza crust" = 10))
	reagents_to_add = list(NUTRIMENT_GOOD = 35, "cheese" = 5, "tomatojuice" = 6)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/margheritaslice
	name = "margherita slice"
	desc = "A slice of the classic pizza."
	icon_state = "pizzamargheritaslice"
	filling_color = "#BAA14C"
	bitesize = 2
	center_of_mass = list("x"=18, "y"=13)

/obj/item/weapon/reagent_containers/food/snacks/margheritaslice/filled
	reagent_data = list(NUTRIMENT_GOOD = list("pizza crust" = 5))
	reagents_to_add = list(NUTRIMENT_GOOD = 5, "tomatojuice" = 2, "cheese" = 1)

/obj/item/weapon/reagent_containers/food/snacks/sliceable/pizza/meatpizza
	name = "meatpizza"
	desc = "A pizza with meat topping."
	icon_state = "meatpizza"
	slice_path = /obj/item/weapon/reagent_containers/food/snacks/meatpizzaslice
	slices_num = 6
	center_of_mass = list("x"=16, "y"=11)
	reagent_data = list(NUTRIMENT_GOOD = list("pizza crust" = 10))
	reagents_to_add = list(NUTRIMENT_GOOD = 10, "protein" = 44, "cheese" = 10, "tomatojuice" = 6)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/meatpizzaslice
	name = "meatpizza slice"
	desc = "A slice of a meaty pizza."
	icon_state = "meatpizzaslice"
	filling_color = "#BAA14C"
	bitesize = 2
	center_of_mass = list("x"=18, "y"=13)

/obj/item/weapon/reagent_containers/food/snacks/meatpizzaslice/filled
	reagent_data = list(NUTRIMENT_GOOD = list("pizza crust" = 5))
	reagents_to_add = list(NUTRIMENT_GOOD = 2, "tomatojuice" = 2, "cheese" = 2, "protein" = 7)

/obj/item/weapon/reagent_containers/food/snacks/sliceable/pizza/mushroompizza
	name = "mushroompizza"
	desc = "Very special pizza."
	icon_state = "mushroompizza"
	slice_path = /obj/item/weapon/reagent_containers/food/snacks/mushroompizzaslice
	slices_num = 6
	center_of_mass = list("x"=16, "y"=11)
	reagent_data = list(NUTRIMENT_GOOD = list("pizza crust" = 10, "mushroom" = 10))
	reagents_to_add = list(NUTRIMENT_GOOD = 35, "cheese" = 5, "tomatojuice" = 6)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/mushroompizzaslice
	name = "mushroompizza slice"
	desc = "Maybe it is the last slice of pizza in your life."
	icon_state = "mushroompizzaslice"
	filling_color = "#BAA14C"
	bitesize = 2
	center_of_mass = list("x"=18, "y"=13)

/obj/item/weapon/reagent_containers/food/snacks/mushroompizzaslice/filled
	reagent_data = list(NUTRIMENT_GOOD = list("pizza crust" = 5, "mushroom" = 5))
	reagents_to_add = list(NUTRIMENT_GOOD = 5, "tomatojuice" = 2, "cheese" = 1)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/sliceable/pizza/vegetablepizza
	name = "vegetable pizza"
	desc = "No one of Tomato Sapiens were harmed during making this pizza."
	icon_state = "vegetablepizza"
	slice_path = /obj/item/weapon/reagent_containers/food/snacks/vegetablepizzaslice
	slices_num = 6
	center_of_mass = list("x"=16, "y"=11)
	reagent_data = list(NUTRIMENT_GOOD = list("pizza crust" = 10, "eggplant" = 5, "carrot" = 5, "corn" = 5))
	reagents_to_add = list(NUTRIMENT_GOOD = 25, "tomatojuice" = 6, "imidazoline" = 12)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/vegetablepizzaslice
	name = "vegetable pizza slice"
	desc = "A slice of the most green pizza of all pizzas not containing green ingredients."
	icon_state = "vegetablepizzaslice"
	filling_color = "#BAA14C"
	bitesize = 2
	center_of_mass = list("x"=18, "y"=13)

/obj/item/weapon/reagent_containers/food/snacks/vegetablepizzaslice/filled
	reagent_data = list(NUTRIMENT_GOOD = list("pizza crust" = 5, "eggplant" = 5, "carrot" = 5, "corn" = 5))
	reagents_to_add = list(NUTRIMENT_GOOD = 4, "tomatojuice" = 2, "imidazoline" = 2)

/obj/item/weapon/reagent_containers/food/snacks/sliceable/pizza/crunch
	name = "pizza crunch"
	desc = "This was once a normal pizza, but it has been coated in batter and deep-fried. Whatever toppings it once had are a mystery, but they're still under there, somewhere..."
	icon_state = "pizzacrunch"
	slice_path = /obj/item/weapon/reagent_containers/food/snacks/pizzacrunchslice
	slices_num = 6
	center_of_mass = list("x"=16, "y"=11)
	reagent_data = list(NUTRIMENT_GOOD = list("fried pizza crust" = 15))
	reagents_to_add = list(NUTRIMENT_GOOD = 25, "batter" = 6, "oil" = 4)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/sliceable/pizza/crunch/Initialize()
	. = ..()
	coating = reagents.get_reagent("batter")

/obj/item/weapon/reagent_containers/food/snacks/pizzacrunchslice
	name = "pizza crunch"
	desc = "A little piece of a heart attack. It's toppings are a mystery, hidden under batter"
	icon_state = "pizzacrunchslice"
	filling_color = "#BAA14C"
	bitesize = 2
	center_of_mass = list("x"=18, "y"=13)
	reagent_data = list(NUTRIMENT_GOOD = list("fried pizza crust" = 5))
	reagents_to_add = list(NUTRIMENT_GOOD = 5, "batter" = 2, "oil" = 1)

/obj/item/weapon/reagent_containers/food/snacks/pizzacrunchslice/Initialize()
	. = ..()
	coating = reagents.get_reagent("batter")

/obj/item/pizzabox
	name = "pizza box"
	desc = "A box suited for pizzas."
	icon = 'icons/obj/food.dmi'
	icon_state = "pizzabox1"
	center_of_mass = list("x" = 16,"y" = 6)

	var/open = 0 // Is the box open?
	var/ismessy = 0 // Fancy mess on the lid
	var/obj/item/weapon/reagent_containers/food/snacks/sliceable/pizza/pizza // Content pizza
	var/list/boxes = list() // If the boxes are stacked, they come here
	var/boxtag = ""

/obj/item/pizzabox/update_icon()
	cut_overlays()

	// Set appropriate description
	if( open && pizza )
		desc = "A box suited for pizzas. It appears to have a [pizza.name] inside."
	else if( boxes.len > 0 )
		desc = "A pile of boxes suited for pizzas. There appears to be [boxes.len + 1] boxes in the pile."

		var/obj/item/pizzabox/topbox = boxes[boxes.len]
		var/toptag = topbox.boxtag
		if( toptag != "" )
			desc = "[desc] The box on top has a tag, it reads: '[toptag]'."
	else
		desc = "A box suited for pizzas."

		if( boxtag != "" )
			desc = "[desc] The box has a tag, it reads: '[boxtag]'."

	// Icon states and overlays
	if( open )
		if( ismessy )
			icon_state = "pizzabox_messy"
		else
			icon_state = "pizzabox_open"

		if( pizza )
			var/image/pizzaimg = image(icon, icon_state = pizza.icon_state)
			pizzaimg.pixel_y = -3
			add_overlay(pizzaimg)

		return
	else
		// Stupid code because byondcode sucks
		var/doimgtag = 0
		if( boxes.len > 0 )
			var/obj/item/pizzabox/topbox = boxes[boxes.len]
			if( topbox.boxtag != "" )
				doimgtag = 1
		else
			if( boxtag != "" )
				doimgtag = 1

		if( doimgtag )
			var/image/tagimg = image(icon, icon_state = "pizzabox_tag")
			tagimg.pixel_y = boxes.len * 3
			add_overlay(tagimg)

	icon_state = "pizzabox[boxes.len+1]"

/obj/item/pizzabox/attack_hand( mob/user as mob )

	if( open && pizza )
		user.put_in_hands( pizza )

		to_chat(user, "<span class='warning'>You take \the [src.pizza] out of \the [src].</span>")
		src.pizza = null
		update_icon()
		return

	if( boxes.len > 0 )
		if( user.get_inactive_hand() != src )
			..()
			return

		var/obj/item/pizzabox/box = boxes[boxes.len]
		boxes -= box

		user.put_in_hands( box )
		to_chat(user, "<span class='warning'>You remove the topmost [src] from your hand.</span>")
		box.update_icon()
		update_icon()
		return
	..()

/obj/item/pizzabox/attack_self( mob/user as mob )

	if( boxes.len > 0 )
		return

	open = !open

	if( open && pizza )
		ismessy = 1

	update_icon()

/obj/item/pizzabox/attackby( obj/item/I as obj, mob/user as mob )
	if( istype(I, /obj/item/pizzabox/) )
		var/obj/item/pizzabox/box = I

		if( !box.open && !src.open )
			// Make a list of all boxes to be added
			var/list/boxestoadd = list()
			boxestoadd += box
			for(var/obj/item/pizzabox/i in box.boxes)
				boxestoadd += i

			if( (boxes.len+1) + boxestoadd.len <= 5 )
				user.drop_from_inventory(box,src)
				box.boxes = list() // Clear the box boxes so we don't have boxes inside boxes. - Xzibit
				src.boxes.Add( boxestoadd )

				box.update_icon()
				update_icon()

				to_chat(user, "<span class='warning'>You put \the [box] ontop of \the [src]!</span>")
			else
				to_chat(user, "<span class='warning'>The stack is too high!</span>")
		else
			to_chat(user, "<span class='warning'>Close \the [box] first!</span>")

		return

	if( istype(I, /obj/item/weapon/reagent_containers/food/snacks/sliceable/pizza/) ) // Long ass fucking object name

		if( src.open )
			user.drop_from_inventory(I,src)
			src.pizza = I

			update_icon()

			to_chat(user, "<span class='warning'>You put \the [I] in \the [src]!</span>")
		else
			to_chat(user, "<span class='warning'>You try to push \the [I] through the lid but it doesn't work!</span>")
		return

	if( I.ispen() )

		if( src.open )
			return

		var/t = sanitize(input("Enter what you want to add to the tag:", "Write", null, null) as text, 30)

		var/obj/item/pizzabox/boxtotagto = src
		if( boxes.len > 0 )
			boxtotagto = boxes[boxes.len]

		boxtotagto.boxtag = copytext("[boxtotagto.boxtag][t]", 1, 30)

		update_icon()
		return
	..()

/obj/item/pizzabox/margherita/New()
	pizza = new /obj/item/weapon/reagent_containers/food/snacks/sliceable/pizza/margherita(src)
	boxtag = "Margherita Deluxe"

/obj/item/pizzabox/vegetable/New()
	pizza = new /obj/item/weapon/reagent_containers/food/snacks/sliceable/pizza/vegetablepizza(src)
	boxtag = "Gourmet Vegatable"

/obj/item/pizzabox/mushroom/New()
	pizza = new /obj/item/weapon/reagent_containers/food/snacks/sliceable/pizza/mushroompizza(src)
	boxtag = "Mushroom Special"

/obj/item/pizzabox/meat/New()
	pizza = new /obj/item/weapon/reagent_containers/food/snacks/sliceable/pizza/meatpizza(src)
	boxtag = "Meatlover's Supreme"

/obj/item/weapon/reagent_containers/food/snacks/dionaroast
	name = "roast diona"
	desc = "It's like an enormous, leathery carrot. With an eye."
	icon_state = "dionaroast"
	trash = /obj/item/trash/plate
	filling_color = "#75754B"
	center_of_mass = list("x"=16, "y"=7)
	reagent_data = list(NUTRIMENT_GOOD = list("salad" = 3))
	reagents_to_add = list(NUTRIMENT_GOOD = 6)
	bitesize = 2

///////////////////////////////////////////
// new old food stuff from bs12
///////////////////////////////////////////
/obj/item/weapon/reagent_containers/food/snacks/dough
	name = "dough"
	desc = "A piece of dough."
	icon = 'icons/obj/food_ingredients.dmi'
	icon_state = "dough"
	bitesize = 2
	center_of_mass = list("x"=16, "y"=13)
	reagent_data = list(NUTRIMENT_GOOD = list("uncooked dough" = 3))
	reagents_to_add = list(NUTRIMENT_GOOD = 3)

// Dough + rolling pin = flat dough
/obj/item/weapon/reagent_containers/food/snacks/dough/attackby(obj/item/weapon/W as obj, mob/user as mob)
	if(istype(W,/obj/item/weapon/material/kitchen/rollingpin))
		new /obj/item/weapon/reagent_containers/food/snacks/sliceable/flatdough(src)
		to_chat(user, "You flatten the dough.")
		qdel(src)

// slicable into 3xdoughslices
/obj/item/weapon/reagent_containers/food/snacks/sliceable/flatdough
	name = "flat dough"
	desc = "A flattened dough."
	icon = 'icons/obj/food_ingredients.dmi'
	icon_state = "flat dough"
	slice_path = /obj/item/weapon/reagent_containers/food/snacks/doughslice
	slices_num = 3
	center_of_mass = list("x"=16, "y"=16)
	reagent_data = list(NUTRIMENT_GOOD = list("uncooked dough" = 3))
	reagents_to_add = list(NUTRIMENT_GOOD = 3)

/obj/item/weapon/reagent_containers/food/snacks/doughslice
	name = "dough slice"
	desc = "A building block of an impressive dish."
	icon = 'icons/obj/food_ingredients.dmi'
	icon_state = "doughslice"
	slice_path = /obj/item/weapon/reagent_containers/food/snacks/spagetti
	slices_num = 1
	bitesize = 2
	center_of_mass = list("x"=17, "y"=19)
	reagent_data = list(NUTRIMENT_GOOD = list("uncooked dough" = 1))
	reagents_to_add = list(NUTRIMENT_GOOD = 1)

/obj/item/weapon/reagent_containers/food/snacks/bun
	name = "bun"
	desc = "A base for any self-respecting burger."
	icon = 'icons/obj/food_ingredients.dmi'
	icon_state = "bun"
	bitesize = 2
	center_of_mass = list("x"=16, "y"=12)
	reagent_data = list(NUTRIMENT_GOOD = list("bun" = 3))
	reagents_to_add = list(NUTRIMENT_GOOD = 4)

/obj/item/weapon/reagent_containers/food/snacks/bun/attackby(obj/item/weapon/W as obj, mob/user as mob)
	var/obj/item/weapon/reagent_containers/food/snacks/result = null
	// Bun + meatball = burger
	if(istype(W,/obj/item/weapon/reagent_containers/food/snacks/meatball))
		result = new /obj/item/weapon/reagent_containers/food/snacks/burger/monkey(src)
		to_chat(user, "You make a burger.")

	// Bun + cutlet = hamburger
	else if(istype(W,/obj/item/weapon/reagent_containers/food/snacks/cutlet))
		result = new /obj/item/weapon/reagent_containers/food/snacks/burger/monkey(src)
		to_chat(user, "You make a burger.")

	//Bun + katsu = chickenfillet
	else if(istype(W,/obj/item/weapon/reagent_containers/food/snacks/chickenkatsu))
		result = new /obj/item/weapon/reagent_containers/food/snacks/chickenfillet(src)
		to_chat(user, "You make a chicken fillet sandwich.")

	// Bun + sausage = hotdog
	else if(istype(W,/obj/item/weapon/reagent_containers/food/snacks/sausage))
		result = new /obj/item/weapon/reagent_containers/food/snacks/hotdog(src)
		to_chat(user, "You make a hotdog.")

	else if(istype(W,/obj/item/weapon/reagent_containers/food/snacks/variable/mob))
		var/obj/item/weapon/reagent_containers/food/snacks/variable/mob/MF = W

		switch (MF.kitchen_tag)
			if ("rodent")
				result = new /obj/item/weapon/reagent_containers/food/snacks/burger/mouse(src)
				to_chat(user, "You make a ratburger!")

	if (result)
		if (W.reagents)
			//Reagents of reuslt objects will be the sum total of both.  Except in special cases where nonfood items are used
			//Eg robot head
			result.reagents.clear_reagents()
			W.reagents.trans_to(result, W.reagents.total_volume)
			reagents.trans_to(result, reagents.total_volume)

		//If the bun was in your hands, the result will be too
		if (loc == user)
			user.drop_from_inventory(src) //This has to be here in order to put the pun in the proper place
			user.put_in_hands(result)

		qdel(W)
		qdel(src)

// Burger + cheese wedge = cheeseburger
/obj/item/weapon/reagent_containers/food/snacks/burger/monkey/attackby(obj/item/weapon/reagent_containers/food/snacks/cheesewedge/W as obj, mob/user as mob)
	if(istype(W))// && !istype(src,/obj/item/weapon/reagent_containers/food/snacks/cheesewedge))
		new /obj/item/weapon/reagent_containers/food/snacks/burger/cheese(src)
		to_chat(user, "You make a cheeseburger.")
		qdel(W)
		qdel(src)
		return
	else
		..()

// Human Burger + cheese wedge = cheeseburger
/obj/item/weapon/reagent_containers/food/snacks/human/burger/attackby(obj/item/weapon/reagent_containers/food/snacks/cheesewedge/W as obj, mob/user as mob)
	if(istype(W))
		new /obj/item/weapon/reagent_containers/food/snacks/burger/cheese(src)
		to_chat(user, "You make a cheeseburger.")
		qdel(W)
		qdel(src)
		return
	else
		..()

/obj/item/weapon/reagent_containers/food/snacks/taco
	name = "taco"
	desc = "Take a bite!"
	icon_state = "taco"
	bitesize = 3
	center_of_mass = list("x"=21, "y"=12)
	reagent_data = list(NUTRIMENT_GOOD = list("taco shell with cheese"))
	reagents_to_add = list(NUTRIMENT_GOOD = 4, "protein" = 3)

/obj/item/weapon/reagent_containers/food/snacks/rawcutlet
	name = "raw cutlet"
	desc = "A thin piece of raw meat."
	icon = 'icons/obj/food_ingredients.dmi'
	icon_state = "rawcutlet"
	bitesize = 1
	center_of_mass = list("x"=17, "y"=20)
	reagents_to_add = list("protein" = 1)

/obj/item/weapon/reagent_containers/food/snacks/rawcutlet/attackby(obj/item/weapon/W as obj, mob/user as mob)
	if(istype(W,/obj/item/weapon/material/knife))
		new /obj/item/weapon/reagent_containers/food/snacks/rawbacon(src)
		new /obj/item/weapon/reagent_containers/food/snacks/rawbacon(src)
		to_chat(user, "You slice the cutlet into thin strips of bacon.")
		qdel(src)
	else
		..()

/obj/item/weapon/reagent_containers/food/snacks/cutlet
	name = "cutlet"
	desc = "A tasty meat slice."
	icon = 'icons/obj/food_ingredients.dmi'
	icon_state = "cutlet"
	bitesize = 2
	center_of_mass = list("x"=17, "y"=20)
	reagents_to_add = list("protein" = 2)

/obj/item/weapon/reagent_containers/food/snacks/rawmeatball
	name = "raw meatball"
	desc = "A raw meatball."
	icon = 'icons/obj/food_ingredients.dmi'
	icon_state = "rawmeatball"
	bitesize = 2
	center_of_mass = list("x"=16, "y"=15)
	reagents_to_add = list("protein" = 2)

/obj/item/weapon/reagent_containers/food/snacks/hotdog
	name = "hotdog"
	desc = "Hot dog, you say? Commoners have resorted to eating dog now, how dreadful."
	icon_state = "hotdog"
	bitesize = 2
	center_of_mass = list("x"=16, "y"=17)
	reagents_to_add = list("protein" = 6)
	
/obj/item/weapon/reagent_containers/food/snacks/flatbread
	name = "flatbread"
	desc = "Bland but filling, like a well-endowed Loamer."
	icon = 'icons/obj/food_ingredients.dmi'
	icon_state = "flatbread"
	bitesize = 2
	center_of_mass = list("x"=16, "y"=16)
	reagent_data = list(NUTRIMENT_GOOD = list("bread" = 3))
	reagents_to_add = list(NUTRIMENT_GOOD = 3)

// potato + knife = raw sticks
/obj/item/weapon/reagent_containers/food/snacks/grown/potato/attackby(obj/item/weapon/W as obj, mob/user as mob)
	if(istype(W,/obj/item/weapon/material/kitchen/utensil/knife))
		new /obj/item/weapon/reagent_containers/food/snacks/rawsticks(src)
		to_chat(user, "You cut the potato.")
		qdel(src)
	else
		..()

/obj/item/weapon/reagent_containers/food/snacks/rawsticks
	name = "raw potato sticks"
	desc = "Raw fries, not very tasty."
	icon = 'icons/obj/food_ingredients.dmi'
	icon_state = "rawsticks"
	bitesize = 2
	center_of_mass = list("x"=16, "y"=12)
	reagent_data = list(NUTRIMENT_GOOD = list("uncooked potatos" = 3))
	reagents_to_add = list(NUTRIMENT_GOOD = 3)

/obj/item/weapon/reagent_containers/food/snacks/liquidfood
	name = "LiquidFood ration"
	desc = "A prepackaged grey slurry of all the essential nutrients for a spacefarer on the go. Should this be crunchy? Now with artificial flavoring!"
	icon_state = "liquidfood"
	trash = /obj/item/trash/liquidfood
	filling_color = "#A8A8A8"
	center_of_mass = list("x"=16, "y"=15)
	bitesize = 4
	reagents_to_add = list(NUTRIMENT_GOOD = 1, "iron" = 3)
	reagent_data = list(NUTRIMENT_GOOD = list("chalk" = 1))

/obj/item/weapon/reagent_containers/food/snacks/liquidfood/Initialize()
	. = ..()
	set_flavor()
	reagents.add_reagent("nutriment", 9, list("[flavor]" = 9))

/obj/item/weapon/reagent_containers/food/snacks/liquidfood/set_flavor()
	flavor = pick("chocolate", "peanut butter cookie", "scrambled eggs", "beef taco", "tofu", "pizza", "spaghetti", "cheesy potatoes", "hamburger", "baked beans", "maple sausage", "chili macaroni", "veggie burger")
	. = ..()

/obj/item/weapon/reagent_containers/food/snacks/tastybread
	name = "bread tube"
	desc = "Bread in a tube. Chewy."
	icon_state = "tastybread"
	trash = /obj/item/trash/tastybread
	filling_color = "#A66829"
	center_of_mass = list("x"=17, "y"=16)
	reagent_data = list(NUTRIMENT_BAD = list("stale bread" = 4))
	reagents_to_add = list(NUTRIMENT_BAD = 6, "sodiumchloride" = 3)

//unathi snacks - sprites by Araskael

/obj/item/weapon/reagent_containers/food/snacks/meatsnack
	name = "mo'gunz meat pie"
	icon_state = "meatsnack"
	desc = "Made from stok meat, packed into a crispy crust."
	trash = /obj/item/trash/meatsnack
	filling_color = "#631212"
	reagent_data = list(NUTRIMENT_BAD = list("pie crust" = 2))
	reagents_to_add = list(NUTRIMENT_BAD = 2, "protein" = 12, "sodiumchloride" = 4)
	bitesize = 5

/obj/item/weapon/reagent_containers/food/snacks/maps
	name = "maps salty ham"
	icon_state = "maps"
	desc = "Various processed meat from Moghes with 600% the amount of recommended daily sodium per can."
	trash = /obj/item/trash/maps
	filling_color = "#631212"
	reagents_to_add = list(NUTRIMENT_BAD = 2, "protein" = 6, "sodiumchloride" = 6)
	bitesize = 3

/obj/item/weapon/reagent_containers/food/snacks/nathisnack
	name = "razi-snack corned beef"
	icon_state = "cbeef"
	desc = "Delicious corned beef and preservatives. Imported from Earth, canned on Ourea."
	trash = /obj/item/trash/nathisnack
	filling_color = "#631212"
	bitesize = 4
	reagents_to_add = list("protein" = 10, "iron" = 3, "sodiumchloride" = 6)

/obj/item/weapon/reagent_containers/food/snacks/pancakes
	name = "pancakes"
	desc = "Pancakes with berries, delicious."
	icon_state = "pancakes"
	trash = /obj/item/trash/plate
	center_of_mass = "x=15;y=11"
	reagent_data = list(NUTRIMENT_GOOD = list("pancake" = 8))
	reagents_to_add = list(NUTRIMENT_GOOD = 8)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/classichotdog
	name = "classic hotdog"
	desc = "Going literal."
	icon_state = "hotcorgi"
	center_of_mass = "x=16;y=17"
	bitesize = 6
	reagents_to_add = list("protein" = 16)

/obj/item/weapon/reagent_containers/food/snacks/lasagna
	name = "lasagna"
	desc = "Favorite of cats."
	icon_state = "lasagna"
	trash = /obj/item/trash/grease
	center_of_mass = list("x"=16, "y"=17)
	reagents_to_add = list(NUTRIMENT_GOOD = 8, "tomatojuice" = 4, "protein" = 12)
	reagent_data = list(NUTRIMENT_GOOD = list("pasta" = 4))
	bitesize = 6

/obj/item/weapon/reagent_containers/food/snacks/donerkebab
	name = "doner kebab"
	desc = "A delicious sandwich-like food from Loam. The meat is typically cooked on a vertical rotisserie."
	icon_state = "doner_kebab"
	reagents_to_add = list(NUTRIMENT_GOOD = 5, "protein" = 4)
	reagent_data = list(NUTRIMENT_GOOD = list("dough" = 4, "cabbage" = 2))
	bitesize = 3

/obj/item/weapon/reagent_containers/food/snacks/sashimi
	name = "carp sashimi"
	desc = "A traditional kobold dish, recreated using space carp."
	icon_state = "sashimi"
	trash = /obj/item/trash/grease
	filling_color = "#FFDEFE"
	center_of_mass = list("x"=17, "y"=13)
	bitesize = 4
	reagents_to_add = list("seafood" = 3, "carpotoxin" = 3)

/obj/item/weapon/reagent_containers/food/snacks/nugget
	name = "chicken nugget"
	icon_state = "nugget_lump"
	bitesize = 3
	reagents_to_add = list("protein" = 4)

/obj/item/weapon/reagent_containers/food/snacks/nugget/Initialize()
	. = ..()
	var/shape = pick("lump", "star", "lizard", "corgi")
	desc = "A chicken nugget vaguely shaped like a [shape]."
	icon_state = "nugget_[shape]"

/obj/item/weapon/reagent_containers/food/snacks/icecreamsandwich
	name = "ice cream sandwich"
	desc = "Portable ice cream in its own packaging."
	icon_state = "icecreamsandwich"
	filling_color = "#343834"
	center_of_mass = list("x"=15, "y"=4)
	reagent_data = list(NUTRIMENT_GOOD = list("ice cream" = 4))
	reagents_to_add = list(NUTRIMENT_GOOD = 4)

/obj/item/weapon/reagent_containers/food/snacks/honeybun
	name = "honey bun"
	desc = "A sticky pastry bun glazed with honey."
	icon_state = "honeybun"
	reagent_data = list(NUTRIMENT_GOOD = list("pastry" = 1))
	reagents_to_add = list(NUTRIMENT_GOOD = 3, "honey" = 3)
	bitesize = 3

// Chip update.
/obj/item/weapon/reagent_containers/food/snacks/tortilla
	name = "tortilla"
	desc = "A thin, flour-based tortilla that can be used in a variety of dishes, or can be served as is."
	icon_state = "tortilla"
	bitesize = 3
	reagent_data = list(NUTRIMENT_GOOD = list("tortilla" = 1))
	center_of_mass = list("x"=16, "y"=16)
	reagents_to_add = list(NUTRIMENT_GOOD = 6)

//chips
/obj/item/weapon/reagent_containers/food/snacks/chip
	name = "chip"
	desc = "A portion sized chip good for dipping."
	icon_state = "chip"
	var/bitten_state = "chip_half"
	bitesize = 1
	center_of_mass = list("x"=16, "y"=16)
	reagent_data = list(NUTRIMENT_GOOD = list("nacho chips" = 1))
	reagents_to_add = list(NUTRIMENT_GOOD = 2)

/obj/item/weapon/reagent_containers/food/snacks/chip/on_consume(mob/M as mob)
	if(reagents && reagents.total_volume)
		icon_state = bitten_state
	. = ..()

/obj/item/weapon/reagent_containers/food/snacks/chip/salsa
	name = "salsa chip"
	desc = "A portion sized chip good for dipping. This one has salsa on it."
	icon_state = "chip_salsa"
	bitten_state = "chip_half"

/obj/item/weapon/reagent_containers/food/snacks/chip/guac
	name = "guac chip"
	desc = "A portion sized chip good for dipping. This one has guac on it."
	icon_state = "chip_guac"
	bitten_state = "chip_half"

/obj/item/weapon/reagent_containers/food/snacks/chip/cheese
	name = "cheese chip"
	desc = "A portion sized chip good for dipping. This one has cheese sauce on it."
	icon_state = "chip_cheese"
	bitten_state = "chip_half"

/obj/item/weapon/reagent_containers/food/snacks/chip/nacho
	name = "nacho chip"
	desc = "A nacho ship stray from a plate of cheesy nachos."
	icon_state = "chip_nacho"
	bitten_state = "chip_half"

/obj/item/weapon/reagent_containers/food/snacks/chip/nacho/salsa
	name = "nacho chip"
	desc = "A nacho ship stray from a plate of cheesy nachos. This one has salsa on it."
	icon_state = "chip_nacho_salsa"
	bitten_state = "chip_half"

/obj/item/weapon/reagent_containers/food/snacks/chip/nacho/guac
	name = "nacho chip"
	desc = "A nacho ship stray from a plate of cheesy nachos. This one has guac on it."
	icon_state = "chip_nacho_guac"
	bitten_state = "chip_half"

/obj/item/weapon/reagent_containers/food/snacks/chip/nacho/cheese
	name = "nacho chip"
	desc = "A nacho ship stray from a plate of cheesy nachos. This one has extra cheese on it."
	icon_state = "chip_nacho_cheese"
	bitten_state = "chip_half"

// chip plates
/obj/item/weapon/reagent_containers/food/snacks/chipplate
	name = "basket of chips"
	desc = "A plate of chips intended for dipping."
	icon_state = "chip_basket"
	trash = /obj/item/trash/chipbasket
	var/vendingobject = /obj/item/weapon/reagent_containers/food/snacks/chip
	reagent_data = list(NUTRIMENT_GOOD = list("tortilla chips" = 10))
	bitesize = 1
	reagents_to_add = list(NUTRIMENT_GOOD = 10)

/obj/item/weapon/reagent_containers/food/snacks/chipplate/attack_hand(mob/user as mob)
	var/obj/item/weapon/reagent_containers/food/snacks/returningitem = new vendingobject(loc)
	returningitem.reagents.clear_reagents()
	reagents.trans_to(returningitem, bitesize)
	returningitem.bitesize = bitesize/2
	user.put_in_hands(returningitem)
	if (reagents && reagents.total_volume)
		to_chat(user, "You take a chip from the plate.")
	else
		to_chat(user, "You take the last chip from the plate.")
		var/obj/waste = new trash(loc)
		if (loc == user)
			user.put_in_hands(waste)
		qdel(src)

/obj/item/weapon/reagent_containers/food/snacks/chipplate/MouseDrop(mob/user) //Dropping the chip onto the user
	if(istype(user) && user == usr)
		user.put_in_active_hand(src)
		src.pickup(user)
		return
	. = ..()

/obj/item/weapon/reagent_containers/food/snacks/chipplate/nachos
	name = "plate of nachos"
	desc = "A very cheesy nacho plate."
	icon_state = "nachos"
	trash = /obj/item/trash/plate
	vendingobject = /obj/item/weapon/reagent_containers/food/snacks/chip/nacho
	reagent_data = list(NUTRIMENT_GOOD = list("tortilla chips" = 10))
	bitesize = 1
	reagents_to_add = list(NUTRIMENT_GOOD = 10)

//dips
/obj/item/weapon/reagent_containers/food/snacks/dip
	name = "queso dip"
	desc = "A simple, cheesy dip consisting of tomatos, cheese, and spices."
	var/nachotrans = /obj/item/weapon/reagent_containers/food/snacks/chip/nacho/cheese
	var/chiptrans = /obj/item/weapon/reagent_containers/food/snacks/chip/cheese
	icon_state = "dip_cheese"
	trash = /obj/item/trash/dipbowl
	bitesize = 1
	reagent_data = list(NUTRIMENT_GOOD = list("queso" = 20))
	center_of_mass = list("x"=16, "y"=16)
	reagents_to_add = list(NUTRIMENT_GOOD = 20)

/obj/item/weapon/reagent_containers/food/snacks/dip/attackby(obj/item/weapon/reagent_containers/food/snacks/item as obj, mob/user as mob)
	. = ..()
	var/obj/item/weapon/reagent_containers/food/snacks/returningitem
	if(istype(item,/obj/item/weapon/reagent_containers/food/snacks/chip/nacho) && item.icon_state == "chip_nacho")
		returningitem = new nachotrans(src)
	else if (istype(item,/obj/item/weapon/reagent_containers/food/snacks/chip) && (item.icon_state == "chip" || item.icon_state == "chip_half"))
		returningitem = new chiptrans(src)
	if(returningitem)
		returningitem.reagents.clear_reagents() //Clear the new chip
		var/memed = 0
		item.reagents.trans_to(returningitem, item.reagents.total_volume) //Old chip to new chip
		if(item.icon_state == "chip_half")
			returningitem.icon_state = "[returningitem.icon_state]_half"
			returningitem.bitesize = Clamp(returningitem.reagents.total_volume,1,10)
		else if(prob(1))
			memed = 1
			to_chat(user, "You scoop up some dip with the chip, but mid-scop, the chip breaks off into the dreadful abyss of dip, never to be seen again...")
			returningitem.icon_state = "[returningitem.icon_state]_half"
			returningitem.bitesize = Clamp(returningitem.reagents.total_volume,1,10)
		else
			returningitem.bitesize = Clamp(returningitem.reagents.total_volume*0.5,1,10)
		qdel(item)
		reagents.trans_to(returningitem, bitesize) //Dip to new chip
		user.put_in_hands(returningitem)

		if (reagents && reagents.total_volume)
			if(!memed)
				to_chat(user, "You scoop up some dip with the chip.")
		else
			if(!memed)
				to_chat(user, "You scoop up the remaining dip with the chip.")
			var/obj/waste = new trash(loc)
			if (loc == user)
				user.put_in_hands(waste)
			qdel(src)

/obj/item/weapon/reagent_containers/food/snacks/dip/salsa
	name = "salsa dip"
	desc = "Traditional Sol chunky salsa dip containing tomatos, peppers, and spices."
	nachotrans = /obj/item/weapon/reagent_containers/food/snacks/chip/nacho/salsa
	chiptrans = /obj/item/weapon/reagent_containers/food/snacks/chip/salsa
	icon_state = "dip_salsa"
	reagent_data = list(NUTRIMENT_GOOD = list("salsa" = 20))
	reagents_to_add = list(NUTRIMENT_GOOD = 20)

/obj/item/weapon/reagent_containers/food/snacks/dip/guac
	name = "guac dip"
	desc = "A recreation of the ancient Sol 'Guacamole' dip using tofu, limes, and spices. This recreation obviously leaves out mole meat."
	nachotrans = /obj/item/weapon/reagent_containers/food/snacks/chip/nacho/guac
	chiptrans = /obj/item/weapon/reagent_containers/food/snacks/chip/guac
	icon_state = "dip_guac"
	reagent_data = list(NUTRIMENT_GOOD = list("guacmole" = 20))
	reagents_to_add = list(NUTRIMENT_GOOD = 20)

//burritos
/obj/item/weapon/reagent_containers/food/snacks/burrito
	name = "meat burrito"
	desc = "Meat wrapped in a flour tortilla. It's a burrito by definition."
	icon_state = "burrito"
	bitesize = 4
	center_of_mass = list("x"=16, "y"=16)
	reagent_data = list(NUTRIMENT_GOOD = list("tortilla" = 6))
	reagents_to_add = list(NUTRIMENT_GOOD = 6, "protein" = 4)

/obj/item/weapon/reagent_containers/food/snacks/burrito_vegan
	name = "vegan burrito"
	desc = "Tofu wrapped in a flour tortilla. Those seen with this food object are Valid."
	icon_state = "burrito_vegan"
	bitesize = 4
	center_of_mass = list("x"=16, "y"=16)
	reagent_data = list(NUTRIMENT_GOOD = list("tortilla" = 6))
	reagents_to_add = list(NUTRIMENT_GOOD = 6, "tofu" = 6)

/obj/item/weapon/reagent_containers/food/snacks/burrito_spicy
	name = "spicy meat burrito"
	desc = "Meat and chilis wrapped in a flour tortilla. Better know where the washroom is."
	icon_state = "burrito_spicy"
	bitesize = 4
	center_of_mass = list("x"=16, "y"=16)
	reagent_data = list(NUTRIMENT_GOOD = list("tortilla" = 6))
	reagents_to_add = list(NUTRIMENT_GOOD = 6, "protein" = 6, "capsaicin" = 6) // this is the devil's work

/obj/item/weapon/reagent_containers/food/snacks/burrito_cheese
	name = "meat cheese burrito"
	desc = "Meat and melted cheese wrapped in a flour tortilla."
	icon_state = "burrito_cheese"
	bitesize = 4
	center_of_mass = list("x"=16, "y"=16)
	reagent_data = list(NUTRIMENT_GOOD = list("tortilla" = 6))
	reagents_to_add = list(NUTRIMENT_GOOD = 6, "protein" = 6)

/obj/item/weapon/reagent_containers/food/snacks/burrito_cheese_spicy
	name = "spicy cheese meat burrito"
	desc = "Meat, melted cheese, and chilis wrapped in a flour tortilla. Medical is north of the washrooms."
	icon_state = "burrito_cheese_spicy"
	bitesize = 4
	center_of_mass = list("x"=16, "y"=16)
	reagent_data = list(NUTRIMENT_GOOD = list("tortilla" = 6))
	reagents_to_add = list(NUTRIMENT_GOOD = 6, "protein" = 6)

/obj/item/weapon/reagent_containers/food/snacks/burrito_hell
	name = "el diablo"
	desc = "Meat and an insane amount of chilis packed in a flour tortilla. The chaplain's office is west of the kitchen."
	icon_state = "burrito_hell"
	bitesize = 4
	center_of_mass = list("x"=16, "y"=16)
	reagent_data = list(NUTRIMENT_GOOD = list("hellfire" = 6))
	reagents_to_add = list(NUTRIMENT_GOOD = 24, "protein" = 9, "condensedcapsaicin" = 20)// 10 Chilis is a lot.

/obj/item/weapon/reagent_containers/food/snacks/breakfast_wrap
	name = "breakfast wrap"
	desc = "Bacon, eggs, cheese, and tortilla grilled to perfection."
	icon_state = "breakfast_wrap"
	bitesize = 4
	center_of_mass = list("x"=16, "y"=16)
	reagent_data = list(NUTRIMENT_GOOD = list("tortilla" = 6))
	reagents_to_add = list(NUTRIMENT_GOOD = 6)

/obj/item/weapon/reagent_containers/food/snacks/burrito_mystery
	name = "mystery meat burrito"
	desc = "The mystery is, why aren't you BSAing it?"
	icon_state = "burrito_mystery"
	bitesize = 5
	center_of_mass = list("x"=16, "y"=16)
	reagent_data = list(NUTRIMENT_GOOD = list("regret" = 6))
	reagents_to_add = list(NUTRIMENT_GOOD = 6)

// Ligger food and also bacon
/obj/item/weapon/reagent_containers/food/snacks/rawbacon
	name = "raw bacon"
	desc = "A very thin piece of raw meat, cut from beef."
	icon = 'icons/obj/food_ingredients.dmi'
	icon_state = "rawbacon"
	bitesize = 1
	center_of_mass = list("x"=16, "y"=16)
	reagents_to_add = list("protein" = 1/3)

/obj/item/weapon/reagent_containers/food/snacks/bacon
	name = "bacon"
	desc = "A tasty meat slice. You don't see any pigs on this station, do you?"
	icon = 'icons/obj/food_ingredients.dmi'
	icon_state = "bacon"
	bitesize = 2
	center_of_mass = list("x"=16, "y"=16)
	reagents_to_add = list("protein" = 1/3, "triglyceride" = 1)

/obj/item/weapon/reagent_containers/food/snacks/bacon/microwave
	name = "microwaved bacon"
	desc = "A tasty meat slice. You don't see any pigs on this station, do you?"
	icon = 'icons/obj/food_ingredients.dmi'
	icon_state = "bacon"
	bitesize = 2
	center_of_mass = list("x"=16, "y"=16)

/obj/item/weapon/reagent_containers/food/snacks/bacon/oven
	name = "oven-cooked bacon"
	desc = "A tasty meat slice. You don't see any pigs on this station, do you?"
	icon = 'icons/obj/food_ingredients.dmi'
	icon_state = "bacon"
	bitesize = 2
	center_of_mass = list("x"=16, "y"=16)

/obj/item/weapon/reagent_containers/food/snacks/chilied_eggs
	name = "chilied eggs"
	desc = "Three deviled eggs floating in a bowl of meat chili. A popular lunchtime meal for Unathi in Ouerea."
	icon_state = "chilied_eggs"
	trash = /obj/item/trash/snack_bowl
	reagents_to_add = list("egg" = 6, "protein" = 2)

/obj/item/weapon/reagent_containers/food/snacks/hatchling_suprise
	name = "hatchling suprise"
	desc = "A poached egg on top of three slices of bacon. A typical breakfast for hungry Unathi children."
	icon_state = "hatchling_suprise"
	trash = /obj/item/trash/snack_bowl
	reagents_to_add = list("egg" = 2, "protein" = 4)

/obj/item/weapon/reagent_containers/food/snacks/red_sun_special
	name = "red sun special"
	desc = "One lousey piece of sausage sitting on melted cheese curds. A cheap meal for Kobold servants."
	icon_state = "red_sun_special"
	trash = /obj/item/trash/plate
	reagents_to_add = list("protein" = 2, "cheese" = 2)

/obj/item/weapon/reagent_containers/food/snacks/riztizkzi_sea
	name = "moghresian sea delight"
	desc = "Three raw eggs floating in a sea of blood. An authentic replication of an ancient dragon delicacy. It's... not kobold blood, is it?"
	icon_state = "riztizkzi_sea"
	trash = /obj/item/trash/snack_bowl
	reagents_to_add = list("egg" = 4, "iron" = 4, "protein" = 1)

/obj/item/weapon/reagent_containers/food/snacks/father_breakfast
	name = "breakfast of champions"
	desc = "A sausage and an omelette on top of a grilled steak."
	icon_state = "father_breakfast"
	trash = /obj/item/trash/plate
	reagents_to_add = list("egg" = 4, "protein" = 6)

/obj/item/weapon/reagent_containers/food/snacks/stuffed_meatball
	name = "stuffed meatball" //YES
	desc = "A meatball loaded with cheese."
	icon_state = "stuffed_meatball"
	reagents_to_add = list("cheese" = 2, "protein" = 4)

/obj/item/weapon/reagent_containers/food/snacks/egg_pancake
	name = "meat pancake"
	desc = "An omelette baked on top of a giant meat patty. This monstrousity is typically shared between four people during a dinnertime meal."
	icon_state = "egg_pancake"
	trash = /obj/item/trash/tray
	reagents_to_add = list("egg" = 2, "protein" = 6)

/obj/item/weapon/reagent_containers/food/snacks/sliceable/grilled_carp
	name = "korlaaskak"
	desc = "A well-dressed carp, seared to perfection and adorned with herbs and spices. Can be sliced into proper serving sizes."
	icon_state = "grilled_carp"
	slice_path = /obj/item/weapon/reagent_containers/food/snacks/grilled_carp_slice
	slices_num = 6
	trash = /obj/item/trash/snacktray
	reagents_to_add = list("seafood" = 12, "spacespice" = 6)

/obj/item/weapon/reagent_containers/food/snacks/grilled_carp_slice
	name = "korlaaskak slice"
	desc = "A well-dressed fillet of carp, seared to perfection and adorned with herbs and spices."
	icon_state = "grilled_carp_slice"
	trash = /obj/item/trash/plate
	reagents_to_add = list("seafood" = 2, "spacespice" = 1)

/obj/item/weapon/reagent_containers/food/snacks/sliceable/sushi_roll
	name = "ouere carp log"
	desc = "A giant carp roll wrapped in special grass that combines unathi and human cooking techniques. Can be sliced into proper serving sizes."
	icon_state = "sushi_roll"
	slice_path = /obj/item/weapon/reagent_containers/food/snacks/sushi_serve
	slices_num = 3
	reagents_to_add = list("seafood" = 6)

/obj/item/weapon/reagent_containers/food/snacks/sushi_serve
	name = "ouere carp cake"
	desc = "A serving of carp roll wrapped in special grass that combines unathi and human cooking techniques."
	icon_state = "sushi_serve"
	reagents_to_add = list("seafood" = 6)

/obj/item/weapon/reagent_containers/food/snacks/spreads
	name = "nutri-spread"
	desc = "A stick of plant-based nutriments in a semi-solid form. I can't believe it's not margarine!"
	icon_state = "marge"
	bitesize = 2
	center_of_mass = list("x"=16, "y"=16)
	reagent_data = list(NUTRIMENT_BAD = list("margarine" = 1))
	reagents_to_add = list(NUTRIMENT_BAD = 20)

/obj/item/weapon/reagent_containers/food/snacks/spreads/butter
	name = "butter"
	desc = "A stick of pure butterfat made from milk products."
	icon_state = "marge"
	bitesize = 2
	center_of_mass = list("x"=16, "y"=16)
	reagent_data = list(NUTRIMENT_BAD = list("butter" = 1))
	reagents_to_add = list(NUTRIMENT_BAD = 20, "triglyceride" = 20, "sodiumchloride" = 1)

/obj/item/weapon/reagent_containers/food/snacks/bacon_stick
	name = "eggpop"
	desc = "A bacon wrapped boiled egg, conviently skewered on a wooden stick."
	icon_state = "bacon_stick"
	reagents_to_add = list("protein" = 3, "egg" = 1)

/obj/item/weapon/reagent_containers/food/snacks/cheese_cracker
	name = "supreme cheese toast"
	desc = "A piece of toast lathered with butter, cheese, spices, and herbs. An Elvish delicacy. Or something."
	icon_state = "cheese_cracker"
	reagent_data = list(NUTRIMENT_GOOD = list("toast" = 8, "butter" = 1))
	reagents_to_add = list(NUTRIMENT_GOOD = 9, "cheese" = 4, "spacespice" = 2)

/obj/item/weapon/reagent_containers/food/snacks/bacon_and_eggs
	name = "bacon and eggs"
	desc = "A piece of bacon and two fried eggs."
	icon_state = "bacon_and_eggs"
	trash = /obj/item/trash/plate
	reagents_to_add = list("protein" = 3, "egg" = 1)

/obj/item/weapon/reagent_containers/food/snacks/sweet_and_sour
	name = "sweet and sour pork"
	desc = "A traditional ancient dragon recipe with a few liberties taken with meat selection."
	icon_state = "sweet_and_sour"
	reagent_data = list(NUTRIMENT_GOOD = list("sweet and sour sauce" = 6))
	reagents_to_add = list(NUTRIMENT_GOOD = 6, "protein" = 3)
	trash = /obj/item/trash/plate

/obj/item/weapon/reagent_containers/food/snacks/corn_dog
	name = "corn dog"
	desc = "A cornbread covered sausage deepfried in oil."
	icon_state = "corndog"
	reagent_data = list(NUTRIMENT_BAD = list("corn batter" = 4))
	reagents_to_add = list(NUTRIMENT_BAD = 4, "protein" = 3)

/obj/item/weapon/reagent_containers/food/snacks/truffle
	name = "chocolate truffle"
	desc = "Rich bite-sized chocolate."
	icon_state = "truffle"
	reagents_to_add = list(NUTRIMENT_GOOD = 1, "coco" = 6)
	bitesize = 4

/obj/item/weapon/reagent_containers/food/snacks/truffle/random
	name = "mystery chocolate truffle"
	desc = "Rich bite-sized chocolate with a mystery filling!"

/obj/item/weapon/reagent_containers/food/snacks/truffle/random/Initialize()
	. = ..()
	var/reagent_string = pick(list("cream","cherryjelly","mint","frostoil","capsaicin","cream","coffee","milkshake"))
	reagents.add_reagent(reagent_string, 4)

/obj/item/weapon/reagent_containers/food/snacks/bacon_flatbread
	name = "bacon cheese flatbread"
	desc = "Not a pizza."
	icon_state = "bacon_pizza"
	reagent_data = list(NUTRIMENT_GOOD = list("flatbread" = 5))
	reagents_to_add = list(NUTRIMENT_GOOD = 5, "protein" = 5)

/obj/item/weapon/reagent_containers/food/snacks/meat_pocket
	name = "meat pocket"
	desc = "Meat and cheese stuffed in a flatbread pocket, grilled to perfection."
	icon_state = "meat_pocket"
	reagent_data = list(NUTRIMENT_GOOD = list("flatbread" = 3))
	reagents_to_add = list(NUTRIMENT_GOOD = 3, "protein" = 3)

/obj/item/weapon/reagent_containers/food/snacks/fish_taco
	name = "carp taco"
	desc = "A questionably cooked fish taco decorated with herbs, spices, and special sauce."
	icon_state = "fish_taco"
	reagent_data = list(NUTRIMENT_GOOD = list("taco seasoning" = 3))
	reagents_to_add = list(NUTRIMENT_GOOD = 3, "seafood" = 3, "spacespice" = 1)

/obj/item/weapon/reagent_containers/food/snacks/nt_muffin
	name = "\improper Muffin"
	desc = "A Loamian corporation-sponsered biscuit with egg, cheese, and sausage."
	icon_state = "nt_muffin"
	reagent_data = list(NUTRIMENT_GOOD = list("biscuit" = 3))
	reagents_to_add = list(NUTRIMENT_GOOD = 3, "protein" = 5)

/obj/item/weapon/reagent_containers/food/snacks/pineapple_ring
	name = "pineapple ring"
	desc = "What the hell is this?"
	icon_state = "pineapple_ring"
	reagents_to_add = list("sugar" = 2, "pineapplejuice" = 3)

/obj/item/weapon/reagent_containers/food/snacks/sliceable/pizza/pineapple
	name = "ham & pineapple pizza"
	desc = "One of the most debated pizzas in existence."
	icon_state = "pineapple_pizza"
	slice_path = /obj/item/weapon/reagent_containers/food/snacks/pineappleslice
	slices_num = 6
	center_of_mass = list("x"=16, "y"=11)
	reagent_data = list(NUTRIMENT_GOOD = list("pizza crust" = 10, "ham" = 10))
	reagents_to_add = list(NUTRIMENT_GOOD = 30, "protein" = 4, "cheese" = 5, "tomatojuice" = 6)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/pineappleslice
	name = "ham & pineapple pizza slice"
	desc = "A slice of contraband."
	icon_state = "pineapple_pizza_slice"
	filling_color = "#BAA14C"
	bitesize = 2
	center_of_mass = list("x"=18, "y"=13)

/obj/item/weapon/reagent_containers/food/snacks/pineappleslice/filled
	reagent_data = list(NUTRIMENT_GOOD = list("pizza crust" = 5))
	reagents_to_add = list(NUTRIMENT_GOOD = 6, "pineapplejuice" = 2)

/obj/item/weapon/reagent_containers/food/snacks/burger/bacon
	name = "bacon burger"
	desc = "The cornerstone of every nutritious breakfast, now with bacon!"
	icon_state = "hburger"
	filling_color = "#D63C3C"
	center_of_mass = list("x"=16, "y"=11)
	reagent_data = list(NUTRIMENT_GOOD = list("bun" = 2))
	reagents_to_add = list(NUTRIMENT_GOOD = 3, "protein" = 4)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/blt
	name = "BLT"
	desc = "Bacon, lettuce, tomatoes. The perfect lunch."
	icon_state = "blt"
	filling_color = "#D63C3C"
	center_of_mass = list("x"=16, "y"=16)
	reagent_data = list(NUTRIMENT_GOOD = list("bread" = 4))
	reagents_to_add = list(NUTRIMENT_GOOD = 4, "protein" = 4)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/onionrings
	name = "onion rings"
	desc = "Like circular fries but better."
	icon_state = "onionrings"
	trash = /obj/item/trash/plate
	filling_color = "#eddd00"
	center_of_mass = "x=16;y=11"
	reagent_data = list(NUTRIMENT_GOOD = list("fried onions" = 5))
	reagents_to_add = list(NUTRIMENT_GOOD = 5)
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/berrymuffin
	name = "berry muffin"
	desc = "A delicious and spongy little cake, with berries."
	icon_state = "berrymuffin"
	filling_color = "#E0CF9B"
	center_of_mass = list("x"=17, "y"=4)
	reagents_to_add = list(NUTRIMENT_GOOD = 5)
	reagent_data = list(NUTRIMENT_GOOD = list("sweetness" = 1, "muffin" = 2, "berries" = 2))
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/soup/onion
	name = "onion soup"
	desc = "A soup with layers."
	icon_state = "onionsoup"
	trash = /obj/item/trash/snack_bowl
	filling_color = "#E0C367"
	center_of_mass = list("x"=16, "y"=7)
	reagents_to_add = list(NUTRIMENT_GOOD = 5)
	reagent_data = list(NUTRIMENT_GOOD = list("onion" = 2, "soup" = 2))
	bitesize = 3

/obj/item/weapon/reagent_containers/food/snacks/porkbowl
	name = "pork bowl"
	desc = "A bowl of fried rice with cuts of meat."
	icon_state = "porkbowl"
	trash = /obj/item/trash/snack_bowl
	filling_color = "#FFFBDB"
	bitesize = 2
	reagents_to_add = list("rice" = 6, "protein" = 4)

/obj/item/weapon/reagent_containers/food/snacks/mashedpotato
	name = "mashed potato"
	desc = "Pillowy mounds of mashed potato."
	icon_state = "mashedpotato"
	trash = /obj/item/trash/plate
	filling_color = "#EDDD00"
	center_of_mass = list("x"=16, "y"=11)
	reagents_to_add = list(NUTRIMENT_GOOD = 4)
	reagent_data = list(NUTRIMENT_GOOD = list("mashed potatoes" = 4))
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/croissant
	name = "croissant"
	desc = "True french cuisine."
	filling_color = "#E3D796"
	icon_state = "croissant"
	reagents_to_add = list(NUTRIMENT_GOOD = 4)
	reagent_data = list(NUTRIMENT_GOOD = list("french bread" = 4))
	bitesize = 2

/obj/item/weapon/reagent_containers/food/snacks/crabmeat
	name = "crab legs"
	desc = "... Coffee? Is that you?"
	icon_state = "crabmeat"
	bitesize = 1
	reagents_to_add = list("seafood" = 2)

/obj/item/weapon/reagent_containers/food/snacks/crab_legs
	name = "steamed crab legs"
	desc = "Crab legs steamed and buttered to perfection. One day when the boss gets hungry..."
	icon_state = "crablegs"
	reagents_to_add = list(NUTRIMENT_GOOD = 2, "seafood" = 6, "sodiumchloride" = 1)
	reagent_data = list(NUTRIMENT_GOOD = list("savory butter" = 2))
	bitesize = 2
	trash = /obj/item/trash/plate

/obj/item/weapon/reagent_containers/food/snacks/banana_split
	name = "banana split"
	desc = "A dessert made with icecream and a banana."
	icon_state = "banana_split"
	reagents_to_add = list(NUTRIMENT_GOOD = 5, "banana" = 3)
	reagent_data = list(NUTRIMENT_GOOD = list("icecream" = 2))
	bitesize = 2
	trash = /obj/item/trash/snack_bowl

/obj/item/weapon/reagent_containers/food/snacks/tuna
	name = "\improper Tuna Snax"
	desc = "A packaged fish snack, guaranteed to 'do not contain space carp.' Whatever that means."
	icon_state = "tuna"
	filling_color = "#FFDEFE"
	center_of_mass = list("x"=17, "y"=13)
	bitesize = 2
	trash = /obj/item/trash/tuna
	reagents_to_add = list("seafood" = 4)

/obj/item/weapon/reagent_containers/food/snacks/cb01
	name = "tau ceti bar"
	desc = "A dark chocolate caramel and nougat bar made famous in Biesel."
	filling_color = "#552200"
	icon_state = "cb01"
	reagents_to_add = list(NUTRIMENT_BAD = 4, "sugar" = 1)
	reagent_data = list(NUTRIMENT_BAD = list("chocolate" = 2, "nougat" = 1, "caramel" = 1))
	bitesize = 2
	w_class = 1

/obj/item/weapon/reagent_containers/food/snacks/cb02
	name = "hundred thousand credit bar"
	desc = "An ironically cheap puffed rice caramel milk chocolate bar."
	filling_color = "#552200"
	icon_state = "cb02"
	reagents_to_add = list(NUTRIMENT_BAD = 4, "sugar" = 1)
	reagent_data = list(NUTRIMENT_BAD = list("chocolate" = 2, "caramel" = 1, "puffed rice" = 1))
	bitesize = 2
	w_class = 1

/obj/item/weapon/reagent_containers/food/snacks/cb03
	name = "spacewind bar"
	desc = "Bubbly milk chocolate."
	filling_color = "#552200"
	icon_state = "cb03"
	reagents_to_add = list(NUTRIMENT_BAD = 4, "sugar" = 1)
	reagent_data = list(NUTRIMENT_BAD = list("chocolate" = 4))
	bitesize = 2
	w_class = 1

/obj/item/weapon/reagent_containers/food/snacks/cb04
	name = "crunchy crisp"
	desc = "An almond flake bar covered in milk chocolate."
	filling_color = "#552200"
	icon_state = "cb04"
	reagents_to_add = list(NUTRIMENT_BAD = 4, "sugar" = 1)
	reagent_data = list(NUTRIMENT_BAD = list("chocolate" = 3, "almonds" = 1))
	bitesize = 2
	w_class = 1

/obj/item/weapon/reagent_containers/food/snacks/cb05
	name = "hearsay bar"
	desc = "A cheap milk chocolate bar loaded with sugar."
	filling_color = "#552200"
	icon_state = "cb05"
	reagents_to_add = list(NUTRIMENT_BAD = 3, "sugar" = 3)
	reagent_data = list(NUTRIMENT_BAD = list("chocolate" = 2, "vomit" = 1))
	bitesize = 3
	w_class = 1

/obj/item/weapon/reagent_containers/food/snacks/cb06
	name = "latte crunch"
	desc = "A large latte flavored wafer chocolate bar."
	filling_color = "#552200"
	icon_state = "cb06"
	reagents_to_add = list(NUTRIMENT_BAD = 4, "sugar" = 1)
	reagent_data = list(NUTRIMENT_BAD = list("chocolate" = 2, "coffee" = 1, "vanilla wafer" = 1))
	bitesize = 3
	w_class = 1

/obj/item/weapon/reagent_containers/food/snacks/cb07
	name = "martian bar"
	desc = "Dark chocolate with a nougat and caramel center. Known as the first chocolate bar grown and produced on Mars."
	filling_color = "#552200"
	icon_state = "cb07"
	reagents_to_add = list(NUTRIMENT_BAD = 4, "sugar" = 1)
	reagent_data = list(NUTRIMENT_BAD = list("chocolate" = 2, "caramel" = 1, "nougat" = 1))
	bitesize = 3
	w_class = 1

/obj/item/weapon/reagent_containers/food/snacks/cb08
	name = "crisp bar"
	desc = "A large puffed rice milk chocolate bar."
	filling_color = "#552200"
	icon_state = "cb08"
	reagents_to_add = list(NUTRIMENT_BAD = 3, "sugar" = 2)
	reagent_data = list(NUTRIMENT_BAD = list("chocolate" = 2, "puffed rice" = 1))
	bitesize = 3
	w_class = 1

/obj/item/weapon/reagent_containers/food/snacks/cb09
	name = "oh daddy bar"
	desc = "A massive cluster of peanuts covered in caramel and chocolate."
	filling_color = "#552200"
	icon_state = "cb09"
	reagents_to_add = list(NUTRIMENT_BAD = 6, "sugar" = 1)
	reagent_data = list(NUTRIMENT_BAD = list("chocolate" = 3, "caramel" = 1, "peanuts" = 2))
	bitesize = 3
	w_class = 1

/obj/item/weapon/reagent_containers/food/snacks/cb10
	name = "laughter bar"
	desc = "Nuts, nougat, peanuts, and caramel covered in chocolate."
	filling_color = "#552200"
	icon_state = "cb10"
	reagents_to_add = list(NUTRIMENT_BAD = 5, "sugar" = 1)
	reagent_data = list(NUTRIMENT_BAD = list("chocolate" = 2, "caramel" = 1, "peanuts" = 1, "nougat" = 1))
	bitesize = 3
	w_class = 1

/obj/item/weapon/reagent_containers/food/snacks/eggplantparm
    name = "eggplant parmigiana"
    desc = "The only good recipe for eggplant."
    icon_state = "eggplantparm"
    trash = /obj/item/trash/plate
    filling_color = "#4D2F5E"
    center_of_mass = list("x"=16, "y"=11)
    reagents_to_add = list(NUTRIMENT_GOOD = 6, "cheese" = 5)
    reagent_data = list(NUTRIMENT_GOOD = list("eggplant" = 3))
    bitesize = 2


#undef NUTRIMENT_GOOD
#undef NUTRIMENT_BAD
