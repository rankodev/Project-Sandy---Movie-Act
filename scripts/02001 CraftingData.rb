module PFM
  module CraftingData
    Recipe = Struct.new(:id, :ingredients, :result, :info_required, :description) do
      def signature
        ingredients.sort.hash
      end

      def matches?(selection)
        signature == selection.sort.hash
      end
    end

    module_function

    # builds recipe from craftdb to bridge old system to new system
    def find_matching(selection)
      CraftInfos::RECIPES.each do |result_sym, ingredients|
        recipe = Recipe.new(result_sym, ingredients, result_sym, CraftInfos::LOCKED_RECIPES.include?(result_sym), nil)
        return recipe if recipe.matches?(selection)
      end
      return nil
    end

    def find_by_id(id)
      ingredients = CraftInfos::RECIPES[id]
      return nil unless ingredients

      return Recipe.new(id, ingredients, id, CraftInfos::LOCKED_RECIPES.include?(id), nil)
    end
  end
end
