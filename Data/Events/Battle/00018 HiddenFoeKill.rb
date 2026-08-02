Battle::Scene.register_event(:logic_init) do |scene|
  pokemon1 = scene.logic.battler(1, 0)
  pokemon2 = scene.logic.battler(1, 1)
  def pokemon1.level_pokemon_number
    "???".to_s.to_pokemon_number
  end

  def pokemon2.level_pokemon_number
    "???".to_s.to_pokemon_number
  end

  def pokemon1.given_name
    return "???"
  end

  def pokemon2.given_name
    return "???"
  end
end
  
Battle::Scene.register_event(:battle_begin) do |scene|
  scene.show_wild_event_message("The enemy has the upper hand!")

  scene.artificial_intelligences.each do |ai|
      move = Battle::Move[:s_basic].new(:surf, 10, 10, scene)
      action1 = Battle::Actions::Attack.new(scene, move, scene.logic.battler(1, 0), 0, 0)
    
      move = Battle::Move[:s_basic].new(:muddy_water, 10, 10, scene)
      action2 = Battle::Actions::Attack.new(scene, move, scene.logic.battler(1, 0), 0, 1)
      
      action1.execute
      action2.execute
  end

  scene.visual.lock do
    @pic = Ranko::GifSprite.new($scene.viewport, 'ledian_shout.gif')
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
  scene.show_wild_event_message("Wait just a second!") # It's calling scene.visual.lock ;)
  scene.visual.wait_for_animation
  @pic.dispose

  scene.visual.lock do
    @pic = Ranko::GifSprite.new($scene.viewport, 'ledian_shout.gif')
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
  scene.show_wild_event_message("I'm not letting you run this time!") # It's calling scene.visual.lock ;)
  scene.visual.wait_for_animation
  @pic.dispose

  scene.show_wild_event_message("Lumi blocked the enemy's escape route!")
  scene.show_wild_event_message("The enemy kept trying anyway.")

    scene.artificial_intelligences.each do |ai|
      move = Battle::Move[:s_basic].new(:slam, 10, 10, scene)
      action1 = Battle::Actions::Attack.new(scene, move, scene.logic.battler(1, 0), 0, 3)
      
      action1.execute
      action1.execute
    end
   scene.visual.lock do
    @pic = Ranko::GifSprite.new($scene.viewport, 'ledian_beaten.gif')
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
  scene.show_wild_event_message("Agh...!") # It's calling scene.visual.lock ;)
  scene.visual.wait_for_animation
  @pic.dispose

    scene.visual.lock do
    @pic = Ranko::GifSprite.new($scene.viewport, 'ledian_beaten.gif')
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
  scene.show_wild_event_message("Is...") # It's calling scene.visual.lock ;)
  scene.visual.wait_for_animation
  @pic.dispose
  scene.visual.lock do
    @pic = Ranko::GifSprite.new($scene.viewport, 'ledian_shout.gif')
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
  scene.show_wild_event_message("Is that all you got?!") # It's calling scene.visual.lock ;)
  scene.visual.wait_for_animation
  @pic.dispose

  scene.show_wild_event_message("The battle continues!")
end