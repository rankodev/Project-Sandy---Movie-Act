module PFM
  module ItemDescriptor
    module_function

    # Define a usage of an attack item from the bag
    # @param klass [Class<Studio::Item>, Symbol] class or db_symbol of the item
    # @yieldparam item [Studio::Item] the item to use
    # @yieldparam scene [GamePlay::Base]
    def define_on_attack_item_use(klass, &block)
      raise 'Block is mandatory' unless block_given?

      EXTEND_DATAS[klass] ||= Wrapper.new
      EXTEND_DATAS[klass].on_attack_item_use = block
      EXTEND_DATAS[klass].attack_item = true
    end

    class Wrapper
      # Tell if the item is an attack item
      # @return [Boolean]
      attr_accessor :attack_item
      # Register the on_use block
      attr_writer :on_attack_item_use

      # Call the on_use block
      # @param scene [GamePlay::Base]
      def on_attack_item_use(scene)
        @on_attack_item_use&.call(@item, scene)
      end
    end
  end
end
