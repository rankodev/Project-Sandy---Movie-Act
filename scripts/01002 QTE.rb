module QTE
	DEFAULT_TIMEOUT_FRAMES = 90 # 1.5 seconds at 60 FPS, if the speed up with F3 oh well
	DEFAULT_PICTURE_ID = 50
	DEFAULT_X = 320
	DEFAULT_Y = 240
	DEFAULT_ORIGIN = 1

	def self.run(switch_id:, key: nil, keys: nil, picture_name: nil, timeout_frames: DEFAULT_TIMEOUT_FRAMES,
							 picture_id: DEFAULT_PICTURE_ID, x: DEFAULT_X, y: DEFAULT_Y, origin: DEFAULT_ORIGIN,
							 success_se: nil)
		return false unless $game_temp
		return false unless $game_screen
		return false unless $game_switches
		valid_keys = Array(keys || key).compact
		raise ArgumentError, 'QTE.run needs at least one key (key: or keys:)' if valid_keys.empty?

		with_player_input_locked do
			$game_switches[switch_id] = false

			remaining = timeout_frames
			while remaining > 0
				Graphics.update
				refresh_input_state

				if valid_keys.any? { |k| qte_key_triggered?(k) }
					play_success_se(success_se)
					$game_switches[switch_id] = true
					return true
				end

				remaining -= 1
			end

			$game_switches[switch_id] = false
			return false
		end
	end

	def self.with_player_input_locked
		return yield unless $game_temp

		previous_state = $game_temp.message_window_showing
		$game_temp.message_window_showing = true
		yield
	ensure
		$game_temp.message_window_showing = previous_state if $game_temp
	end

	def self.play_success_se(success_se)
		if success_se
			$game_system.se_play(success_se)
		elsif $data_system&.decision_se
			$game_system.se_play($data_system.decision_se)
		end
	end

	def self.refresh_input_state
		return Input.update if Input.respond_to?(:update)
		return Input.update_state if Input.respond_to?(:update_state)
		return Input.refresh if Input.respond_to?(:refresh)
		return Input.poll if Input.respond_to?(:poll)
	end

	def self.qte_key_triggered?(key)
		normalized_key = key.is_a?(String) ? key.to_sym : key
		return true if Input.respond_to?(:trigger?) && Input.trigger?(normalized_key)
		return true if Input.respond_to?(:press?) && Input.press?(normalized_key)

		false
	rescue StandardError
		false
	end

	LEFT_KEY = :LEFT
	RIGHT_KEY = :RIGHT
	UP_KEY = :UP
	DOWN_KEY = :DOWN
	A_KEY = :A
	B_KEY = :B
	C_KEY = :C
	X_KEY = :X
	Y_KEY = :Y
	Z_KEY = :Z
	L_KEY = :L
	R_KEY = :R
	LEFT_OR_A_KEYS = [LEFT_KEY, A_KEY].freeze

	LETTER_TO_KEY = {
		A: A_KEY,
		B: B_KEY,
		C: C_KEY,
		X: X_KEY,
		Y: Y_KEY,
		Z: Z_KEY,
		L: L_KEY,
		R: R_KEY,
		LEFT: LEFT_KEY,
		RIGHT: RIGHT_KEY,
		UP: UP_KEY,
		DOWN: DOWN_KEY,
		:"<-" => LEFT_KEY,
		:"->" => RIGHT_KEY
	}.freeze

	def self.run_letter(switch_id:, letter:, picture_name: nil, timeout_frames: DEFAULT_TIMEOUT_FRAMES,
											picture_id: DEFAULT_PICTURE_ID, x: DEFAULT_X, y: DEFAULT_Y, origin: DEFAULT_ORIGIN)
		key = LETTER_TO_KEY[letter.to_s.upcase.to_sym]
		raise ArgumentError, "Unknown or unavailable QTE key: #{letter}" unless key

		run(
			switch_id: switch_id,
			key: key,
			picture_name: picture_name,
			timeout_frames: timeout_frames,
			picture_id: picture_id,
			x: x,
			y: y,
			origin: origin
		)
	end

	def self.run_left_or_a(switch_id:, picture_name: nil, timeout_frames: DEFAULT_TIMEOUT_FRAMES,
										picture_id: DEFAULT_PICTURE_ID, x: DEFAULT_X, y: DEFAULT_Y, origin: DEFAULT_ORIGIN)
		run(
			switch_id: switch_id,
			keys: LEFT_OR_A_KEYS,
			picture_name: picture_name,
			timeout_frames: timeout_frames,
			picture_id: picture_id,
			x: x,
			y: y,
			origin: origin
		)
	end
end