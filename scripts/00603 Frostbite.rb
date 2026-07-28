module Battle
  module Effects
    class Status
      class Frostbite < Status
        # Give the move mod1 mutiplier (before the +2 in the formula)
        # @param user [PFM::PokemonBattler] user of the move
        # @param target [PFM::PokemonBattler] target of the move
        # @param move [Battle::Move] move
        # @return [Float, Integer] multiplier
        def mod1_multiplier(user, target, move)
          return 1 if user != self.target
          return 1 unless move.special?

          return 0.5
        end

        # Prevent frostbite from being applied twice
        # @param handler [Battle::Logic::StatusChangeHandler]
        # @param status [Symbol] :poison, :toxic, :confusion, :sleep, :freeze, :paralysis, :burn, :flinch, :cure
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        # @return [:prevent, nil] :prevent if the status cannot be applied
        def on_status_prevention(handler, status, target, launcher, skill)
          # Ignore if status is not frostbitten or the taget is not the target of this effect
          return if target != self.target
          return if status != :freeze

          # Prevent change by telling the target is already paralysed
          return handler.prevent_change do
            handler.scene.display_message_and_wait(parse_text_with_pokemon(19, 297, target))
          end
        end

        # Apply frostbite effect on end of turn
        # @param logic [Battle::Logic] logic of the battle
        # @param scene [Battle::Scene] battle scene
        # @param battlers [Array<PFM::PokemonBattler>] all alive battlers
        def on_end_turn_event(logic, scene, battlers)
          return unless battlers.include?(target)
          return if target.dead?
          return if target.has_ability?(:magic_guard)

          hp = frost_effect
          # Apply heat proof protection
          hp /= 2 if target.has_ability?(:heatproof)
          scene.display_message_and_wait(parse_text_with_pokemon(19, 291, target))
          scene.visual.show_rmxp_animation(target, 469 + status_id)
          logic.damage_handler.damage_change(hp.clamp(1, Float::INFINITY), target)

          # Ensure the procedure does not get blocked by this effect
          nil
        end

        private

        # Return the Burn effect on HP of the Pokemon
        # @return [Integer] number of HP loosen
        def frost_effect
          return (target.max_hp / 8).clamp(1, Float::INFINITY)
        end
      end

      register(:freeze, Frostbite)
    end

    module Mechanics
      module ForceNextMove
        # Function that tells us if we should pause the move or not
        # @param user [PFM::PokemonBattler] user of the move
        def paused?(user)
          return true if move && MOVES_PAUSED.none?(move.db_symbol) && (user.asleep? || user.effects.has?(:flinch))

          return false
        end

        # Function that tells us if we should interrupt the move or not
        # @param user [PFM::PokemonBattler] user of the move
        def interrupted?(user)
          return true if move && MOVES_PAUSED.none?(move.db_symbol) && (user.asleep? || user.effects.has?(:flinch))

          return false
        end
      end

      module OutOfReach
        # Function that tells us if we should interrupt the move or not
        # @param user [PFM::PokemonBattler] user of the move
        def interrupted?(user)
          return true if move && MOVES_PAUSED.none?(move.db_symbol) && (user.asleep? || user.effects.has?(:flinch))

          return false
        end
      end
    end
  end

  class Logic
    class CatchHandler
      STATUS_MODIFIER[:freeze] = 1.5
    end
  end

  class Move
    class PreAttackBase
      def can_pre_use_move?(user)
        @enabled = false
        return false if user.asleep?

        @enabled = true
        return true
      end
    end

    class Facade
      # Check if the move must be boosted
      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] target of the move
      # @return [Boolean]
      def boosted?(user, target)
        return user.status? && !user.asleep?
      end
    end
  end
end

module BattleUI
  class PokemonSprite
    STATUS_TONE[:freeze] = [0.23, 0.56, 1, 0.8, 0]
  end
end

module Battle
  module AI
    class Base
      # Generate the heal item action for the pokemon
      # @param pokemon [PFM::PokemonBattler]
      # @param move_heuristics [Array<Float>]
      # @return [Array<[Float, Actions::Item]>]
      def status_heal_item_actions_for(pokemon, move_heuristics)
        if pokemon.burn?
          items = BURN_HEAL_ITEMS
          rate = 1 - pokemon.hp_rate / 4
        elsif pokemon.poisoned? || pokemon.toxic?
          items = POISON_HEAL_ITEMS
          rate = 1 - pokemon.hp_rate / 4
        elsif pokemon.paralyzed?
          items = PARALYZE_HEAL_ITEMS
          rate = 0.78
        elsif pokemon.frozen?
          items = FREEZE_HEAL_ITEMS
          rate = 1 - pokemon.hp_rate / 4
        elsif pokemon.asleep?
          items = WAKE_UP_ITEMS
          rate = 0.76
        end
        return items.select { |item| pokemon.bag.contain_item?(item) }.map do |item|
          wrapper = PFM::ItemDescriptor.actions(item)
          wrapper.bind(@scene, pokemon)
          next([rate, Actions::Item.new(@scene, wrapper, pokemon.bag, pokemon)])
        end.compact
      end
    end
  end
end
