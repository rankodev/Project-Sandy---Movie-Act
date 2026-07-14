# Mission UI allows the game to show a list of quests to take
# Each mission has rank, optional icon, location, quest and unlock_switch
#
# Rank is a value between E and S (E D C B A S)
# Icon is the filename of the icon in mission ui or nil (eg. 'main_quest_icon')
# Location is the ID of the the zone where the player should go
# Quest is the ID of the quest containing mission name, description & loot
# unlock_switch is the ID of the switch to enable so the mission is available on the board

# TODO: 
# Main menu:
#  -> Message locked "(What kind of mission are available today… ?)"
#  -> Show list of unlocked missions
#  --> List item shows name, rank and taken status
#  -> List has a scroll bar on the left showing how far we are in the list
# Sub menu:
#  -> Message remains
#  -> Shows the quest info (see txt file)
module PSMA
  class MissionUI < GamePlay::BaseCleanUpdate
    MISSIONS = [
      { rank: 'E', icon: 'main_quest_icon', location: :zone_16, quest_id: :quest_2, unlock_switch: 189 },
      { rank: 'A', icon: nil, location: :zone_16, quest_id: :quest_1, unlock_switch: 190 },
    ]

    # To implement
    # 1. Mission filtering based on switch (+ validation)
    # 2. Mission List Item (in composition)
    # 3. Mission List Scroll Bar (in composition)
    # 4. Mission Details (+ description scrollbar => composition2 + viewport for scrolling)
    # 5. Confirmation when accepting mission
    # (see player choice for locked message)
  end
end
