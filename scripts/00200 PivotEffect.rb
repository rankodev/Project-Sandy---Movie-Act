module Battle 
    module Effects
    # Class describing the Pivot effect
        class Pivot < PokemonTiedEffectBase
            # Function called when a Pokemon has actually switched with another one
            # @param handler [Battle::Logic::SwitchHandler]
            # @param who [PFM::PokemonBattler] Pokemon that is switched out
            # @param with [PFM::PokemonBattler] Pokemon that is switched in
            def on_switch_event(handler, who, with)
                handler.logic.stat_change_handler.stat_change_with_process(:spd, 1, with)
            end
            # Function giving the name of the effect
            # @return [Symbol]
            def name
                return :pivot
            end
        end
    end
end