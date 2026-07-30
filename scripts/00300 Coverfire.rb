module Battle
    module Effects
      class CoverfireCenterOfAttention < CenterOfAttention
        def target_redirection(user, targets, move)
          return if targets.include?(user)

          super
        end
      end

      class CoverfireShield < PokemonTiedEffectBase
        # Create a new CoverfireShield effect
        # @param logic [Battle::Logic]
        # @param pokemon [PFM::PokemonBattler]
        def initialize(logic, pokemon)
          super(logic, pokemon)
          self.counter = 1
        end

        # Reduce incoming damage by 25% for the Coverfire user
        # @param user [PFM::PokemonBattler] user of the move
        # @param target [PFM::PokemonBattler] target of the move
        # @param move [Battle::Move] the move being used
        # @return [Float]
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
      # Get the reason why the move is disabled
      # @param user [PFM::PokemonBattler] user of the move
      # @return [#call] Block that should be called when the move is disabled
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
      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        user.effects.add(Effects::CoverfireCenterOfAttention.new(logic, user, 1, self))
        user.effects.add(Effects::CoverfireShield.new(logic, user))
        scene.display_message_and_wait(parse_text_with_pokemon(19, 670, user))
      end
      # Test if any alive battler used followMe this turn
      # @param user [PFM::PokemonBattler] user of the move
      # @return [Boolean]
      def any_battler_with_follow_me_effect?(user)
        last_move_history = logic.adjacent_allies_of(user).map { |battler| battler.successful_move_history.last }.compact
        return last_move_history.any? { |move_history| move_history.current_turn? && move_history.move.be_method == :s_follow_me }
      end
    end
    Move.register(:s_coverfire, Coverfire)
    end
  end