Battle::Scene.register_event(:battle_begin) do |scene|
  scene.show_wild_event_message("Warning! Dangerous opponents approach!")
end

Battle::Scene.register_event(:AI_force_action) do |scene, ai, index|
  next if $game_temp.battle_turn != 1 # 1 = first turn

  launcher = scene.logic.battler(1,1)

  move1 = Battle::Move[:s_hit_and_run].new(:hit_and_run, 1, 1, scene)
  move2 = launcher.moveset[0]
  
  sneasel_action = Battle::Actions::Attack.new(scene, move1, scene.logic.battler(1, 0), 0, 1)

  sandslash_action = Battle::Actions::Attack.new(scene, move2, launcher, 0, 0)

  next [sneasel_action, sandslash_action]
end