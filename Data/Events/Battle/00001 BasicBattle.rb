Battle::Scene.register_event(:battle_begin) do |scene|
    scene.show_wild_event_message(("A battle begins!")) # It's calling scene.visual.lock ;)
end