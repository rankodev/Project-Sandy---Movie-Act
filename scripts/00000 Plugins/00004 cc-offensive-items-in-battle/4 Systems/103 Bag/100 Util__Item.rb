module Util
  module Item
    module AttackItemPatch
      # Use an item in a GamePlay::Base child class
      # @param item_id [Integer] ID of the item in the database
      # @return [PFM::ItemDescriptor::Wrapper, false] item descriptor wrapper if the item could be used
      def util_item_useitem(item_id, &result_process)
        item_wrapper = PFM::ItemDescriptor.actions(item_id)
        return super unless item_wrapper.attack_item && $game_temp.in_battle

        if item_wrapper.chen
          display_message(parse_text(22, 43))
          return false
        elsif item_wrapper.no_effect
          display_message(parse_text(22, 108))
          return false
        end

        return util_attack_item_on_use_sequence(item_wrapper, result_process)
      end

      # Part where the item_wrapper request to use the item
      # @param item_wrapper [PFM::ItemDescriptor::Wrapper]
      # @param result_process [Proc, nil]
      # @return [PFM::ItemDescriptor::Wrapper]
      def util_attack_item_on_use_sequence(item_wrapper, result_process)
        # @type [Battle::Scene]
        scene = $scene.find_parent(Battle::Scene)
        # @type [Battle::Logic]
        logic = scene.logic
        # @type [Studio::TechItem]
        tech_item = item_wrapper.item

        pokemon_name = logic.battler(0, scene.player_actions.size).given_name
        move_name    = data_move(tech_item.move).name

        text_keys = {
          PFM::Text::PKNICK[0] => pokemon_name,
          PFM::Text::MOVE[0] => move_name
        }

        display_message(parse_text(10_002, 0, text_keys))

        item_wrapper.on_attack_item_use(self)
        result_process&.call
        return item_wrapper
      end
    end

    prepend AttackItemPatch
  end
end
