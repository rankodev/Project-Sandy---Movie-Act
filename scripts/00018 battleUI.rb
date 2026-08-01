module BattleUI
    #HP Bars
  class InfoBar < UI::SpriteStack
    # The information of the HP Bar # bw, bh, bx, by, nb_states
    HP_BAR_INFO = [65, 4, 0, 0, 6]
    def create_hp
      hp_background_filename = !enemy? && $game_switches[902] ? 'battle/battlebar_3v3' : 'battle/battlebar_'
      hp_bar_filename = !enemy? && $game_switches[902] ? 'battle/bars_hp_3v3' : 'battle/bars_hp'

      @hp_background = add_sprite(*hp_background_coordinates, hp_background_filename)
      # @type [UI::Bar]
      @hp_bar = push_sprite Bar.new(@viewport, *hp_bar_coordinates, RPG::Cache.interface(hp_bar_filename), *HP_BAR_INFO)
      @hp_bar.data_source = :hp_rate
      @hp_text = add_text(36, 20, 0, 10, (enemy? || $game_switches[902]) ? :void_string : :hp_pokemon_number, type: SymText, color: 10)
    end
    # The information of the Exp Bar # bw, bh, bx, by, nb_states
    EXP_BAR_INFO = [16, 1, 0, 0, 1]
    def create_exp
      return if enemy? || $game_switches[902]

      add_sprite(90, 30, 'battle/battlebar_exp')
      # @type [UI::Bar]
      @exp_bar = push_sprite Bar.new(@viewport, 91, 31, RPG::Cache.interface('battle/bars_exp'), *EXP_BAR_INFO)
      @exp_bar.data_source = :exp_rate
    end
    #Picture InfoBar Enemy and then Player
    def base_position_v1
      return 16, 9 if enemy?

      return 184, 127
    end

    # 2v2
    def base_position_v2
        return 0, 20 if enemy? && $game_switches[498] #2v1
        return 0, 15 if enemy?

        return 180, 110
    end
    
    def base_position_v3
        return 0, 20 if enemy? && $game_switches[498] #2v1
        return 0, 15 if enemy?

        return 220, 110
    end    

    # Second Pokemon in 2v2 HP Bar
    def offset_position_v2
      return 12, 30 if enemy?

      return 12, 38
    end

        # Second Pokemon in 3v3 HP Bar
    def offset_position_v3
      return 12, 30 if enemy?

      return -7, 25
    end

    #Custom HP Bar Coordinates Enemy -> Player
    def hp_background_coordinates
      return enemy? ? [36, 15] : [32, 15]
    end

    def hp_bar_coordinates
      return [x + 49, y + 16] if enemy?

      return $game_switches[902] ? [x + 42, y + 1] : [x + 45, y + 16]
    end

    def create_name
      with_font(20) do
        enemy? ? (@name = add_text(17, -2, 0, 16, :given_name, 0, 1, color: 10, type: SymText)) : (@name = add_text(12, -2, 0, 16, :given_name, 0, 1, color: 10, type: SymText))
      end
    end

    def create_catch_sprite
      add_sprite(116, 13, 'battle/ball', type: PokemonCaughtSprite)
    end

    def create_gender_sprite
      enemy? ? (add_sprite(70, -1, NO_INITIAL_IMAGE, type: GenderSprite)) : (add_sprite($game_switches[902] ? 42 : 67, -1, NO_INITIAL_IMAGE, type: GenderSprite))
    end

    def create_level
      enemy? ? (add_text(104, -4, 0, 16, :level_pokemon_number, 0, 1, color: 37, type: SymText)) : (add_text($game_switches[902] ? 73 : 100, -4, 4, 16, :level_pokemon_number, 0, 1, color: 37, type: SymText))
    end

    def create_status
      enemy? ? (add_sprite(8, 12, NO_INITIAL_IMAGE, type: StatusSprite)) : (add_sprite(8, 12, NO_INITIAL_IMAGE, type: StatusSprite))
    end
  end
end