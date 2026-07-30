Battle::Scene.register_event(:logic_init) do |scene|
  pokemon = scene.logic.battler(1, 0)
  def pokemon.level_pokemon_number
    "???".to_s.to_pokemon_number
  end
end

Battle::Scene.register_event(:battle_begin) do |scene|
  scene.show_wild_event_message("A rather lukewarm opponent approaches!")
    scene.show_wild_event_message("The enemy was caught off guard and is unable to attack!")
end

Battle::Scene.register_event(:AI_force_action) do |scene, ai, index|
  next []
end