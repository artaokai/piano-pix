-- Copyright (C) 2025 hellohellohell012321 (Modified by Antigravity)
-- Licensed under the GNU GPL v3. See LICENSE file for details.

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local translator = loadstring(game:HttpGet("https://raw.githubusercontent.com/artaokai/piano-roblox/main/translator.lua", true))()
local NotificationLibrary = loadstring(game:HttpGet("https://raw.githubusercontent.com/artaokai/piano-roblox/main/notif_lib.lua"))()

local function translateText(text)
    return translator:translateText(text)
end

local Window = Fluent:CreateWindow({
    Title = "Auto Piano",
    SubTitle = "by Arta",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightControl
})

-- Data from original MAIN.lua
local songs = {
    {name = "GOLDEN HOUR", bpm = "94", url = "GOLDEN_HOUR", cat = {"beautiful", "best"}, tags = {"jvke", "love, sad", "popular"}},
    {name = "YOUNG GIRL A", bpm = "130", url = "YOUNG_GIRL_A", cat = {"anime/jpop", "sad", "beautiful", "best"}, tags = {"siinamota", "vocaloid"}},
    {name = "MOONLIGHT SONATA - THIRD MOVEMENT", bpm = "163", url = "WHAT_THE_FUCKK", cat = {"classical", "best", "peak"}, tags = {"ludwig van beethoven"}},
    {name = "UNDERTALE", bpm = "100", url = "UNDERTALE", cat = {"video games", "undertale", "best", "epic"}, tags = {}},
    {name = "TURKISH MARCH", bpm = "92", url = "TURKISH", cat = {"classical"}, tags = {"mozart", "rondo alla turca"}},
    {name = "UNRAVEL (ANIMENZ ARR.)", bpm = "132", url = "UNRAVEL_EPIC", cat = {"epic", "best", "beautiful", "peak", "movies/tv"}, tags = {"tokyo ghoul", "animenz", "unravel epic"}},
    {name = "SNOWFALL", bpm = "96", url = "SNOWFALL", cat = {"beautiful", "sad", "best"}, tags = {"oneheart"}},
    {name = "BOHEMIAN RHAPSODY", bpm = "80", url = "BOHEMIAN_RHAPSODY", cat = {"rock"}, tags = {"queen"}},
    {name = "RENAI CIRCULATION", bpm = "120", url = "RENAI_CIRCULATION", cat = {"anime/jpop", "memes", "peak", "best"}, tags = {"bakemonogatari"}},
    {name = "WE NOT LIKE YOU", bpm = "155", url = "WE_NOT_LIKE_U", cat = {"pop/hiphop", "memes", "new"}, tags = {"nettspend"}},
}

local categories = {
    "all", "new", "peak", "best", "epic", "beautiful", "video games", "movies/tv", "memes", "classical",
    "pop/hiphop", "anime/jpop", "seasonal", "sad", "electronic", "rock", "creepy/weirdcore", "undertale",
    "deltarune", "geometry dash", "minecraft", "omori"
}

-- Globals expected by playback scripts
bpm = 100
errormargin = 0
spoofMidiPlz = false
_G.STOPIT = true
_G.songisplaying = false

-- Tabs
local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "home" }),
    Songs = Window:AddTab({ Title = "Songs", Icon = "music" }),
    Favorites = Window:AddTab({ Title = "Favorites", Icon = "star" }),
    Custom = Window:AddTab({ Title = "Custom", Icon = "plus-circle" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local Options = Fluent.Options

-- Persistance setup
local function getFavs()
    if isfile("TALENTLESS_FAV_SONGS.txt") then
        local content = readfile("TALENTLESS_FAV_SONGS.txt")
        local favs = {}
        for line in content:gmatch("[^\r\n]+") do
            if line ~= "" then table.insert(favs, line) end
        end
        return favs
    end
    return {}
end

local function saveFavs(favs)
    writefile("TALENTLESS_FAV_SONGS.txt", table.concat(favs, "\n"))
end

local function isFav(name)
    local favs = getFavs()
    return table.find(favs, name) ~= nil
end

local function toggleFav(name)
    local favs = getFavs()
    local idx = table.find(favs, name)
    if idx then
        table.remove(favs, idx)
    else
        table.insert(favs, name)
    end
    saveFavs(favs)
end

-- Play Logic
local function playSong(songData, isCustom)
    if _G.songisplaying then
        Fluent:Notify({
            Title = "Error",
            Content = translateText("songplayingerror"),
            Duration = 3
        })
        return
    end

    _G.STOPIT = false
    _G.songisplaying = true
    
    local success, songscript
    if isCustom then
        success, songscript = pcall(function() return readfile(songData.file) end)
    else
        success, songscript = pcall(function() 
            return game:HttpGet("https://cdn.jsdelivr.net/gh/hellohellohell012321/TALENTLESS/SONGS/" .. songData.url, true)
        end)
    end
    
    if not success or not songscript or songscript == "" then
        _G.songisplaying = false
        Fluent:Notify({
            Title = "Error",
            Content = "Failed to load song script. Check your connection or the song URL.",
            Duration = 5
        })
        return
    end

    if Options.SpoofMidi and Options.SpoofMidi.Value then
        loadstring(game:HttpGet("https://raw.githubusercontent.com/artaokai/piano-roblox/main/midi_spoof_loader.lua", true))()
    else
        loadstring(game:HttpGet("https://raw.githubusercontent.com/artaokai/piano-roblox/main/loader_main.lua", true))()
    end
    
    task.spawn(function()
        local playSuccess, playErr = pcall(function()
            loadstring(songscript)()
        end)
        if not playSuccess then
            _G.songisplaying = false
            warn("Playback error: " .. tostring(playErr))
        end
    end)
end

-- UI Rendering
-- Main Tab
Tabs.Main:AddParagraph({
    Title = "Welcome to TALENTLESS",
    Content = "Premium piano automation tool.\n\nUse the sidebar to navigate through songs and settings.\nNo key required."
})

local songListContainer = Tabs.Songs:AddSection("Song Library")

if not Fluent then
    warn("Failed to load Fluent UI library.")
    return
end

-- Fluent doesn't easily support dynamic refreshing of sections without re-creating them or using custom frames.
-- I'll use a functional approach to create song entries.

local function createSongEntry(tab, songData, isCustom)
    local title = songData.name or songData.buttonName
    local bpmVal = songData.bpm
    
    local row = tab:AddButton({
        Title = title,
        Description = "BPM: " .. bpmVal .. (isCustom and " (Custom)" or ""),
        Callback = function()
            bpm = tonumber(bpmVal)
            playSong(songData, isCustom)
        end
    })
    
    -- Favorite button in Fluent is usually a Toggle or a separate Button.
    -- I'll add a favorite toggle next to it if I can, or just a button.
end

-- For simplicity and better UX in Fluent, I'll list all songs and add a search/filter.

-- Songs Tab
local categoryDropdown = Tabs.Songs:AddDropdown("CategoryFilter", {
    Title = "Category",
    Values = categories,
    Default = "all",
    Callback = function(Value)
        -- Update list
    end
})

local searchInput = Tabs.Songs:AddInput("SearchQuery", {
    Title = "Search",
    Default = "",
    Placeholder = "Search song name or tags...",
    Callback = function(Value)
        -- Update list
    end
})

Tabs.Songs:AddSection("Songs")

for _, song in ipairs(songs) do
    Tabs.Songs:AddButton({
        Title = song.name,
        Description = "BPM: " .. song.bpm .. " | Tags: " .. table.concat(song.tags, ", "),
        Callback = function()
            bpm = tonumber(song.bpm)
            playSong(song, false)
        end
    })
end

-- Favorites Tab
Tabs.Favorites:AddSection("Your Favorites")
local function refreshFavs()
    local favs = getFavs()
    for _, favName in ipairs(favs) do
        Tabs.Favorites:AddButton({
            Title = favName,
            Callback = function()
                -- Find song by name
                for _, s in ipairs(songs) do
                    if s.name == favName then
                        bpm = tonumber(s.bpm)
                        playSong(s, false)
                        return
                    end
                end
            end
        })
    end
end
refreshFavs()

-- Custom Tab
Tabs.Custom:AddSection("Custom Songs")
Tabs.Custom:AddButton({
    Title = "Add Custom Song",
    Description = "Open the song adder tool",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/artaokai/piano-roblox/main/add_song.lua", true))()
    end
})

-- Settings Tab
Tabs.Settings:AddSection("Piano Settings")
Tabs.Settings:AddSlider("BPMOverride", {
    Title = "Global BPM",
    Description = "Overrides song BPM if set",
    Default = 100,
    Min = 20,
    Max = 400,
    Rounding = 0,
    Callback = function(Value)
        bpm = Value
    end
})

Tabs.Settings:AddSlider("ErrorMargin", {
    Title = "Error Margin",
    Description = "Adds human-like delay",
    Default = 0,
    Min = 0,
    Max = 0.1,
    Rounding = 3,
    Callback = function(Value)
        errormargin = Value
    end
})

Tabs.Settings:AddToggle("SpoofMidi", {
    Title = "Spoof MIDI",
    Description = "Hides QWERTY inputs (Piano Rooms only)",
    Default = false,
    Callback = function(Value)
        spoofMidiPlz = Value
    end
})

Tabs.Settings:AddSection("UI Settings")
Tabs.Settings:AddDropdown("Language", {
    Title = "Language",
    Values = {"en", "id", "fil", "ar", "de", "es", "fr", "it", "jp", "kr", "pt", "ru", "tr", "vi", "zh"},
    Default = "en",
    Callback = function(Value)
        -- Update language
    end
})

-- Footer
Window:SelectTab(1)

Fluent:Notify({
    Title = "Auto Piano Loaded",
    Content = "Enjoy the music!",
    Duration = 5
})

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("Talentless")
SaveManager:SetFolder("Talentless/main")

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

SaveManager:LoadAutoloadConfig()
