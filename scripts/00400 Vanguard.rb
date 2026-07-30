module Battle
    module Effects
      class Ability
        class SupremeVanguard < Ability
          def initialize(logic, target, db_symbol)
            super
            @multiplier = 0
            @endure_used = false
            @show_endure_message = false
          end

          def on_switch_event(handler, who, with)
            return if with != @target

            @endure_used = false
            return if handler.logic.retrieve_party_from_battler(with).all?(&:alive?)

            @multiplier = 0
            handler.logic.retrieve_party_from_battler(with).each { |battler| @multiplier += battler.ko_count }
            @multiplier = @multiplier.clamp(0, 5)
            @multiplier = (@multiplier / 10.0).truncate(1)
            log_data("Supreme Vanguard - Defenses increased by #{1 + @multiplier}")
            handler.scene.visual.show_ability(with)
            handler.scene.visual.wait_for_animation
            handler.scene.display_message_and_wait(parse_text_with_pokemon(66, 1666, with))
          end

          def on_damage_prevention(handler, hp, target, launcher, skill)
            return if @endure_used
            return if target != @target || target == launcher
            return if target.hp > hp
            return unless launcher && skill
            return unless launcher.can_be_lowered_or_canceled?

            @endure_used = true
            @show_endure_message = true
            return target.hp - 1
          end

          def on_post_damage(handler, hp, target, launcher, skill)
            return unless @show_endure_message

            @show_endure_message = false
            handler.scene.visual.show_ability(target)
            handler.scene.display_message_and_wait(parse_text_with_pokemon(19, 514, target))
          end

          def dfe_modifier
            return super + @multiplier
          end

          def dfs_modifier
            return super + @multiplier
          end

        end
        register(:supreme_vanguard, SupremeVanguard)
      end
    end
  end
  