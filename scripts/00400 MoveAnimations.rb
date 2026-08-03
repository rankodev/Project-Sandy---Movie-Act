module Battle
  # Module responsive of handling all move animation
  #
  # All animation will have the following values in their resolver:
  #   - :visual => Battle::Visual object
  #   - :user => BattleUI::PokemonSprite of the user of the move
  #   - :target => BattleUI::PokemonSprite of the target of the move (first if user animation, current if target animation)
  #   - :viewport => Viewport of the user sprite
  module MoveAnimation
    @specific_move_animations = {}
    @generic_move_animations = {}
    module_function
    # Function that store a specific move animation
    # @param move_db_symbol [Symbol]
    # @param animation_reason [Symbol]
    # @param animation_user [Yuki::AnimationMixin] unstarted animation of user that will be serialized
    # @param animation_target [Yuki::AnimationMixin] unstarted animation of target that will be serialized
    def register_specific_animation(move_db_symbol, animation_reason, animation_user, animation_target)
      (@specific_move_animations[move_db_symbol] ||= {})[animation_reason] = Marshal.dump([animation_user, animation_target])
    end
    # Function that stores a generic move animation
    # @param move_kind [Integer] 1 = physical, 2 = special, 3 = status
    # @param move_type [Integer] type of the move
    # @param animation_user [Yuki::AnimationMixin] unstarted animation of user that will be serialized
    # @param animation_target [Yuki::AnimationMixin] unstarted animation of target that will be serialized
    def register_generic_animation(move_kind, move_type, animation_user, animation_target)
      (@generic_move_animations[move_kind] ||= {})[move_type] = Marshal.dump([animation_user, animation_target])
    end
    # Function that retreives the animation for the user & the target depending on the condition
    # @param move [Battle::Move | Contest::Move] move used
    # @param animation_reason [Array<Symbol>] reason of the animation (in order you want it, you'll get the first that got resolved)
    # @return [Array<Yuki::AnimationMixin>, nil] animation on user, animation on target
    def get(move, *animation_reason)
      db_symbol = move.db_symbol
      found_reason = animation_reason.find { |reason| @specific_move_animations.dig(db_symbol, reason) }
      return Marshal.load(@specific_move_animations.dig(db_symbol, found_reason)) if found_reason
      generic = @generic_move_animations.dig(move.atk_class, move.type)
      return Marshal.load(generic) if generic
      return nil
    end
    # Function that plays an animation
    # @param animations [Array<Yuki::AnimationMixin>]
    # @param visual [Battle::Visual]
    # @param user [PFM::PokemonBattler] user of the move
    # @param targets [Array<PFM::PokemonBattler>] expected targets
    def play(animations, visual, user, targets)
      animations = animations.dup
      user_animation = animations.shift
      animations << Marshal.load(Marshal.dump(animations.last)) while animations.size < targets.size
      user_sprite = visual.battler_sprite(user.bank, user.position)
      target_sprites = targets.map { |target| visual.battler_sprite(target.bank, target.position) }
      user_animation.resolver = {visual: visual, user: user_sprite, target: target_sprites.first, viewport: user_sprite.viewport, camera_positionner: visual.camera_positionner}
      animations.each_with_index do |animation, index|
        animation.resolver = {visual: visual, user: user_sprite, target: target_sprites[index], viewport: user_sprite.viewport}
        animation.start
      end
      user_animation.start
      visual.animations << user_animation
      visual.animations.concat(animations)
      visual.wait_for_animation
    end
    # Function that plays an animation
    # @param animations [Array<Yuki::Animation::TimedAnimation>]
    # @param visual [Contest::Visual]
    # @param user [PFM::ContestCreature] user of the move
    # @param target [ContestTargetSprite] sprite used as a target
    def play_contest(animations, visual, user, target)
      animations = animations.dup
      user_animation = animations.shift
      user_sprite = visual.contestant_sprite(user)
      user_animation.resolver = {visual: visual, user: user_sprite, target: target, viewport: user_sprite.viewport}.method(:[])
      animations.each do |animation|
        animation.resolver = {visual: visual, user: user_sprite, target: target, viewport: user_sprite.viewport}.method(:[])
        animation.start
      end
      user_animation.start
      visual.animations << user_animation
      visual.animations.concat(animations)
      visual.wait_for_animation
    end
  end
end
## Module allowing the animation to chose the bank of the user in case of differences
module Yuki
  module Animation
    # Class describing an animation that plays depending on the user's bank
    class UserBankRelativeAnimation < Player
      # Create a new UserBankRelativeAnimation
      # @param banks [Array<AnimationMixin>] animations that plays on each banks
      def initialize(banks = nil)
        super()
        @bank_animations = banks || []
      end
      # @deprecated Inherits from bad practices
      def play_before_on_bank(bank, other)
        log_error('Using deprecated function, please initialize the UserBankRelativeAnimation properly')
        if @bank_animations[bank]
          if @bank_animations[bank].is_a?(Player)
            @bank_animations[bank].play(other)
          else
            @bank_animations[bank] = Player.new([@bank_animations[bank], other])
          end
        else
          @bank_animations[bank] = other
        end
        return self
      end
      # Start the animation
      # @param begin_offset [Float] offset for starting the animation (added to animation's clock)
      # @return [self]
      def start(begin_offset = 0)
        @stack.clear
        @parallel_stack.clear
        @last_index = -1
        bank_animation = @bank_animations[resolve(:user).bank]
        if bank_animation
          bank_animation.resolver = @resolver
          play(bank_animation)
        end
        super
      end
    end
    module_function
    # Create a new UserBankRelativeAnimation
    # @param banks [Array<AnimationMixin>] animations that plays on each banks
    # @return [UserBankRelativeAnimation] the created animation
    def user_bank_relative_animation(banks = nil)
      return UserBankRelativeAnimation.new(banks)
    end
    public
    module_function
    # Animation camera movement
    # @param target [Symbol] target of the camera movement
    # @param duration [Float] duration of the camera movement
    # @return [Yuki::Animation::Player] the camera movement animation
    def camera_move_animation(target = :target, duration = 0.4)
      ya = Yuki::Animation
      return ya.player(ya.send_command_to(target, :center_camera), ya.wait(duration))
    end
    # Animation Recenter movement
    # @return [Yuki::Animation::Player] the recenter camera animation
    def camera_reset_position
      ya = Yuki::Animation
      return ya.player(ya.send_command_to(:visual, :start_center_animation), ya.wait(0.3))
    end
    public
    module_function
    # @deprecated You can use parallel instead
    def combine_animation(animations, time_global)
      log_error('Using deprecated method combine_animation')
      return parallel(wait(time_global), *animations)
    end
    # @deprecated You can use player and parallel instead
    def combine_animation_with_sound(sound, animations, time_global)
      log_error('Using deprecated method combine_animation_with_sound')
      return player(se_play(sound), parallel(wait(time_global), *animations))
    end
    # @deprecated you can use player instead
    def combine_before_animation(animations)
      log_error('Using deprecated method combine_before_animation')
      return player(*animations)
    end
    # @deprecated you can use player instead
    def combine_before_animation_with_sound(sound, animations)
      log_error('Using deprecated method combine_before_animation_with_sound')
      return player(se_play(sound), *animations)
    end
    public
    module_function
    # Class that performs a compress Animation
    class CompressAnimation < TimedAnimation
      # Create a new CompressAnimation
      # @param time_to_process [Float] number of seconds (with generic time) to process the animation
      # @param on [Object] object that will receive the property
      # @param a [Integer] value in x retrieved to the sprite_zoom
      # @param b [Integer] value in y retrieved to the sprite_zoom
      # @param distortion [#call, Symbol] callable taking one parameter (between 0 & 1) and
      # convert it to another number (between 0 & 1) in order to distort time
      # @param time_source [#call, Symbol] callable taking no parameter and giving the current time
      def initialize(time_to_process, on, a, b, distortion: :SQUARE010_DISTORTION, time_source: :SCENE_TIME_SOURCE)
        super(time_to_process, distortion, time_source)
        @on_param = on
        @compress_x = a
        @compress_y = b
      end
      # Start the animation (initialize it)
      # @param begin_offset [Float] offset that prevents the animation from starting before now + begin_offset seconds
      def start(begin_offset = 0)
        super
        @on = resolve(@on_param)
        @origin = @on.sprite_zoom
        @delta_x = @compress_x
        @delta_y = @compress_y
      end
      # Method you should always overwrite in order to perform the right animation
      # @param time_factor [Float] number between 0 & 1 indicating the progression of the animation
      def update_internal(time_factor)
        @on.zoom_x = @origin + @delta_x * time_factor
        @on.zoom_y = @origin + @delta_y * time_factor
      end
    end
    # Create a new CompressAnimation
    # @param time_to_process [Float] number of seconds (with generic time) to process the animation
    # @param on [Object] object that will receive the property
    # @param a [Integer] value in x retrieved to the sprite_zoom
    # @param b [Integer] value in y retrieved to the sprite_zoom
    # @param iteration [#call, Integer] number of iteration of the animation
    # @param distortion [#call, Symbol] callable taking one parameter (between 0 & 1) and
    # convert it to another number (between 0 & 1) in order to distort time
    # @param time_source [#call, Symbol] callable taking no parameter and giving the current time
    # @return [CompressAnimation]
    def compress(time_to_process, on, a, b, iteration: 1, distortion: :SQUARE010_DISTORTION, time_source: :SCENE_TIME_SOURCE)
      return player(*iteration.times.map {CompressAnimation.new(time_to_process, on, a, b, distortion: distortion, time_source: time_source) })
    end
    public
    module_function
    # Class that performs a healing particle animation
    class HealingParticlePlayer < Player
      # Create a HealingParticlePlayer.
      # @param sprite_id [Symbol]
      # @param properties [Hash]
      # @option properties [String]  :filename
      # @option properties [Symbol] :on
      # @option properties [Array<Integer>] :origin
      # @option properties [Array<Float>] :offsets
      # @option properties [Array<Float>] :spawn_color
      # @option properties [Array<Float>] :up_color
      # @option properties [Array<Float>] :fade_color
      # @option properties [Integer] :delta_y
      # @option properties [Float] :zoom
      def initialize(sprite_id, properties)
        ya = Yuki::Animation
        @properties = properties
        @sprite_id = sprite_id
        super([ya.create_sprite(:viewport, @sprite_id, Sprite, nil, [:load, @properties[:filename], :animation], [:zoom=, 0], [:set_origin, *@properties[:origin]]), ya.resolved(*particle_animation), ya.dispose_sprite(@sprite_id)])
      end
      private
      # Apply a color to the sprite's shader
      # @param name [Symbol] name of the property to apply
      # @return [Object]
      def apply_color(name)
        return unless @properties[name]
        resolve(@sprite_id).shader.set_float_uniform('color', @properties[name])
      end
      def particle_animation
        ya = Yuki::Animation
        start_y = rand(-16..16)
        return [ya.send_command_to(self, :apply_color, :spawn_color), ya.particle_random_sprite_command(@sprite_id, @properties[:on], *@properties[:offsets]), ya.wait(rand * 0.6), ya.parallel(ya.scalar_y_from_sprite(0.9, @sprite_id, @properties[:on], start_y, start_y - @properties[:delta_y]), ya.particle_zoom(0.9, @sprite_id, @properties[:on], 0, @properties[:zoom] || 0.3, distortion: :SQUARE010_DISTORTION), ya.player(ya.wait(0.4), ya.send_command_to(self, :apply_color, :up_color), ya.wait(0.3), ya.send_command_to(self, :apply_color, :fade_color)))]
      end
    end
    # Create a healing particle animation.
    # @param particle_id [Symbol,String] ID under which the sprite will be created
    # @param properties [Hash] animation properties (see {HealingParticlePlayer})
    # @return [HealingParticlePlayer]
    def healing_particle_animation(particle_id, properties)
      HealingParticlePlayer.new(particle_id, properties)
    end
    public
    module_function
    # Class that performs a move particle animation
    class MoveParticleAnimation < TimedAnimation
      # Create a new MoveParticleAnimation
      # @note Create an animation between two sprites, an offset will be randomly choose for each coordinates depending of the proportion parameters,
      # if 0, it will stay on the origin, at 1 it can placed everywhere on the sprite
      # @param time_to_process [Float] number of seconds (with generic time) to process the animation
      # @param particle [Sprite, Sprite3D] sprite that will be moved
      # @param from [PokemonSprite, PokemonSprite3D] based on which Sprite it will start
      # @param to [PokemonSprite, PokemonSprite3D] on which Sprite it will go
      # @param proportion_x [Float] proportion of the sprite width that will cover (by default 1)
      # @param proportion_y [Float] proportion of the sprite height that will cover (by default 1)
      # @param use_zoom [Boolean] is the zoom difference used (by default false)
      # @param distortion [#call, Symbol] callable taking one parameter (between 0 & 1) and
      #   converting it to another number (between 0 & 1) to distort time
      # @param time_source [#call, Symbol] callable taking no parameter and giving the current time
      def initialize(time_to_process, particle, from, to, proportion_x = 1, proportion_y = 1, use_zoom: false, distortion: :UNICITY_DISTORTION, time_source: :SCENE_TIME_SOURCE)
        super(time_to_process, distortion, time_source)
        @particle_param = particle
        @from_param = from
        @to_param = to
        @use_zoom = use_zoom
        @proportion_x = proportion_x
        @proportion_y = proportion_y
      end
      # Start the animation (initialize it)
      # @param begin_offset [Float] offset that prevents the animation from starting before now + begin_offset seconds
      def start(begin_offset = 0)
        super
        @origin_sprite = resolve(@from_param)
        @destination_sprite = resolve(@to_param)
        @particle = resolve(@particle_param)
        destination_zoom = @use_zoom ? @destination_sprite.sprite_zoom_battle_animation : 1
        @origin_zoom = @use_zoom ? @origin_sprite.sprite_zoom_battle_animation : 1
        rand_x = rand * 2 - 1
        rand_y = rand * 2 - 1
        origin_x = @origin_sprite.x
        origin_y = @origin_sprite.y - @origin_sprite.bitmap.height / 2 * @origin_zoom
        @origin_x = origin_x + (@origin_sprite.bitmap.width / 2 * @origin_zoom * rand_x * @proportion_x).to_i
        @origin_y = origin_y + (@origin_sprite.bitmap.height / 2 * @origin_zoom * rand_y * @proportion_y).to_i
        destination_x = @destination_sprite.x
        destination_y = @destination_sprite.y - @origin_sprite.bitmap.height / 2 * destination_zoom
        @destination_x = destination_x + (@destination_sprite.bitmap.width / 2 * destination_zoom * rand_x * @proportion_x).to_i
        @destination_y = destination_y + (@destination_sprite.bitmap.height / 2 * destination_zoom * rand_y * @proportion_y).to_i
        @delta_x = @destination_x - @origin_x
        @delta_y = @destination_y - @origin_y
        @delta_zoom = destination_zoom - @origin_zoom
      end
      # Method you should always overwrite in order to perform the right animation
      # @param time_factor [Float] number between 0 & 1 indicating the progression of the animation
      def update_internal(time_factor)
        @particle.set_position(@origin_x + @delta_x * time_factor, @origin_y + @delta_y * time_factor)
        @particle.zoom = @origin_zoom + @delta_zoom * time_factor if @use_zoom
      end
    end
    # Class that performs a move particle animation with offset
    class MoveParticleOffsetAnimation < TimedAnimation
      # Create a new MoveParticleOffsetAnimation
      # @note Create an animation between two sprites with the possibility to apply an offset in both coordinates between the sprites
      # @param time_to_process [Float] number of seconds (with generic time) to process the animation
      # @param particle [Sprite, Sprite3D] sprite that will be moved
      # @param from [PokemonSprite, PokemonSprite3D] based on which Sprite it will start
      # @param to [PokemonSprite, PokemonSprite3D] on which Sprite it will go
      # @param offset_x [Integer] offset on x
      # @param offset_y [Integer] offset on y
      # @param from_center [Boolean] is the origin from the center of the sprite (by default false)
      # @param distortion [#call, Symbol] callable taking one parameter (between 0 & 1) and
      #   converting it to another number (between 0 & 1) to distort time
      # @param time_source [#call, Symbol] callable taking no parameter and giving the current time
      def initialize(time_to_process, particle, from, to, offset_x, offset_y, from_center: false, distortion: :UNICITY_DISTORTION, time_source: :SCENE_TIME_SOURCE)
        super(time_to_process, distortion, time_source)
        @particle_param = particle
        @from_param = from
        @to_param = to
        @offset_x = offset_x
        @offset_y = offset_y
      end
      # Start the animation (initialize it)
      # @param begin_offset [Float] offset that prevents the animation from starting before now + begin_offset seconds
      def start(begin_offset = 0)
        super
        @origin_sprite = resolve(@from_param)
        @destination_sprite = resolve(@to_param)
        @particle = resolve(@particle_param)
        destination_zoom = @destination_sprite.sprite_zoom_battle_animation
        @origin_zoom = @origin_sprite.sprite_zoom_battle_animation
        center_y = @from_center ? @origin_sprite.bitmap.height / 2 : 0
        @origin_x = @origin_sprite.x
        @origin_y = @origin_sprite.y - center_y * @origin_zoom
        @destination_x = @destination_sprite.x + @offset_x * destination_zoom
        @destination_y = @destination_sprite.y + @offset_y * destination_zoom
        @delta_x = @destination_x - @origin_x
        @delta_y = @destination_y - @origin_y
        @delta_zoom = destination_zoom - @origin_zoom
      end
      # Method you should always overwrite in order to perform the right animation
      # @param time_factor [Float] number between 0 & 1 indicating the progression of the animation
      def update_internal(time_factor)
        @particle.set_position(@origin_x + @delta_x * time_factor, @origin_y + @delta_y * time_factor)
        @particle.zoom = @origin_zoom + @delta_zoom * time_factor if @use_zoom
      end
    end
    # Create a new MoveParticleAnimation
    # @param time_to_process [Float] number of seconds (with generic time) to process the animation
    # @param particle [Sprite, Sprite3D] sprite that will be moved
    # @param from [PokemonSprite, PokemonSprite3D] based on which Sprite it will start
    # @param to [PokemonSprite, PokemonSprite3D] on which Sprite it will go
    # @param proportion_x [Float] proportion of the sprite width that will cover (by default 1)
    # @param proportion_y [Float] proportion of the sprite height that will cover (by default 1)
    # @param use_zoom [Boolean] is the zoom difference used (by default false)
    # @param distortion [#call, Symbol] callable taking one parameter (between 0 & 1) and
    #   converting it to another number (between 0 & 1) to distort time
    # @param time_source [#call, Symbol] callable taking no parameter and giving the current time
    # @return [MoveParticleAnimation]
    def particle_move_to_sprite(time_to_process, particle, from, to, proportion_x = 1, proportion_y = 1, use_zoom: false, distortion: :UNICITY_DISTORTION, time_source: :SCENE_TIME_SOURCE)
      MoveParticleAnimation.new(time_to_process, particle, from, to, proportion_x, proportion_y, use_zoom: use_zoom, distortion: distortion, time_source: time_source)
    end
    # Create a new MoveParticleOffsetAnimation
    # @param time_to_process [Float] number of seconds (with generic time) to process the animation
    # @param particle [Sprite, Sprite3D] sprite that will be moved
    # @param from [PokemonSprite, PokemonSprite3D] based on which Sprite it will start
    # @param to [PokemonSprite, PokemonSprite3D] on which Sprite it will go
    # @param offset_x [Integer] offset on x
    # @param offset_y [Integer] offset on y
    # @param from_center [Boolean] is the origin from the center of the sprite (by default false)
    # @param distortion [#call, Symbol] callable taking one parameter (between 0 & 1) and
    #   converting it to another number (between 0 & 1) to distort time
    # @param time_source [#call, Symbol] callable taking no parameter and giving the current time
    # @return [MoveParticleOffsetAnimation]
    def particle_move_to_sprite_offset(time_to_process, particle, from, to, offset_x = 0, offset_y = 0, from_center: false, distortion: :UNICITY_DISTORTION, time_source: :SCENE_TIME_SOURCE)
      MoveParticleOffsetAnimation.new(time_to_process, particle, from, to, offset_x, offset_y, from_center: from_center, distortion: distortion, time_source: time_source)
    end
    public
    module_function
    # Class that performs a particle on sprite animation
    class ParticleOnSpriteAnimation < TimedAnimation
      # Create a new ParticleOnSpriteAnimation
      # @param time_to_process [Float] number of seconds (with generic time) to process the animation
      # @param particle [Sprite, Sprite3D] sprite that will be placed
      # @param on [PokemonSprite, PokemonSprite3D] based on which Sprite dimension it will be placed
      # @param proportion_x [Float] proportion of the sprite width that will cover (by default 1)
      # @param proportion_y [Float] proportion of the sprite height that will cover (by default 1)
      # @param distortion [#call, Symbol] callable taking one parameter (between 0 & 1) and
      #   converting it to another number (between 0 & 1) to distort time
      # @param time_source [#call, Symbol] callable taking no parameter and giving the current time
      def initialize(time_to_process, particle, on, proportion_x = 1, proportion_y = 1, distortion: :UNICITY_DISTORTION, time_source: :SCENE_TIME_SOURCE)
        super(time_to_process, distortion, time_source)
        @particle_param = particle
        @on_param = on
        @proportion_x = proportion_x
        @proportion_y = proportion_y
      end
      # Start the animation (initialize it)
      # @param begin_offset [Float] offset that prevents the animation from starting before now + begin_offset seconds
      def start(begin_offset = 0)
        super
        @pokemon_sprite = resolve(@on_param)
        @particle = resolve(@particle_param)
        sprite_zoom = @pokemon_sprite.sprite_zoom_battle_animation
        @origin_x = @pokemon_sprite.x
        @origin_y = @pokemon_sprite.y - @pokemon_sprite.bitmap.height / 2 * sprite_zoom
        @delta_x = (@pokemon_sprite.bitmap.width / 2 * sprite_zoom * (rand * 2 - 1) * @proportion_x).to_i
        @delta_y = (@pokemon_sprite.bitmap.height / 2 * sprite_zoom * (rand * 2 - 1) * @proportion_y).to_i
      end
      # Method you should always overwrite in order to perform the right animation
      # @param time_factor [Float] number between 0 & 1 indicating the progression of the animation
      def update_internal(time_factor)
        @particle.set_position(@origin_x + @delta_x * time_factor, @origin_y - @delta_y * time_factor)
      end
    end
    # Place a particle on a sprite with an offset
    class ParticleOnSpriteOffset < Command
      # Create a new ParticleOnSpriteOffset
      # @param particle [Sprite, Sprite3D] sprite that will be placed
      # @param on [PokemonSprite, PokemonSprite3D] based on which Sprite dimension it will be placed
      # @param offset_x [Integer] (by default 0)
      # @param offset_y [Integer] (by default 0)
      def initialize(particle, on, offset_x = 0, offset_y = 0)
        super()
        @particle_param = particle
        @on_param = on
        @offset_x = offset_x
        @offset_y = offset_y
      end
      private
      # Execute the placement of the particle on the sprite with the offset
      def update_internal
        pokemon_sprite = resolve(@on_param)
        particle = resolve(@particle_param)
        sprite_zoom = pokemon_sprite.sprite_zoom_battle_animation
        origin_x = pokemon_sprite.x + @offset_x * sprite_zoom
        origin_y = pokemon_sprite.y + @offset_y * sprite_zoom
        particle.set_position(origin_x, origin_y)
      end
    end
    # Place a particle on a sprite randomly
    class ParticleOnSpriteRandom < Command
      # Create a new ParticleOnSpriteRandom
      # @param particle [Sprite, Sprite3D] sprite that will be placed
      # @param on [PokemonSprite, PokemonSprite3D] based on which Sprite dimension it will be placed
      # @param proportion_x [Float] proportion of the sprite width that will cover (by default 1)
      # @param proportion_y [Float] proportion of the sprite height that will cover (by default 1)
      def initialize(particle, on, proportion_x = 1, proportion_y = 1)
        super()
        @particle_param = particle
        @on_param = on
        @proportion_x = proportion_x
        @proportion_y = proportion_y
      end
      private
      # Execute the placement of the particle on the sprite randomly
      def update_internal
        pokemon_sprite = resolve(@on_param)
        particle = resolve(@particle_param)
        sprite_zoom = pokemon_sprite.sprite_zoom_battle_animation
        rand_x = 2 * rand - 1
        rand_y = 2 * rand - 1
        offset_center = pokemon_sprite.bitmap.height / 2 * sprite_zoom
        origin_x = pokemon_sprite.x + (pokemon_sprite.bitmap.width * @proportion_x * rand_x * sprite_zoom).to_i
        origin_y = pokemon_sprite.y - offset_center + (pokemon_sprite.bitmap.height * @proportion_y * rand_y * sprite_zoom).to_i
        particle.set_position(origin_x, origin_y)
      end
    end
    # Class that performs a move particle on sprite animation
    class MoveParticleOnSprite < TimedAnimation
      # Create a new MoveParticleOnSprite
      # @param time_to_process [Float] number of seconds (with generic time) to process the animation
      # @param particle [Sprite, Sprite3D] sprite that will moved
      # @param on [PokemonSprite, PokemonSprite3D] based on which Sprite dimension it will navigate
      # @param start_x [Integer]
      # @param start_y [Integer]
      # @param final_x [Integer]
      # @param final_y [Integer]
      # @param use_zoom [Boolean] use zoom of the sprite (by default true)
      # @param distortion [#call, Symbol] callable taking one parameter (between 0 & 1) and
      #   converting it to another number (between 0 & 1) to distort time
      # @param time_source [#call, Symbol] callable taking no parameter and giving the current time
      def initialize(time_to_process, particle, on, start_x, start_y, final_x, final_y, use_zoom: true, distortion: :UNICITY_DISTORTION, time_source: :SCENE_TIME_SOURCE)
        super(time_to_process, distortion, time_source)
        @particle_param = particle
        @on_param = on
        @use_zoom = use_zoom
        @start_x = start_x
        @start_y = start_y
        @final_x = final_x
        @final_y = final_y
      end
      # Start the animation (initialize it)
      # @param begin_offset [Float] offset that prevents the animation from starting before now + begin_offset seconds
      def start(begin_offset = 0)
        super
        pokemon_sprite = resolve(@on_param)
        @particle = resolve(@particle_param)
        sprite_zoom = @use_zoom ? pokemon_sprite.sprite_zoom_battle_animation : 1
        @origin_x = pokemon_sprite.x + @start_x * sprite_zoom
        @origin_y = pokemon_sprite.y + @start_y * sprite_zoom
        final_x = pokemon_sprite.x + @final_x * sprite_zoom
        final_y = pokemon_sprite.y + @final_y * sprite_zoom
        @delta_x = final_x - @origin_x
        @delta_y = final_y - @origin_y
      end
      # Method you should always overwrite in order to perform the right animation
      # @param time_factor [Float] number between 0 & 1 indicating the progression of the animation
      def update_internal(time_factor)
        @particle.set_position(@origin_x + @delta_x * time_factor, @origin_y + @delta_y * time_factor)
      end
    end
    # Create a new MoveParticleOnSprite
    # @param time_to_process [Float] number of seconds (with generic time) to process the animation
    # @param particle [Sprite, Sprite3D] sprite that will moved
    # @param on [PokemonSprite, PokemonSprite3D] based on which Sprite dimension it will navigate
    # @param start_x [Integer]
    # @param start_y [Integer]
    # @param final_x [Integer]
    # @param final_y [Integer]
    # @param use_zoom [Boolean] use zoom of the sprite (by default true)
    # @param distortion [#call, Symbol] callable taking one parameter (between 0 & 1) and
    #   converting it to another number (between 0 & 1) to distort time
    # @param time_source [#call, Symbol] callable taking no parameter and giving the current time
    # @return [MoveParticleOnSprite]
    def move_particle_on_sprite(time_to_process, particle, on, start_x, start_y, final_x, final_y, use_zoom: true, distortion: :UNICITY_DISTORTION, time_source: :SCENE_TIME_SOURCE)
      return MoveParticleOnSprite.new(time_to_process, particle, on, start_x, start_y, final_x, final_y, use_zoom: use_zoom, distortion: distortion, time_source: time_source)
    end
    # Create a new ParticleOnSpriteOffset
    # @param particle [Sprite, Sprite3D] sprite that will be placed
    # @param on [PokemonSprite, PokemonSprite3D] based on which Sprite dimension it will be placed
    # @param offset_x [Integer] (by default 0)
    # @param offset_y [Integer] (by default 0)
    # @return [ParticleOnSpriteOffset]
    def particle_on_sprite_command(particle, on, offset_x = 0, offset_y = 0)
      return ParticleOnSpriteOffset.new(particle, on, offset_x, offset_y)
    end
    # Create a new ParticleOnSpriteRandom
    # @param particle [Sprite, Sprite3D] sprite that will be placed
    # @param on [PokemonSprite, PokemonSprite3D] based on which Sprite dimension it will be placed
    # @param proportion_x [Integer] (by default 1)
    # @param proportion_y [Integer] (by default 1)
    # @return [ParticleOnSpriteRandom]
    def particle_random_sprite_command(particle, on, proportion_x = 1, proportion_y = 1)
      return ParticleOnSpriteRandom.new(particle, on, proportion_x, proportion_y)
    end
    # Create a new ParticleOnSpriteAnimation
    # @param time_to_process [Float] number of seconds (with generic time) to process the animation
    # @param particle [Sprite, Sprite3D] sprite that will be placed
    # @param on [PokemonSprite, PokemonSprite3D] based on which Sprite dimension it will be placed
    # @param proportion_x [Float] proportion of the sprite width that will cover (by default 1)
    # @param proportion_y [Float] proportion of the sprite height that will cover (by default 1)
    # @param distortion [#call, Symbol] callable taking one parameter (between 0 & 1) and
    #   converting it to another number (between 0 & 1) to distort time
    # @param time_source [#call, Symbol] callable taking no parameter and giving the current time
    # @return [ParticleOnSpriteAnimation]
    def particle_on_sprite(time_to_process, particle, on, proportion_x = 1, proportion_y = 1, distortion: :UNICITY_DISTORTION, time_source: :SCENE_TIME_SOURCE)
      return ParticleOnSpriteAnimation.new(time_to_process, particle, on, proportion_x, proportion_y, distortion: distortion, time_source: time_source)
    end
    public
    module_function
    # Class that performs a particle zoom animation
    class ParticleZoomAnimation < TimedAnimation
      # Create a new ParticleZoomAnimation
      # @param time_to_process [Float] number of seconds (with generic time) to process the animation
      # @param particle [Sprite, Sprite3D] sprite that will be placed
      # @param on [PokemonSprite, PokemonSprite3D] Sprite from which the zoom will be based
      # @param a [Float] zoom_start
      # @param b [Float] zoom_final
      # @param distortion [#call, Symbol] callable taking one parameter (between 0 & 1) and
      #   converting it to another number (between 0 & 1) to distort time
      # @param time_source [#call, Symbol] callable taking no parameter and giving the current time
      def initialize(time_to_process, particle, on, a, b, distortion: :UNICITY_DISTORTION, time_source: :SCENE_TIME_SOURCE)
        super(time_to_process, distortion, time_source)
        @particle_param = particle
        @on_param = on
        @zoom_start = a
        @zoom_final = b
      end
      # Start the animation (initialize it)
      # @param begin_offset [Float] offset that prevents the animation from starting before now + begin_offset seconds
      def start(begin_offset = 0)
        super
        @pokemon_sprite = resolve(@on_param)
        @particle = resolve(@particle_param)
        @origin_x = @pokemon_sprite.x
        @origin_y = @pokemon_sprite.y
        sprite_zoom = @pokemon_sprite.sprite_zoom_battle_animation
        @zoom_start *= sprite_zoom
        @zoom_final *= sprite_zoom
        @delta_zoom = @zoom_final - @zoom_start
      end
      # Method you should always overwrite in order to perform the right animation
      # @param time_factor [Float] number between 0 & 1 indicating the progression of the animation
      def update_internal(time_factor)
        @particle.zoom = @zoom_start + @delta_zoom * time_factor
      end
    end
    # Class that performs a particle zoom on the X axis animation
    class ParticleZoomXAnimation < ParticleZoomAnimation
      # Method you should always overwrite in order to perform the right animation
      # @param time_factor [Float] number between 0 & 1 indicating the progression of the animation
      def update_internal(time_factor)
        @particle.zoom_x = @zoom_start + @delta_zoom * time_factor
      end
    end
    # Class that performs a particle zoom on the Y axis animation
    class ParticleZoomYAnimation < ParticleZoomAnimation
      # Method you should always overwrite in order to perform the right animation
      # @param time_factor [Float] number between 0 & 1 indicating the progression of the animation
      def update_internal(time_factor)
        @particle.zoom_y = @zoom_start + @delta_zoom * time_factor
      end
    end
    # Create a new ParticleZoomAnimation
    # @param time_to_process [Float] number of seconds (with generic time) to process the animation
    # @param particle [Sprite, Sprite3D] sprite that will be placed
    # @param on [PokemonSprite, PokemonSprite3D] Sprite from which the zoom will be based
    # @param a [Float] zoom_start
    # @param b [Float] zoom_final
    # @param distortion [#call, Symbol] callable taking one parameter (between 0 & 1) and
    #   converting it to another number (between 0 & 1) to distort time
    # @param time_source [#call, Symbol] callable taking no parameter and giving the current time
    # @return [ParticleZoomAnimation]
    def particle_zoom(time_to_process, particle, on, a, b, distortion: :UNICITY_DISTORTION, time_source: :SCENE_TIME_SOURCE)
      return ParticleZoomAnimation.new(time_to_process, particle, on, a, b, distortion: distortion, time_source: time_source)
    end
    # Create a new ParticleZoomXAnimation
    # @param time_to_process [Float] number of seconds (with generic time) to process the animation
    # @param particle [Sprite, Sprite3D] sprite that will be placed
    # @param on [PokemonSprite, PokemonSprite3D] Sprite from which the zoom will be based
    # @param a [Float] zoom_start
    # @param b [Float] zoom_final
    # @param distortion [#call, Symbol] callable taking one parameter (between 0 & 1) and
    #   converting it to another number (between 0 & 1) to distort time
    # @param time_source [#call, Symbol] callable taking no parameter and giving the current time
    # @return [ParticleZoomXAnimation]
    def particle_zoom_x(time_to_process, particle, on, a, b, distortion: :UNICITY_DISTORTION, time_source: :SCENE_TIME_SOURCE)
      return ParticleZoomXAnimation.new(time_to_process, particle, on, a, b, distortion: distortion, time_source: time_source)
    end
    # Create a new ParticleZoomYAnimation
    # @param time_to_process [Float] number of seconds (with generic time) to process the animation
    # @param particle [Sprite, Sprite3D] sprite that will be placed
    # @param on [PokemonSprite, PokemonSprite3D] Sprite from which the zoom will be based
    # @param a [Float] zoom_start
    # @param b [Float] zoom_final
    # @param distortion [#call, Symbol] callable taking one parameter (between 0 & 1) and
    #   converting it to another number (between 0 & 1) to distort time
    # @param time_source [#call, Symbol] callable taking no parameter and giving the current time
    # @return [ParticleZoomYAnimation]
    def particle_zoom_y(time_to_process, particle, on, a, b, distortion: :UNICITY_DISTORTION, time_source: :SCENE_TIME_SOURCE)
      return ParticleZoomYAnimation.new(time_to_process, particle, on, a, b, distortion: distortion, time_source: time_source)
    end
    public
    module_function
    # Class that performs a scalar on the X axis from sprite animation
    class ScalarXFromSprite < TimedAnimation
      # Create a new ScalarXFromSprite
      # @param time_to_process [Float] number of seconds (with generic time) to process the animation
      # @param on [Object] object that will receive the property
      # @param sprite [Object] on which the origin will be based on
      # @param start_x [Integer] start_x
      # @param offset_x [Integer] offset_x
      # @param distortion [#call, Symbol] callable taking one parameter (between 0 & 1) and
      # convert it to another number (between 0 & 1) in order to distort time
      # @param time_source [#call, Symbol] callable taking no parameter and giving the current time
      def initialize(time_to_process, on, sprite, start_x, offset_x, distortion: :UNICITY_DISTORTION, time_source: :SCENE_TIME_SOURCE)
        super(time_to_process, distortion, time_source)
        @on_param = on
        @sprite_param = sprite
        @start_x = start_x
        @offset_x = offset_x
      end
      # Start the animation (initialize it)
      # @param begin_offset [Float] offset that prevents the animation from starting before now + begin_offset seconds
      def start(begin_offset = 0)
        super
        pokemon_sprite = resolve(@sprite_param)
        @on = resolve(@on_param)
        sprite_zoom = pokemon_sprite.sprite_zoom_battle_animation
        @origin_x = pokemon_sprite.x + @start_x * sprite_zoom
        @offset_x *= sprite_zoom
      end
      # Update the scalar animation
      # @param time_factor [Float] number between 0 & 1 indicating the progression of the animation
      def update_internal(time_factor)
        @on.x = @origin_x + @offset_x * time_factor
      end
    end
    # Class that performs a scalar on the Y axis from sprite animation
    class ScalarYFromSprite < TimedAnimation
      # Create a new ScalarYFromSprite
      # @param time_to_process [Float] number of seconds (with generic time) to process the animation
      # @param on [Object] object that will receive the property
      # @param sprite [Object] on which the origin will be based on
      # @param start_y [Integer] start_y
      # @param offset_y [Integer] offset_y
      # @param distortion [#call, Symbol] callable taking one parameter (between 0 & 1) and
      # convert it to another number (between 0 & 1) in order to distort time
      # @param time_source [#call, Symbol] callable taking no parameter and giving the current time
      def initialize(time_to_process, on, sprite, start_y, offset_y, distortion: :UNICITY_DISTORTION, time_source: :SCENE_TIME_SOURCE)
        super(time_to_process, distortion, time_source)
        @on_param = on
        @sprite_param = sprite
        @start_y = start_y
        @offset_y = offset_y
      end
      # Start the animation (initialize it)
      # @param begin_offset [Float] offset that prevents the animation from starting before now + begin_offset seconds
      def start(begin_offset = 0)
        super
        pokemon_sprite = resolve(@sprite_param)
        @on = resolve(@on_param)
        sprite_zoom = pokemon_sprite.sprite_zoom_battle_animation
        @origin_y = pokemon_sprite.y + @start_y * sprite_zoom
        @offset_y *= sprite_zoom
      end
      # Update the scalar animation
      # @param time_factor [Float] number between 0 & 1 indicating the progression of the animation
      def update_internal(time_factor)
        @on.y = @origin_y + @offset_y * time_factor
      end
    end
    # Create a scalar animation on the x property of an element, linked to a sprite for the original position
    # @param time_to_process [Float] number of seconds (with generic time) to process the animation
    # @param on [Object] object that will receive the property
    # @param sprite [Object] on which the origin will be based on
    # @param start_x [Integer] start_x
    # @param offset_x [Integer] offset_x
    # @param distortion [#call, Symbol] callable taking one parameter (between 0 & 1) and
    # convert it to another number (between 0 & 1) in order to distort time
    # @param time_source [#call, Symbol] callable taking no parameter and giving the current time
    # @return [ScalarXFromSprite]
    def scalar_x_from_sprite(time_to_process, on, sprite, start_x, offset_x, distortion: :UNICITY_DISTORTION, time_source: :SCENE_TIME_SOURCE)
      return ScalarXFromSprite.new(time_to_process, on, sprite, start_x, offset_x, distortion: distortion, time_source: time_source)
    end
    # Create a scalar animation on the y property of an element, linked to a sprite for the original position
    # @param time_to_process [Float] number of seconds (with generic time) to process the animation
    # @param on [Object] object that will receive the property
    # @param sprite [Object] on which the origin will be based on
    # @param start_y [Integer] start_y
    # @param offset_y [Integer] offset_y
    # @param distortion [#call, Symbol] callable taking one parameter (between 0 & 1) and
    # convert it to another number (between 0 & 1) in order to distort time
    # @param time_source [#call, Symbol] callable taking no parameter and giving the current time
    # @return [ScalarYFromSprite]
    def scalar_y_from_sprite(time_to_process, on, sprite, start_y, offset_y, distortion: :UNICITY_DISTORTION, time_source: :SCENE_TIME_SOURCE)
      return ScalarYFromSprite.new(time_to_process, on, sprite, start_y, offset_y, distortion: distortion, time_source: time_source)
    end
  end
end
# Module to override sprite creation for Fake3D battle scenes
Yuki::Animation::SpriteCreationCommand.prepend(Fake3DCreateSpriteFallback)
ya = Yuki::Animation
animation_target = ya.wait(0.1)
sprite_src_rect_animations = 8.times.flat_map { |i| [ya.send_command_to(:sprite, :set_rect, (i % 4) * 104, 0, 104, 192), ya.wait(0.12)] }
animation_user = ya.player(ya.create_sprite(:viewport, :sprite, Sprite, nil, [:load, 'acid_armor', :animation], [:set_rect, 0, 0, 104, 192], [:zoom=, 1], [:set_origin, 52, 132]), ya.resolved(ya.particle_zoom(0, :sprite, :user, 1, 1), ya.move_sprite_position(0, :sprite, :user, :user), ya.se_play('moves/acid_armor'), ya.wait(0.1), *sprite_src_rect_animations), ya.dispose_sprite(:sprite))
Battle::MoveAnimation.register_specific_animation(:acid_armor, :first_use, animation_user, animation_target)
ya = Yuki::Animation
animation_user = ya.wait(0.1)
sprite_src_rect_animations = 3.times.flat_map { |i| [ya.send_command_to(:sprite, :set_rect, i * 104, 0, 104, 192), ya.wait(0.1)] }
animation_target = ya.player(ya.create_sprite(:viewport, :sprite, Sprite, nil, [:load, 'acrobatics', :animation], [:set_rect, 0, 0, 104, 192], [:zoom=, 0.5], [:set_origin, 52, 132]), ya.resolved(ya.particle_zoom(0, :sprite, :target, 0.5, 0.5), ya.move_sprite_position(0, :sprite, :target, :target), ya.se_play('moves/acrobatics'), ya.wait(0.2), *sprite_src_rect_animations), ya.dispose_sprite(:sprite))
Battle::MoveAnimation.register_specific_animation(:acrobatics, :first_use, animation_user, animation_target)
ya = Yuki::Animation
animation_user = ya.wait(0.1)
sprite_src_rect_animations = 13.times.flat_map { |i| [ya.send_command_to(:sprite, :set_rect, i * 208, 0, 208, 192), ya.wait(0.055)] }
animation_target = ya.player(ya.create_sprite(:viewport, :sprite, Sprite, nil, [:load, 'aerial_ace', :animation], [:set_rect, 0, 0, 208, 192], [:zoom=, 0.75], [:set_origin, 104, 132]), ya.resolved(ya.particle_zoom(0, :sprite, :target, 0.75, 0.75), ya.move_sprite_position(0, :sprite, :target, :target), ya.se_play('moves/aerial_ace'), ya.wait(0.1), *sprite_src_rect_animations), ya.dispose_sprite(:sprite))
Battle::MoveAnimation.register_specific_animation(:aerial_ace, :first_use, animation_user, animation_target)
ya = Yuki::Animation
animation_user = ya.wait(0.1)
sprite_src_rect_animations = 7.times.flat_map { |i| [ya.send_command_to(:sprite, :set_rect, i * 208, 0, 208, 192), ya.wait(0.055)] }
animation_target = ya.player(ya.create_sprite(:viewport, :sprite, Sprite, nil, [:load, 'air_slash', :animation], [:set_rect, 0, 0, 208, 192], [:zoom=, 0.75], [:set_origin, 104, 132]), ya.resolved(ya.particle_zoom(0, :sprite, :target, 0.75, 0.75), ya.move_sprite_position(0, :sprite, :target, :target), ya.se_play('moves/air_slash'), ya.wait(0.1), *sprite_src_rect_animations), ya.dispose_sprite(:sprite))
Battle::MoveAnimation.register_specific_animation(:air_slash, :first_use, animation_user, animation_target)
ya = Yuki::Animation
animation_target = ya.wait(0.1)
sprite_src_rect_animations = 9.times.flat_map { |i| [ya.send_command_to(:sprite, :set_rect, (i % 3) * 104, 0, 104, 192), ya.wait(0.15)] }
animation_user = ya.player(ya.create_sprite(:viewport, :sprite, Sprite, nil, [:load, 'aqua_ring', :animation], [:set_rect, 0, 0, 104, 192], [:zoom=, 0.75], [:set_origin, 52, 132]), ya.resolved(ya.particle_zoom(0, :sprite, :user, 0.75, 0.75), ya.move_sprite_position(0, :sprite, :user, :user), ya.se_play('moves/aqua_ring'), ya.wait(0.1), *sprite_src_rect_animations), ya.dispose_sprite(:sprite))
Battle::MoveAnimation.register_specific_animation(:aqua_ring, :first_use, animation_user, animation_target)
ya = Yuki::Animation
animation_user = ya.wait(0.1)
user_sprite_src_rect_animations = 3.times.flat_map { |i| [ya.send_command_to(:sprite, :set_rect, i * 104, 0, 104, 192), ya.wait(0.065)] }
enemy_sprite_src_rect_animations = 4.times.flat_map { |i| [ya.send_command_to(:sprite, :set_rect, 312 + (i * 104), 0, 104, 192), ya.wait(0.075)] }
animation_target = ya.player(ya.create_sprite(:viewport, :sprite, Sprite, nil, [:load, 'aqua_tail', :animation], [:set_rect, 0, 0, 104, 192], [:zoom=, 1], [:set_origin, 52, 132]), ya.resolved(ya.particle_zoom(0, :sprite, :target, 1, 1), ya.move_sprite_position(0, :sprite, :target, :target), ya.se_play('moves/aqua_tail'), ya.wait(0.1), *user_sprite_src_rect_animations, *enemy_sprite_src_rect_animations), ya.dispose_sprite(:sprite))
Battle::MoveAnimation.register_specific_animation(:aqua_tail, :first_use, animation_user, animation_target)
ya = Yuki::Animation
animation_user = ya.wait(0.1)
sprite_src_rect_animations = 4.times.flat_map { |i| [ya.send_command_to(:sprite, :set_rect, i * 104, 0, 104, 192), ya.wait(0.15)] }
animation_target = ya.player(ya.create_sprite(:viewport, :sprite, Sprite, nil, [:load, 'assurance', :animation], [:set_rect, 0, 0, 104, 192], [:zoom=, 1], [:set_origin, 52, 132]), ya.resolved(ya.particle_zoom(0, :sprite, :target, 1, 1), ya.move_sprite_position(0, :sprite, :target, :target), ya.se_play('moves/assurance'), ya.wait(0.1), *sprite_src_rect_animations), ya.dispose_sprite(:sprite))
Battle::MoveAnimation.register_specific_animation(:assurance, :first_use, animation_user, animation_target)
ya = Yuki::Animation
animation_user = ya.wait(0.1)
sprite_src_rect_animations = 5.times.flat_map { |i| [ya.send_command_to(:sprite, :set_rect, i * 104, 0, 104, 192), ya.wait(i == 1 ? 0.15 : 0.085)] }
animation_target = ya.player(ya.create_sprite(:viewport, :sprite, Sprite, nil, [:load, 'astonish', :animation], [:set_rect, 0, 0, 104, 192], [:zoom=, 1], [:set_origin, 52, 132]), ya.resolved(ya.particle_zoom(0, :sprite, :target, 1, 1), ya.move_sprite_position(0, :sprite, :target, :target), ya.se_play('moves/astonish'), ya.wait(0.1), *sprite_src_rect_animations), ya.dispose_sprite(:sprite))
Battle::MoveAnimation.register_specific_animation(:astonish, :first_use, animation_user, animation_target)
ya = Yuki::Animation
animation_user = ya.wait(0.1)
sprite_src_rect_animations = 19.times.flat_map { |i| [ya.send_command_to(:sprite, :set_rect, i * 104, 0, 104, 192), ya.wait(0.1)] }
animation_target = ya.player(ya.create_sprite(:viewport, :sprite, Sprite, nil, [:load, 'avalanche', :animation], [:set_rect, 0, 0, 104, 192], [:zoom=, 1.25], [:set_origin, 52, 110]), ya.resolved(ya.particle_zoom(0, :sprite, :target, 1.25, 1.25), ya.move_sprite_position(0, :sprite, :target, :target), ya.se_play('moves/avalanche'), ya.wait(0.1), *sprite_src_rect_animations), ya.dispose_sprite(:sprite))
Battle::MoveAnimation.register_specific_animation(:avalanche, :first_use, animation_user, animation_target)
ya = Yuki::Animation
all_animations = []
sprite_attributes = [[:set_rect, 0, 0, 32, 32], [:zoom=, 1], [:opacity=, 0], [:set_origin, 16, 32]]
setup_animation = ya.user_bank_relative_animation([ya.create_sprite(:viewport, :sprite, Sprite, nil, [:load, 'hand-front-left', :animation], *sprite_attributes), ya.create_sprite(:viewport, :sprite, Sprite, nil, [:load, 'hand-front-right', :animation], *sprite_attributes)])
fall_animation = ya.player(ya.particle_zoom(0, :sprite, :target, 1, 1), ya.falling_animation(1, :sprite, :target, 200))
sprite_animation = ya.player(ya.send_command_to(:sprite, :opacity=, 200), ya.wait(0.2), ya.send_command_to(:sprite, :set_rect, 0, 32, 32, 32), ya.wait(0.2), ya.send_command_to(:sprite, :opacity=, 230), ya.send_command_to(:sprite, :set_rect, 0, 0, 32, 32), ya.wait(0.3), ya.opacity_change(0.3, :sprite, 230, 0))
deformation_animation = ya.player(ya.wait(0.1), ya.compress(0.3, :target, 0.2, -0.6))
particles = 20.times.map { |i| "sprite_#{i}".freeze }
create_particle_sprites = particles.map do |s|
  next(ya.create_sprite(:viewport, s, Sprite, nil, [:load, 'circle_particle', :animation], [:opacity=, 0], [:set_origin, 8, 8]))
end
dispose_particle_sprites = particles.map { |s| ya.dispose_sprite(s) }
particle_animations = particles.map do |sprite|
  next(ya.player(ya.wait(0.2), ya.send_command_to(sprite, :opacity=, 255), ya.parallel(ya.radius_move(0.5, sprite, :target, 60), ya.tone_animation(0.5, sprite, [1, 0.65, 0, 1]), ya.scalar(0.5, sprite, :zoom=, 1, 0))))
end
animation_user = ya.player(ya.parallel(setup_animation, *create_particle_sprites), ya.camera_move_animation, ya.resolved(ya.se_play('moves/karate-chop'), ya.parallel(ya.wait(1.1), fall_animation, sprite_animation, deformation_animation, ya.parallel(ya.wait(0.6), *particle_animations))), ya.parallel(ya.dispose_sprite(:sprite), *dispose_particle_sprites), ya.camera_reset_position)
Battle::MoveAnimation.register_specific_animation(:karate_chop, :first_use, animation_user, ya.wait(0))
ya = Yuki::Animation
animation_target = ya.wait(0)
seed_sprites = 4.times.map { |i| "seed_#{i}".freeze }
seed_properties = [[:load, 'seed', :animation], [:opacity=, 255], [:zoom=, 0], [:set_origin, 16, 16]]
create_seed_animations = seed_sprites.map { |s| ya.create_sprite(:viewport, s, Sprite, nil, *seed_properties) }
dispose_seed_animations = seed_sprites.map { |s| ya.dispose_sprite(s) }
seed_throw_animations = seed_sprites.map.with_index do |sprite, i|
  zoom_animation = ya.player(ya.parallel(ya.particle_zoom_x(0.5, sprite, :target, 0, 0.7), ya.particle_zoom_y(0.5, sprite, :target, 0, 1)), ya.parallel(ya.particle_zoom_x(0.2, sprite, :target, 0.7, 0), ya.particle_zoom_y(0.2, sprite, :target, 1, 0)))
  next(ya.player(ya.wait(0.2 * i), ya.particle_random_sprite_command(sprite, :user, 0, 0), ya.parallel(ya.wait(0.5), zoom_animation, ya.rotation(0.8, sprite, 0, 1440), ya.particle_move_to_sprite(0.7, sprite, :user, :target, 0, 0), ya.scalar_offset(0.7, sprite, :y, :y=, 20, -64, distortion: :SQUARE010_DISTORTION))))
end
position_array = [[0, 0], [-21, -3], [21, 3]]
seed_grow_sprites = 3.times.map { |i| "growth_#{i}".freeze }
seed_grow_properties = [[:load, 'seed-growth', :animation], [:opacity=, 255], [:zoom=, 0], [:set_origin, 16, 32], [:set_rect, 0, 0, 32, 32]]
create_seed_grow_animations = seed_grow_sprites.map { |s| ya.create_sprite(:viewport, s, Sprite, nil, *seed_grow_properties) }
dispose_seed_grow_animations = seed_grow_sprites.map { |s| ya.dispose_sprite(s) }
seeds_growth_animations = seed_grow_sprites.map.with_index do |sprite, i|
  sprite_src_rect_animations = 5.times.flat_map { |j| [ya.wait(0.05), ya.send_command_to(sprite, :set_rect, 32 * j, 0, 32, 32)] }
  next(ya.player(ya.wait(0.6), ya.particle_on_sprite_command(sprite, :target, *position_array[i]), ya.tone_animation(0, sprite, [0.08, 0.94, 0.05, 0.83]), ya.wait(0.1 * i), ya.particle_zoom(0, sprite, :target, 0, 1), *sprite_src_rect_animations, ya.wait(0.2), ya.opacity_change(0.3, sprite, 255, 0)))
end
animation_target = ya.player(ya.parallel(*create_seed_animations, *create_seed_grow_animations), ya.resolved(ya.parallel(ya.parallel(ya.wait(1.5), *seeds_growth_animations), ya.parallel(ya.wait(0.7), *seed_throw_animations))), ya.parallel(*dispose_seed_animations, *dispose_seed_grow_animations))
animation_user = ya.player(ya.se_play('moves/leech-seed-1'), ya.wait(0.8), ya.send_command_to(:target, :center_camera), ya.wait(1.5), ya.send_command_to(:visual, :start_center_animation))
Battle::MoveAnimation.register_specific_animation(:leech_seed, :first_use, animation_user, animation_target)
ya = Yuki::Animation
particle_sprites = 20.times.map { |i| "particle_#{i}".freeze }
distortions = %i[POWDER_1 POWDER_2 POWDER_3 POWDER_4 POWDER_5] * 4
create_sprites_animations = particle_sprites.map do |s|
  next(ya.create_sprite(:viewport, s, Sprite, nil, [:load, 'Circle-blurry-M-2', :animation], [:opacity=, 255], [:zoom=, 0], [:set_origin, 16, 16]))
end
sprite_animations = particle_sprites.map.with_index do |particle, i|
  move_animation = ya.parallel(ya.scalar_x_from_sprite(1.2, particle, :target, 0, 15, distortion: distortions[i]), ya.falling_animation(1.2, particle, :target, 80, distortion: :UNICITY_DISTORTION), ya.particle_zoom(1.2, particle, :target, 0.7, 0.3, distortion: :POSITIVE_OSCILLATING_16), ya.player(ya.wait(0.8), ya.opacity_change(0.3, particle, 255, 0)))
  next(ya.player(ya.tone_animation(0, particle, [0.78, 0.26, 0.93, 0.83]), ya.wait(0.2 * i / 5), ya.particle_zoom(0, particle, :target, 0, 0.5), move_animation))
end
dispose_sprite_animations = particle_sprites.map { |s| ya.dispose_sprite(s) }
pokemon_animation = ya.player(ya.wait(0.5), ya.send_command_to(:target, :stop_gif_animation=, true), ya.send_command_to(:target, :set_tone_to, 0.78, 0.26, 0.93, 0.6), ya.compress(0.15, :target, -0.2, 0.2, iteration: 5), ya.send_command_to(:target, :reset_tone_status), ya.send_command_to(:target, :stop_gif_animation=, false))
animation_target = ya.player(ya.parallel(*create_sprites_animations), ya.resolved(ya.player(ya.camera_move_animation(:target), ya.se_play('moves/poison-powder')), ya.parallel(ya.wait(1.5), *sprite_animations, pokemon_animation), ya.camera_reset_position), ya.parallel(*dispose_sprite_animations))
Battle::MoveAnimation.register_specific_animation(:poison_powder, :first_use, ya.wait(0), animation_target)
ya = Yuki::Animation
particles = 16.times.map { |i| "sprite_#{i}".freeze }
create_particle_sprites = particles.map do |s|
  next(ya.create_sprite(:viewport, s, Sprite, nil, [:load, 'Circle-blurry-M-2', :animation], [:zoom=, 0], [:set_origin, 16, 16]))
end
particle_animations = particles.map do |s|
  ya.player(ya.tone_animation(0, s, [0.92, 0.65, 0.08, 1]), ya.wait(rand * 0.4), ya.parallel(ya.radius_move(0.5, s, :user, 90, reversed: true), ya.particle_zoom(0.35, s, :user, 0.7, 0)), ya.dispose_sprite(s))
end
star_particles = 10.times.map { |i| "star_sprite_#{i}".freeze }
star_animations = star_particles.map do |sprite_id|
  next(ya.healing_particle_animation(sprite_id, {filename: 'star-4-ring-L', on: :user, origin: [32, 32], offsets: [0.4, 0], spawn_color: [0.97, 0.97, 0.73, 0.9], up_color: [0.86, 0.78, 0.26, 0.9], fade_color: [0.93, 0.68, 0.41, 0.9], delta_y: 50}))
end
animation_user = ya.player(ya.parallel(*create_particle_sprites), ya.resolved(ya.camera_move_animation(:user), ya.se_play('moves/recover'), ya.parallel(ya.player(ya.wait(0.2), ya.compress(0.3, :user, 0.15, -0.4)), *particle_animations, ya.player(ya.wait(0.1), ya.parallel(*star_animations)))), ya.camera_reset_position)
Battle::MoveAnimation.register_specific_animation(:recover, :first_use, animation_user, ya.wait(0))
ya = Yuki::Animation
particle_sprites = 20.times.map { |i| "particle_#{i}".freeze }
distortions = %i[POWDER_1 POWDER_2 POWDER_3 POWDER_4 POWDER_5] * 4
create_sprites_animations = particle_sprites.map do |s|
  next(ya.create_sprite(:viewport, s, Sprite, nil, [:load, 'circle-blurry-m-2', :animation], [:opacity=, 255], [:zoom=, 0], [:set_origin, 16, 16]))
end
sprite_animations = particle_sprites.map.with_index do |particle, i|
  move_animation = ya.parallel(ya.scalar_x_from_sprite(1.2, particle, :target, 0, 15, distortion: distortions[i]), ya.falling_animation(1.2, particle, :target, 80, distortion: :UNICITY_DISTORTION), ya.particle_zoom(1.2, particle, :target, 0.7, 0.3, distortion: :POSITIVE_OSCILLATING_16), ya.player(ya.wait(0.8), ya.opacity_change(0.3, particle, 255, 0)))
  next(ya.player(ya.tone_animation(0, particle, [0, 0.94, 0.58, 0.83]), ya.wait(0.2 * i / 5), ya.particle_zoom(0, particle, :target, 0, 0.5), move_animation))
end
dispose_sprite_animations = particle_sprites.map { |s| ya.dispose_sprite(s) }
pokemon_animation = ya.player(ya.wait(0.5), ya.send_command_to(:target, :stop_gif_animation=, true), ya.send_command_to(:target, :set_tone_to, 0, 0.94, 0.58, 0.6), ya.compress(0.15, :target, -0.2, 0.2, iteration: 5), ya.send_command_to(:target, :reset_tone_status), ya.send_command_to(:target, :stop_gif_animation=, false))
animation_target = ya.player(ya.parallel(*create_sprites_animations), ya.resolved(ya.player(ya.camera_move_animation(:target), ya.se_play('moves/poison-powder')), ya.parallel(ya.wait(1.5), *sprite_animations, pokemon_animation), ya.camera_reset_position), ya.parallel(*dispose_sprite_animations))
Battle::MoveAnimation.register_specific_animation(:sleep_powder, :first_use, ya.wait(0), animation_target)
ya = Yuki::Animation
particle_sprites = 20.times.map { |i| "particle_#{i}".freeze }
distortions = %i[POWDER_1 POWDER_2 POWDER_3 POWDER_4 POWDER_5] * 4
create_sprites_animations = particle_sprites.map do |s|
  next(ya.create_sprite(:viewport, s, Sprite, nil, [:load, 'Circle-blurry-M-2', :animation], [:opacity=, 255], [:zoom=, 0], [:set_origin, 16, 16]))
end
sprite_animations = particle_sprites.map.with_index do |particle, i|
  move_animation = ya.parallel(ya.scalar_x_from_sprite(1.2, particle, :target, 0, 15, distortion: distortions[i]), ya.falling_animation(1.2, particle, :target, 80, distortion: :UNICITY_DISTORTION), ya.particle_zoom(1.2, particle, :target, 0.7, 0.3, distortion: :POSITIVE_OSCILLATING_16), ya.player(ya.wait(0.8), ya.opacity_change(0.3, particle, 255, 0)))
  next(ya.player(ya.tone_animation(0, particle, [0.97, 0.91, 0.08, 0.83]), ya.wait(0.2 * i / 5), ya.particle_zoom(0, particle, :target, 0, 0.5), move_animation))
end
dispose_sprite_animations = particle_sprites.map { |s| ya.dispose_sprite(s) }
pokemon_animation = ya.player(ya.wait(0.5), ya.send_command_to(:target, :stop_gif_animation=, true), ya.send_command_to(:target, :set_tone_to, 0.97, 0.91, 0.08, 0.6), ya.compress(0.15, :target, -0.2, 0.2, iteration: 5), ya.send_command_to(:target, :reset_tone_status), ya.send_command_to(:target, :stop_gif_animation=, false))
animation_target = ya.player(ya.parallel(*create_sprites_animations), ya.resolved(ya.player(ya.camera_move_animation(:target), ya.se_play('moves/poison-powder')), ya.parallel(ya.wait(1.5), *sprite_animations, pokemon_animation), ya.camera_reset_position), ya.parallel(*dispose_sprite_animations))
Battle::MoveAnimation.register_specific_animation(:stun_spore, :first_use, ya.wait(0), animation_target)
ya = Yuki::Animation
animation_user = ya.user_bank_relative_animation([ya.ellipse(1.5, :user, 18, 9, turn: 2), ya.ellipse(1.5, :user, 11, -5, turn: 2)])
animation_target = ya.se_play('moves/tail_whip')
Battle::MoveAnimation.register_specific_animation(:tail_whip, :first_use, animation_user, animation_target)
ya = Yuki::Animation
animation_user = ya.wait(0.1)
sprite_src_rect_animations = 5.times.flat_map do
  next([ya.wait(0.05), ya.send_command_to(:sprite, :set_rect, 192, 0, 192, 192), ya.wait(0.05), ya.send_command_to(:sprite, :set_rect, 0, 0, 192, 192)])
end
animation_target = ya.player(ya.create_sprite(:viewport, :sprite, Sprite, nil, [:load, '017-Thunder02', :animation], [:set_rect, 0, 0, 192, 192], [:zoom=, 0.5], [:set_origin, 96, 192]), ya.resolved(ya.move_sprite_position(0, :sprite, :target, :target), ya.se_play('moves/thunder_wave'), ya.send_command_to(:sprite, :z=, 1), *sprite_src_rect_animations, ya.wait(0.05)), ya.dispose_sprite(:sprite))
Battle::MoveAnimation.register_specific_animation(:thunder_wave, :first_use, animation_user, animation_target)
ya = Yuki::Animation
animation_user = ya.wait(0.05)
sprite_src_rect_animations = 8.times.flat_map do |i|
  next(7.times.flat_map { |j| [ya.wait(0.015), ya.send_command_to(:sprite, :set_rect, 200 * j, 200 * i, 200, 200)] })
end
animation_target = ya.player(ya.create_sprite(:viewport, :sprite, Sprite, nil, [:load, 'vine-whip', :animation], [:set_rect, 0, 0, 200, 200], [:zoom=, 1], [:set_origin, 100, 100]), ya.resolved(ya.particle_zoom(0, :sprite, :target, 1, 1), ya.move_sprite_position(0, :sprite, :target, :target), ya.se_play('moves/vine_whip'), ya.send_command_to(:sprite, :z=, 1), *sprite_src_rect_animations, ya.wait(0.05)), ya.dispose_sprite(:sprite))
Battle::MoveAnimation.register_specific_animation(:vine_whip, :first_use, animation_user, animation_target)
ya = Yuki::Animation
particle_sprites = 20.times.map { |i| "particle_#{i}".freeze }
distortions = %i[POWDER_1 POWDER_2 POWDER_3 POWDER_4 POWDER_5] * 4
create_sprites_animations = particle_sprites.map do |s|
  next(ya.create_sprite(:viewport, s, Sprite, nil, [:load, 'Circle-blurry-M-2', :animation], [:opacity=, 255], [:zoom=, 0], [:set_origin, 16, 16]))
end
sprite_animations = particle_sprites.map.with_index do |particle, i|
  move_animation = ya.parallel(ya.scalar_x_from_sprite(1.2, particle, :target, 0, 15, distortion: distortions[i]), ya.falling_animation(1.2, particle, :target, 80, distortion: :UNICITY_DISTORTION), ya.particle_zoom(1.2, particle, :target, 0.7, 0.3, distortion: :POSITIVE_OSCILLATING_16), ya.player(ya.wait(0.8), ya.opacity_change(0.3, particle, 255, 0)))
  next(ya.player(ya.tone_animation(0, particle, [0.78, 0.26, 0.93, 0.83]), ya.wait(0.2 * i / 5), ya.particle_zoom(0, particle, :target, 0, 0.5), move_animation))
end
dispose_sprite_animations = particle_sprites.map { |s| ya.dispose_sprite(s) }
pokemon_animation = ya.player(ya.wait(0.5), ya.send_command_to(:target, :stop_gif_animation=, true), ya.send_command_to(:target, :set_tone_to, 0.78, 0.26, 0.93, 0.6), ya.compress(0.15, :target, -0.2, 0.2, iteration: 5), ya.send_command_to(:target, :reset_tone_status), ya.send_command_to(:target, :stop_gif_animation=, false))
animation_target = ya.player(ya.parallel(*create_sprites_animations), ya.resolved(ya.player(ya.camera_move_animation(:target), ya.se_play('moves/poison-powder')), ya.parallel(ya.wait(1.5), *sprite_animations, pokemon_animation), ya.camera_reset_position), ya.parallel(*dispose_sprite_animations))
Battle::MoveAnimation.register_specific_animation(:panicea, :first_use, ya.wait(0), animation_target)
