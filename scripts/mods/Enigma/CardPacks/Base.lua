local enigma = get_mod("Enigma")

local COMMON = enigma.CARD_RARITY.common
local RARE = enigma.CARD_RARITY.rare
local EPIC = enigma.CARD_RARITY.epic
local LEGENDARY = enigma.CARD_RARITY.legendary

local pack_handle = enigma.managers.card_pack:register_card_pack("Enigma", "base", "Base")

pack_handle.register_passive_cards({
    caffeinated = {
        name = "base_caffeinated",
        rarity = COMMON,
        cost = 2,
        texture = "enigma_base_caffeinated"
    },
    executioner = {
        name = "base_executioner",
        rarity = EPIC,
        cost = 2,
    },
    expertise = {
        name = "base_expertise",
        rarity = COMMON,
        cost = 1,
    },
    gym_rat = {
        name = "base_gym_rat",
        rarity = COMMON,
        cost = 1,
    },
    spartan = {
        name = "base_spartan",
        rarity = RARE,
        cost = 1,
    },
    tough_skin = {
        name = "base_tough_skin",
        rarity = COMMON,
        cost = 0,
    },
    veteran = {
        name = "base_veteran",
        rarity = EPIC,
        cost = 4,
    },
    warp_flesh = {
        name = "base_warp_flesh",
        rarity = RARE,
        cost = 3,
    },
})

pack_handle.register_surge_cards({
    retreat = {
        name = "base_retreat",
        rarity = RARE,
        cost = 1,
        duration_seconds = 15
    },
    stolen_bell = {
        name = "base_stolen_bell",
        rarity = RARE,
        cost = 1,
        duration_seconds = 100
    },
    warpfire_strikes = {
        name = "base_warpfire_strikes",
        rarity = COMMON,
        cost = 2,
        duration_seconds = 60
    },
    warpstone_pie = {
        name = "base_warpstone_pie",
        rarity = EPIC,
        cost = 1,
        duration_seconds = 31.4
    },
    wrath_of_khorne = {
        name = "base_wrath_of_khorne",
        rarity = EPIC,
        cost = 1,
        duration_seconds = 10
    },
})

pack_handle.register_ability_cards({
    cyclone_strike = {
        name = "base_cyclone_strike",
        rarity = RARE,
        cost = 0
    },
    ranalds_play = {
        name = "base_ranalds_play",
        rarity = LEGENDARY,
        cost = 1
    },
    long_rest = {
        name = "base_long_rest",
        rarity = LEGENDARY,
        cost = 3
    },
})