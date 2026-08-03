module Battle
    module Effects
      class CoverfireCenterOfAttention < CenterOfAttention
        def target_redirection(user, targets, move)
          target_list = Array(targets)
          return if target_list.include?(user)

          super
        end
      end

      class CoverfireShield < PokemonTiedEffectBase
        # @param logic [Battle::Logic]
        # @param pokemon [PFM::PokemonBattler]
        def initialize(logic, pokemon)
          super(logic, pokemon)
          self.counter = 1
        end

        def on_effectiveness_multiplier(user, target, move)
          return 1.0 if target != @pokemon
          return 0.75
        end

        # Name of the effect
        # @return [Symbol]
        def name
          :coverfire_shield
        end
      end
    end

    class Move
    class Coverfire < Basic
      def disable_reason(user)
        return unless user.move_history&.last&.db_symbol == db_symbol
        return proc {@logic.scene.display_message_and_wait(parse_text_with_pokemon(19, 911, user, PFM::Text::MOVE[1] => name)) }
      end
      def move_usable_by_user(user, targets)
        return false unless super
        if logic.battle_info.vs_type == 1 || logic.battler_attacks_last?(user) || any_battler_with_follow_me_effect?(user)
          show_usage_failure(user)
          return false
        end
        return true
      end
      private

      def deal_effect(user, actual_targets)
        user.effects.add(Effects::CoverfireCenterOfAttention.new(logic, user, 1, self))
        user.effects.add(Effects::CoverfireShield.new(logic, user))
        scene.display_message_and_wait(parse_text_with_pokemon(19, 670, user))
      end
      def any_battler_with_follow_me_effect?(user)
        last_move_history = logic.adjacent_allies_of(user).map { |battler| battler.successful_move_history.last }.compact
        return last_move_history.any? { |move_history| move_history.current_turn? && move_history.move.be_method == :s_follow_me }
      end
    end
    Move.register(:s_coverfire, Coverfire)
    end
  end