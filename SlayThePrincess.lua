--- STEAMODDED HEADER
--- MOD_NAME: Slay The Princess
--- MOD_ID: SlayThePrincess
--- MOD_AUTHOR: [Kastamera]
--- PREFIX: stp
--- MOD_DESCRIPTION: Slay the Princess Balatro mod
----------------------------------------------
------------MOD CODE -------------------------
function SMODS.INIT.SlayThePrincess()
    -- keep if you need init later
end

SMODS.Atlas {
    key = "SlayThePrincess",
    path = "SlayThePrincess.png",
    px = 71,
    py = 95
}

------------PRINCESS DECK---------------------
SMODS.Back {
    name = "Princess Deck",
    key = "princess",
    pos = {
        x = 0,
        y = 0
    },
    config = {
        princess = true
    },
    atlas = 'SlayThePrincess',

    loc_txt = {
        name = "Princess Deck",
        text = {"Start with {C:red}level 0{} {C:attention}poker hands{} and",
                "a {C:dark_edition}Negative{} {C:attention}Eternal{} {C:purple}The Princess{}."}
    },

    apply = function(self)
        G.E_MANAGER:add_event(Event({
            func = function()
                if G.jokers then
                    SMODS.add_card {
                        key = "j_princess",
                        stickers = {"eternal"},
                        force_stickers = true,
                        edition = "e_negative"
                    }
                    --SMODS.add_card {
                    --    key = "j_dragon"
                    --}
                    --SMODS.add_card {
                    --    key = "j_spectre"
                    --}
                end
                return true
            end
        }))

        for poker_hand_key, _ in pairs(G.GAME.hands) do
            SMODS.smart_level_up_hand(nil, poker_hand_key, true, -1)
        end
    end
}

SMODS.Rarity {
    key = "stp_pristine",
    default_weight = 0.005,
    badge_colour = HEX('CFFFF6'),
    pools = {
        ["Joker"] = true
    },
    loc_txt = {
        name = "Pristine"
    }
}

------------JOKERS---------------------
-- The Princess
SMODS.Joker {
    key = "princess",
    pool = "joker",
    blueprint_compat = true,
    rarity = 1,
    cost = 4,
    pos = {
        x = 1,
        y = 0
    },
    eternal_compat = true,
    unlocked = true,
    discovered = true,
    atlas = 'SlayThePrincess',
    config = {
        extra = {
            mult = 0
        }
    },
    loc_txt = {
        name = "The Princess",
        text = {"{C:red}+1{} Mult for each {C:attention}Queen{}", "in your {C:attention}full deck{}",
                "{C:inactive}(Currently {C:red}+#1#{C:inactive} Mult)"}
    },

    _count_queens = function()
        local n = 0
        for _, c in ipairs(G.playing_cards or {}) do
            if c and c.get_id and c:get_id() == 12 then
                n = n + 1
            end
        end
        return n
    end,

    loc_vars = function(self, info_queue, card)
        card.ability.extra.mult = self._count_queens()
        return {
            vars = {card.ability.extra.mult}
        }
    end,

    calculate = function(self, card, context)
        if context.joker_main and not context.blueprint then
            return {
                mult = self._count_queens()
            }
        end
    end
}

-- The Spectre
SMODS.Joker {
    key = "spectre",
    pool = "joker",
    blueprint_compat = true,
    rarity = 2,
    cost = 6,
    pos = {
        x = 3,
        y = 0
    },
    eternal_compat = true,
    unlocked = true,
    discovered = false,
    atlas = 'SlayThePrincess',
    loc_txt = {
        name = "The Spectre",
        text = {"Whenever you destroy a {C:attention}Queen{},", "create a {C:spectral}Spectral{} card."}
    },

    calculate = function(self, card, context)
        if context.remove_playing_cards and not context.blueprint then
            local queens_destroyed = 0
            for _, removed_card in ipairs(context.removed) do
                if removed_card:get_id() == 12 then
                    queens_destroyed = queens_destroyed + 1
                end
            end
            if queens_destroyed > 0 then
                if #G.consumeables.cards + G.GAME.consumeable_buffer < G.consumeables.config.card_limit then
                    spectrals_to_summon = math.min(queens_destroyed, G.consumeables.config.card_limit -
                        #G.consumeables.cards + G.GAME.consumeable_buffer)
                    G.GAME.consumeable_buffer = G.GAME.consumeable_buffer + spectrals_to_summon
                    G.E_MANAGER:add_event(Event({
                        func = (function()
                            for i = 1, spectrals_to_summon do
                                SMODS.add_card {
                                    set = 'Spectral'
                                }
                            end
                            G.GAME.consumeable_buffer = 0
                            return true
                        end)
                    }))
                    return {
                        message = localize('k_plus_spectral'),
                        colour = G.C.SECONDARY_SET.Spectral
                    }
                end
                return {
                    remove = true
                }
            end
        end
    end
}

-- The Nightmare
SMODS.Joker {
    key = "nightmare",
    pool = "joker",
    blueprint_compat = true,
    rarity = 1,
    cost = 5,
    pos = {
        x = 6,
        y = 0
    },
    eternal_compat = true,
    unlocked = true,
    discovered = false,
    atlas = 'SlayThePrincess',

    config = {
        extra = {
            mult = 0,
            mult_mod = 5,
            previous_hands = {}
        }
    },
    loc_txt = {
        name = "The Nightmare",
        text = {"This Joker gains {C:mult}+#2#{} Mult per", "hand played, resets when you",
                "play a {C:attention}poker hand{} that was", "played in the {C:attention}last 3 poker hands{}",
                "{C:inactive}(Currently {C:mult}+#1#{C:inactive} Mult)"}
    },

    _check_and_append_list = function(card, poker_hand)
        local extra = card.ability.extra
        local list = extra.previous_hands or {}
        extra.previous_hands = list

        local seen = false
        for _, v in ipairs(list) do
            if v == poker_hand then
                seen = true;
                break
            end
        end

        if seen then
            extra.mult = extra.mult_mod
            for k in pairs(list) do
                list[k] = nil
            end
            table.insert(list, poker_hand)
            return {
                message = localize('k_reset')
            }
        end

        extra.mult = extra.mult + extra.mult_mod
        if #list >= 3 then
            table.remove(list, 1)
        end
        table.insert(list, poker_hand)

        return {
            message = localize('k_upgrade_ex'),
            colour = G.C.MULT
        }
    end,

    loc_vars = function(self, info_queue, card)
        return {
            vars = {card.ability.extra.mult, card.ability.extra.mult_mod}
        }
    end,

    calculate = function(self, card, context)
        if context.before and not context.blueprint then
            local played_hand = context.scoring_name or "" -- ensure a string
            local ret = self._check_and_append_list(card, played_hand)
            if ret then
                return ret
            end
        end
        if context.joker_main then
            return {
                mult = card.ability.extra.mult
            }
        end
    end
}

-- The Witch
SMODS.Joker {
    key = "witch",
    pool = "joker",
    blueprint_compat = true,
    rarity = 1,
    cost = 5,
    pos = {
        x = 0,
        y = 1
    },
    eternal_compat = true,
    unlocked = true,
    discovered = false,
    atlas = 'SlayThePrincess',
    config = {
        extra = {
            xmult_low = 0.5,
            xmult_high = 2,
            odds = 3
        }
    },
    loc_txt = {
        name = "The Witch",
        text = {"{X:mult,C:white} X#4#{} Mult", "{C:green}#1# in #2#{} chance for",
                "{X:mult,C:white} X#3#{} Mult instead"}
    },

    loc_vars = function(self, info_queue, card)
        local numerator, denominator = SMODS.get_probability_vars(card, 1, card.ability.extra.odds, 'witch')
        return {
            vars = {numerator, denominator, card.ability.extra.xmult_low, card.ability.extra.xmult_high}
        }
    end,

    calculate = function(self, card, context)
        if context.joker_main then
            if SMODS.pseudorandom_probability(card, 'witch', 1, card.ability.extra.odds) then
                return {
                    xmult = card.ability.extra.xmult_low
                }
            end
            return {
                xmult = card.ability.extra.xmult_high
            }
        end
    end
}

-- The Thorn
SMODS.Joker {
    key = "thorn",
    pool = "joker",
    blueprint_compat = false,
    rarity = 2,
    cost = 7,
    pos = {
        x = 4,
        y = 1
    },
    eternal_compat = true,
    unlocked = true,
    discovered = false,
    atlas = 'SlayThePrincess',
    config = {
        extra = {
            dollars = -5,
            upgrade = 10,
            upgraded = false
        }
    },

    loc_txt = {
        name = "The Thorn",
        text = {"Earn {C:money}$#1#{} at end of round", "and increase this gain by {C:money}$1",
                "{C:inactive}Becomes {C:dark_edition}Negative{} {C:inactive}and {C:attention}Eternal{}",
                "{C:inactive}in #2# rounds"}
    },

    loc_vars = function(self, info_queue, card)
        return {
            vars = {card.ability.extra.dollars, card.ability.extra.upgrade}
        }
    end,

    calculate = function(self, card, context)
        if context.end_of_round and context.game_over == false and context.main_eval and not context.blueprint then
            card.ability.extra.dollars = card.ability.extra.dollars + 1
            if card.ability.extra.upgrade > 0 then
                card.ability.extra.upgrade = card.ability.extra.upgrade - 1
                if card.ability.extra.upgrade > 0 then
                    return {
                        message = 'Trying to trust...'
                    }
                end
            end
            if not card.ability.extra.upgraded then
                card:set_edition({
                    negative = true
                }, true)
                card:set_eternal(true)
                card.ability.extra.upgraded = true
            end
        end
    end,

    calc_dollar_bonus = function(self, card)
        return card.ability.extra.dollars
    end
}

-- The Adversary
SMODS.Joker {
    key = "adversary",
    pool = "joker",
    blueprint_compat = true,
    rarity = 2,
    cost = 6,
    pos = {
        x = 6,
        y = 1
    },
    eternal_compat = false,
    unlocked = true,
    discovered = false,
    atlas = 'SlayThePrincess',
    config = {
        extra = {
            mult = 0,
            mult_mod = 15,
            sold_count = 1
        }
    },

    loc_txt = {
        name = "The Adversary",
        text = {"{C:red}+#1#{} Mult, increases by {C:red}+#2#{} Mult", "every time this Joker is sold"}
    },

    _state = function()
        G.GAME._adversary = G.GAME._adversary or {
            sold = 1
        }
        return G.GAME._adversary
    end,

    loc_vars = function(self, info_queue, card)
        local sold = self._state().sold
        return {
            vars = {sold * card.ability.extra.mult_mod, card.ability.extra.mult_mod, sold}
        }
    end,

    calculate = function(self, card, context)
        if context.selling_self and not context.blueprint then
            G.E_MANAGER:add_event(Event {
                func = function()
                    self._state().sold = self._state().sold + 1
                    play_sound('generic1', 0.9 + math.random() * 0.1, 0.8)
                    return {
                        message = 'MORE!',
                        colour = G.C.MULT
                    }
                end
            })
            return nil, true
        end

        if context.joker_main then
            return {
                mult = self._state().sold * card.ability.extra.mult_mod
            }
        end
    end
}

-- The Tower
SMODS.Joker {
    key = "tower",
    pool = "joker",
    blueprint_compat = true,
    rarity = 1,
    cost = 5,
    pos = {
        x = 1,
        y = 1
    },
    eternal_compat = true,
    unlocked = true,
    discovered = false,
    atlas = 'SlayThePrincess',
    config = {
        extra = {
            chips = 0,
            chips_mod = 2
        }
    },
    loc_txt = {
        name = "The Tower",
        text = {"All {C:attentiom}ranks{} lower than", "{C:attention}Queen{} are debuffed,",
                "{C:chips}+#2#{} Chips for each debuffed", "card in your {C:attention}full deck",
                "{C:inactive}(Currently {C:chips}+#1#{} {C:inactive}Chips)"}
    },

    _count_debuffed = function()
        if not G.playing_cards then
            return 0
        end
        local n = 0
        for _, c in ipairs(G.playing_cards or {}) do
            if c.debuff then
                n = n + 1
            end
        end
        return n
    end,

    loc_vars = function(self, info_queue, card)
        card.ability.extra.chips = self._count_debuffed() * card.ability.extra.chips_mod
        return {
            vars = {card.ability.extra.chips, card.ability.extra.chips_mod}
        }
    end,

    calculate = function(self, card, context)
        if context.debuff_card and type(context.debuff_card:get_id()) == "number" and context.debuff_card:get_id() < 12 then
            return {
                debuff = true
            }
        end
        if context.joker_main then
            return {
                chips = self._count_debuffed() * card.ability.extra.chips_mod
            }
        end
    end
}

-- The Fury
SMODS.Joker {
    key = "fury",
    pool = "joker",
    blueprint_compat = true,
    rarity = 2,
    cost = 6,
    pos = {
        x = 2,
        y = 1
    },
    eternal_compat = true,
    unlocked = true,
    discovered = false,
    atlas = 'SlayThePrincess',
    config = {
        extra = {
            mult = 0,
            mult_mod = 2,
            xmult = 1,
            xmult_mod = 0.1
        }
    },
    loc_txt = {
        name = "The Fury",
        text = {"This Joker gains {C:red}+#2#{} Mult", "every time a {C:attention}playing card{} is",
                "destroyed, and {X:mult,C:white} X#4# {} Mult", "every time a {C:attention}playing card{}",
                "is added to your deck",
                "{C:inactive}(Currently {C:red}+#1#{} {C:inactive}Mult and {X:mult,C:white} X#3# {C:inactive} Mult)"}
    },

    loc_vars = function(self, info_queue, card)
        return {
            vars = {card.ability.extra.mult, card.ability.extra.mult_mod, card.ability.extra.xmult,
                    card.ability.extra.xmult_mod}
        }
    end,

    calculate = function(self, card, context)
        if context.remove_playing_cards and not context.blueprint then
            local removed_card_count = #context.removed
            if removed_card_count > 0 then
                card.ability.extra.mult = card.ability.extra.mult + removed_card_count * card.ability.extra.mult_mod
                return {
                    message = localize {
                        type = 'variable',
                        key = 'a_mult',
                        vars = {card.ability.extra.mult}
                    }
                }
            end
        end
        if context.playing_card_added and not context.blueprint then
            card.ability.extra.xmult = card.ability.extra.xmult + #context.cards * card.ability.extra.xmult_mod
            return {
                message = localize {
                    type = 'variable',
                    key = 'a_xmult',
                    vars = {card.ability.extra.xmult}
                }
            }
        end
        if context.joker_main then
            return {
                mult = card.ability.extra.mult,
                Xmult = card.ability.extra.xmult
            }
        end
    end
}

-- The Stranger
SMODS.Joker {
    key = "stranger",
    pool = "joker",
    blueprint_compat = true,
    rarity = 3,
    cost = 7,
    pos = {
        x = 5,
        y = 0
    },
    eternal_compat = true,
    unlocked = true,
    discovered = false,
    atlas = 'SlayThePrincess',
    loc_txt = {
        name = "The Stranger",
        text = {"All scoring cards gain a", "random {C:enhanced}Enhancement{} before", "scoring"}
    },

    _get_random_enhancement = function()
        local enhancement_pool = {'m_gold', 'm_steel', 'm_glass', 'm_wild', 'm_mult', 'm_lucky', 'm_stone', 'm_bonus'}
        return pseudorandom_element(enhancement_pool)
    end,

    calculate = function(self, card, context)
        if context.before and not context.blueprint then
            for _, scored_card in ipairs(context.scoring_hand) do
                scored_card:set_ability(self._get_random_enhancement(), nil, true)
                G.E_MANAGER:add_event(Event({
                    func = function()
                        scored_card:juice_up()
                        return true
                    end
                }))
            end
            return {
                message = 'Enhanced',
                colour = G.C.PURPLE
            }
        end
    end
}

-- The Razor
SMODS.Joker {
    key = "razor",
    pool = "joker",
    blueprint_compat = true,
    rarity = 3,
    cost = 8,
    pos = {
        x = 2,
        y = 0
    },
    eternal_compat = true,
    unlocked = true,
    discovered = false,
    atlas = 'SlayThePrincess',
    config = {
        extra = {
            chips = 0,
            chip_mod = 25
        }
    },
    loc_txt = {
        name = "The Razor",
        text = {"Destroy {C:attention}Kings{} and {C:attention}Jacks{} after", "they score, then gain",
                "{C:chips}+#2#{} Chips for each destroyed", "{C:inactive}(Currently {C:chips}+#1#{C:inactive} Chips)"}
    },

    loc_vars = function(self, info_queue, card)
        return {
            vars = {card.ability.extra.chips, card.ability.extra.chip_mod}
        }
    end,

    calculate = function(self, card, context)
        if context.destroy_card and not context.blueprint then
            for _, hand_card in ipairs(context.scoring_hand) do
                if context.destroy_card == hand_card then
                    local id = hand_card:get_id()
                    if id == 11 or id == 13 then
                        card.ability.extra.chips = card.ability.extra.chips + card.ability.extra.chip_mod
                        return {
                            remove = true,
                            message = localize('k_upgrade_ex'),
                            colour = G.C.CHIPS,
                            play_sound('slice1', 0.96 + math.random() * 0.08)
                        }
                    end
                end
            end
        end
        if context.joker_main then
            return {
                chips = card.ability.extra.chips
            }
        end
    end
}

-- The Apotheosis
SMODS.Joker {
    key = "apotheosis",
    pool = "joker",
    blueprint_compat = true,
    rarity = 3,
    cost = 9,
    pos = {
        x = 5,
        y = 1
    },
    eternal_compat = true,
    unlocked = true,
    discovered = false,
    atlas = 'SlayThePrincess',
    loc_txt = {
        name = "The Apotheosis",
        text = {"If played {C:attention}poker hand{} contains", "a {C:attention}Queen{}, upgrade level of",
                "played {C:attention}poker hand"}
    },

    calculate = function(self, card, context)
        if context.before then
            local has_queen = false
            for _, hand_card in ipairs(context.scoring_hand) do
                if hand_card:get_id() == 12 then
                    has_queen = true
                end
            end
            if has_queen then
                return {
                    level_up = true,
                    message = localize('k_level_up_ex')
                }
            end
            return {
                message = 'No queens'
            }
        end
    end
}

-- The Princess and the Dragon
SMODS.Joker {
    key = "dragon",
    pool = "joker",
    blueprint_compat = true,
    rarity = "stp_pristine",
    cost = 14,
    pos = {
        x = 0,
        y = 2
    },
    eternal_compat = true,
    unlocked = true,
    discovered = false,
    atlas = 'SlayThePrincess',
    config = {
        extra = {
            chips = 0,
            chip_mod = 25
        }
    },

    _count_scoring_queens = function(context)
        local n = 0
        for _, hand_card in ipairs(context.scoring_hand) do
            if hand_card and hand_card.get_id and hand_card:get_id() == 12 then
                n = n + 1
            end
        end
        return n
    end,

    _count_scoring_non_queens = function(context)
        local n = 0
        for _, hand_card in ipairs(context.scoring_hand) do
            if hand_card and hand_card.get_id and hand_card:get_id() ~= 12 then
                n = n + 1
            end
        end
        return n
    end,

    loc_txt = {
        name = "The Princess and the Dragon",
        text = {"For each scoring {C:attention}Queen{}, retrigger", "every scoring {C:attention}non-Queen{}, and",
                "for each scoring {C:attention}non-Queen{},", "retrigger every scoring {C:attention}Queen{}"}
    },

    calculate = function(self, card, context)
        if context.repetition and context.cardarea == G.play then
            scoring_queens = self._count_scoring_queens(context)
            scoring_non_queens = self._count_scoring_non_queens(context)
            if context.other_card:get_id() == 12 then return { repetitions = scoring_non_queens } end
            if context.other_card:get_id() ~= 12 then return { repetitions = scoring_queens } end
        end
    end
}

-- The Shifting Mound
SMODS.Joker {
    key = "shifty",
    pool = "joker",
    blueprint_compat = true,
    rarity = 4,
    cost = 20,
    pos = {
        x = 4,
        y = 0
    },
    eternal_compat = true,
    unlocked = true,
    discovered = false,
    atlas = 'SlayThePrincess',
    config = {
        extra = {
            xmult = 0
        }
    },
    loc_txt = {
        name = "The Shifting Mound",
        text = {"{X:red,C:white} X1 {} Mult for each", "{C:attention}Princess Joker{} you have",
                "{C:inactive}(Currently {X:red,C:white} X#1# {C:inactive})"}
    },

    _count_princesses = function()
        local n = 0
        if not G.jokers then
            return 1
        end
        for _, j in ipairs(G.jokers.cards or {}) do
            local center = j.config and j.config.center
            if center and center.atlas == 'SlayThePrincess' then
                n = n + 1
            end
        end
        return n
    end,

    loc_vars = function(self, info_queue, card)
        card.ability.extra.xmult = self._count_princesses()
        return {
            vars = {card.ability.extra.xmult}
        }
    end,

    calculate = function(self, card, context)
        if context.joker_main then
            return {
                xmult = self._count_princesses()
            }
        end
    end
}
----------------------------------------------
------------MOD CODE END----------------------
