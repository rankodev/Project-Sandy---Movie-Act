module PSMA
  # Script adding the Player Choice UI
  # To call this script, you simply add the following in a script command
  # ```ruby
  # $game_temp.player_choice_calling = true
  # ```
  # When the message is done it'll call the scene and the result will be stored in variable 111
  #
  # Note: If you want to keep the message asking for the face on the screen, I guess you can add this script before message:
  # ```ruby
  # $scene.message_window.stay_visible = true
  # ```
  class PlayerChoice < GamePlay::BaseCleanUpdate
    # List of available starts
    STARTERS = %w[bulbasaur cyndaquil treecko snivy froakie rowlet scorbunny quaxly]# zorua espurr rockruff]
    # List of emotions we want to show
    EMOTIONS = %w[neutral joy]
    # List of Face X position
    FACE_X_POSITION = [-26, 36, 78, 160, 242, 284, 346]
    # List of Face Y position
    FACE_Y_POSITION = [185, 180, 175, 160, 175, 180, 185]
    # List of Face Zoom
    FACE_ZOOM = [0.25, 0.25, 0.5, 1, 0.5, 0.25, 0.25]
    # List of opacities
    FACE_OPACITY = [0, 200, 255, 255, 255, 200, 0]
    # Duration for movement
    MOVE_DURATION = 0.2

    def initialize
      super
      @index = 0
      @emotion_index = 0
    end

    # Skip other updates if blocking animations are playing
    def message_processing?
      return true if super
      return true if @animation && !@animation.done?
      return false
    end

    # Update inputs
    def update_inputs
      return action_lr(-1) if Input.press?(:LEFT)
      return action_lr(1) if Input.press?(:RIGHT)
      return automatic_input_update
    end

    def action_a
      log_debug("Selecting: #{STARTERS[@index]}")
      # TODO: Add a message?
      $game_variables[111] = @index
      # We can also store emotion into another variable, I need ID
      @running = false
      # TODO: Add a go out animation
    end

    # Action triggered when pressing LEFT or RIGHT
    # @param direction [Integer] direction of the press -1 for left, 1 for right
    def action_lr(direction)
      load_face(@faces[0], @index + direction * 3)
      @index = (@index + direction) % STARTERS.size
      base = base_rotation_animation(direction)
      @animation = Yuki::Animation.parallel(base, *@faces.map.with_index { |sp, i| face_move_rl(sp, i, i - direction) })
      @animation.start
    end

    # Create the animation that serves as a base for the parallel rotation animation
    # @param direction [Integer] direction of the rotation
    # @return [Yuki::Animation::Player]
    def base_rotation_animation(direction)
      ya = Yuki::Animation
      return ya.player(
        ya.wait(MOVE_DURATION),
        ya.send_command_to(@faces, :rotate!, direction)
      )
    end

    # Create the animation moving a face sprite left or right
    # @param sp [Sprite]
    # @param i [Integer]
    # @param next_index [Integer]
    def face_move_rl(sp, i, next_index)
      ya = Yuki::Animation
      next_index %= FACE_X_POSITION.size
      return ya.parallel(
        ya.move(MOVE_DURATION, sp, FACE_X_POSITION[i], FACE_Y_POSITION[i], FACE_X_POSITION[next_index], FACE_Y_POSITION[next_index]),
        ya.scalar(MOVE_DURATION, sp, :zoom=, FACE_ZOOM[i], FACE_ZOOM[next_index]),
        ya.opacity_change(MOVE_DURATION, sp, FACE_OPACITY[i], FACE_OPACITY[next_index])
      )
    end

    # Update all the animations
    def update_graphics
      @animation&.update
      @emotion_animation&.update if !@animation || @animation.done?
    end

    # Create all the sprite / animation for that scene
    def create_graphics
      super
      create_background
      create_faces
      create_enter_animation
      create_emotion_animation
    end

    def create_background
      # TODO: Add specific background if needed
    end

    # Create all the face sprites
    def create_faces
      @faces = 7.times.map do |i| 
        sp = load_face(Sprite.new(@viewport), i - 3)
        sp.opacity = 0
        sp.ox = sp.width / 2
        sp.oy = sp.height
        sp.zoom = FACE_ZOOM[i]
        next sp
      end
    end

    # Create the animation of all the face entering the scene
    def create_enter_animation
      ya = Yuki::Animation
      @animation = ya.parallel(ya.wait(0.5), *@faces.map.with_index { |sp, i| face_enter_animation(sp, i) })
      @animation.start
    end

    # @param sp [Sprite]
    # @param i [Integer]
    def face_enter_animation(sp, i)
      ya = Yuki::Animation
      return ya.parallel(
        ya.move(0.5, sp, FACE_X_POSITION[i], 300, FACE_X_POSITION[i], FACE_Y_POSITION[i]),
        ya.opacity_change(0.5, sp, 0, FACE_OPACITY[i])
      )
    end

    # Create the emotion index rotation animation
    # Note: If this is bad, we can simply remove that.
    def create_emotion_animation
      ya = Yuki::Animation
      @emotion_animation = ya.timed_loop_animation(2, [ya.wait(1.8), ya.send_command_to(self, :rotate_emotion)])
      @emotion_animation.start
    end

    # Function rotating the emotion index
    def rotate_emotion
      @emotion_index = (@emotion_index + 1) % EMOTIONS.size
      @faces.each_with_index { |sp, i| load_face(sp, i + @index - 3)}
    end

    # @param sp [Sprite] sprite to set
    # @param index [Integer] index of the start to load
    # @return [Sprite]
    def load_face(sp, index)
      emotion = EMOTIONS[@emotion_index]
      starter = STARTERS[index % STARTERS.size]
      return sp.load("portraits/#{starter}_#{emotion}", :picture)
    end
  end
end

class Game_Temp
  # @return [Boolean]
  attr_accessor :player_choice_calling
end

class Scene_Map
  add_call_scene(:call_player_choice) { $game_temp.player_choice_calling }

  private

  def call_player_choice
    $game_temp.player_choice_calling = false
    call_scene(PSMA::PlayerChoice)
  end
end
