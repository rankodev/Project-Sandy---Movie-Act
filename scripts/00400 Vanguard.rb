module Battle
    module Effects
      class Ability
        class SupremeVanguard < Ability
          def initialize(logic, target, db_symbol)
            super
            @endure_used = false
            @show_endure_message = false
            @last_dead_count = 0
          end

          def on_switch_event(handler, who, with)
            return if with != @target

            @endure_used = false
            @last_dead_count = current_dead_count(with)
            multiplier = current_multiplier(with)
            return if multiplier <= 0

            log_data("Supreme Vanguard - Defenses increased by #{1 + multiplier}")
            handler.scene.visual.show_ability(with)
            handler.scene.visual.wait_for_animation
            handler.scene.display_message_and_wait(parse_text_with_pokemon(66, 1666, with))
          end

          def on_end_turn_event(logic, scene, battlers)
            return unless battlers.include?(@target)
            return if @target.dead?

            dead_count = current_dead_count
            if dead_count > @last_dead_count
              scene.visual.show_ability(@target)
              scene.visual.wait_for_animation
              scene.display_message_and_wait(parse_text_with_pokemon(66, 1666, @target))
            end
            @last_dead_count = dead_count
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
            return super + current_multiplier
          end

          def dfs_modifier
            return super + current_multiplier
          end

          private

          def current_dead_count(battler = @target)
            return @logic.retrieve_party_from_battler(battler).count { |ally| !ally.alive? }
          end

          def current_multiplier(battler = @target)
            dead_count = current_dead_count(battler)
            return (dead_count.clamp(0, 5) / 10.0).truncate(1)
          end

        end
        register(:supreme_vanguard, SupremeVanguard)
      end
    end
  end
  