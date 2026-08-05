module GamePlay
  class Bag < BaseCleanUpdate::FrameBalanced
    # @type [Array<Integer>]
    battle_pockets = POCKETS_PER_MODE[:battle]
    unless battle_pockets.include?(3)
      heal_index = battle_pockets.index(2)
      battle_pockets.insert(heal_index ? heal_index + 1 : 0, 3)
    end
  end
end
