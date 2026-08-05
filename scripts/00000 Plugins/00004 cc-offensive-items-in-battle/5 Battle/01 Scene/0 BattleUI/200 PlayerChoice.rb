module BattleUI
  class PlayerChoice
    class SubChoice
      # Patch to handle chen prevention for attack items in the last item shortcut
      module AttackItemShortcutPatch
        # Intercept the shortcut action to check chen prevention for attack items
        # @note Base only checks chen for FleeingItem, this extends to attack items
        def action_a
          item = $bag.last_battle_item
          return super if item.id == 0 || !$bag.contain_item?(item.db_symbol)

          item_wrapper = PFM::ItemDescriptor.actions(item.id)
          if item_wrapper.attack_item && item_wrapper.chen
            play_buzzer_se
            @scene.message_window.wait_input = true
            @scene.display_message(parse_text(22, 43))
            return
          end

          return super
        end
      end

      prepend AttackItemShortcutPatch
    end
  end
end
