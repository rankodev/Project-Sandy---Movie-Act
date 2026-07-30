Battle::Scene.register_event(:logic_init) do |scene|
  pokemon = scene.logic.battler(1, 0)
  def pokemon.level_pokemon_number
    "???".to_s.to_pokemon_number
  end

  def scene.questions
    return [
      {flavor: 'Your attempts to harm me thus far have been embarrasing.', question: 'In what manner do you believe the world will hold back against you?', answers: ["We'll have to become stronger", "Not everything is solved with violence"], right_answer: [0]},
      {flavor: 'But, here you are, fighting someone beyond your current capabilities.', question: "Are you willing to stay and fight with all your might?", answers: ["We'll fight no matter what", "We could run to fight another day"], right_answer: [0]},
      {flavor: 'Hear me, children.', question: 'Choose to open one of my hands, right now.', answers: ['Left!', 'Right!', 'Immediately attack'], right_answer: [2]},
    ]
  end

  scene.instance_variable_set(:@asked_questions, [])

end

Battle::Scene.register_event(:battle_begin) do |scene|
scene.show_wild_event_message("Warning! A dangerous opponent approaches!")
  scene.visual.lock do
    @pic = Ranko::GifSprite.new($scene.viewport, 'indeedee_neutral.gif')
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
  scene.show_wild_event_message("For many years I have tended to the stead of many agents of justice...") # It's calling scene.visual.lock ;)
  scene.visual.wait_for_animation
  @pic.dispose

  scene.visual.lock do
    @pic = Ranko::GifSprite.new($scene.viewport, 'indeedee_neutral.gif')
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
  scene.show_wild_event_message("I've nurtured the establishment that has become a beacon of hope and salvation for Pokémon all over the region.") # It's calling scene.visual.lock ;)
  scene.visual.wait_for_animation
  @pic.dispose

  scene.visual.lock do
    @pic = Ranko::GifSprite.new($scene.viewport, 'indeedee_neutral.gif')
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
  scene.show_wild_event_message("But, I see now that there is no outrunning what we have left behind.")
  scene.visual.wait_for_animation
  @pic.dispose

  scene.visual.lock do
    @pic = Ranko::GifSprite.new($scene.viewport, 'indeedee_neutral.gif')
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
  scene.show_wild_event_message("We must choose whether to be burdened by the chains of others or freed by the choices of our own.")
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
  scene.show_wild_event_message("What?") # It's calling scene.visual.lock ;)
  scene.visual.wait_for_animation
  @pic.dispose

  scene.visual.lock do
    @pic = Ranko::GifSprite.new($scene.viewport, 'indeedee_sigh.gif')
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
  scene.show_wild_event_message("Wrong answer.") # It's calling scene.visual.lock ;)
  scene.visual.wait_for_animation
  @pic.dispose

  move = Battle::Move[:s_terrain].new(:psychic_terrain, 1, 1, scene)
  action2 = Battle::Actions::Attack.new(scene, move, scene.logic.battler(1, 0), 0, 0)

  action2.execute
end

Battle::Scene.register_event(:trainer_dialog) do |scene|
  next unless $game_temp.battle_turn % 3 == 0
  
  trainer_team = scene.logic.alive_battlers(1).select { |pokemon| pokemon.status? || pokemon.hp < pokemon.max_hp }
  next if trainer_team.empty?
  
  trainer_team.select(&:status?).each do |pokemon|
    pokemon.cure
    scene.show_wild_event_message("Indeedee shrugged off his status!")
    # @type [BattleUI::InfoBar]
    bar = scene.visual.refresh_info_bar(pokemon)
    bar&.refresh
    return log_error("No battle bar at position #{pokemon.bank}, #{pokemon.position}") unless bar
    bar.refresh
  end
end

Battle::Scene.register_event(:AI_force_action) do |scene, ai, index|

  if $game_temp.battle_turn == 2
    asked_questions = scene.instance_variable_get(:@asked_questions)
    if asked_questions.size == scene.questions.size
      asked_questions = []
    end
  
    selected = scene.questions[0]
    asked_questions << selected
    scene.instance_variable_set(:@asked_questions, asked_questions)
  
    scene.visual.lock do
      @pic = Ranko::GifSprite.new($scene.viewport, 'indeedee_neutral.gif')
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
    scene.show_wild_event_message(selected[:flavor]) 
    scene.visual.wait_for_animation
  
    result = scene.show_wild_choice_message(selected[:question], 1, *selected[:answers])
    if selected[:right_answer].include?(result)
      scene.show_wild_event_message("You will simply promise yourselves to match the occasion? I see.")
      @pic.dispose
      class Battle::Effects::CrowdCheering < Battle::Effects::PositionTiedEffectBase
        # Create a new Pokemon tied effect
        # @param logic [Battle::Logic] logic used to get all the handler in order to allow the effect to work
        # @param bank [Integer] bank where the effect is tied
        # @param position [Integer] position where the effect is tied
        # @param turn_count [Integer] number of turn for the confusion (not including current turn)
        def initialize(logic, bank, position, turn_count = Float::INFINITY)
          super(logic, bank, position)
          self.counter = turn_count
        end
    
        def sp_def_multiplier(user, target, move)
          return 1 if target != @target
          return 1 unless user.can_be_lowered_or_canceled?

          return 1.5
        end
      end
      scene.show_wild_event_message("Indeedee seems to have weakened his attacks...!")
      scene.logic.bank_effects[0].add(Battle::Effects::CrowdCheering.new(scene.logic, 0, 0, Float::INFINITY))
      
    else
      scene.show_wild_event_message("You truly believe criminals are willing to play nicely? What a disappointing answer.")
      @pic.dispose
    end
  end

  if $game_temp.battle_turn == 4
    asked_questions = scene.instance_variable_get(:@asked_questions)
    if asked_questions.size == scene.questions.size
      asked_questions = []
    end
  
    selected = scene.questions[1]
    asked_questions << selected
    scene.instance_variable_set(:@asked_questions, asked_questions)
  
    scene.visual.lock do
      @pic = Ranko::GifSprite.new($scene.viewport, 'indeedee_neutral.gif')
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
    scene.show_wild_event_message(selected[:flavor]) 
    scene.visual.wait_for_animation
  
    result = scene.show_wild_choice_message(selected[:question], 1, *selected[:answers])
    if selected[:right_answer].include?(result)
      scene.show_wild_event_message("You would stay and fight? I see.")
      @pic.dispose
      class Battle::Effects::CrowdCheering < Battle::Effects::PositionTiedEffectBase
        # Create a new Pokemon tied effect
        # @param logic [Battle::Logic] logic used to get all the handler in order to allow the effect to work
        # @param bank [Integer] bank where the effect is tied
        # @param position [Integer] position where the effect is tied
        # @param turn_count [Integer] number of turn for the confusion (not including current turn)
        def initialize(logic, bank, position, turn_count = Float::INFINITY)
          super(logic, bank, position)
          self.counter = turn_count
        end
    
        def sp_def_multiplier(user, target, move)
          return 1 if target != @target
          return 1 unless user.can_be_lowered_or_canceled?

          return 2
        end
      end
      scene.show_wild_event_message("Indeedee seems to have weakened his attacks...!")
      scene.logic.bank_effects[0].add(Battle::Effects::CrowdCheering.new(scene.logic, 0, 0, Float::INFINITY))
    else
      scene.show_wild_event_message("You would so easily let such a criminal go? To endanger all who would become victims in the future? Pathetic.")
      @pic.dispose
    end
  end

  if $game_temp.battle_turn == 6
    
    next if index != 0
    
    asked_questions = scene.instance_variable_get(:@asked_questions)
  
    selected = scene.questions[2]
    asked_questions << selected
    scene.instance_variable_set(:@asked_questions, asked_questions)
  
    scene.visual.lock do
      @pic = Ranko::GifSprite.new($scene.viewport, 'indeedee_neutral.gif')
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
    scene.show_wild_event_message(selected[:flavor]) 
    scene.visual.wait_for_animation
  
    result = scene.show_wild_choice_message(selected[:question], 1, *selected[:answers])
    
    if selected[:right_answer].include?(result)
      scene.show_wild_event_message("?!")
      @pic.dispose
      scene.show_wild_event_message("The enemy was caught off guard! Indeedee's turn was skipped!")
      next []
    else
      scene.show_wild_event_message("You really couldn't resist playing such a simple game? You two really are children. Good-bye.")
      @pic.dispose

      scene.show_wild_event_message("You were caught off guard! Indeedee unleashed a barrage of attacks!")
      move = Battle::Move[:s_terrain].new(:psychic_terrain, 1, 1, scene)
      action1 = Battle::Actions::Attack.new(scene, move, scene.logic.battler(1, 0), 0, 0)
    
      move = Battle::Move[:s_expanding_force].new(:expanding_force, 1, 1, scene)
      action2 = Battle::Actions::Attack.new(scene, move, scene.logic.battler(1, 0), 0, 1)
      
      action1.execute
      action2.execute
    end
  end
end