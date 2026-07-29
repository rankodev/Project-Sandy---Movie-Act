module Battle
  module Effects
    class Ability
      class SuspiciousPouch < Ability
        SPECIAL_ITEMS = %i[
            flame_orb toxic_orb hard_stone light_ball iron_ball kings_rock lagging_tail quick_claw sticky_barb white_herb bread
      ]
        def on_end_turn_event(logic, scene, battlers)
          picked_item = SPECIAL_ITEMS.sample
          return unless battlers.include?(@target)
          return if @target.dead?
          return unless @target.item_db_symbol == :__undef__
          return unless bchance?(0.5)
          scene.visual.show_ability(@target)
          logic.item_change_handler.change_item(picked_item, true, @target)
          scene.display_message_and_wait(parse_text_with_pokemon(19, 475, @target, PFM::Text::ITEM2[1] => @target.item_name))
        end
      end
      register(:suspicious_pouch, SuspiciousPouch)
    end
  end
end

module Battle
  module SuspiciousPouchItemImmunity
    # Special Items don't affect Scraggy
    def suspicious_pouch_blocks_held_item_effects?
      return false unless has_ability?(:suspicious_pouch)

      Battle::Effects::Ability::SuspiciousPouch::SPECIAL_ITEMS.include?(item_db_symbol)
    end

    def hold_item?(*items)
      return false if suspicious_pouch_blocks_held_item_effects?

      super
    end

    def can_use_item?(*args)
      return false if suspicious_pouch_blocks_held_item_effects?

      return super if defined?(super)
      true
    end

    def can_use_held_item?(*args)
      return false if suspicious_pouch_blocks_held_item_effects?

      return super if defined?(super)
      true
    end
  end
end

class PFM::PokemonBattler
  prepend Battle::SuspiciousPouchItemImmunity
end