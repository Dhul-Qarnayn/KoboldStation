/obj/item/weapon/trap
	name = "mechanical trap"
	throw_speed = 2
	throw_range = 1
	gender = PLURAL
	icon = 'icons/obj/items.dmi'
	var/icon_base = "beartrap"
	icon_state = "beartrap0"
	randpixel = 0
	center_of_mass = null
	desc = "A mechanically activated leg trap. Low-tech, but reliable. Looks like it could really hurt if you set it off."
	throwforce = 0
	w_class = 3
	origin_tech = list(TECH_ENGINEERING = 2)
	matter = list(DEFAULT_WALL_MATERIAL = 18750)
	var/deployed = FALSE
	var/time_to_escape = 60

/obj/item/weapon/trap/proc/can_use(mob/user)
	return (user.IsAdvancedToolUser() && !issilicon(user) && !user.stat && !user.restrained())

/obj/item/weapon/trap/attack_self(mob/user)
	..()
	if(!deployed && can_use(user))
		if(deploy(user))
			user.drop_from_inventory(src)
			anchored = TRUE

/obj/item/weapon/trap/proc/deploy(mob/user)
	user.visible_message(
		"<span class='danger'>[user] starts to deploy \the [src].</span>",
		"<span class='danger'>You begin deploying \the [src]!</span>",
		"You hear the slow creaking of a spring."
		)

	if (do_after(user, 5 SECONDS))
		user.visible_message(
			"<span class='danger'>[user] deploys \the [src].</span>",
			"<span class='danger'>You deploy \the [src]!</span>",
			"You hear a latch click loudly."
			)

		deployed = TRUE
		update_icon()
		return TRUE
	return FALSE

/obj/item/weapon/trap/user_unbuckle_mob(mob/user)
	if(buckled_mob && can_use(user))
		user.visible_message(
			"<span class='notice'>\The [user] begins freeing \the [buckled_mob] from \the [src].</span>",
			"<span class='notice'>You carefully begin to free \the [buckled_mob] from \the [src].</span>",
			"<span class='notice'>You hear metal creaking.</span>"
			)
		if(do_after(user, time_to_escape))
			user.visible_message("<span class='notice'>\The [buckled_mob] is freed from \the [src] by \the [user].</span>")
			unbuckle_mob()
			anchored = FALSE

/obj/item/weapon/trap/attack_hand(mob/user)
	if(buckled_mob && can_use(user))
		user.visible_message(
			"<span class='notice'>[user] begins freeing [buckled_mob] from \the [src].</span>",
			"<span class='notice'>You carefully begin to free [buckled_mob] from \the [src].</span>"
			)
		if(do_after(user, time_to_escape))
			user.visible_message("<span class='notice'>[buckled_mob] is freed from \the [src] by [user].</span>")
			unbuckle_mob()
			anchored = FALSE
	else if(deployed && can_use(user))
		user.visible_message(
			"<span class='danger'>[user] starts to disarm \the [src].</span>",
			"<span class='notice'>You begin disarming \the [src]!</span>",
			"You hear a latch click followed by the slow creaking of a spring."
			)
		if(do_after(user, 6 SECONDS))
			user.visible_message(
				"<span class='danger'>[user] disarms \the [src].</span>",
				"<span class='notice'>You disarm \the [src]!</span>"
				)
			deployed = FALSE
			anchored = FALSE
			update_icon()
	else
		..()

/obj/item/weapon/trap/proc/attack_mob(mob/living/L)

	var/target_zone
	if(L.lying)
		target_zone = ran_zone()
	else
		target_zone = pick("l_foot", "r_foot", "l_leg", "r_leg")

	//armour
	var/blocked = L.run_armor_check(target_zone, "melee")
	if(blocked >= 100)
		return

	var/success = L.apply_damage(30, BRUTE, target_zone, blocked, src)
	if(!success)
		return 0

	//trap the victim in place
	set_dir(L.dir)
	can_buckle = TRUE
	buckle_mob(L)
	to_chat(L, "<span class='danger'>The steel jaws of \the [src] bite into you, trapping you in place!</span>")
	deployed = FALSE
	can_buckle = initial(can_buckle)
	playsound(src, 'sound/weapons/beartrap_shut.ogg', 100, 1)//Really loud snapping sound

	if (istype(L, /mob/living/simple_animal/hostile/bear))
		var/mob/living/simple_animal/hostile/bear/bear = L
		bear.anger += 15//traps make bears really angry
		bear.instant_aggro()

/obj/item/weapon/trap/Crossed(atom/movable/AM)
	if(deployed && isliving(AM))
		var/mob/living/L = AM
		L.visible_message(
			"<span class='danger'>[L] steps on \the [src].</span>",
			"<span class='danger'>You step on \the [src]!</span>",
			"<b>You hear a loud metallic snap!</b>"
			)
		attack_mob(L)
		if(!buckled_mob)
			anchored = FALSE
		deployed = FALSE
		update_icon()
	..()


/obj/item/weapon/trap/update_icon()
	icon_state = "[icon_base][deployed]"

/obj/item/weapon/trap/animal
	name = "small trap"
	throw_speed = 2
	throw_range = 1
	gender = PLURAL
	icon = 'icons/obj/items.dmi'
	icon_base = "small"
	icon_state = "small0"
	desc = "A small mechanical trap that's used to catch small animals like rats, lizards, and chicks."
	throwforce = 2
	force = 1
	w_class = 2
	origin_tech = list(TECH_ENGINEERING = 1)
	matter = list(DEFAULT_WALL_MATERIAL = 1750)
	deployed = FALSE
	time_to_escape = 3 // Minutes
	can_buckle = TRUE
	var/breakout = FALSE
	var/last_shake = 0
	var/list/allowed_mobs = list(/mob/living/simple_animal/rat, /mob/living/simple_animal/chick, /mob/living/simple_animal/lizard)
	var/release_time = 0
	var/list/resources = list(rods = 6)
	var/spider = TRUE
	health = 100
	var/datum/weakref/captured = null

/obj/item/weapon/trap/animal/MouseDrop_T(mob/living/M, mob/living/user)
	if(!istype(M))
		return

	if(!captured)
		if(!is_type_in_list(M, allowed_mobs))
			to_chat(user, span("warning", "[M] won't fit in there!"))
		else if(do_after(user, 5 SECONDS))
			capture(M)
	else
		to_chat(user, "<span class='warning'>\The [src] is already full!</span>")

/obj/item/weapon/trap/animal/update_icon()
	icon = initial(icon)
	icon_state = "[icon_base][deployed]"

/obj/item/weapon/trap/animal/examine(mob/user)
	..()
	if(captured)
		var/datum/L = captured.resolve()
		if (L)
			to_chat(user, "<span class='warning'>[L] is trapped inside!</span>")
			return
	else if(deployed)
		to_chat(user, span("warning", "It's set up and ready to capture something."))
	else
		to_chat(user, "<span class='notice'>\The [src] is empty and un-deployed.</span>")

/obj/item/weapon/trap/animal/Crossed(atom/movable/AM)
	if(!deployed || !anchored)
		return

	if(captured) // just in case but this shouldn't happen
		return

	capture(AM)

/obj/item/weapon/trap/animal/proc/capture(var/mob/AM, var/msg = 1)
	if(isliving(AM) && is_type_in_list(AM, allowed_mobs))
		var/mob/living/L = AM
		if(msg)
			L.visible_message(
				"<span class='danger'>[L] enters \the [src], and it snaps shut with a clatter!</span>",
				"<span class='danger'>You enter \the [src], and it snaps shut with a clatter!</span>",
				"<b>You hear a loud metallic snap!</b>"
				)
		if(AM.loc != loc)
			AM.forceMove(loc)
		captured = WEAKREF(L)
		buckle_mob(L)
		playsound(src, 'sound/weapons/beartrap_shut.ogg', 100, 1)
		deployed = FALSE
		src.animate_shake()
		update_icon()

/obj/item/weapon/trap/animal/proc/req_breakout()
	if(deployed || !captured)
		return 0 // Trap-door is open, no one is captured.
	if(breakout)
		return -1 //Already breaking out.
	return 1

/obj/item/weapon/trap/animal/proc/breakout_callback(var/mob/living/escapee)
	if (QDELETED(escapee))
		return FALSE

	if ((world.time - last_shake) > 5 SECONDS)
		playsound(loc, "sound/effects/grillehit.ogg", 100, 1)
		animate_shake()
		last_shake = world.time

	return TRUE

// If we are stuck, and need to get out
/obj/item/weapon/trap/animal/user_unbuckle_mob(var/mob/living/escapee)
	if (req_breakout() < 1)
		return

	escapee.next_move = world.time + 100
	escapee.last_special = world.time + 100
	to_chat(escapee, "<span class='warning'>You begin to shake and bump the lock of \the [src]. (this will take about [time_to_escape] minutes).</span>")
	visible_message("<span class='danger'>\The [src] begins to shake violently! Something is attempting to escape it!</span>")

	var/time = 360 * time_to_escape * 2
	breakout = TRUE

	if (!do_after(escapee, time, act_target = src, extra_checks = CALLBACK(src, .proc/breakout_callback, escapee)))
		breakout = FALSE
		return

	breakout = FALSE
	to_chat(escapee, "<span class='warning'>You successfully break out!</span>")
	visible_message("<span class='danger'>\The [escapee] successfully breaks out of \the [src]!</span>")
	playsound(loc, "sound/effects/grillehit.ogg", 100, 1)

	release()

/obj/item/weapon/trap/animal/CollidedWith(atom/AM)
	if(deployed && is_type_in_list(AM, allowed_mobs))
		Crossed(AM)
	else
		..()

/obj/item/weapon/trap/animal/verb/release_animal()
	set src in orange(1)
	set category = "Object"
	set name = "Release animal"

	if(!usr.canmove || usr.stat || usr.restrained())
		return

	if(!ishuman(usr))
		to_chat(usr, "<span class='warning'>This mob type can't use this verb.</span>")
		return

	var/datum/M = captured ? captured.resolve() : null

	if(M)
		var/open = alert("Do you want to open the cage and free \the [M]?",,"No","Yes")

		if(open == "No")
			return

		if(!can_use(usr))
			to_chat(usr, "<span class='warning'>You cannot use \the [src].</span>")
			return

		if(usr == M)
			to_chat(usr, "<span class='warning'>You can't open \the [src] from the inside! You'll need to force it open.</span>")
			return

		var/adj = src.Adjacent(usr)
		if(!adj)
			attack_self(src)
			return

		release(usr)

/obj/item/weapon/trap/animal/crush_act()
	if(captured)
		var/datum/L = captured ? captured.resolve() : null
		if(L && isliving(L))
			var/mob/living/LL = L
			LL.gib()
	new /obj/item/stack/material/steel(get_turf(src))
	qdel(src)

/obj/item/weapon/trap/animal/ex_act(severity)
	switch(severity)
		if(1)
			health -= rand(120, 240)
		if(2)
			health -= rand(60, 120)
		if(3)
			health -= rand(30, 60)

	if (health <= 0)
		if(captured)
			release()
		new /obj/item/stack/material/steel(get_turf(src))
		qdel(src)

/obj/item/weapon/trap/animal/bullet_act(var/obj/item/projectile/Proj)
	for (var/atom/movable/A in src)
		if(istype(A, /mob/living))
			var/mob/living/M = A
			M.bullet_act(Proj)

/obj/item/weapon/trap/animal/proc/release(var/mob/user, var/turf/target)
	if(!target)
		target = src.loc
	if(user)
		visible_message("<span class='notice'>[user] opens \the [src].</span>")

	var/datum/L = captured ? captured.resolve() : null
	if (!L)
		captured = null
		release_time = world.time
		return

	var/msg
	if (isliving(L))
		var/mob/living/ll = L
		msg = "<span class='warning'>[ll] runs out of \the [src].</span>"

	unbuckle_mob()
	captured = null
	visible_message(msg)
	animate_shake()
	update_icon()
	release_time = world.time

/obj/item/weapon/trap/animal/attackby(obj/item/W, mob/user)
	if(istype(W, /obj/item/weapon/grab))
		var/obj/item/weapon/grab/G = W
		var/mob/living/M = G.affecting

		if (G.state == GRAB_PASSIVE || G.state == GRAB_UPGRADING)
			to_chat(user, span("notice", "You need a better grip on \the [M]!"))
			return

		user.visible_message("<span class='notice'>[user] starts putting [M] into \the [src].</span>", "<span class='notice'>You start putting [M] into \the [src].</span>")

		if (!is_type_in_list(M, allowed_mobs))
			to_chat(user, span("warning", "[M] won't fit in there!"))
			return

		if (do_mob(user, M, 3 SECONDS, needhand = 0))
			if(captured?.resolve())
				return
			capture(M)

	else if(W.iswelder())
		var/obj/item/weapon/weldingtool/WT = W
		if(!WT.welding)
			to_chat(user, span("warning", "Your \the [W] is off!"))
			return
		user.visible_message("<span class='notice'>[user] is trying to slice \the [src] open!</span>",
							 "<span class='notice'>You are trying to slice \the [src] open!</span>")

		if (do_after(user, 30/W.toolspeed, act_target = src))
			if(WT.remove_fuel(2, user))
				user.visible_message("<span class='notice'>[user] slices \the [src] open!</span>",
									"<span class='notice'>You slice \the [src] open!</span>")
				new /obj/item/stack/rods(src.loc, resources["rods"])
				if(resources.len == 2)
					new /obj/item/stack/material/steel(src.loc, resources["metal"])
				release(user)
				qdel(src)

	else if(W.isscrewdriver())
		var/turf/T = get_turf(src)
		if(!T)
			to_chat(user, "<span class='warning'>There is nothing to secure [src] to!</span>")
			return

		user.visible_message("<span class='notice'>[user] is trying to [anchored ? "un" : "" ]secure \the [src]!</span>",
							 "<span class='notice'>You are trying to [anchored ? "un" : "" ]secure \the [src]!</span>")
		playsound(src.loc, "sound/items/[pick("Screwdriver", "Screwdriver2")].ogg", 50, 1)

		if (do_after(user, 30/W.toolspeed, act_target = src))
			density = !density
			anchored = !anchored
			user.visible_message("<span class='notice'>[user] [anchored ? "" : "un" ]secures \the [src]!</span>",
								"<span class='notice'>You [anchored ? "" : "un" ]secure \the [src]!</span>")
	else
		..()

/obj/item/weapon/trap/animal/Move()
	..()
	if(captured)
		var/datum/M = captured.resolve()
		if(isliving(M))
			var/mob/living/L = M
			if(L && buckled_mob.buckled == src)
				L.forceMove(loc)
			else if(L)
				captured = null
		else
			captured = null

/obj/item/weapon/trap/animal/attack_hand(mob/user)
	if(user.loc == src || captured)
		return

	if(anchored && deployed)
		to_chat(user, span("notice", "\The [src] is already anchored and set!"))
	else if(anchored)
		deploy(user)
	else
		..()

/obj/item/weapon/trap/animal/proc/pass_without_trace(mob/user, pct = 100)
	if(!is_type_in_list(user, allowed_mobs))
		user.forceMove(loc)
		user.visible_message("<span class='notice'>[user] passes over \the [src] without triggering it.</span>",
						"<span class='notice'>You pass over \the [src] without triggering it.</span>"
		)
	else
		user.visible_message("<span class='notice'>[user] attempts to pass through \the [src] without triggering it.</span>",
							"<span class='notice'>You attempt to pass through \the [src] without triggering it. </span>"
		)
		if(do_after(user, 2 SECONDS, act_target = src))
			if(prob(pct))
				user.forceMove(loc)
				user.visible_message("<span class='notice'>[user] passes through \the [src] without triggering it.</span>",
								"<span class='notice'>You pass through \the [src] without triggering it.</span>"
				)
			else
				user.forceMove(loc)
				user.visible_message("<span class='warning'>[user] accidentally triggers \the [src]!</span>",
								"<span class='warning'>You accidentally trigger \the [src]!</span>"
				)
				capture(user)

/obj/item/weapon/trap/animal/MouseDrop(over_object, src_location, over_location)
	if(!isliving(usr) || !src.Adjacent(usr))
		return

	if(captured)
		pass_without_trace(usr) // It's full

	if(is_type_in_list(usr, allowed_mobs))
		pass_without_trace(usr, 50)
		return

	else if(iscarbon(usr))
		pass_without_trace(usr)

	else
		..()

/obj/item/weapon/trap/animal/attack_self(mob/user)
	if(!can_use(user))
		to_chat(user, "<span class='warning'>You cannot use \the [src].</span>")
		return

	if(captured)
		release(user, user.loc)

/obj/item/weapon/trap/animal/attack(var/target, mob/living/user)
	if(!deployed)
		return

	if(captured) // It is full
		return

	if(isliving(target))
		var/mob/living/M = target
		if(is_type_in_list(M, allowed_mobs))
			user.visible_message(
							"<span class='warning'>[user] traps [M] inside of \the [src].</span>",
							"<span class='warning'>You trap [M] inside of the \the [src]!</span>",
							"<b>You hear a loud metallic snap!</b>"
							)
			capture(M, msg = 0)
	else
		..()

/obj/item/weapon/trap/animal/CanPass(atom/movable/mover, turf/target, height=0, air_group=0)
	return TRUE

/obj/item/weapon/trap/animal/medium
	name = "medium trap"
	desc = "A medium mechanical trap that is used to catch moderately-sized animals like cats, monkeys, nymphs, and wayward maintenance drones."
	icon_base = "medium"
	icon_state = "medium0"
	throwforce = 4
	force = 5
	w_class = 4
	origin_tech = list(TECH_ENGINEERING = 3)
	matter = list(DEFAULT_WALL_MATERIAL = 5750)
	deployed = FALSE
	resources = list(rods = 12)
	spider = FALSE

/obj/item/weapon/trap/animal/medium/Initialize()
	. = ..()
	allowed_mobs = list(
						/mob/living/simple_animal/cat, /mob/living/simple_animal/corgi, /mob/living/simple_animal/hostile/diyaab, /mob/living/simple_animal/penguin, /mob/living/simple_animal/crab,
						/mob/living/simple_animal/chicken, /mob/living/simple_animal/yithian, /mob/living/silicon/robot/drone,
						/mob/living/simple_animal/spiderbot, /mob/living/simple_animal/hostile/tree)

/obj/item/weapon/trap/animal/large
	name = "large trap"
	desc = "A large mechanical trap that is used to catch larger animals, from spiders and dogs to bears and even larger mammals."
	icon_base = "large"
	icon_state = "large0"
	throwforce = 6
	force = 10
	w_class = 6
	density = 1
	origin_tech = list(TECH_ENGINEERING = 3)
	matter = list(DEFAULT_WALL_MATERIAL = 15750)
	deployed = FALSE
	resources = list(rods = 12, metal = 4)
	spider = FALSE

/obj/item/weapon/trap/animal/large/Initialize()
	. = ..()
	allowed_mobs = list(
						/mob/living/simple_animal/hostile/retaliate/goat, /mob/living/simple_animal/cow, /mob/living/simple_animal/corgi/fox,
						/mob/living/simple_animal/hostile/carp, /mob/living/simple_animal/hostile/bear, /mob/living/simple_animal/hostile/alien, /mob/living/simple_animal/hostile/giant_spider,
						/mob/living/simple_animal/hostile/commanded/dog, /mob/living/simple_animal/hostile/retaliate/cavern_dweller, /mob/living/carbon/human/)

/obj/item/weapon/trap/animal/large/attack_hand(mob/user)
	if(user == buckled_mob)
		return
	else if(!anchored)
		to_chat(user, span("warning", "You need to anchor \the [src] first!"))
	else if(captured)
		to_chat(user, span("warning", "You can't deploy \the [src] with something caught!"))
	else
		..()

/obj/item/weapon/trap/animal/large/attackby(obj/item/W, mob/user)
	if(W.iswrench())
		var/turf/T = get_turf(src)
		if(!T)
			to_chat(user, "<span class='warning'>There is nothing to secure [src] to!</span>")
			return

		if(anchored && deployed)
			to_chat(user, span("warning", "You can't do that while \the [src] is deployed! Undeploy it first."))
			return

		user.visible_message("<span class='notice'>[user] begins [anchored ? "un" : "" ]securing \the [src]!</span>",
							  "<span class='notice'>You beign [anchored ? "un" : "" ]securing \the [src]!</span>")
		playsound(src.loc, W.usesound, 50, 1)

		if(do_after(user, 30/W.toolspeed, act_target = src))
			anchored = !anchored
			user.visible_message("<span class='notice'>[user] [anchored ? "" : "un" ]secures \the [src]!</span>",
								"<span class='notice'>You [anchored ? "" : "un" ]secure \the [src]!</span>")

	else if(W.isscrewdriver())
		// Unlike smaller traps, screwdriver shouldn't work on this.
		return
	else
		..()

/obj/item/weapon/trap/animal/large/MouseDrop(over_object, src_location, over_location)
	if(captured)
		to_chat(usr, span("warning", "The trap door's down, you can't get through there!"))
		return

	if(!src.Adjacent(usr))
		return

	if(!ishuman(usr))
		..()
		return

	var/pct = 0
	if(usr.a_intent == I_HELP)
		pct = 100
	else if(usr.a_intent != I_HURT)
		pct = 50

	pass_without_trace(usr, pct)

/obj/item/weapon/trap/animal/large/CanPass(atom/movable/mover, turf/target, height=0, air_group=0)
	if(deployed)
		return TRUE
	return FALSE

/obj/item/weapon/large_trap_foundation
	name = "large trap foundation"
	desc = "A metal foundation for large trap, it is missing metals rods to hold the prey."
	icon_state = "large_foundation"
	icon = 'icons/obj/items.dmi'
	throwforce = 4
	force = 5
	w_class = 5

/obj/item/weapon/large_trap_foundation/attackby(obj/item/W, mob/user)
	if(istype(W, /obj/item/stack/rods))
		var/obj/item/stack/rods/O = W
		if(O.get_amount() >= 12)

			to_chat(user, "<span class='notice'>You are trying to add metal bars to \the [src].</span>")

			if (!do_after(user, 2 SECONDS, act_target = src))
				return

			to_chat(user, "<span class='notice'>You add metal bars to \the [src].</span>")
			O.use(12)
			new /obj/item/weapon/trap/animal/large(src.loc)
			qdel(src)
			return
		else
			to_chat(user, "<span class='warning'>You need at least 12 rods to complete \the [src].</span>")
	else if(istype(W, /obj/item/weapon/screwdriver))
		return
	else
		..()

