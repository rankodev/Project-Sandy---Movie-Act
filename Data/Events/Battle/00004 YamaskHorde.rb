Battle::Scene.register_event(:AI_force_action) do |scene, ai, index|
  next nil if ai.bank == 0
  next [ai.trigger, ai.trigger].flatten
end

Battle::Scene.register_event(:battle_begin) do |scene|
  scene.visual.lock do
    @pic = Ranko::GifSprite.new($scene.viewport, 'yamask.gif')
    @pic.set_position(0, 0)
    @pic.set_z(20_000)
    @pic.visible = true
    Graphics.sort_z
    Audio.se_play('Audio/SE/562cryMulti.ogg')
    anim = Yuki::Animation
    animation = anim.send_command_to(@pic, :update)
    200.times do
      animation.play_before(anim.wait(0.01))
      animation.play_before(anim.send_command_to(@pic, :update))
    end
    animation.start
    scene.visual.animations << animation
  end
  scene.show_wild_event_message("It's a horde of aggressive Yamask!") # It's calling scene.visual.lock ;)
  scene.visual.wait_for_animation
  @pic.dispose
  scene.show_wild_event_message("They began to attack as one!")
end