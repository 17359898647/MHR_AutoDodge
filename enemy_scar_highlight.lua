local re = re
local sdk = sdk
local d2d = d2d
local imgui = imgui
local log = log
local json = json
local draw = draw
local thread = thread
local require = require
local tostring = tostring
local pairs = pairs
local ipairs = ipairs
local math = math
local string = string
local table = table
local type = type
local _ = _

local Core = require("_CatLib")
local CONST = require("_CatLib.const")


local mod = Core.NewMod("Enemy Scar Highlight")

-- mod.OnFrame(function ()
--     local highlight
--     imgui.text(string.format("IsAim: %s", tostring(highlight._IsAim)))
-- end)

mod.HookFunc("app.cEnemyLoopEffectHighlight", "isActivate()", function (args)
    local storage = thread.get_hook_storage()
    storage["this"] = Core.Cast(args[2])
    return sdk.PreHookResult.SKIP_ORIGINAL
end, function (retval)
    local storage = thread.get_hook_storage()
    local this = storage["this"]
    if this then
        this._IsAim = true
    end
    return sdk.to_ptr(1)
end)
