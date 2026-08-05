module BattleUI
  module SkillChoiceAbstraction
    # Ensure default values are set for the UI to allow the targeting interface to be displayed.
    # @param pokemon [PFM::PokemonBattler]
    # @param move [Battle::Move]
    def attack_item(pokemon, move)
      @pokemon = pokemon
      @mega_enabled = false
      @index = @last_indexes[pokemon].to_i.clamp(0, max_index)
      @result = move
    end
  end
end
