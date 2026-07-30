Battle::Scene.register_event(:battle_begin) do |scene|
  scene.show_wild_event_message("Warning! A dangerous opponent approaches!")
end

