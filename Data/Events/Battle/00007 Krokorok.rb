Battle::Scene.register_event(:logic_init) do |scene|
  pokemon = scene.logic.battler(1, 0)
    def pokemon.level_pokemon_number
      "???".to_s.to_pokemon_number
    end
end

Battle::Scene.register_event(:battle_begin) do |scene|
scene.show_wild_event_message("Warning! A dangerous opponent approaches!")
  scene.visual.lock do
    @pic = Ranko::GifSprite.new($scene.viewport, 'krokorok.gif')
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
  scene.show_wild_event_message("All right, you two idiots wanna be moral do-gooders? You're really going to push me this far?!") # It's calling scene.visual.lock ;)
  scene.visual.wait_for_animation
  @pic.dispose

  scene.visual.lock do
    @pic = Ranko::GifSprite.new($scene.viewport, 'sobble_confused.gif')
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
  scene.show_wild_event_message("I think it's perfectly reasonable to--") # It's calling scene.visual.lock ;)
  scene.visual.wait_for_animation
  @pic.dispose

  scene.visual.lock do
    @pic = Ranko::GifSprite.new($scene.viewport, 'krokorok.gif')
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
  scene.show_wild_event_message("Shut up, nerd!") # It's calling scene.visual.lock ;)
  scene.visual.wait_for_animation
  @pic.dispose

  move = Battle::Move[:s_torment].new(:torment, 1, 1, scene)
  action1 = Battle::Actions::Attack.new(scene, move, scene.logic.battler(1, 0), 0, 0)

  move = Battle::Move[:s_torment].new(:torment, 1, 1, scene)
  action2 = Battle::Actions::Attack.new(scene, move, scene.logic.battler(1, 0), 0, 1)

  action2.execute
end

Battle::Scene.register_event(:trainer_dialog) do |scene|
  next if $game_temp.battle_turn != 3 # 1 = first turn

  scene.visual.lock do
    @pic = Ranko::GifSprite.new($scene.viewport, 'krokorok.gif')
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
  scene.show_wild_event_message("It's time everyone! Get in here and pile on!") 
  scene.visual.wait_for_animation
  @pic.dispose

  scene.visual.lock do
    @pic = Ranko::GifSprite.new($scene.viewport, 'sandiles.gif')
    @pic.set_position(0, -20)
    @pic.set_z(20_000)
    @pic.visible = true
    Graphics.sort_z
    anim = Yuki::Animation
    animation = anim.send_command_to(@pic, :update)
    150.times do
      animation.play_before(anim.wait(0.01))
      animation.play_before(anim.send_command_to(@pic, :update))
    end
    animation.start
    scene.visual.animations << animation
  end
  scene.show_wild_event_message("Yeah!") 
  scene.visual.wait_for_animation
  @pic.dispose
  move = Battle::Move[:s_five_times].new(:sandile_pile, 1, 1, scene)
  action = Battle::Actions::Attack.new(scene, move, scene.logic.battler(1, 0), 0, rand(2))
  action.execute
  scene.visual.wait_for_animation
  @pic.dispose
end

