module Battle
  module Actions
    # Class describing the usage of an AttackItem
    # @note Inherits priority/comparison logic from Attack. pursuit_enabled and ignore_speed stay false.
    class AttackItem < Attack
      # Get the item wrapper executing the action
      # @return [PFM::ItemDescriptor::Wrapper]
      attr_reader :item_wrapper

      # Create a new attack item action
      # @param scene [Battle::Scene]
      # @param bag [PFM::Bag]
      # @param item_wrapper [PFM::ItemDescriptor::Wrapper] the item wrapper executing the action
      # @param move [Battle::Move]
      # @param launcher [PFM::PokemonBattler] the Pokemon responsive of the item usage
      # @param target_bank [Integer] the bank of the target
      # @param target_position [Integer] the position of the target in the bank
      def initialize(scene, bag, item_wrapper, move, launcher, target_bank, target_position)
        super(scene, move, launcher, target_bank, target_position)
        @bag = bag
        @item_wrapper = item_wrapper
      end

      # Execute the action
      def execute
        @bag.last_battle_item_db_symbol = @item_wrapper.item.db_symbol
        return super
      end
    end
  end
end
