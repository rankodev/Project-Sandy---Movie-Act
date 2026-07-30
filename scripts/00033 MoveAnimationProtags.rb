class Game_Player
	RUN_KEYS = %i[X].freeze

	if method_defined?(:update_move_parameter)
		alias move_animation_protags_update_move_parameter update_move_parameter
	end

	if method_defined?(:update)
		alias move_animation_protags_update update
	end

	# Keep the Stop Animation state from forcing a permanent walking speed.
	# If the player holds the Run key, promote the move parameter back to running.
	def update_move_parameter(parameter)
		if parameter == :walking && run_animation_run_input?
			return move_animation_protags_update_move_parameter(:running)
		end

		move_animation_protags_update_move_parameter(parameter)
	end

	# Re-apply run every frame so the stop-animation event can't pin the player to walk speed.
	def update
		move_animation_protags_update if defined?(move_animation_protags_update)
		update_move_parameter(:running) if run_animation_run_input?
	end

	def run_animation_run_input?
		return false unless Input.respond_to?(:press?)

		RUN_KEYS.any? { |key| Input.press?(key) }
	end
end
