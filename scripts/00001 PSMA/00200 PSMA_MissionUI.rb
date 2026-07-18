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
  # Mission UI scene
  class MissionUI < GamePlay::BaseCleanUpdate
    MISSIONS = [
      { rank: 'E', icon: 'main_quest_icon', location: :zone_16, quest_id: :quest_2, unlock_switch: 189 },
      { rank: 'A', icon: nil, location: :zone_16, quest_id: :quest_1, unlock_switch: 190 },
    ]

    def initialize
      super()
      @missions = load_missions
    end

    # Mission object in the Mission UI (provides interface to data needed for UI)
    class Mission
      VALID_RANK = %w[E D C B A S]
      
      # @return [String | nil] icon of the mission
      attr_reader :icon

      # @return [Integer] rank of the mission in the ranks.png file
      attr_reader :rank

      # Create a new mission from items in MISSIONS array
      # @param rank [String] rank of the mission
      # @param icon [String | nil] icon shown in UI for the mission
      # @param location [Symbol] ID of the zone where the player must go to perform the mission
      # @param quest_id [Symbol] ID of the quest connected to the mission
      # @param unlock_switch [Integer | nil] ID of the switch enabling the mission in the board
      def initialize(rank:, icon:, location:, quest_id:, unlock_switch:)
        @rank = validate_rank(rank)
        @icon = icon
        @location = validate_location(location)
        @quest = validate_quest(quest_id)
        @unlock_switch = validate_unlock_switch(unlock_switch)
      end

      # Get the location name of the mission
      # @return [String]
      def location_name
        return @location.name
      end

      # Get the name of the mission (<=> quest name)
      # @return [String]
      def name
        return @quest.name
      end

      # Get the description of the mission (<=> quest description)
      # @return [String]
      def description
        return @quest.description
      end

      private

      def validate_rank(rank)
        rank_index = VALID_RANK.index(rank)
        raise "Invalid rank `#{rank}` for mission" unless rank_index

        return rank_index
      end

      def validate_location(location)
        zone = data_zone(location)
        if zone.db_symbol != location
          raise "Received invalid location `#{location}` for mission"
        end

        return zone
      end

      def validate_quest(quest_id)
        quest = data_quest(quest_id)
        if quest.db_symbol != quest_id
          raise "Received invalid quest_id `#{quest_id}` for mission"
        end

        return quest
      end

      def validate_unlock_switch(switch_id)
        raise "Mission was not filtered properly" unless $game_switches[switch_id]

        return true
      end
    end

    private

    # Load all the missions
    # @return [Array<Mission>]
    def load_missions
      return MISSIONS.filter_map do |mission|
        next nil unless $game_switches[mission[:unlock_switch]]

        next Mission.new(**mission)
      end
    end

    # To implement
    # 1. Mission filtering based on switch (+ validation)
    # 2. Mission List Item (in composition)
    # 3. Mission List Scroll Bar (in composition)
    # 4. Mission Details (+ description scrollbar => composition2 + viewport for scrolling)
    # 5. Confirmation when accepting mission
    # (see player choice for locked message)
  end
end
