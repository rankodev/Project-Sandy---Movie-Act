module Battle
    class Move
        class Pivot < Move
            # Tell if the move is a move that switch the user if that hit
            def self_user_switch?
                return true
            end
            # Function that tests if the user is able to use the move
            # @param user [PFM::PokemonBattler] user of the move
            # @param targets [Array<PFM::PokemonBattler>] expected targets
            # @note Thing that prevents the move from being used should be defined by :move_prevention_user Hook
            # @return [Boolean] if the procedure can continue
            def move_usable_by_user(user, targets)
                return false unless super
                return show_usage_failure(user) && false unless @logic.switch_handler.can_switch?(user, self)
                return true
            end
            # Function that deals the effect to the pokemon
            # @param user [PFM::PokemonBattler] user of the move
            # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
            def deal_effect(user, actual_targets)
                super
                actual_targets.each do |target|
                target.effects.add(Battle::Effects::Pivot.new(logic, target))
                logic.request_switch(target, nil)
                end
            end
        end
        Move.register(:s_pivot, Pivot)
    end
end