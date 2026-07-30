Battle::Scene.register_event(:logic_init) do |scene|
    pokemon1 = scene.logic.battler(1, 0)
    pokemon2 = scene.logic.battler(1, 1)
    pokemon3= scene.logic.battler(0, 0)
    def pokemon1.level_pokemon_number
      "???".to_s.to_pokemon_number
    end
  
    def pokemon2.level_pokemon_number
      "???".to_s.to_pokemon_number
    end
end

Battle::Scene.register_event(:battle_begin) do |scene|
    scene.show_wild_event_message(("A battle begins!")) # It's calling scene.visual.lock ;)
end

Battle::Scene.register_event(:AI_force_action) do |scene, ai, index|
    next if index != 0 && ai.bank != 1
end