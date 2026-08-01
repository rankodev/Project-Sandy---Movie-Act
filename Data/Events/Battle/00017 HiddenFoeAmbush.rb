Battle::Scene.register_event(:logic_init) do |scene|
    # Method that call all the switch event for the Pokemon that entered the battle in the begining
    pokemon1 = scene.logic.battler(1, 0)
    pokemon2 = scene.logic.battler(1, 1)
    def pokemon1.level_pokemon_number
      "???".to_s.to_pokemon_number
    end
  
    def pokemon2.level_pokemon_number
      "???".to_s.to_pokemon_number
    end
  
    def pokemon1.given_name
      return "???"
    end
  
    def pokemon2.given_name
      return "???"
    end
    def scene.show_enter_event
      @logic.all_alive_battlers.sort_by(&:spd).reverse.each do |battler|
        @logic.switch_handler.execute_switch_events(battler, battler)
      end
      call_event(:battle_begin)
    end
  end

Battle::Scene.register_event(:battle_begin) do |scene|
    scene.show_wild_event_message("The enemy ambushed your team!")

    scene.show_wild_event_message("You were caught off guard!")
    move = Battle::Move[:s_basic].new(:surf, 1, 1, scene)
    action1 = Battle::Actions::Attack.new(scene, move, scene.logic.battler(1, 0), 0, 0)

    move = Battle::Move[:s_basic].new(:muddy_water, 1, 1, scene)
    action2 = Battle::Actions::Attack.new(scene, move, scene.logic.battler(1, 0), 0, 1)
    
    action1.execute
    action2.execute

    flee_action = Battle::Actions::Flee.new(scene, scene.logic.battler(1, 0))

    def flee_action.execute(from_scene = false)
      if from_scene
        execute_from_scene
      elsif @scene.logic.switch_handler.can_switch?(@target)
        @scene.logic.battle_result = @target.bank == 0 ? 1 : 3
        @scene.next_update = :battle_end
      end
    end

    flee_action.execute
    battler_s = scene.visual.battler_sprite(1,0)
    battler_s.flee_animation
    scene.visual.wait_for_animation
    scene.next_update = :battle_end
    scene.show_wild_event_message("The enemy left the battle!")
end