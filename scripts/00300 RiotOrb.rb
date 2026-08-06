module Battle
	class Move
		class RiotOrb < Move
			# Effects that can't be stacked with this move
			# @return [Array<Symbol>]
			UNSTACKABLE_EFFECTS = %i[dragon_cheer focus_energy]

			def move_usable_by_user(user, targets)
				return false unless super
				battlers = @logic.all_alive_battlers
				return show_usage_failure(user) && false if battlers.all? { |target| UNSTACKABLE_EFFECTS.any? { |e| target.effects.has?(e) } }
				return true
			end

			private

			def deal_effect(user, actual_targets)
				@logic.all_alive_battlers.each do |target|
					next if UNSTACKABLE_EFFECTS.any? { |e| target.effects.has?(e) }

					target.effects.add(Effects::FocusEnergy.new(@logic, target))
					@scene.display_message_and_wait(parse_text_with_pokemon(19, 1047, target))
				end
			end
		end

		Move.register(:s_riot_orb, RiotOrb)
	end
end
