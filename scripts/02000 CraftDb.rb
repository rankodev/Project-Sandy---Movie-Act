module CraftInfos
    PRIMARY_M_LIST = %i[plain_seed spare_cloth dull_berry persim_berry rawst_berry pecha_berry chesto_berry cheri_berry pomeg_berry kelpsy_berry qualot_berry hondew_berry grepa_berry tamato_berry oran_berry gravelerock potion poke_ball quality_cloth fantastic_cloth exotic_seed majestic_seed stiff_berry majestic_berry]

        # NAME
        PRIMARY_M_DATA = {
            :plain_seed => ["Plain Seed"],
            :spare_cloth => ["Spare Cloth"],
            :dull_berry => ["Dull Berry"],
            :oran_berry => ["Oran Berry"],
            :persim_berry => ["Persim Berry"],
            :rawst_berry => ["Rawst Berry"],
            :pecha_berry => ["Pecha Berry"],
            :chesto_berry => ["Chesto Berry"],
            :cheri_berry => ["Cheri Berry"],
            :pomeg_berry => ["Pomeg Berry"],
            :kelpsy_berry => ["Kelpsy Berry"],
            :qualot_berry => ["Qualot Berry"],
            :hondew_berry => ["Hondew Berry"],
            :grepa_berry => ["Grepa Berry"],
            :tamato_berry => ["Tamato Berry"],
            :gravelerock => ["Gravelerock"],
            :potion => ["Potion"],
            :poke_ball => ["Poke Ball"],
            :quality_cloth => ["Quality Cloth"],
            :fantastic_cloth => ["Fantastic Cloth"],
            :exotic_seed => ["Exotic Seed"],
            :majestic_seed => ["Majestic Seed"],
            :stiff_berry => ["Stiff Berry"],
            :majestic_berry => ["Majestic Berry"],
        }

        # make sure main ingredient is first for categorisation in the filter
        RECIPES = {
            :totter_seed => {:plain_seed => 1, :oran_berry => 1 },
            :sleep_seed => {:plain_seed => 1, :chesto_berry => 1 },
            :noxious_seed => {:plain_seed => 1, :pecha_berry => 1 },
            :stun_seed => {:plain_seed => 1, :cheri_berry => 1},
            :quick_seed => {:plain_seed => 1, :tamato_berry => 2 },
            :sharp_seed => {:majestic_seed => 1, :oran_berry => 1, :chesto_berry => 1 },
            :iron_seed => {:plain_seed => 1, :qualot_berry => 2 },
            :amplify_seed => {:exotic_seed => 1, :oran_berry => 1 },
            :fortify_seed => {:plain_seed => 1, :grepa_berry => 2 },
            :oran_berry => {:potion => 2},
            :sitrus_berry => {:majestic_berry => 1, :oran_berry => 1, :chesto_berry => 1},
            :persim_band => {:spare_cloth => 2, :persim_berry => 1 },
            :pecha_scarf => {:quality_cloth => 1, :oran_berry => 1 },
            :defense_scarf => {:spare_cloth => 1, :oran_berry => 1},
            :zinc_band => {:fantastic_cloth => 1, :oran_berry => 1, :chesto_berry => 1},
            :graveler_statue => {:gravelerock => 3 },
            :pomeg_berry => {:dull_berry => 1, :oran_berry => 1},
            :tamato_berry => {:stiff_berry => 1, :oran_berry => 1}
        }

        # recipes here require $craftdex.discover(:recipe_id)
        LOCKED_RECIPES = %i[defense_scarf zinc_band graveler_statue]

        # groups recipes into filter categories
        CATEGORIES = {
            :study_scarf => %i[defense_scarf pecha_scarf zinc_band],
            :specialty_seed => %i[totter_seed amplify_seed sharp_seed],
            :pinch_berries => %i[pomeg_berry tamato_berry sitrus_berry]
        }

    module_function

    def get_primary_item_name(sym)
        entry = PRIMARY_M_DATA[sym]
        return entry[0] if entry
        log_error("CraftInfos: #{sym} is missing a PRIMARY_M_DATA entry, falling back to item name")
        return data_item(sym).name
    end

    def get_primary_item_icon(sym)
        entry = PRIMARY_M_DATA[sym]
        return "craft/ingredients/#{entry[0]}" if entry
        return "craft/ingredients/#{data_item(sym).name}"
    end

    def get_recipe(sym)
        return RECIPES[sym]
    end

    def main_ingredients_for(category)
        CATEGORIES[category].map { |result| RECIPES[result].keys.first }
    end

    def other_ingredients_for(category)
        mains = main_ingredients_for(category)
        others = []
        CATEGORIES[category].each do |result|
            RECIPES[result].keys.each do |ingredient|
                others << ingredient unless mains.include?(ingredient) || others.include?(ingredient)
            end
        end
        return others
    end

    def starter_ingredients
        CATEGORIES.values.flat_map do |results|
            RECIPES[results.first].keys
        end.uniq
    end
end