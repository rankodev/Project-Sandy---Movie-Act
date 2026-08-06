module GamePlay
    class CraftMenu < BaseCleanUpdate::FrameBalanced
        include UI

        # A: add selected material to tray | X: attempt craft
        # Y: clear tray               | B: quit
        # L/R: cycle category filter
        ACTIONS = [:in_press_a, :in_press_x, :in_press_y, :in_press_b]

        CATEGORY_ORDER = [:all, :study_scarf, :specialty_seed, :pinch_berries]
        CATEGORY_LABELS = {
            :all => 'All Items',
            :study_scarf => 'Study Scarf',
            :specialty_seed => 'Specialty Seed',
            :pinch_berries => 'Pinch Berries'
        }

        TITLE_Y = 2
        MAIN_HEADER_Y = 20
        MAIN_ROW_Y = 38
        OTHER_HEADER_Y = 80
        OTHER_ROW_Y = 98
        ALL_GRID_Y_OFFSET = 20

        def initialize()
            super()
            @category_index = 0
        end

        def create_graphics
            create_viewport
            $craftdex.refresh_found_ingredients!
            refresh_item_list
            create_base_ui
            create_headers
            create_item_boxes
            create_ingredients
            layout_boxes
            update_item_boxes
            @item_boxes[0].select
            update_item_info_box
        end

        def update_inputs
            if Input.repeat?(:UP)
                update_in_index_change if current_category == :all && set_index_by_delta(-4)
            elsif Input.repeat?(:DOWN)
                update_in_index_change if current_category == :all && set_index_by_delta(4)
            elsif Input.repeat?(:LEFT)
                update_in_index_change if set_index_by_delta(-1)
            elsif Input.repeat?(:RIGHT)
                update_in_index_change if set_index_by_delta(1)
            elsif Input.trigger?(:L)
                cycle_category(-1)
            elsif Input.trigger?(:R)
                cycle_category(1)
            elsif Input.trigger?(:A)
                in_press_a
            elsif Input.trigger?(:X)
                in_press_x
            elsif Input.trigger?(:Y)
                in_press_y
            elsif Input.trigger?(:B)
                in_press_b
            end
            return true
        end
  
        def update_mouse(moved)
            update_mouse_ctrl_buttons(@base_ui.ctrl, ACTIONS)
            if Mouse.released?(:LEFT)
                @item_boxes.each do |box|
                    if box.visible? and box.simple_mouse_in?
                        in_press_a
                    end
                end
            end
            return true unless moved
            @item_boxes.each do |box|
                if box.visible? and box.simple_mouse_in?
                    update_in_index_change if set_index_by_delta(box.index - @index)
                end
            end
        end
  
        def update_graphics
            @base_ui.update_background_animation
            return true
        end

        private

        def current_category
            CATEGORY_ORDER[@category_index]
        end

        def refresh_item_list
            if current_category == :all
                @item_list = CraftInfos::PRIMARY_M_LIST.select { |sym| $craftdex.found?(sym) }
                @main_count = 0
            else
                mains = CraftInfos.main_ingredients_for(current_category).select { |sym| $craftdex.found?(sym) }
                others = CraftInfos.other_ingredients_for(current_category).select { |sym| $craftdex.found?(sym) }
                @item_list = mains + others
                @main_count = mains.length
            end
            @max_index = @item_list.size - 1
            @index = 0
            @real_index = 0
        end

        def cycle_category(delta)
            previous_index = @index
            @category_index = (@category_index + delta) % CATEGORY_ORDER.length
            refresh_item_list
            layout_boxes
            update_item_boxes
            @item_boxes[previous_index].unselect
            @item_boxes[0].select
            update_item_info_box
            play_decision_se
        end

        def create_base_ui
            @base_ui = GenericBase.new(@viewport, button_texts)
            @base_ui.button_texts = ["Add", "Craft", "Clear", "Quit"]
        end

        def button_texts
            return Array.new(4, ext_text(9000, 22 + 3))
        end

        def create_headers
            @category_title = CraftCategoryHeader.new(@viewport, 5, TITLE_Y)
            @main_header = CraftCategoryHeader.new(@viewport, 5, MAIN_HEADER_Y)
            @main_header.text = "Main Ingredients"
            @other_header = CraftCategoryHeader.new(@viewport, 5, OTHER_HEADER_Y)
            @other_header.text = "Other Ingredients"
            update_headers_visibility
        end

        def update_headers_visibility
            @category_title.text = CATEGORY_LABELS[current_category]
            if current_category == :all
                @main_header.hide
                @other_header.hide
            else
                @main_header.show
                @other_header.show
            end
        end

        def create_item_boxes
            @item_boxes = []
            0.upto(15) do |idx|
                @item_boxes << CraftItemBox.new(@viewport, idx)
            end
            @item_info_box = CraftItemInfoBox.new(@viewport)
        end

        def create_ingredients
            @ingredients_box = IngredientsBox.new(@viewport)
            update_tray_display
        end

        def layout_boxes
            update_headers_visibility
            @item_boxes.each(&:hide) 
            if current_category == :all
                @item_boxes.each do |box|
                    x, y = box.get_coordinates(box.index)
                    box.reposition(x, y + ALL_GRID_Y_OFFSET)
                end
            else
                main_count = @main_count
                columns = 4 
                row_height = CraftItemBox::BOX_HEIGHT + CraftItemBox::BOX_STRIDE_Y
                0.upto(15) do |idx|
                    if idx < main_count
                        x = CraftItemBox::BOX_BASE_X + idx*(CraftItemBox::BOX_WIDTH + CraftItemBox::BOX_STRIDE_X)
                        @item_boxes[idx].reposition(x, MAIN_ROW_Y)
                    else
                        other_i = idx - main_count
                        col = other_i % columns
                        row = other_i / columns
                        x = CraftItemBox::BOX_BASE_X + col*(CraftItemBox::BOX_WIDTH + CraftItemBox::BOX_STRIDE_X)
                        y = OTHER_ROW_Y + row*row_height
                        @item_boxes[idx].reposition(x, y)
                    end
                end
            end
        end

        def assign_item_to_box(sym, idx)
            @item_boxes[idx].data = { "item_sym" => sym }
            @item_boxes[idx].show
        end

        def update_item_boxes
            if current_category == :all
                update_item_boxes_scrolling
            else
                update_item_boxes_flat
            end
        end

        def update_item_boxes_flat
            @item_list.each_with_index do |sym, idx|
                assign_item_to_box(sym, idx)
            end
            @item_list.length.upto(15) do |idx|
                @item_boxes[idx].hide
            end
        end

        def update_item_boxes_scrolling
            offset = 0
            @index.downto(0) do |idx|
                current_item_sym = @item_list[@real_index - offset]
                assign_item_to_box(current_item_sym, idx)
                offset += 1
            end

            max = (@max_index - @real_index + @index) >= 15 ? 15 : (@max_index - @real_index + @index)
            offset = 1
            (@index + 1).upto(max) do |idx|
                current_item_sym = @item_list[@real_index + offset]
                assign_item_to_box(current_item_sym, idx)
                offset += 1
            end

            (max + 1).upto(15) do |idx|
                @item_boxes[idx].hide
            end
        end

        def get_selected_item
            return @item_list[@real_index]
        end

        def update_item_info_box
            item = get_selected_item
            return unless item

            @item_info_box.data = item
        end

        def update_tray_display
            @ingredients_box.tray = $craftdex.tray
        end

        def set_index_by_delta(delta)
            return false if delta == 0
            next_real_index = @real_index + delta
            return false if next_real_index < 0 or next_real_index > @max_index
            play_decision_se
            next_index = @index + delta
            next_index = @index - 3 if (delta == 1) and (next_index > 15)
            next_index = @index + 3 if (delta == -1) and (next_index < 0)
            if (next_index >= 0) and (next_index <= 15)
                @item_boxes[next_index].select
                @item_boxes[@index].unselect
                @index = next_index
            end
            @real_index += delta
        end

        def update_in_index_change
            update_item_boxes
            update_item_info_box
        end

        def in_press_a
            item = get_selected_item
            return play_buzzer_se unless item

            if $craftdex.add_to_tray(item)
                play_decision_se
                update_tray_display
            else
                play_buzzer_se
            end
        end

        def in_press_x
            case $craftdex.attempt_tray_craft
            when :empty
                play_buzzer_se
            when :no_match
                display_message(" Nothing happens...")
            when :undiscovered
                display_message(" ...Nothing happens.")
            when :already_unlocked
                display_message(" You already know how to make that.")
            when :success
                recipe = $craftdex.last_recipe
                Audio.se_play("audio/me/pmdItemGet")
                display_message(" You unlocked the shop permit for #{data_item(recipe.result).exact_name} !")
            end
            update_tray_display
            update_item_boxes
        end

        def in_press_y
            if $craftdex.tray.empty?
                play_buzzer_se
            else
                $craftdex.clear_tray
                play_decision_se
                update_tray_display
            end
        end

        def in_press_b
            @running = false
        end
    end
end
