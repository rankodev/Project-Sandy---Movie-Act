Battle::Scene.register_event(:AI_force_action) do |scene, ai, index|
    next nil if ai.bank == 0
    next [ai.trigger, ai.trigger].flatten
  end

Battle::Scene.register_event(:logic_init) do |scene|
  pokemon = scene.logic.battler(1, 0)
    def pokemon.level_pokemon_number
      "???".to_s.to_pokemon_number
    end
end

Battle::Scene.register_event(:battle_begin) do |scene|
  scene.show_wild_event_message("It's an ambush! The enemy has the upper hand!")

  move = Battle::Move[:s_torment].new(:torment, 1, 1, scene)
  action1 = Battle::Actions::Attack.new(scene, move, scene.logic.battler(1, 0), 0, 0)

  move = Battle::Move[:s_torment].new(:torment, 1, 1, scene)
  action2 = Battle::Actions::Attack.new(scene, move, scene.logic.battler(1, 0), 0, 1)

  action1.execute
  action2.execute
end