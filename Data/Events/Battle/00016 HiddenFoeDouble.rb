Battle::Scene.register_event(:logic_init) do |scene|
  pokemon1 = scene.logic.battler(1, 0)
  pokemon2 = scene.logic.battler(1, 1)
  def pokemon1.level_pokemon_number
    "???".to_s.to_pokemon_number
  end

  def pokemon2.level_pokemon_number
    "???".to_s.to_pokemon_number
  end
end

Battle::Scene.register_event(:battle_begin) do |scene|
  scene.show_wild_event_message("Warning! A dangerous opponent approaches!")
end

