local Settings = require("systems.settings")

local AudioManager = {
  music = {},
  sounds = {},
  currentMusic = nil,
  musicVolume = 1.0,
  sfxVolume = 1.0,
  masterVolume = 1.0
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

  -- Load sounds
  local soundCategories = { "impact", "player", "ui", "weapons" }
  for _, category in ipairs(soundCategories) do
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

function AudioManager.playMusic(musicName)
  if AudioManager.currentMusic then
    AudioManager.currentMusic:stop()
  end

  local music = AudioManager.music[musicName]
  if music then
    music:setVolume(AudioManager.musicVolume * AudioManager.masterVolume)
    music:play()
    AudioManager.currentMusic = music
  end
end

function AudioManager.playSound(soundName)
  -- soundName can be "category.name"
  local category, name = soundName:match("([^%.]+)%.([^%.]+)")
  local source
  
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
    clone:setVolume(AudioManager.sfxVolume * AudioManager.masterVolume)
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
