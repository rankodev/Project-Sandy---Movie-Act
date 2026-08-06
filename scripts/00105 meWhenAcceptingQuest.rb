module AddMEWhenAcceptingQuest
  def show_quest_inform(names, quest_status)
    super
    return unless $scene.is_a?(Scene_Map)
    
    Audio.me_play('audio/me/sraMission.ogg') if quest_status == :new && names.any?
  end
end

PFM::Quests.prepend(AddMEWhenAcceptingQuest)
