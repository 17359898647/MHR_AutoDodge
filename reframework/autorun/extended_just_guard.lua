local lib = require("_CatLib")
local techGuardFlag 
local guardFlag 
local guard_info = {
    guard = nil,
    tech_guard = nil,
}

local timer = require("_CatLib.utils.timer")

local mod = lib.NewMod("extended_just_guard","extended_just_guard")

if not mod.Config.frame then
    mod.Config = {
        frame = 30.0
    }
    mod.SaveConfig()
end



mod.OnPreUpdateBehavior(
function ()
        timer:runner()
        local hunterCharacter = lib.GetPlayerCharacter()
        if not hunterCharacter then return end

        techGuardFlag = hunterCharacter:checkHunterStatusFlag(4)
        guardFlag = hunterCharacter:checkHunterStatusFlag(2)

        if techGuardFlag and not guard_info.tech_guard then
            timer:run("justgurad",mod.Config.frame,function ()
                hunterCharacter:onHunterStatusFlag(4)
            end,function ()
                hunterCharacter:get_HunterStatus():get_field("_HunterStatusFlag"):off(4)
            end)
        end

        if not guardFlag then
            timer:stop("justgurad")
        end
        
        
        guard_info.guard = guardFlag
        -- 更新 TechnicalGuradFlag
        guard_info.tech_guard = techGuardFlag
end
)

mod.OnDebugFrame(
    function ()
        -- imgui.text("techGuardFlag: "..tostring(techGuardFlag))
        -- imgui.text("guardFlag: "..tostring(guardFlag))
        -- imgui.text("guard_info.tech_guard: "..tostring(guard_info.tech_guard))
        -- imgui.text("guard_info.guard: "..tostring(guard_info.guard))
        imgui.text("timer: "..timer:getDebugRemainingFrames())
    end
)

mod.Menu(
    function ()
        local changed = false
        if mod.Config.frame > 60 then
            mod.Config.frame = 60
            changed = true
        end
        changed, mod.Config.frame = imgui.slider_float("just guard frame", mod.Config.frame, 1, 60)
        return changed
    end
)


mod.Run()