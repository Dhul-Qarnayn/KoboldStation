/obj/structure/girder
	icon_state = "girder"
	anchored = 1
	density = 1
	layer = ABOVE_CABLE_LAYER
	w_class = 5
	var/state = 0
	var/health = 200
	var/cover = 50 //how much cover the girder provides against projectiles.
	var/material/reinf_material
	var/reinforcing = 0

/obj/structure/girder/displaced
	icon_state = "displaced"
	anchored = 0
	health = 50
	cover = 25

/obj/structure/girder/attack_generic(var/mob/user, var/damage, var/attack_message = "smashes apart", var/wallbreaker)
	if(!damage || !wallbreaker)
		return 0
	user.do_attack_animation(src)
	visible_message("<span class='danger'>[user] [attack_message] the [src]!</span>")
	spawn(1) dismantle()
	return 1

/obj/structure/girder/bullet_act(var/obj/item/projectile/Proj)
	//Girders only provide partial cover. There's a chance that the projectiles will just pass through. (unless you are trying to shoot the girder)
	if(Proj.original != src && !prob(cover))
		return PROJECTILE_CONTINUE //pass through

	var/damage = Proj.get_structure_damage()
	if(!damage)
		return

	if(!istype(Proj, /obj/item/projectile/beam))
		damage *= 0.4 //non beams do reduced damage

	health -= damage
	..()
	if(health <= 0)
		dismantle()

	return

/obj/structure/girder/proc/reset_girder()
	anchored = 1
	cover = initial(cover)
	health = min(health,initial(health))
	state = 0
	icon_state = initial(icon_state)
	reinforcing = 0
	if(reinf_material)
		reinforce_girder()

/obj/structure/girder/attackby(obj/item/W as obj, mob/user as mob)
	if(W.iswrench() && state == 0)
		if(anchored && !reinf_material)
			playsound(src.loc, W.usesound, 100, 1)
			to_chat(user, "<span class='notice'>Now disassembling the girder...</span>")
			if(do_after(user,40/W.toolspeed))
				if(!src) return
				to_chat(user, "<span class='notice'>You dissasembled the girder!</span>")
				dismantle()
		else if(!anchored)
			playsound(src.loc, W.usesound, 100, 1)
			to_chat(user, "<span class='notice'>Now securing the girder...</span>")
			if(do_after(user, 40/W.toolspeed))
				to_chat(user, "<span class='notice'>You secured the girder!</span>")
				reset_girder()

	else if(istype(W, /obj/item/weapon/gun/energy/plasmacutter))
		to_chat(user, "<span class='notice'>Now slicing apart the girder...</span>")
		if(do_after(user,30/W.toolspeed))
			if(!src) return
			to_chat(user, "<span class='notice'>You slice apart the girder!</span>")
			dismantle()

	else if(istype(W, /obj/item/weapon/melee/energy))
		var/obj/item/weapon/melee/energy/WT = W
		if(WT.active)
			to_chat(user, "<span class='notice'>Now slicing apart the girder...</span>")
			if(do_after(user,30/W.toolspeed))
				if(!src) return
				to_chat(user, "<span class='notice'>You slice apart the girder!</span>")
				dismantle()
		else
			to_chat(user, "<span class='notice'>You need to activate the weapon to do that!</span>")
			return

	else if(istype(W, /obj/item/weapon/melee/energy/blade))
		to_chat(user, "<span class='notice'>Now slicing apart the girder...</span>")
		if(do_after(user,30/W.toolspeed))
			if(!src) return
			to_chat(user, "<span class='notice'>You slice apart the girder!</span>")
			dismantle()

	else if(istype(W, /obj/item/weapon/melee/chainsword))
		var/obj/item/weapon/melee/chainsword/WT = W
		if(WT.active)
			to_chat(user, "<span class='notice'>Now slicing apart the girder...</span>")
			if(do_after(user,60/W.toolspeed))
				if(!src) return
				to_chat(user, "<span class='notice'>You slice apart the girder!</span>")
				dismantle()
		else
			to_chat(user, "<span class='notice'>You need to activate the weapon to do that!</span>")
			return

	else if(istype(W, /obj/item/weapon/pickaxe/diamonddrill))
		to_chat(user, "<span class='notice'>You drill through the girder!</span>")
		dismantle()

	else if(W.isscrewdriver())
		if(state == 2)
			playsound(src.loc, W.usesound, 100, 1)
			to_chat(user, "<span class='notice'>Now unsecuring support struts...</span>")
			if(do_after(user,40/W.toolspeed))
				if(!src) return
				to_chat(user, "<span class='notice'>You unsecured the support struts!</span>")
				state = 1
		else if(anchored && !reinf_material)
			playsound(src.loc, W.usesound, 100, 1)
			reinforcing = !reinforcing
			to_chat(user, "<span class='notice'>\The [src] can now be [reinforcing? "reinforced" : "constructed"]!</span>")

	else if(W.iswirecutter() && state == 1)
		playsound(src.loc, 'sound/items/Wirecutter.ogg', 100, 1)
		to_chat(user, "<span class='notice'>Now removing support struts...</span>")
		if(do_after(user,40/W.toolspeed))
			if(!src) return
			to_chat(user, "<span class='notice'>You removed the support struts!</span>")
			reinf_material = null
			reset_girder()

	else if(W.iscrowbar() && state == 0 && anchored)
		playsound(src.loc, 'sound/items/Crowbar.ogg', 100, 1)
		to_chat(user, "<span class='notice'>Now dislodging the girder...</span>")
		if(do_after(user, 40/W.toolspeed))
			if(!src) return
			to_chat(user, "<span class='notice'>You dislodged the girder!</span>")
			icon_state = "displaced"
			anchored = 0
			health = 50
			cover = 25

	else if(istype(W, /obj/item/stack/material))
		if(reinforcing && !reinf_material)
			if(!reinforce_with_material(W, user))
				return ..()
		else
			if(!construct_wall(W, user))
				return ..()

	else
		return ..()

/obj/structure/girder/proc/construct_wall(obj/item/stack/material/S, mob/user)
	if(S.get_amount() < 2)
		to_chat(user, "<span class='notice'>There isn't enough material here to construct a wall.</span>")
		return 0

	var/material/M = name_to_material[S.default_type]
	if(!istype(M))
		return 0

	var/wall_fake
	add_hiddenprint(usr)

	if(M.integrity < 50)
		to_chat(user, "<span class='notice'>This material is too soft for use in wall construction.</span>")
		return 0

	to_chat(user, "<span class='notice'>You begin adding the plating...</span>")

	if(!do_after(user,40) || !S.use(2))
		return 1 //once we've gotten this far don't call parent attackby()

	if(anchored)
		to_chat(user, "<span class='notice'>You added the plating!</span>")
	else
		to_chat(user, "<span class='notice'>You create a false wall! Push on it to open or close the passage.</span>")
		wall_fake = 1

	var/turf/Tsrc = get_turf(src)
	Tsrc.ChangeTurf(/turf/simulated/wall)
	var/turf/simulated/wall/T = get_turf(src)
	T.set_material(M, reinf_material)
	if(wall_fake)
		T.can_open = 1
	T.add_hiddenprint(usr)
	qdel(src)
	return 1

/obj/structure/girder/proc/reinforce_with_material(obj/item/stack/material/S, mob/user) //if the verb is removed this can be renamed.
	if(reinf_material)
		to_chat(user, "<span class='notice'>\The [src] is already reinforced.</span>")
		return 0

	if(S.get_amount() < 2)
		to_chat(user, "<span class='notice'>There isn't enough material here to reinforce the girder.</span>")
		return 0

	var/material/M = name_to_material[S.default_type]
	if(!istype(M) || M.integrity < 50)
		to_chat(user, "You cannot reinforce \the [src] with that; it is too soft.")
		return 0

	to_chat(user, "<span class='notice'>Now reinforcing...</span>")
	if (!do_after(user,40) || !S.use(2))
		return 1 //don't call parent attackby() past this point
	to_chat(user, "<span class='notice'>You added reinforcement!</span>")

	reinf_material = M
	reinforce_girder()
	return 1

/obj/structure/girder/proc/reinforce_girder()
	cover = reinf_material.hardness
	health = 500
	state = 2
	icon_state = "reinforced"
	reinforcing = 0

/obj/structure/girder/proc/dismantle()
	new /obj/item/stack/material/steel(get_turf(src))
	new /obj/item/stack/material/steel(get_turf(src))
	qdel(src)

/obj/structure/girder/attack_hand(mob/user as mob)
	if (HULK in user.mutations)
		visible_message("<span class='danger'>[user] smashes [src] apart!</span>")
		dismantle()
		return
	return ..()


/obj/structure/girder/ex_act(severity)
	switch(severity)
		if(1.0)
			qdel(src)
			return
		if(2.0)
			if (prob(30))
				dismantle()
				return
			else
				health -= rand(60,180)

		if(3.0)
			if (prob(5))
				dismantle()
				return
			else
				health -= rand(40,80)
		else

	if(health <= 0)
		dismantle()
	return

/obj/structure/girder/cult
	icon= 'icons/obj/cult.dmi'
	icon_state= "cultgirder"
	health = 250
	cover = 70
	appearance_flags = NO_CLIENT_COLOR

/obj/structure/girder/cult/dismantle()
	new /obj/effect/decal/remains/human(get_turf(src))
	qdel(src)

/obj/structure/girder/cult/attackby(obj/item/W as obj, mob/user as mob)
	if(W.iswrench())
		playsound(src.loc, W.usesound, 100, 1)
		to_chat(user, "<span class='notice'>Now disassembling the girder...</span>")
		if(do_after(user,40/W.toolspeed))
			to_chat(user, "<span class='notice'>You dissasembled the girder!</span>")
			dismantle()

	else if(istype(W, /obj/item/weapon/gun/energy/plasmacutter))
		to_chat(user, "<span class='notice'>Now slicing apart the girder...</span>")
		if(do_after(user,30/W.toolspeed))
			to_chat(user, "<span class='notice'>You slice apart the girder!</span>")
		dismantle()

	else if(istype(W, /obj/item/weapon/pickaxe/diamonddrill))
		to_chat(user, "<span class='notice'>You drill through the girder!</span>")
		new /obj/effect/decal/remains/human(get_turf(src))
		dismantle()

	else if(istype(W, /obj/item/weapon/melee/energy))
		var/obj/item/weapon/melee/energy/WT = W
		if(WT.active)
			to_chat(user, "<span class='notice'>Now slicing apart the girder...</span>")
			if(do_after(user,30/W.toolspeed))
				to_chat(user, "<span class='notice'>You slice apart the girder!</span>")
			dismantle()
		else
			to_chat(user, "<span class='notice'>You need to activate the weapon to do that!</span>")
			return

	else if(istype(W, /obj/item/weapon/melee/energy/blade))
		to_chat(user, "<span class='notice'>Now slicing apart the girder...</span>")
		if(do_after(user,30/W.toolspeed))
			to_chat(user, "<span class='notice'>You slice apart the girder!</span>")
		dismantle()

	else if(istype(W, /obj/item/weapon/melee/chainsword))
		var/obj/item/weapon/melee/chainsword/WT = W
		if(WT.active)
			to_chat(user, "<span class='notice'>Now slicing apart the girder...</span>")
			if(do_after(user,60/W.toolspeed))
				to_chat(user, "<span class='notice'>You slice apart the girder!</span>")
			dismantle()
		else
			to_chat(user, "<span class='notice'>You need to activate the weapon to do that!</span>")
			return


/obj/structure/girder/CanPass(atom/movable/mover, turf/target, height=0, air_group=0)
	if (!mover)
		return 1
	if(istype(mover,/obj/item/projectile) && density)
		if (prob(50))
			return 1
		else
			return 0
	else if(mover.checkpass(PASSTABLE))
//Animals can run under them, lots of empty space
		return 1
	return ..()
