module Battle
  class Logic
    # Return the adjacent foes
    # @param pokemon [PFM::PokemonBattler]
    # @return [Array<PFM::PokemonBattler>]
    def adjacent_foes_of(pokemon)
      return foes_of(pokemon, false) if @battle_info.vs_type == 3
      
      return foes_of(pokemon, true)
    end
  end
end