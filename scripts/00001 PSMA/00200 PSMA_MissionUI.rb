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
      { rank: 'E', icon: 'main_quest_icon', location: :zone_18, quest_id: :quest_2, unlock_switch: 189 },
      { rank: 'A', icon: nil, location: :zone_18, quest_id: :quest_1, unlock_switch: 190 },
      { rank: 'B', icon: 'main_quest_icon', location: :zone_18, quest_id: :quest_2, unlock_switch: 189 },
      { rank: 'C', icon: 'main_quest_icon', location: :zone_18, quest_id: :quest_2, unlock_switch: 189 },
      { rank: 'D', icon: 'main_quest_icon', location: :zone_18, quest_id: :quest_2, unlock_switch: 189 },
      { rank: 'E', icon: 'main_quest_icon', location: :zone_18, quest_id: :quest_2, unlock_switch: 189 },
      { rank: 'S', icon: 'main_quest_icon', location: :zone_18, quest_id: :quest_2, unlock_switch: 189 },
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

    def update_inputs
      @running = false if Input.trigger?(:B)
      p [Mouse.x, Mouse.y] if Mouse.trigger?(:LEFT)
      return if @list_composition.update_inputs
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

      def update_inputs
        if Input.repeat?(:DOWN)
          @index = (@index + 1) % @missions.size
          update_offsets
        elsif Input.repeat?(:UP)
          @index = (@index - 1) % @missions.size
          update_offsets
        else
          return false
        end

        return true
      end

      private

      def update_offsets
        start_index = compute_start_index
        @selector.y = (@index - start_index) * MissionListElement::DELTA_Y + @selector_base_y
        @scrollbar.y = @scrollbar_base_y + (@index / (@missions.size - 1.0)) * 100 if @missions.size > 1
        refresh_list(start_index)
      end

      def compute_start_index
        return 0 if @index < 2
        return 0 if @missions.size <= 5
        return @index - 2 if (@index + 3) <= @missions.size
        return @missions.size - 5
      end

      def refresh_list(start_index)
        @mission_list.each_with_index do |mission, i|
          mission.data = @missions[i + start_index]
        end
      end

      def create_graphics
        create_background
        create_selector
        create_mission_list
        create_scroll_bar
      end

      def create_background
        add_background('mission_ui/mission_board')
        add_sprite(96, 15, 'mission_ui/mission_label')
        add_sprite(267, 15, 'mission_ui/rank_label')
      end

      def create_mission_list
        @mission_list = 5.times.map do |i|
          MissionListElement.new(@viewport, i).tap { |e| e.data = @missions[i] }
        end
      end

      def create_scroll_bar
        @scrollbar = add_sprite(87, 42, 'mission_ui/scrollbar', ox: 5) # 41 - 173 (30)
        @scrollbar_base_y = @scrollbar.y
      end

      def create_selector
        @selector = add_background('mission_ui/highlighter')
        @selector.x = MissionListElement::BASE_X - 18
        @selector.y = MissionListElement::BASE_Y - 6
        @selector_base_y = @selector.y
        @selector.src_rect.width = 219
      end
    end

    class MissionListElement < UI::SpriteStack
      BASE_Y = 50
      DELTA_Y = 25
      BASE_X = 107

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
        @icon = add_sprite(0, 16, NO_INITIAL_IMAGE, ox: 16, oy: 29)
      end

      def create_name
        @name = add_text(16, 0, 0, 16, nil.to_s, color: 10)
      end

      def create_taken
        @taken = add_sprite(120, 5, 'mission_ui/taken')
        @taken.zoom = 0.5
      end

      def create_rank
        # @type [SpriteSheet]
        @rank = add_sprite(178, 0, 'mission_ui/ranks', 6, 1, type: SpriteSheet)
      end
    end
  end
end

if ENV['PSDK_BINARY_PATH'] == '/Volumes/mvme/projects/PokemonStudio/psdk-binaries/'
  class Scene_Map
    def update
      @spriteset.update
      if Input.trigger?(:X)
        $game_switches[189] = true
        $game_switches[190] = true
        $scene.call_scene(PSMA::MissionUI)
      end
    end
  end
end
