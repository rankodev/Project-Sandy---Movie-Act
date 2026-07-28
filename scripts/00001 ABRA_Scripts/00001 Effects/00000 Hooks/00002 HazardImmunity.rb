# Extension: on_ignore_hazards? hook
module Battle
  module Effects
    class EffectBase
      def on_ignore_hazards?(handler, who, with)
        false && handler && who && with
      end
    end
    module HazardImmunityExtension
      def on_switch_event(handler, who, with)
        return if handler.logic.each_effects(with).any? { |e| e.on_ignore_hazards?(handler, who, with) }
        super
      end
    end
    [Spikes, StealthRock, StickyWeb, ToxicSpikes].each { |klass| klass.prepend(HazardImmunityExtension) }
  end
end
