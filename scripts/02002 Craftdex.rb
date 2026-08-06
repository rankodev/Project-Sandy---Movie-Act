module PFM

    class Craftdex
        # get game state
        # @return [PFM::GameState]
        attr_accessor :game_state

        # get all primary items player has
        attr_accessor :primary_items

        # unused - legacy
        attr_accessor :unlocked_ingredients

        # permits unlocked
        attr_writer :permits

        # recipes discovered
        attr_writer :discovered

        # current crafting tray contents
        attr_writer :tray

        # last successful craft
        attr_reader :last_recipe

        # ingredients player has had at any point in bag
        attr_writer :found_ingredients

        def initialize(game_state = PFM.game_state)
            @game_state = game_state
            @primary_items = initialize_primary_items
            @unlocked_ingredients = []
            @permits = []
            @discovered = []
            @tray = {}
            @last_recipe = nil
            @found_ingredients = []
        end

        # fix to ensure old saves don't crash
        def permits
            @permits ||= []
        end

        def discovered
            @discovered ||= []
        end

        def tray
            @tray ||= {}
        end

        def found_ingredients
            @found_ingredients ||= []
        end

        def found?(sym)
            found_ingredients.include?(sym)
        end

        def mark_found(sym)
            found_ingredients << sym unless found_ingredients.include?(sym)
        end

        # marks everything in bag as found - call when opening crafting
        def refresh_found_ingredients!
            CraftInfos::PRIMARY_M_LIST.each do |sym|
                mark_found(sym) if $bag.item_quantity(sym) > 0
            end
            CraftInfos.starter_ingredients.each { |sym| mark_found(sym) }
        end

        def initialize_primary_items
            primary_items = {}
            CraftInfos::PRIMARY_M_LIST.each do |sym|
                primary_items[sym] = 0
            end
            return primary_items
        end

        def unlock(sym)
            @unlocked_ingredients << sym
        end

        # whether permit has been unlocked or not
        def permit?(sym)
            @permits.include?(sym)
        end

        # unlocks permit
        def unlock_permit(sym)
            @permits << sym unless @permits.include?(sym)
        end

        # discovers recipe
        def discover(recipe_id)
            @discovered << recipe_id unless @discovered.include?(recipe_id)
        end

        def known?(recipe_id)
            @discovered.include?(recipe_id)
        end

        def get_max_craftable_quantity(recipe, recipe_name = nil)
            maximum = 99
            log_info(recipe_name)
            recipe.each do |ingredient, quantity|
                new_candidate = $bag.item_quantity(ingredient) / quantity
                if new_candidate < maximum
                    maximum = new_candidate
                end
            end
            return maximum == 0 ? 0 : 1 if recipe_name == :graveler_statue
            return maximum
        end

        # checks if recipe craftable
        def can_craft(recipe, nb=1)
            recipe.each do |ingredient, quantity|
                return false if $bag.item_quantity(ingredient) < nb*quantity
            end
            return true
        end

        # legacy craft modified to give permit
        def craft(sym, nb)
            recipe = CraftInfos.get_recipe(sym)
            recipe.each do |ingredient, quantity|
                $bag.remove_item(ingredient, quantity*nb)
            end
            unlock_permit(sym)
            @unlocked_ingredients.delete(:graveler_statue) if sym == :graveler_statue
        end

        def add_primary_item(sym, quantity)
            @primary_items[sym] += quantity 
        end

        # adds one unit of item to crafting tray, capped by bag contents
        def add_to_tray(item_symbol)
            already = @tray[item_symbol] || 0
            return false if $bag.item_quantity(item_symbol) <= already
            @tray[item_symbol] = already + 1
            true
        end

        def remove_from_tray(item_symbol)
            return false unless @tray[item_symbol]
            @tray[item_symbol] -= 1
            @tray.delete(item_symbol) if @tray[item_symbol] <= 0
            true
        end

        def clear_tray
            @tray.clear
        end

        # checks order independent match against recipes, on success grants permit
        def attempt_tray_craft
            @last_recipe = nil
            return :empty if @tray.empty?
            recipe = PFM::CraftingData.find_matching(@tray)
            return :no_match unless recipe
            return :undiscovered if recipe.info_required && !known?(recipe.id)
            return :already_unlocked if permit?(recipe.result)
            @tray.each { |sym, qty| $bag.remove_item(sym, qty) }
            unlock_permit(recipe.result)
            discover(recipe.id)
            @last_recipe = recipe
            clear_tray
            :success
        end
    end
    
    class GameState
        attr_accessor :craftdex

        on_player_initialize(:craftdex) { @craftdex = PFM::Craftdex.new(self) }
        on_expand_global_variables(:craftdex) do
            @craftdex ||= PFM::Craftdex.new(self)
            $craftdex = @craftdex
            @craftdex.game_state = self
        end
    end
end
