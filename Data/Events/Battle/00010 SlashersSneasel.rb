Battle::Scene.register_event(:logic_init) do |scene|
  pokemon = scene.logic.battler(1, 0)
  def pokemon.level_pokemon_number
    "???".to_s.to_pokemon_number
  end
end

Battle::Scene.register_event(:battle_begin) do |scene|
  scene.show_wild_event_message("Warning! A dangerous opponent approaches!")
end

Battle::Scene.register_event(:trainer_dialog) do |scene|
  next unless $game_temp.battle_turn == 2

  scene.visual.lock do
    @pic = Ranko::GifSprite.new($scene.viewport, 'sneasel_inspired.gif')
    @pic.set_position(20, 133)
    @pic.set_z(20_000)
    @pic.visible = true
    Graphics.sort_z
    anim = Yuki::Animation
    animation = anim.send_command_to(@pic, :update)
    20.times do
      animation.play_before(anim.wait(0.01))
      animation.play_before(anim.send_command_to(@pic, :update))
    end
    animation.start
    scene.visual.animations << animation
  end
  scene.show_wild_event_message("Interesting...")
  scene.visual.wait_for_animation
  @pic.dispose

  scene.visual.lock do
    @pic = Ranko::GifSprite.new($scene.viewport, 'sneasel_joyous.gif')
    @pic.set_position(20, 133)
    @pic.set_z(20_000)
    @pic.visible = true
    Graphics.sort_z
    anim = Yuki::Animation
    animation = anim.send_command_to(@pic, :update)
    20.times do
      animation.play_before(anim.wait(0.01))
      animation.play_before(anim.send_command_to(@pic, :update))
    end
    animation.start
    scene.visual.animations << animation
  end
  scene.show_wild_event_message("Okay, that's enough information for me!")
  scene.show_wild_event_message("Later losers!")
  scene.visual.wait_for_animation
  @pic.dispose

  trainer_team = scene.logic.alive_battlers(1).select { |pokemon| pokemon.status? || pokemon.hp < pokemon.max_hp }
  
  trainer_team.select(&:status?).each do |pokemon|
    pokemon.cure
    scene.show_wild_event_message("Sneasel chomped down on a Lum Berry!")
    # @type [BattleUI::InfoBar]
    bar = scene.visual.refresh_info_bar(pokemon)
    bar&.refresh
    return log_error("No battle bar at position #{pokemon.bank}, #{pokemon.position}") unless bar
    bar.refresh
  end

  flee_action = Battle::Actions::Flee.new(scene, scene.logic.battler(1, 0))
  def flee_action.execute(from_scene = false)
    if from_scene
      execute_from_scene
    elsif @scene.logic.switch_handler.can_switch?(@target)
      @scene.logic.battle_result = @target.bank == 0 ? 1 : 3
      @scene.next_update = :battle_end
    end
  end
  
  flee_action.execute
  battler_s = scene.visual.battler_sprite(1,0)
  battler_s.flee_animation
  scene.visual.wait_for_animation
  scene.next_update = :battle_end
end