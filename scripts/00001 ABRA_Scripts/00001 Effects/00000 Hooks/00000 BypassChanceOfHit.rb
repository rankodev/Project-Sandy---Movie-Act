# Extension: on_bypass_chance_of_hit? hook
# This script adds a new effect hook that allows abilities to bypass accuracy checks
# (guarantee that moves will hit) under custom conditions.

module Battle
  class Move
    module BypassChanceOfHitExtension
      def bypass_chance_of_hit?(user, target)
        return true if super
        return logic.each_effects(user, target).any? { |e| e.on_bypass_chance_of_hit?(user, target, self) }
      end
    end
    prepend BypassChanceOfHitExtension
  end

  module Effects
    class EffectBase
      def on_bypass_chance_of_hit?(user, target, move)
        nil && user && target && move
      end
    end
  end
end
