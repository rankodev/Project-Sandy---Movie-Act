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

# $game_switches[189] = true
# $game_switches[190] = true
# $scene.call_scene(PSMA::MissionUI)
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

    def create_graphics
      super
      create_list_composition
      #create_mission_composition
      # create_entry_animation
    end

    def create_list_composition
      @list_composition = ListComposition.new(@viewport, @missions)
    end

    def create_mission_composition
      @mission_composition = MissionComposition.new(@viewport)
    end

    def update_graphics
      @list_composition.update
      #@mission_composition.update
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

      # Check if the mission is taken
      def taken?
        quests = PFM.game_state.quests
        quest_id = @quest.id
        return quests.finished?(quest_id) || !!quests.active_quest(quest_id)
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

    class ListComposition < UI::SpriteStack
      # @param viewport [Viewport]
      # @param missions [Array<Mission>]
      def initialize(viewport, missions)
        super(viewport)
        @missions = missions
        @index = 0
        create_graphics
      end

      private

      def create_graphics
        create_background
        create_mission_list
        create_scroll_bar
        create_selector
      end

      def create_background
        add_background('mission_ui/mission_board')
      end

      def create_mission_list
        @mission_list = 5.times.map do |i|
          MissionListElement.new(@viewport, i).tap { |e| e.data = @missions[i] }
        end
      end

      def create_scroll_bar
        @scrollbar = add_sprite(75, 80, 'mission_ui/scrollbar')
      end

      def create_selector
        @selector = add_sprite(0, 0, 'mission_ui/highlighter')
        coordinates = @mission_list[0].stack[0]
        @selector.x = coordinates.x
        @selector.y = coordinates.y
      end
    end

    class MissionListElement < UI::SpriteStack
      BASE_Y = 80 # TODO: Fixme
      DELTA_Y = 60 # TODO: Fixme
      BASE_X = 80 # TODO: Fixme

      # @param viewport [Viewport]
      # @param index [Integer]
      def initialize(viewport, index)
        super(viewport, BASE_X, BASE_Y + index * DELTA_Y)
        create_graphics
      end

      # @param mission [Mission]
      def data=(mission)
        self.visible = !!mission
        return unless mission

        @name.text = mission.name
        @rank.sx = mission.rank
        @taken.visible = mission.taken?
        if mission.icon
          @icon.visible = true
          @icon.load("mission_ui/#{mission.icon}", :interface)
        else
          @icon.visible = false
        end
      end

      private

      def create_graphics
        create_icon
        create_name
        create_taken
        create_rank
      end

      def create_icon
        @icon = add_sprite(0, 16, NO_INITIAL_IMAGE, ox: 16, oy: 32)
      end

      def create_name
        @name = add_text(32, 0, 0, 16, nil.to_s, color: 10)
      end

      def create_taken
        @taken = add_sprite(120, 0, 'mission_ui/taken')
      end

      def create_rank
        # @type [SpriteSheet]
        @rank = add_sprite(160, 0, 'mission_ui/ranks', 1, 6, type: SpriteSheet)
      end
    end
  end
end
