module PSMA
  module TitleOverwrite
    AIU_KEY2METHOD = GamePlay::BaseCleanUpdate::AIU_KEY2METHOD
      .merge({ LEFT: nil, RIGHT: nil })
      .transform_values! { :action_a }

    def next_splash_initialize
      if @splash_counter == 3
        @current_state = :title_animation # Just to be sure
        return create_title_animation
      end

      @splash_counter += 1
      if @splash_counter == 3
        @background.bitmap.dispose
        @background.load('psdk3', :picture)
        @gif_handler = nil
        create_splash_gif_fade_out
      else
        @background.opacity = 255
        @gif_handler = Yuki::GifReader.create("psdk#{@splash_counter}.gif", :picture)
        create_splash_gif_animation
      end
      @splash_animation.start
    end

    def update_graphics
      super
      @gif_handler.update(@background.bitmap) if @gif_handler
    end

    def create_splash_gif_animation
      ya = Yuki::Animation
      @splash_animation = ya.wait_signal { @gif_handler.frame + 1 >= @gif_handler.frame_count }
      @splash_animation.play(ya.send_command_to(self, :next_splash_initialize))
    end

    def create_splash_gif_fade_out
      ya = Yuki::Animation
      @splash_animation = ya.player(
        ya.se_play('newsoupnintendo'),
        ya.wait(0.5),
        ya.opacity_change(0.4, @background, 255, 0),
        ya.send_command_to(self, :next_splash_initialize)
      )
    end

    def create_title_background
      @gif_handler = Yuki::GifReader.create('background.gif', :picture)
      @background.opacity = 255
    end

    def create_title_controls
      # TODO: show the starten picture and give it its animation
    end
    
    # Jump straight to game if main action is pressed
    def action_a
      action_play_game
    end

    # Force existing actions to use action_a
    alias action_up action_a
    alias action_down action_a

    # Update inputs (implement any button behavior)
    def update_inputs
      return false unless super

      return automatic_input_update(AIU_KEY2METHOD)
    end
  end
end
Scene_Title.prepend(PSMA::TitleOverwrite)
