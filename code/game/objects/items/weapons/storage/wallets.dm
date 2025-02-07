/obj/item/weapon/storage/wallet
	name = "wallet"
	desc = "It can hold a few small and personal things."
	storage_slots = 10
	icon_state = "wallet"
	w_class = 2
	max_w_class = 2
	can_hold = list(
		/obj/item/weapon/spacecash,
		/obj/item/weapon/card,
		/obj/item/clothing/mask/smokable,
		/obj/item/clothing/accessory/badge,
		/obj/item/clothing/accessory/locket,
		/obj/item/device/flashlight/pen,
		/obj/item/seeds,
		/obj/item/stack/medical,
		/obj/item/weapon/coin,
		/obj/item/weapon/dice,
		/obj/item/weapon/disk,
		/obj/item/weapon/implanter,
		/obj/item/weapon/flame/lighter,
		/obj/item/weapon/flame/match,
		/obj/item/weapon/lipstick,
		/obj/item/weapon/haircomb,
		/obj/item/weapon/paper,
		/obj/item/weapon/paper_bundle,
		/obj/item/weapon/pen,
		/obj/item/weapon/photo,
		/obj/item/weapon/reagent_containers/dropper,
		/obj/item/weapon/reagent_containers/syringe,
		/obj/item/weapon/reagent_containers/pill,
		/obj/item/weapon/reagent_containers/hypospray/autoinjector,
		/obj/item/weapon/screwdriver,
		/obj/item/weapon/stamp,
		/obj/item/device/encryptionkey,
		/obj/item/fluff)
	slot_flags = SLOT_ID

	var/obj/item/weapon/card/id/front_id = null
	var/flipped = null
	var/flippable = 1
	var/wear_over_suit = 0


/obj/item/weapon/storage/wallet/remove_from_storage(obj/item/W as obj, atom/new_location)
	. = ..(W, new_location)
	if(.)
		if(W == front_id)
			front_id = null
			name = initial(name)
			update_icon()

/obj/item/weapon/storage/wallet/handle_item_insertion(obj/item/W as obj, prevent_warning = 0)
	. = ..(W, prevent_warning)
	if(.)
		if(!front_id && istype(W, /obj/item/weapon/card/id))
			front_id = W
			name = "[name] ([front_id])"
			update_icon()

/obj/item/weapon/storage/wallet/update_icon()
	overlays.Cut()
	if(front_id)
		var/tiny_state = "id-generic"
		if("id-"+front_id.icon_state in icon_states(icon))
			tiny_state = "id-"+front_id.icon_state
		var/image/tiny_image = new/image(icon, icon_state = tiny_state)
		tiny_image.appearance_flags = RESET_COLOR
		overlays += tiny_image
	mob_icon_update()

/obj/item/weapon/storage/wallet/GetID()
	return front_id

/obj/item/weapon/storage/wallet/GetAccess()
	var/obj/item/I = GetID()
	if(I)
		return I.GetAccess()
	else
		return ..()

/obj/item/weapon/storage/wallet/random/fill()
	..()
	var/item1_type = pick(                \
		/obj/item/weapon/spacecash/c10,   \
		/obj/item/weapon/spacecash/c100,  \
		/obj/item/weapon/spacecash/c1000, \
		/obj/item/weapon/spacecash/c20,   \
		/obj/item/weapon/spacecash/c200,  \
		/obj/item/weapon/spacecash/c50,   \
		/obj/item/weapon/spacecash/c500   \
	)
	var/item2_type
	if(prob(50))
		item2_type = pick(                    \
			/obj/item/weapon/spacecash/c10,   \
			/obj/item/weapon/spacecash/c100,  \
			/obj/item/weapon/spacecash/c1000, \
			/obj/item/weapon/spacecash/c20,   \
			/obj/item/weapon/spacecash/c200,  \
			/obj/item/weapon/spacecash/c50,   \
			/obj/item/weapon/spacecash/c500   \
		)
	var/item3_type = pick(            \
		/obj/item/weapon/coin/silver, \
		/obj/item/weapon/coin/silver, \
		/obj/item/weapon/coin/gold,   \
		/obj/item/weapon/coin/iron,   \
		/obj/item/weapon/coin/iron,   \
		/obj/item/weapon/coin/iron    \
	)

	if(item1_type)
		new item1_type(src)
	if(item2_type)
		new item2_type(src)
	if(item3_type)
		new item3_type(src)

/obj/item/weapon/storage/wallet/proc/mob_icon_update()
	if (ismob(src.loc))
		var/mob/M = src.loc
		M.update_inv_wear_id()

/obj/item/weapon/storage/wallet/verb/flip_side()
	set name = "Flip wallet side"
	set category = "Object"
	set src in usr
	if(use_check_and_message(usr, use_flags = USE_DISALLOW_SILICONS))
		return
	if (!flippable)
		to_chat(usr, "You cannot flip \the [src] as it is not a flippable item.")
		return

	src.flipped = !src.flipped
	if(src.flipped)
		src.overlay_state = "[overlay_state]_flip"
	else
		src.overlay_state = initial(overlay_state)
	to_chat(usr, "You change \the [src] to be on your [src.flipped ? "left" : "right"] side.")
	mob_icon_update()

/obj/item/weapon/storage/wallet/verb/toggle_icon_layer()
	set name = "Switch Wallet Layer"
	set category = "Object"
	set src in usr

	if(use_check_and_message(usr, use_flags = USE_DISALLOW_SILICONS))
		return
	if(wear_over_suit == -1)
		to_chat(usr, "<span class='notice'>\The [src] cannot be worn above your suit!</span>")
		return
	wear_over_suit = !wear_over_suit
	mob_icon_update()

/obj/item/weapon/storage/wallet/colourable
	icon_state = "wallet-white"

/obj/item/weapon/storage/wallet/purse
	name = "wallet purse"
	desc = "A stylish long wallet purse with several slots."
	icon_state = "wallet-purse"

/obj/item/weapon/storage/wallet/lanyard
	name = "lanyard"
	desc = "A thick cord with a hook and plastic film designed for the hunter of elk, lover of women, sovereign of the moon."
	storage_slots = 2
	icon_state = "lanyard"
	item_state = "lanyard"
	overlay_state = "lanyard"
	attack_verb = list("whipped", "lashed", "lightly garroted")
	w_class = 1
	max_w_class = 1
	can_hold = list(
		/obj/item/weapon/card,
		/obj/item/clothing/accessory/badge,
		/obj/item/clothing/accessory/locket,
		/obj/item/weapon/disk,
		/obj/item/weapon/paper,
		/obj/item/weapon/paper_bundle,
		/obj/item/weapon/pen,
		/obj/item/weapon/photo)
	flippable = 0 //until a cleaner way is implemented to just simply have the verb not show up at all
	var/plastic_film_overlay_state = "plasticfilm"
	var/front_id_overlay_state

	drop_sound = 'sound/items/drop/clothing.ogg'

/obj/item/weapon/storage/wallet/lanyard/New()
	..()
	var/image/film_image = new/image(icon, icon_state = "lanyard_film")
	film_image.appearance_flags = RESET_COLOR
	overlays += film_image

/obj/item/weapon/storage/wallet/lanyard/update_icon()
	..()
	if(front_id)
		front_id_overlay_state = front_id.icon_state
	var/image/film_image = new/image(icon, icon_state = "lanyard_film")
	film_image.appearance_flags = RESET_COLOR
	overlays += film_image
	mob_icon_update()