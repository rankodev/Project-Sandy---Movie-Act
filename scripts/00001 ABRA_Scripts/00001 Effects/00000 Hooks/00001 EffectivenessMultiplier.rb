# Extension: on_effectiveness_multiplier hook
# This script adds a new effect hook that allows abilities and effects to modify
# the overall effectiveness multiplier of a move (e.g., return 2.0 for double effectiveness).
#
# Usage in abilities:
#   def on_effectiveness_multiplier(user, target, move)
#     return 2.0 if some_condition
#     return 1.0
#   end

module Battle
  class Move
    # Module that extends Battle::Move to support custom effectiveness multipliers
    module EffectivenessMultiplierExtension
      # rubocop:disable Style/RedundantReturn
      # Get the custom effectiveness multiplier from all active effects
      # @param user [PFM::PokemonBattler]
      # @param target [PFM::PokemonBattler]
      # @return [Float]
      def effectiveness_multiplier(user, target)
        return logic.each_effects(user, target).reduce(1.0) do |product, e|
          product * e.on_effectiveness_multiplier(user, target, self)
        end
      end

      # Overwrite type_modifier to include custom multipliers
      # This ensures AI and other logic that use type_modifier see the correct value
      def type_modifier(user, target)
        multiplier = super
        return multiplier * effectiveness_multiplier(user, target)
      end

      # Overwrite damages to apply custom multipliers to the final damage
      def damages(user, target)
        damage = super
        multiplier = effectiveness_multiplier(user, target)

        return (damage * multiplier).floor
      end
    end
    prepend EffectivenessMultiplierExtension
  end

  module Effects
    class EffectBase
      # Function called to get a custom effectiveness multiplier for a move
      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] target of the move
      # @param move [Battle::Move] the move being used
      # @return [Float, Integer] the multiplier to apply to effectiveness
      def on_effectiveness_multiplier(user, target, move)
        nil && user && target && move
        return 1.0
      end
    end
  end
end
