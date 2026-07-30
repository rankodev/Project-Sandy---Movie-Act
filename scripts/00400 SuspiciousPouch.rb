module Battle
  module Effects
    class Ability
      class SuspiciousPouch < Ability
        SPECIAL_ITEMS = %i[
            flame_orb toxic_orb light_ball iron_ball lagging_tail kings_rock flame_orb toxic_orb light_ball iron_ball lagging_tail
          ]

        def target_has_no_item?
          symbol = @target.item_db_symbol
          symbol == :__undef__ || symbol.nil?
        end

        def on_end_turn_event(logic, scene, battlers)
          return unless battlers.include?(@target)
          return if @target.dead?
          return unless target_has_no_item?

          SPECIAL_ITEMS.shuffle.each do |picked_item|
            logic.item_change_handler.change_item(picked_item, true, @target)
            break unless target_has_no_item?
          end

          return if target_has_no_item?

          scene.visual.show_ability(@target)
          scene.display_message_and_wait(parse_text_with_pokemon(6969, 11, @target, PFM::Text::ITEM2[1] => @target.item_name))
        end
      end
      register(:suspicious_pouch, SuspiciousPouch)
    end
  end
end

module Battle
  module Effects
    class Item
      module SuspiciousPouchOrbImmunity
        def on_end_turn_event(logic, scene, battlers)
          if @target&.bank == 0 && @target.has_ability?(:suspicious_pouch)
            return
          end

          super
        end
      end

      class FlameOrb
        prepend SuspiciousPouchOrbImmunity
      end

      class ToxicOrb
        prepend SuspiciousPouchOrbImmunity
      end
    end
  end
end
