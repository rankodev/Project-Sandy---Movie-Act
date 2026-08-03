module PFM
  class Pokemon
    # Maximum number of HP bars a Boss can have.
    # @return [Integer]
    MAX_BOSS_BARS = 5

    # Return if the Pokemon is a Boss.
    # @return [Boolean]
    attr_accessor :boss
    # The number of hp bars the Pokemon has.
    # @return [Integer]
    attr_accessor :nb_bars_hp
    # The type of halo to display for the boss (:flame, :ice, :orbital, :pulse, :shadow, :vortex)
    # @return [Symbol, nil]
    attr_accessor :boss_halo

    # The db_symbols of the boss effects attached to the Pokemon (empty = none).
    # @return [Array<Symbol>]
    def boss_effects_db_symbols
      @boss_effects_db_symbols ||= []
      return @boss_effects_db_symbols
    end

    # Set the boss effects, clearing the memoized battle list so it rebuilds.
    # @param db_symbols [Array<Symbol>]
    def boss_effects_db_symbols=(db_symbols)
      @boss_effects_db_symbols = db_symbols
      @boss_effects = nil
    end

    # The first boss effect attached to the Pokemon (nil = none).
    # @return [Symbol, nil]
    def boss_effect_db_symbol
      return boss_effects_db_symbols.first
    end

    # Set a single boss effect (nil clears every boss effect).
    # @param db_symbol [Symbol, nil]
    def boss_effect_db_symbol=(db_symbol)
      self.boss_effects_db_symbols = db_symbol ? [db_symbol] : []
    end
  end
end
