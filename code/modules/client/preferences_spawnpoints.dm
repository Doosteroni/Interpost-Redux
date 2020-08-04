GLOBAL_VAR(spawntypes)

/proc/spawntypes()
	if(!GLOB.spawntypes)
		GLOB.spawntypes = list()
		for(var/type in typesof(/datum/spawnpoint)-/datum/spawnpoint)
			var/datum/spawnpoint/S = type
			var/display_name = initial(S.display_name)
			if((display_name in GLOB.using_map.allowed_spawns) || initial(S.always_visible))
				GLOB.spawntypes[display_name] = new S
	return GLOB.spawntypes

/datum/spawnpoint
	var/msg		  //Message to display on the arrivals computer.
	var/list/turfs   //List of turfs to spawn on.
	var/display_name //Name used in preference setup.
	var/always_visible = FALSE	// Whether this spawn point is always visible in selection, ignoring map-specific settings.
	var/list/restrict_job = null
	var/list/disallow_job = null

/datum/spawnpoint/proc/check_job_spawning(job)
	if(restrict_job && !(job in restrict_job))
		return 0

	if(disallow_job && (job in disallow_job))
		return 0

	return 1

//Called after mob is created, moved to a turf and equipped.
/datum/spawnpoint/proc/after_join(mob/victim)
	return

#ifdef UNIT_TEST
/datum/spawnpoint/Del()
	crash_with("Spawn deleted: [log_info_line(src)]")
	..()

/datum/spawnpoint/Destroy()
	crash_with("Spawn destroyed: [log_info_line(src)]")
	. = ..()
#endif

/datum/spawnpoint/arrivals
	display_name = "Arrivals Shuttle"
	msg = "has arrived on the station"

/datum/spawnpoint/arrivals/New()
	..()
	turfs = GLOB.latejoin

/datum/spawnpoint/gateway
	display_name = "Gateway"
	msg = "has completed translation from offsite gateway"

/datum/spawnpoint/gateway/New()
	..()
	turfs = GLOB.latejoin_gateway

/datum/spawnpoint/cryo
	display_name = "Cryogenic Storage"
	msg = "has completed cryogenic awakening"
	disallow_job = list("Robot")

/datum/spawnpoint/cryo/New()
	..()
	turfs = GLOB.latejoin_cryo

/datum/spawnpoint/cryo/after_join(mob/living/carbon/human/victim)
	if(!istype(victim))
		return
	var/area/A = get_area(victim)
	var/list/spots = list()

	for(var/obj/machinery/cryopod/C in A)
		if(!C.occupant)
			spots += C
	if(!length(spots))
		to_chat(victim, "You woke up a bit earlier than everyone.")
		turfs -= get_turf(victim)
		return

	for(var/obj/machinery/cryopod/C in shuffle(spots))
		if(!C.occupant)
			C.set_occupant(victim, 1)
			to_chat(victim, "<span class='notice'You're awakening from cryosleep...</span>")
			victim.sleeping = 0
			victim.Sleeping(rand(2,7))
			victim.bodytemperature = victim.species.cold_level_1 //very cold, but a point before damage

			if(!victim.isSynthetic()) //fluff. I didn't used else at next lines because of code readness
				to_chat(victim, "<span class='notice'>You're feeling cold and realize that there are water drops on your face. Cryogenic Liquid just \
				stopped refrigerating the air in the chamber...You see a bright light, blinding you. \
				Yet another shift has begun.</span>")
			else
				to_chat(victim, "<span class='notice'>Awakening signal received. Battery is charged. All systems nominal. Ready to work, my lord.</span>")

			if(!victim.isSynthetic())
				give_effect(victim)
				give_advice(victim)

				victim.drowsyness += 30
			break

/datum/spawnpoint/cyborg
	display_name = "Cyborg Storage"
	msg = "has been activated from storage"
	restrict_job = list("Cyborg")

/datum/spawnpoint/cyborg/New()
	..()
	turfs = GLOB.latejoin_cyborg

/datum/spawnpoint/default
	display_name = DEFAULT_SPAWNPOINT_ID
	msg = "has arrived on the station"
	always_visible = TRUE