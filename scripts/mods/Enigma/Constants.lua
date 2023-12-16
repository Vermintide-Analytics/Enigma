local enigma = get_mod("Enigma")

enigma.CARD_TYPE = {
    passive = "passive",
    attack = "attack",
    ability = "ability",
    chaos = "chaos"
}
enigma.validate_card_type = function(type)
    if type(type) ~= "string" then
        return false
    end
    return enigma.CARD_TYPE[type]
end

enigma.CARD_RARITY = {
    common = "common",
    rare = "rare",
    epic = "epic",
    legendary = "legendary"
}
enigma.validate_rarity = function(rarity)
    if type(rarity) ~= "string" then
        return false
    end
    return enigma.CARD_RARITY[rarity]
end

enigma.CARD_LOCATION = {
    draw_pile = "draw_pile",
    hand = "hand",
    discard_pile = "discard_pile",
    out_of_play_pile = "out_of_play_pile"
}
enigma.can_play_from_location = function(location)
    return location == enigma.CARD_LOCATION.draw_pile or location == enigma.CARD_LOCATION.hand
end
enigma.can_discard_from_location = function(location)
    return location == enigma.CARD_LOCATION.draw_pile or location == enigma.CARD_LOCATION.hand
end