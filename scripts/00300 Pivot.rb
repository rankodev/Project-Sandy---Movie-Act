module Battle
    class Move
        class Pivot < Move
      def move_usable_by_user(user, targets)
        return false unless super
        allies = @logic.allies_of(user)
        if allies.empty?
          show_usage_failure(user)
          return false
        end

        chosen_ally = targets&.first
        if chosen_ally && !allies.include?(chosen_ally)
          show_usage_failure(user)
          return false
        end
        return true
      end
      def no_choice_skill?
        return false
      end
      def battler_targets(pokemon, logic)
        return logic.allies_of(pokemon)
      end
      def deal_effect(user, actual_targets)
        ally = actual_targets.first || @logic.allies_of(user).first
        @logic.switch_battlers(user, ally)
        scene.visual.show_switch_form_animation(ally)
        scene.visual.show_switch_form_animation(user)
        scene.display_message_and_wait(parse_text_with_pokemon(19, 1143, user, PFM::Text::PKNICK[1] => ally.given_name))
        @logic.stat_change_handler.stat_change_with_process(:spd, 1, user, user, self)
        @logic.stat_change_handler.stat_change_with_process(:spd, 1, ally, user, self)
        @logic.all_alive_battlers.each { |pokemon| scene.visual.refresh_info_bar(pokemon) }
      end
    end
    Move.register(:s_pivot, Pivot)
    end
end