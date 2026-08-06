module UI
    # item boxes representing materials
    class CraftItemBox < SpriteStack
        BOX_WIDTH = 38
        BOX_HEIGHT = 40
        BOX_STRIDE_X = 6
        BOX_STRIDE_Y = 2
        BOX_BASE_X = 5
        BOX_BASE_Y = 5

        def initialize(viewport, index)
            super(viewport, *get_coordinates(index))
            @index = index
            @data = {}
            @visible = false
            create_sprite
        end

        def create_sprite
            @box = add_sprite(0, 0, 'craft/items_box', :interface)
            @item_icon = add_sprite(3, 3, NO_INITIAL_IMAGE)
        end

        def get_coordinates(index)
            coords = [
                BOX_BASE_X + (index % 4)*(BOX_WIDTH + BOX_STRIDE_X),
                BOX_BASE_Y + (index / 4)*(BOX_HEIGHT + BOX_STRIDE_Y)
            ]
            return coords
        end

        def data=(data)
            @data = data
            update_sprites
        end

        def update_sprites
            @item_icon.set_bitmap(CraftInfos.get_primary_item_icon(@data["item_sym"]), :interface)
            if $bag.item_quantity(@data["item_sym"]) <= 0
                @item_icon.opacity = 96
            else
                @item_icon.opacity = 255
            end
        end

        def hide
            self.visible = false
            @visible = false
        end

        def show
            self.visible = true
            @visible = true
        end

        def select
            @box.set_bitmap('craft/items_box_selected', :interface)
        end

        def unselect
            @box.set_bitmap('craft/items_box', :interface)
        end

        def index
            return @index
        end

        def visible?
            return @visible
        end

        def reposition(x, y)
            self.x = x
            self.y = y
        end
    end

    class CraftCategoryHeader < SpriteStack
        def initialize(viewport, x, y)
            super(viewport, x, y)
            @label = add_text(0, 0, 200, 16, nil.to_s, color: 9)
            @label.z = 5
        end

        def text=(str)
            @label.text = str
        end

        def hide
            self.visible = false
        end

        def show
            self.visible = true
        end
    end

    class CraftItemInfoBox < SpriteStack
        BOX_BASE_X = 5
        BOX_BASE_Y = 160

        def initialize(viewport)
            super(viewport, BOX_BASE_X, BOX_BASE_Y)
            @data = nil
            create_sprite
            @description = create_descr_text
        end

        def create_sprite
            @bg = add_background('craft/win_info')
        end

        def create_descr_text
            text = add_text(8, 4, 310, 16, nil.to_s, color: 9)
            text.z = 5
            return text
        end

        # data is a symbol representing an item
        def data=(data)
            @data = data
            update_description
        end

        def update_description
            @description.multiline_text = data_item(data).descr
        end
    end

    class IngredientsBox < SpriteStack
        BOX_BASE_X = 186
        BOX_BASE_Y = 1
        MAX_SLOTS = 4

        def initialize(viewport)
            super(viewport, BOX_BASE_X, BOX_BASE_Y)
            @tray = {}
            @recipe_sprites = []
            create_sprite
        end

        def create_sprite
            @bg = add_background('craft/ingredients_box')
            0.upto(MAX_SLOTS - 1) do |idx|
                @recipe_sprites << IngredientsInfo.new(@viewport, idx)
            end
        end

        def tray=(tray)
            @tray = tray
            idx = 0
            @tray.each do |item_sym, quantity|
                break if idx >= MAX_SLOTS

                @recipe_sprites[idx].data = { "item_sym" => item_sym, "quantity" => quantity }
                idx += 1
            end
            idx.upto(MAX_SLOTS - 1) do |i|
                @recipe_sprites[i].data = nil
            end
        end
    end

    class IngredientsInfo < SpriteStack
        BASE_X = 196
        BASE_Y = 7
        HEIGHT = 32
        Y_STRIDE = 3
        def initialize(viewport, index)
            super(viewport, *get_coordinates(index))
            @index = index
            @data = nil
            @item_icon = create_sprite
            @ingredient_name_text = create_ingredient_name
            @ingredient_quantity_text = create_ingredient_quantity
        end

        def create_sprite
            sp = add_sprite(0, 0, NO_INITIAL_IMAGE)
            return sp
        end

        def create_ingredient_name
            text = add_text(34, 4, 0, 13, nil.to_s, color: 9)
            text.z = 2
            return text
        end

        def create_ingredient_quantity
            text = add_text(34, 18, 0, 13, nil.to_s, color: 9)
            text.z = 2
            return text
        end

        def get_coordinates(index)
            coords = [
                BASE_X,
                BASE_Y + index*(Y_STRIDE + HEIGHT)
            ]
            return coords
        end

        # data is a hash containing item_sym and quantity keys — quantity
        # here is "how many of this item are currently in the tray"
        def data=(data)
            @data = data
            update_sprites
        end

        def update_sprites
            if @data
                @item_icon.set_bitmap(CraftInfos.get_primary_item_icon(@data["item_sym"]), :interface)
                @item_icon.opacity = 255
                @ingredient_name_text.text = CraftInfos.get_primary_item_name(@data["item_sym"])
                @ingredient_quantity_text.text = "#{$bag.item_quantity(@data["item_sym"]).to_s.to_pokemon_number}#{"/".to_pokemon_number}#{@data["quantity"].to_s.to_pokemon_number}"
            else
                @item_icon.opacity = 0
                @ingredient_name_text.text = nil.to_s
                @ingredient_quantity_text.text = nil.to_s
            end
        end
    end

end
