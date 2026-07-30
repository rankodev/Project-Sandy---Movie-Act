Battle::Scene.register_event(:logic_init) do |scene|
  pokemon = scene.logic.battler(1, 0)
  def pokemon.level_pokemon_number
    "???".to_s.to_pokemon_number
  end
end

Battle::Scene.register_event(:battle_begin) do |scene|
  scene.show_wild_event_message("Warning! A dangerous opponent approaches!")
end

