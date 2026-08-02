Battle::Scene.register_event(:logic_init) do |scene|
    pokemon1 = scene.logic.battler(1, 0)

    def pokemon1.level_pokemon_number
      "???".to_s.to_pokemon_number
    end

end

Battle::Scene.register_event(:battle_begin) do |scene|
  scene.show_wild_event_message("A rather lukewarm opponent approaches!")
end

Battle::Scene.register_event(:AI_force_action) do |scene, ai, index|
    next nil if ai.bank == 0
    next [ai.trigger, ai.trigger].flatten
  end