Battle::Scene.register_event(:logic_init) do |scene|
    pokemon1 = scene.logic.battler(1, 0)

    def pokemon1.level_pokemon_number
      "???".to_s.to_pokemon_number
    end
  
    def pokemon1.given_name
      return "???"
    end
end

Battle::Scene.register_event(:battle_begin) do |scene|
  scene.show_wild_event_message("A rather lukewarm opponent approaches!")
  scene.show_wild_event_message("The enemy was caught off guard and is unable to attack!")
end

