-- Plasma balancing code mostly copy-pasted from back.lua (108). Due to the method being written poorly, this must be reinjected, but modified to only affect decks with "config.plasma_balancing = true"
local Backtrigger_effectRef = Back.trigger_effect
function Back:trigger_effect(args)

    -- Preserve original variable calculations to not break Plasma Deck
    local chips, mult = Backtrigger_effectRef(self, args)
    if not args then
        return chips, mult
    end
    -- Replace "name" == 'Plasma Deck' with a better version
    if self.effect.config.plasma_balancing and args.context == 'blind_amount' then
        return
    end
    -- Again here
    if self.effect.config.plasma_balancing and args.context == 'final_scoring_step' then
        local tot = args.chips + args.mult
        args.chips = math.floor(tot/2)
        args.mult = math.floor(tot/2)
        update_hand_text({delay = 0}, { mult = args.mult, chips = args.chips})

        G.E_MANAGER:add_event(Event({
            func = (function()
                local text = localize('k_balanced')
                play_sound('gong', 0.94, 0.3)
                play_sound('gong', 0.94*1.5, 0.2)
                play_sound('tarot1', 1.5)
                ease_colour(G.C.UI_CHIPS, {0.8, 0.45, 0.85, 1})
                ease_colour(G.C.UI_MULT, {0.8, 0.45, 0.85, 1})
                attention_text({
                    scale = 1.4, text = text, hold = 2, align = 'cm', offset = {x = 0,y = -2.7},major = G.play
                })

                G.E_MANAGER:add_event(Event({
                    trigger = 'after',
                    blockable = false,
                    blocking = false,
                    delay =  4.3,
                    func = (function()
                        ease_colour(G.C.UI_CHIPS, G.C.BLUE, 2)
                        ease_colour(G.C.UI_MULT, G.C.RED, 2)
                        return true
                    end)
                }))

                G.E_MANAGER:add_event(Event({
                    trigger = 'after',
                    blockable = false,
                    blocking = false,
                    no_delete = true,
                    delay =  6.3,
                    func = (function()
                        G.C.UI_CHIPS[1], G.C.UI_CHIPS[2], G.C.UI_CHIPS[3], G.C.UI_CHIPS[4] = G.C.BLUE[1], G.C.BLUE[2], G.C.BLUE[3], G.C.BLUE[4]
                        G.C.UI_MULT[1], G.C.UI_MULT[2], G.C.UI_MULT[3], G.C.UI_MULT[4] = G.C.RED[1], G.C.RED[2], G.C.RED[3], G.C.RED[4]
                        return true
                    end)
                }))
                return true
            end)
        }))
        delay(0.6)
        -- Preserve original variable calculations to not break Plasma Deck
        chips, mult = args.chips, args.mult
    end
    return chips, mult

end

-- Code we have to inject into the run directly right after deck is selected
local Backapply_to_runRef = Back.apply_to_run
function Back.apply_to_run(arg_56_0)
    Backapply_to_runRef(arg_56_0)

    -- Immediately ban all of the things in the current deck's "config.ban_keys" table (when appplicable), so the game hasn't even loaded Tags yet
    --This is why the event is blocked out; method would would never ban the Tags if done within the Balatro event handler... :(
    --(Shop should not need a reload, as we have not yet instantiated it)
    if arg_56_0.effect.config.ban_keys then
        --[[    G.E_MANAGER:add_event(Event({
            blockable = false,
            blocking = true,
            func = function()    ]]
                print('[nPD] Custom Deck selected! banning cards...')
                for _, v in ipairs(arg_56_0.effect.config.ban_keys) do
                    G.GAME.banned_keys[v.id] = true
                end
                print('[nPD] DONE!')
                return true
            --[[    end
        }))    ]]
    end

end


-- Load decks
local nativefs = require("nativefs")
-- Dynamically get all files within the decks subfolder, to then load automatically
local deck_subpath = "decks/"
local naneinf_decks_path = SMODS.current_mod.path .. deck_subpath
local naneinf_decks_table = nativefs.getDirectoryItems(naneinf_decks_path)

for _, custom_naneinf_deck in ipairs(naneinf_decks_table) do
    print("[nPD] Loading Deck: " .. custom_naneinf_deck)
    assert(SMODS.load_file(deck_subpath .. custom_naneinf_deck))()
end


-- Done, until one of these custom decks selected
print('[nPD] Mod loaded successfully!')
