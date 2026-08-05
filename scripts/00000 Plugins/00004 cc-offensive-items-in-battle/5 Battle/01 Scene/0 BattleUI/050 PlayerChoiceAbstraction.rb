module BattleUI
  module PlayerChoiceAbstraction
    # Patch to redirect attack items to the attack item choice flow instead of creating an Actions::Item
    module AttackItemShortcutPatch
      # Redirect attack items to the attack item choice flow
      # @param item [Studio::Item] the item to use
      def use_item(item)
        item_wrapper = PFM::ItemDescriptor.actions(item.id)
        return super unless item_wrapper.attack_item

        scene.attack_item_shortcut = item_wrapper
        @result = :bag
      end
    end

    prepend AttackItemShortcutPatch
  end
end
