module Battle
  class Visual
    # Set the attack item move on the skill choice UI without showing it
    # @param pokemon_index [Integer] Index of the Pokemon in the party
    # @param move [Battle::Move] The move to use
    # @return [true]
    def show_item_skill_choice(pokemon_index, move)
      pokemon = @scene.logic.battler(0, pokemon_index)
      @skill_choice_ui.attack_item(pokemon, move)
      return true
    end
  end
end
