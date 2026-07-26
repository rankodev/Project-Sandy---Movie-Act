# Extension: Global Stat Change Hooks
module Battle
  module Effects
    module SelfStatChangeEffectExtension
      def on_global_stat_change(h, s, p, t, l, sk); nil; end
      def on_global_stat_change_post(h, s, p, t, l, sk); nil; end
      def on_self_stat_change(h, s, p, t, l, sk); nil; end
      def on_self_stat_change_post(h, s, p, t, l, sk); nil; end
      def disable_hooks
        super
        class << self
          alias on_self_stat_change on_stat_increase_prevention
          alias on_self_stat_change_post on_stat_increase_prevention
          alias on_global_stat_change on_stat_increase_prevention
          alias on_global_stat_change_post on_stat_increase_prevention
        end
      end
    end
    class EffectBase
      prepend SelfStatChangeEffectExtension
    end
  end
  class Logic
    module SelfStatChangeExtension
      def handle_stat_change_events(stat, power, target, launcher, skill)
        power = super
        logic.each_effects(*logic.all_alive_battlers) do |e|
          res = e.on_global_stat_change(self, stat, power, target, launcher, skill)
          power = res if res.is_a?(Integer)
        end
        if target == launcher
          logic.each_effects(*logic.all_alive_battlers) do |e|
            res = e.on_self_stat_change(self, stat, power, target, launcher, skill)
            power = res if res.is_a?(Integer)
          end
        end
        power
      end
      def handle_stat_change_post_events(stat, power, target, launcher, skill)
        super
        logic.each_effects(*logic.all_alive_battlers) { |e| e.on_global_stat_change_post(self, stat, power, target, launcher, skill) }
        if target == launcher
          logic.each_effects(*logic.all_alive_battlers) { |e| e.on_self_stat_change_post(self, stat, power, target, launcher, skill) }
        end
      end
    end
    class StatChangeHandler
      prepend SelfStatChangeExtension
    end
  end
end
