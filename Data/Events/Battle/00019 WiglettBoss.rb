Battle::Scene.register_event(:logic_init) do |scene|
    pokemon1 = scene.logic.battler(1, 0)

    def pokemon1.level_pokemon_number
      "???".to_s.to_pokemon_number
    end

end

Battle::Scene.register_event(:battle_begin) do |scene|
  scene.show_wild_event_message("A dangerous opponent approaches!")

    scene.visual.lock do
    @pic = Ranko::GifSprite.new($scene.viewport, 'sobble_confused2.gif')
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
  scene.show_wild_event_message("I'm getting a little bit of deja vu here.") # It's calling scene.visual.lock ;)
  scene.visual.wait_for_animation
  @pic.dispose

      scene.visual.lock do
    @pic = Ranko::GifSprite.new($scene.viewport, 'wigletts.gif')
    @pic.set_position(0, -20)
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
  scene.show_wild_event_message("My combination attacks will be unparalleled across the lands!") # It's calling scene.visual.lock ;)
  scene.visual.wait_for_animation
  @pic.dispose
end

Battle::Scene.register_event(:AI_force_action) do |scene, ai, index|
    next nil if ai.bank == 0
    next [ai.trigger, ai.trigger].flatten
  end