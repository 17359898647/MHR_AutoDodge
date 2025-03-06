local re = re
local sdk = sdk
local json = json
local imgui = imgui

local CONST = require("_CatLib.const")

local SceneManagerType = sdk.find_type_definition("via.SceneManager")

local ScreenW, ScreenH
local function GetScreenSize()
    if ScreenW and ScreenH then
        return ScreenW, ScreenH
    end

    ---@type via.SceneManager
    local mgr = sdk.get_native_singleton("via.SceneManager")
    if not mgr then
        return 1920, 1080
    end

    ---@type via.SceneView
    local view = sdk.call_native_func(mgr, SceneManagerType,  "get_MainView")
    if not view then
        return 1920, 1080
    end

    ---@type via.Size
    local size = view:get_Size()
    if not size then
        return 1920, 1080
    end

    ScreenW, ScreenH = size.w, size.h
    return ScreenW, ScreenH
end

local CONF_FILE_NAME = "_catlib_config.json"
local Conf = json.load_file(CONF_FILE_NAME) or {}

if Conf.UIScale == nil then
    local w, h = GetScreenSize()
    if h then
        Conf.UIScale = h / 2160
    else
        Conf.UIScale = 1
    end

    -- Conf.DefaultFontSize = 9 * Conf.UIScale
    -- if Conf.DefaultFontSize < 10 then
    --     Conf.DefaultFontSize = 10
    -- end
end

if Conf.Language == nil then
    Conf.LanguageOverride = false

    local mgr = sdk.get_managed_singleton("app.GUIManager")
    if not mgr then
        Conf.Language = CONST.LanguageType.English
        return
    end

    Conf.Language = mgr:getSystemLanguageToApp()
end

local LANGUAGES = {
    [CONST.LanguageType.Japanese] = "Japanese",
    [CONST.LanguageType.English] = "English",
    [CONST.LanguageType.Korean] = "Korean",
    [CONST.LanguageType.SimplifiedChinese] = "Chinese",
}

re.on_draw_ui(function()
    local changed = false
    local configChanged = false

    if imgui.tree_node("_CatLib Global Config") then
        imgui.text("UI Scale: by default, 0.5x for 1080p, 0.75x for 2K, 1x for 4K (2160p).")
        imgui.text("This option is used to initialize mod configuration, doesn't work if the config file has been generated.")
        imgui.text("You need to delete existed config files under reframework/data directory.")
        changed, Conf.UIScale = imgui.drag_float("UI Scale", Conf.UIScale, 0.1, 0.5, 4)
        configChanged = configChanged or changed

        imgui.text("You need to reset script or restart the game after changing this")

        changed, Conf.LanguageOverride = imgui.checkbox("Override Language", Conf.LanguageOverride)
        configChanged = configChanged or changed

        changed, Conf.Language = imgui.combo("Language", Conf.Language, LANGUAGES)
        configChanged = configChanged or changed
    
        imgui.tree_pop();
    end

    if configChanged then
        json.dump_file(CONF_FILE_NAME, Conf)
    end
end)


return Conf