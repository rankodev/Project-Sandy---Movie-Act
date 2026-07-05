def show_player_portrait(mood: :neutral, number: 50, x: 30, y: 136, zoom_x: 50, zoom_y: 50)
    case $game_variables[111]
    when 1 # Cyndaquil
      base = "cyndaquil_"
    when 2 # Quaxly
      base = "quaxly_"
    when 3 # Scorbunny
      base = "scorbunny_"
    when 4 # Rowlet
      base = "rowlet_"
    when 5 # Snivy
      base = "snivy_"
    when 6 # Espurr
      base = "espurr_"
    when 7 # Hisuian Zorua
      base = "hzorua_"
    when 8 # Bulbasaur GROOKEY HAS BEEN ANNIHILATED FROM THE GAME DUE TO NOT HAVING ANY PORTRAITS RAHH
      base = "bulbasaur_"
    when 9 # Treecko
      base = "treecko_"
    when 10 # Froakie
      base = "froakie_"
    when 11 # Chimchar
      base = "chimchar_"
    when 12 # Rockruff
      base = "rockruff_"
    end

    dir = "portraits/"
    filename = dir + base + mood.to_s
    $game_screen.pictures[number].show(filename, 0, x, y, zoom_x, zoom_y, 255, 0)
    return true
  end

  def show_npc_portrait(mood: :neutral, number: 50, x: 30, y: 136, zoom_x: 50, zoom_y: 50)
    dir = "portraits/"
    filename = dir + mood.to_s
    $game_screen.pictures[number].show(filename, 0, x, y, zoom_x, zoom_y, 255, 0)
    return true
  end