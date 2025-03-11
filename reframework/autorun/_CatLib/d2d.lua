local re = re
local sdk = sdk
local d2d = d2d
local imgui = imgui
local log = log
local json = json
local draw = draw
local tostring = tostring
local pairs = pairs
local ipairs = ipairs
local math = math
local string = string
local table = table

local FontUtils = require("_CatLib.font")


local _M = {}

---@param func fun()
---@param postFunc fun()?, if nil, func as postFunc
function _M.D2dRegister(func, postFunc)
    if d2d == nil then return end

    if postFunc == nil then
        d2d.register(function()
            FontUtils.LoadD2dFont()
        end, func)
    else
        d2d.register(func, postFunc)
    end
end

---@param x number
---@param y number
---@param w number
---@param h number
---@param color number
function _M.Rect(x, y, w, h, color)
    if not color then return end
    d2d.fill_rect(x, y, w, h, color)
end

---@param x number
---@param y number
---@param w number
---@param h number
---@param thickness number
---@param color number
function _M.OutlineRect(x, y, w, h, thickness, color)
    if not color then return end
    d2d.outline_rect(x, y, w, h, thickness, color)
end

---@param x number
---@param y number
---@param color number
---@param msg string
---@param size number|nil
---@param bold boolean|nil
---@param italic boolean|nil
function _M.Text(x, y, color, msg, size, bold, italic)
    if not color then return end
    d2d.text(FontUtils.LoadD2dFont(size, bold, italic), msg, x, y, color)
end

---@param x1 number
---@param y2 number
---@param x2 number
---@param y2 number
---@param thickness number
---@param color number
function _M.Line(x1, y1, x2, y2, thickness, color)
    if not color then return end
    d2d.line(x1, y1, x2, y2, thickness, color)
end

function _M.Image(image, x, y, sizeX, sizeY)
    if not image then return end
    d2d.image(image, x, y, sizeX, sizeY)
end

function _M.Quad(x1, y1, x2, y2, x3, y3, x4, y4, thickness, color)
    if not color then return end
    d2d.quad(x1, y1, x2, y2, x3, y3, x4, y4, thickness, color)
end

function _M.FillQuad(x1, y1, x2, y2, x3, y3, x4, y4, color)
    if not color then return end
    d2d.fill_quad(x1, y1, x2, y2, x3, y3, x4, y4, color)
end

function _M.Circle(x, y, r, thickness, color)
    if not color then return end
    d2d.circle(x, y, r, thickness, color)
end

function _M.FillCircle(x, y, r, color)
    if not color then return end
    d2d.fill_circle(x, y, r, color)
end

function _M.Pie(x, y, r, startAngle, sweepAngle, color, clockwise)
    if not color then return end
    d2d.pie(x, y, r, startAngle, sweepAngle, color, clockwise)
end

function _M.PieOutline(x, y, r, startAngle, sweepAngle, thickness, color, clockwise)
    if not color then return end
    d2d.outline_pie(x, y, r, startAngle, sweepAngle, thickness, color, clockwise)
end

function _M.Ring(x, y, outerR, innerR, start, sweep, color, clockwise)
    if not color then return end
    if innerR > outerR then
        outerR, innerR = innerR, outerR
    end
    d2d.ring(x, y, outerR, innerR, start, sweep, color, clockwise)
end

function _M.RingOutline(x, y, outerR, innerR, start, sweep, thickness, color, clockwise)
    if not color then return end
    if innerR > outerR then
        outerR, innerR = innerR, outerR
    end
    d2d.outline_ring(x, y, outerR, innerR, start, sweep, thickness, color, clockwise)
end

return _M