local Settings = require("systems.settings")

local AudioManager = {
  music = {},
  sounds = {},
  soundCooldowns = {},
  currentMusic = nil,
  musicVolume = 1.0,
  sfxVolume = 1.0,
  masterVolume = 1.0,
  pendingMusicName = nil,
  delayTimer = 0,
  fadeTimer = 0,
  fadeDuration = 1.0
}

function AudioManager.init()
  -- Load settings
  local settingsData = Settings.load()
  AudioManager.masterVolume = settingsData.audio.masterVolume or 1.0
  AudioManager.musicVolume = settingsData.audio.musicVolume or 1.0
  AudioManager.sfxVolume = settingsData.audio.sfxVolume or 1.0

  -- Load music
  local musicFiles = {
    menu = "assets/music/music_menu.ogg",
    stage1 = "assets/music/music_stage1.ogg",
    stage2 = "assets/music/music_stage2.ogg",
    stage3 = "assets/music/music_stage3.ogg",
    boss = "assets/music/music_boss.ogg"
  }

  for name, path in pairs(musicFiles) do
    if love.filesystem.getInfo(path) then
      AudioManager.music[name] = love.audio.newSource(path, "stream")
      AudioManager.music[name]:setLooping(true)
    end
  end

  -- Load weapon sounds
  AudioManager.sounds.weapons = {}
  AudioManager.sounds.weapons.plasma_lance = love.audio.newSource("assets/sounds/weapons/weapon_plasma_lance.ogg", "static")
  AudioManager.sounds.weapons.missile_swarm = love.audio.newSource("assets/sounds/weapons/weapon_missile_swarm.ogg", "static")
  AudioManager.sounds.weapons.arc_conductor = love.audio.newSource("assets/sounds/weapons/weapon_arc_conductor.ogg", "static")
  AudioManager.sounds.weapons.orbital_drones = love.audio.newSource("assets/sounds/weapons/weapon_orbital_drones.ogg", "static")
  AudioManager.sounds.weapons.gravity_mines_drop = love.audio.newSource("assets/sounds/weapons/weapon_gravity_mines_drop.ogg", "static")
  AudioManager.sounds.weapons.gravity_mines_explosion = love.audio.newSource("assets/sounds/weapons/weapon_gravity_mines_explosion.ogg", "static")
  AudioManager.sounds.weapons.photon_whip = love.audio.newSource("assets/sounds/weapons/weapon_photon_whip.ogg", "static")
  AudioManager.sounds.weapons.pulse_wave = love.audio.newSource("assets/sounds/weapons/weapon_pulse_wave.ogg", "static")
  AudioManager.sounds.weapons.railgun = love.audio.newSource("assets/sounds/weapons/weapon_railgun.ogg", "static")
  AudioManager.sounds.weapons.scatter_blaster = love.audio.newSource("assets/sounds/weapons/weapon_scatter_blaster.ogg", "static")

  -- Load impact sounds
  AudioManager.sounds.impact = {}
  AudioManager.sounds.impact.hit = love.audio.newSource("assets/sounds/impact/impact_hit.ogg", "static")
  AudioManager.sounds.impact.explosion = love.audio.newSource("assets/sounds/impact/impact_explosion.ogg", "static")

  -- Load other sounds dynamically
  local otherCategories = { "player", "ui" }
  for _, category in ipairs(otherCategories) do
    AudioManager.sounds[category] = {}
    local files = love.filesystem.getDirectoryItems("assets/sounds/" .. category)
    for _, file in ipairs(files) do
      local name = file:match("(.+)%..+") -- remove extension
      -- Remove category prefix from name if it exists (e.g., "ui_back" -> "back")
      local cleanName = name:gsub("^" .. category .. "_", "")
      local path = "assets/sounds/" .. category .. "/" .. file
      AudioManager.sounds[category][cleanName] = love.audio.newSource(path, "static")
    end
  end
end

function AudioManager.update(dt)
  if AudioManager.delayTimer > 0 then
    AudioManager.delayTimer = AudioManager.delayTimer - dt
    if AudioManager.delayTimer <= 0 then
      local music = AudioManager.music[AudioManager.pendingMusicName]
      if music then
        music:setVolume(0)
        music:play()
        AudioManager.currentMusic = music
        AudioManager.fadeTimer = 0
      end
      AudioManager.pendingMusicName = nil
    end
  elseif AudioManager.currentMusic and AudioManager.fadeTimer < AudioManager.fadeDuration then
    AudioManager.fadeTimer = math.min(AudioManager.fadeDuration, AudioManager.fadeTimer + dt)
    local volume = (AudioManager.fadeTimer / AudioManager.fadeDuration) * AudioManager.musicVolume * AudioManager.masterVolume
    AudioManager.currentMusic:setVolume(volume)
  end
end

function AudioManager.playMusic(musicName, delay, fadeDuration)
  local music = AudioManager.music[musicName]
  if not music then return end

  if (AudioManager.currentMusic == music and music:isPlaying()) or 
     (AudioManager.pendingMusicName == musicName and AudioManager.delayTimer > 0) then
    return
  end

  if AudioManager.currentMusic then
    AudioManager.currentMusic:stop()
    AudioManager.currentMusic = nil
  end

  AudioManager.pendingMusicName = musicName
  AudioManager.delayTimer = delay or 0.5
  AudioManager.fadeDuration = fadeDuration or 1.0
  AudioManager.fadeTimer = 0
end

function AudioManager.playSound(soundName, volumeMultiplier)
  -- soundName can be "category.name"
  local category, name = soundName:match("([^%.]+)%.([^%.]+)")
  
  -- Apply cooldown to non-weapon sounds to prevent spam
  if category ~= "weapons" then
    local currentTime = love.timer.getTime()
    local lastPlayTime = AudioManager.soundCooldowns[soundName] or 0
    if currentTime - lastPlayTime < 0.05 then
      return
    end
    AudioManager.soundCooldowns[soundName] = currentTime
  end

  local source
  local volMult = volumeMultiplier or 1.0
  
  if category and name then
    if AudioManager.sounds[category] then
      source = AudioManager.sounds[category][name]
    end
  else
    -- Fallback if no dot is present, though not specified in requirements
    source = AudioManager.sounds[soundName]
  end

  if source then
    local clone = source:clone()
    clone:setVolume(AudioManager.sfxVolume * AudioManager.masterVolume * volMult)
    clone:play()
  end
end

function AudioManager.setMusicVolume(volume)
  AudioManager.musicVolume = volume
  if AudioManager.currentMusic then
    AudioManager.currentMusic:setVolume(AudioManager.musicVolume * AudioManager.masterVolume)
  end
end

function AudioManager.setSfxVolume(volume)
  AudioManager.sfxVolume = volume
end

function AudioManager.setMasterVolume(volume)
  AudioManager.masterVolume = volume
  love.audio.setVolume(volume)
  if AudioManager.currentMusic then
    AudioManager.currentMusic:setVolume(AudioManager.musicVolume * AudioManager.masterVolume)
  end
end

return AudioManager
