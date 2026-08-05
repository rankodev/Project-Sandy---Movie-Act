module PFM
  module ItemDescriptor
    define_chen_prevention(Studio::TechItem) do |klass|
      next false unless $game_temp.in_battle
      next false if klass.is_battle_usable

      next true
    end

    define_on_attack_item_use(Studio::TechItem) do |item, scene|
      GamePlay.bag_mixin.from(scene).battle_item_wrapper = PFM::ItemDescriptor.actions(item.db_symbol)
      scene.return_to_scene(Battle::Scene)
    end
  end
end
