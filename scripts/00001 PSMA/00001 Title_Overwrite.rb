module PSMA
  module TitleOverwrite
    # Make all input keys use the action_a method
    AIU_KEY2METHOD = GamePlay::BaseCleanUpdate::AIU_KEY2METHOD
      .merge({ LEFT: nil, RIGHT: nil })
      .transform_values! { :action_a }

    # Update all gif / animations
    def update_graphics
      super
      @gif_handler.update(@background.bitmap) if @gif_handler
      @title_gif_handler.update(@title.bitmap) if @title_gif_handler
      @title_anim&.update
      @start_anim&.update
    end

    # Create the next splash after the default splash
    def next_splash_initialize
      if @splash_counter == 3
        @current_state = :title_animation # Just to be sure
        return create_title_animation
      end

      @splash_counter += 1
      # When we are at the last splash, we show "made with PSDK"
      if @splash_counter == 3
        @background.bitmap.dispose
        @background.load('psdk3', :picture)
        @gif_handler = nil
        create_splash_gif_fade_out
      else
        # Otherwise we use the gif animation for the appearance + rainbow
        @background.opacity = 255
        @gif_handler = Yuki::GifReader.create("psdk#{@splash_counter}.gif", :picture)
        create_splash_gif_animation
      end
      # Start the new splash animation
      @splash_animation.start
    end

    # Create the splash gif animation (wait for last gif frame + show next splash)
    def create_splash_gif_animation
      ya = Yuki::Animation
      @splash_animation = ya.wait_signal { @gif_handler.frame + 1 >= @gif_handler.frame_count }
      @splash_animation.play(ya.send_command_to(self, :next_splash_initialize))
    end

    # Create the splash fade out animation
    def create_splash_gif_fade_out
      ya = Yuki::Animation
      @splash_animation = ya.player(
        ya.se_play('newsoupnintendo'),
        ya.wait(0.5),
        ya.opacity_change(0.4, @background, 255, 0),
        ya.send_command_to(self, :next_splash_initialize)
      )
    end

    # Create the gif background, this time sprite already exists so we just load the gif handler
    # Note: The existing background is the same size,
    #       if the PSDK logo was a different size we'd have
    #       to re-create the background texture (otherwise crash)
    def create_title_background
      @gif_handler = Yuki::GifReader.create('background.gif', :picture)
      @background.opacity = 255
    end

    # Create the game title + animation
    # Note: I did not bother loading the static PNG as the last frame is good
    def create_title_title
      @title_gif_handler = Yuki::GifReader.create('title_anim.gif', :picture)
      @title = Sprite.new(@viewport)
      @title.z = 200
      @title.bitmap = Texture.new(@title_gif_handler.width, @title_gif_handler.height)
      ya = Yuki::Animation
      @title_anim = ya.wait_signal { @title_gif_handler.frame + 1 >= @title_gif_handler.frame_count }
      @title_anim.play(ya.send_command_to(self, :stop_title_gif))
      @title_anim.start
    end

    # Stop the title animation by setting the gif handler to nil (no further update)
    def stop_title_gif
      @title_gif_handler = nil
    end

    # Create the press any key to continue sprite & animation
    def create_title_controls
      @start = Sprite.new(@viewport)
      @start.z = 150
      @start.load('starten', :picture)
      ya = Yuki::Animation
      @start_anim = ya.timed_loop_animation(1.75, [
        ya.opacity_change(0.5, @start, 0, 255),
        ya.wait(0.5),
        ya.opacity_change(0.5, @start, 255, 0),
        ya.wait(0.25),
      ])
      @start_anim.start
    end
    
    # Jump straight to game if main action is pressed
    def action_a
      action_play_game
      return true
    end

    # Force existing actions to use action_a
    alias action_up action_a
    alias action_down action_a

    # Update inputs (implement any button behavior)
    def update_inputs
      return false unless super

      return action_a if Mouse.press?(:LEFT)

      return automatic_input_update(AIU_KEY2METHOD)
    end

    # Nicely dispose the title texture
    def dispose
      @title&.bitmap&.dispose
      super
      # Flush the title cache
      RPG::Cache.load_title(true)
    end
  end
end
Scene_Title.prepend(PSMA::TitleOverwrite)
