module Battle
  class Scene
    attr_reader :attack_item_wrapper

    # Get the item wrapper stored by the last item shortcut
    # @return [PFM::ItemDescriptor::Wrapper, nil]
    attr_accessor :attack_item_shortcut

    # Method that asks the attack item to use
    # @note When @attack_item_shortcut is set (via last item shortcut), the bag UI is skipped
    # @note Non-attack items are handled inline to avoid reopening the bag
    def attack_item_choice
      @attack_item_wrapper = @attack_item_shortcut || @visual.show_item_choice
      @attack_item_shortcut = nil

      return @next_update = :player_action_choice unless @attack_item_wrapper
      return attack_item_choice_normal_item unless @attack_item_wrapper.attack_item

      # @type [Studio::TechItem]
      tech_item = @attack_item_wrapper.item
      studio_move = data_move(tech_item.move)
      battle_move = Battle::Move[studio_move.be_method].new(studio_move.db_symbol, 1, 1, self)
      @visual.show_item_skill_choice(@player_actions.size, battle_move)
      @next_update = :attack_item_target_choice
    ensure
      @skip_frame = true
    end

    private

    # Handle a non-attack item selected from the bag opened by attack_item_choice
    def attack_item_choice_normal_item
      return if special_item_choice_action(@attack_item_wrapper)

      user = @logic.battler(0, @player_actions.size)
      @player_actions << Actions::Item.new(self, @attack_item_wrapper, user.bag, user)
      if @attack_item_wrapper.item.is_limited
        user.bag.remove_item(@attack_item_wrapper.item.db_symbol, 1)
        @logic.player_processing_item << @attack_item_wrapper.item
      end

      log_debug("Action : #{@player_actions.last}") if debug?
      @next_update = can_player_make_another_action_choice? ? :player_action_choice : :trigger_all_AI
    end

    public

    # Method that asks the target of the choosen move
    def attack_item_target_choice
      launcher, move, target_bank, target_position, _mega = @visual.show_target_choice
      return @next_update = :player_action_choice unless launcher && move && target_bank && target_position

      @player_actions << Actions::AttackItem.new(self, launcher.bag, @attack_item_wrapper, move, launcher, target_bank, target_position)
      if @attack_item_wrapper.item.is_limited
        launcher.bag.remove_item(@attack_item_wrapper.item.db_symbol, 1)
        @logic.player_processing_item << @attack_item_wrapper.item
      end

      log_debug("Action : #{@player_actions.last}") if debug?
      @next_update = can_player_make_another_action_choice? ? :player_action_choice : :trigger_all_AI
    ensure
      @skip_frame = true
    end

    module ScenePatch
      # Redirect :bag to :attack_item_choice which handles both normal and attack items
      # @param choice [Symbol]
      # @param forced_action [Battle::Actions::Base]
      def player_action_choice_internal(choice, forced_action)
        return super unless choice == :bag

        @next_update = :attack_item_choice
      end

      # Clean the action that was removed from the stack (Make sure we don't lock things)
      def clean_action(action)
        return super unless action.is_a?(Actions::AttackItem)

        $bag.add_item(@logic.player_processing_item.last.db_symbol)
        @logic.player_processing_item.pop
      end
    end

    prepend ScenePatch
  end
end
