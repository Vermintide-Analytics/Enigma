local enigma = get_mod("Enigma")

local uim = {
    big_card_to_display = nil,
}
enigma.managers.ui = uim

uim.show_big_card = function(self, card)
    self.big_card_to_display = card
end

uim.hide_big_card = function(self)
    self.big_card_to_display = nil
end