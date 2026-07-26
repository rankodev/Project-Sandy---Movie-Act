# Extension: on_poison_damage and on_burn_damage hooks
module Battle
  module Effects
    class EffectBase
      def on_poison_damage(h, hp, t); nil; end
      def on_burn_damage(h, hp, t); nil; end
    end
    module StatusDamageHook
      def on_end_turn_event(logic, scene, battlers)
        return unless battlers.include?(target) && !target.dead?
        if respond_to?(:toxic?) && toxic?
          @toxic_count += 1
          inc = true
        end
        hp = status_damage_amount
        hn = global_poisoning? ? :on_poison_damage : :on_burn_damage
        h_ov = hp
        res = logic.each_effects(target) do |e|
          r = e.send(hn, logic.damage_handler, h_ov, target)
          if r.is_a?(Integer); h_ov = r; next r; end
          next r if r == :prevent
          next nil
        end
        if res == :prevent; return nil
        elsif res.is_a?(Integer)
          if h_ov < 0; logic.damage_handler.heal(target, h_ov.abs)
          else; scene.visual.show_status_animation(target, @status); logic.damage_handler.damage_change(h_ov.clamp(1, Float::INFINITY), target); end
          return nil
        end
        @toxic_count -= 1 if inc; super
      end
      def status_damage_amount
        return poison_effect if respond_to?(:poison_effect)
        return burn_effect if respond_to?(:burn_effect)
        0
      end
    end
    [Status::Poison, Status::Toxic, Status::Burn].each { |k| k.prepend(StatusDamageHook) }
  end
end
