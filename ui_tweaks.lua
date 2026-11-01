local ffi = require 'ffi'
local imgui = require 'mimgui'
local memory = require 'memory'
local sampev = require 'samp.events'
local encoding = require 'encoding'

local config = {}
do
    local DIR = getWorkingDirectory() .. '\\config\\'

    local function filePath(name)
        return DIR .. name .. '.json'
    end

    local function readFile(path)
        local file = io.open(path, 'rb')
        if not file then return nil end
        local text = file:read('*a')
        file:close()
        return text
    end

    local function writeFile(path, text)
        local file = io.open(path, 'wb')
        if not file then return false end
        file:write(text)
        file:close()
        return true
    end

    local function copy(value)
        if type(value) ~= 'table' then return value end
        local result = {}
        for k, v in pairs(value) do result[k] = copy(v) end
        return result
    end

    local function merge(defaults, source)
        local result = {}
        for key, default in pairs(defaults) do
            local value = source and source[key]
            if type(default) == 'table' then
                local isDict = next(default) ~= nil and #default == 0
                if type(value) == 'table' then
                    result[key] = isDict and merge(default, value) or copy(value)
                else
                    result[key] = copy(default)
                end
            elseif type(value) == type(default) then
                result[key] = value
            else
                result[key] = default
            end
        end
        return result
    end

    function config.save(name, data)
        if not doesDirectoryExist(DIR) then createDirectory(DIR) end
        return writeFile(filePath(name), encodeJson(data))
    end

    function config.load(name, defaults, legacy)
        local text = readFile(filePath(name))
        local source = text and decodeJson(text)
        local fresh = type(source) ~= 'table'
        if fresh and legacy then
            local ok, migrated = pcall(legacy)
            source = ok and migrated or nil
        end
        local data = merge(defaults, type(source) == 'table' and source or nil)
        if fresh then config.save(name, data) end
        return data
    end
end

local theme = {}
do
    local V4 = imgui.ImVec4

    local COLORS = {
        WindowBg = V4(0.10, 0.10, 0.10, 1.00),
        ChildBg = V4(0.14, 0.14, 0.14, 1.00),
        PopupBg = V4(0.12, 0.12, 0.12, 1.00),
        Border = V4(0.43, 0.43, 0.50, 0.50),
        BorderShadow = V4(0.00, 0.00, 0.00, 0.00),
        FrameBg = V4(0.20, 0.20, 0.20, 1.00),
        FrameBgHovered = V4(0.30, 0.30, 0.30, 1.00),
        FrameBgActive = V4(0.25, 0.25, 0.25, 1.00),
        TitleBg = V4(0.10, 0.10, 0.10, 1.00),
        TitleBgActive = V4(0.10, 0.10, 0.10, 1.00),
        TitleBgCollapsed = V4(0.00, 0.00, 0.00, 0.51),
        MenuBarBg = V4(0.14, 0.14, 0.14, 1.00),
        ScrollbarBg = V4(0.02, 0.02, 0.02, 0.53),
        ScrollbarGrab = V4(0.31, 0.31, 0.31, 1.00),
        ScrollbarGrabHovered = V4(0.41, 0.41, 0.41, 1.00),
        ScrollbarGrabActive = V4(0.51, 0.51, 0.51, 1.00),
        CheckMark = V4(0.26, 0.59, 0.98, 1.00),
        SliderGrab = V4(0.24, 0.52, 0.88, 1.00),
        SliderGrabActive = V4(0.26, 0.59, 0.98, 1.00),
        Button = V4(0.20, 0.20, 0.20, 1.00),
        ButtonHovered = V4(0.28, 0.28, 0.28, 1.00),
        ButtonActive = V4(0.18, 0.18, 0.18, 1.00),
        Header = V4(0.26, 0.59, 0.98, 0.31),
        HeaderHovered = V4(0.26, 0.59, 0.98, 0.80),
        HeaderActive = V4(0.26, 0.59, 0.98, 1.00),
        Separator = V4(0.43, 0.43, 0.50, 0.50),
        SeparatorHovered = V4(0.10, 0.40, 0.75, 0.78),
        SeparatorActive = V4(0.10, 0.40, 0.75, 1.00),
        ResizeGrip = V4(0.26, 0.59, 0.98, 0.25),
        ResizeGripHovered = V4(0.26, 0.59, 0.98, 0.67),
        ResizeGripActive = V4(0.26, 0.59, 0.98, 0.95),
        Tab = V4(0.18, 0.35, 0.58, 0.86),
        TabHovered = V4(0.26, 0.59, 0.98, 0.80),
        TabActive = V4(0.20, 0.41, 0.68, 1.00),
        TabUnfocused = V4(0.07, 0.10, 0.15, 0.97),
        TabUnfocusedActive = V4(0.14, 0.26, 0.42, 1.00),
        Text = V4(1.00, 1.00, 1.00, 1.00),
        TextDisabled = V4(0.50, 0.50, 0.50, 1.00),
    }

    theme.color = {
        Green = V4(0.4, 1.0, 0.4, 1.0),
        Red = V4(1.0, 0.4, 0.4, 1.0),
        Orange = V4(1.0, 0.8, 0.2, 1.0),
        Gray = V4(0.5, 0.5, 0.5, 1.0),
        LightGray = V4(0.7, 0.7, 0.7, 1.0),
        Cash = V4(0.35, 0.95, 0.35, 1.0),
        Blue = V4(0.26, 0.59, 0.98, 1.0),
        Gold = V4(1.0, 0.84, 0.0, 1.0),
    }

    theme.button = {
        green = {V4(0.25, 0.6, 0.3, 1), V4(0.32, 0.7, 0.38, 1), V4(0.2, 0.5, 0.25, 1)},
        blue = {V4(0.25, 0.45, 0.7, 1), V4(0.32, 0.55, 0.8, 1), V4(0.2, 0.38, 0.6, 1)},
        red = {V4(0.6, 0.2, 0.2, 1), V4(0.75, 0.28, 0.28, 1), V4(0.5, 0.15, 0.15, 1)},
        purple = {V4(0.4, 0.4, 0.8, 1), V4(0.5, 0.5, 0.9, 1), V4(0.33, 0.33, 0.7, 1)},
        ghost = {V4(0.5, 0.5, 0.5, 0.25), V4(0.5, 0.5, 0.5, 0.45), V4(0.5, 0.5, 0.5, 0.6)},
    }

    function theme.apply()
        local style = imgui.GetStyle()
        style.WindowRounding = 10.0
        style.ChildRounding = 8.0
        style.FrameRounding = 6.0
        style.PopupRounding = 8.0
        style.ScrollbarRounding = 6.0
        style.GrabRounding = 6.0
        style.TabRounding = 6.0
        style.FrameBorderSize = 1.0
        for name, value in pairs(COLORS) do
            if imgui.Col[name] then style.Colors[imgui.Col[name]] = value end
        end
    end

    function theme.pushButton(kind)
        local c = theme.button[kind]
        imgui.PushStyleColor(imgui.Col.Button, c[1])
        imgui.PushStyleColor(imgui.Col.ButtonHovered, c[2])
        imgui.PushStyleColor(imgui.Col.ButtonActive, c[3])
    end

    function theme.popButton()
        imgui.PopStyleColor(3)
    end

    function theme.coloredButton(kind, label, size)
        theme.pushButton(kind)
        local pressed = imgui.Button(label, size)
        theme.popButton()
        return pressed
    end

    function theme.u32(color)
        return imgui.ColorConvertFloat4ToU32(color)
    end
end

encoding.default = 'CP1251'
local u8 = encoding.UTF8

local cfg = config.load('ui_tweaks', {
    nametags = {
        enabled = true,
        hideOriginal = true,
        maxDist = 60.0,
        nearDist = 20.0,
        fadeLen = 10.0,
        maxHp = 100,
        maxArmor = 100,
        showHpNumber = true,
        showArmorNumber = true,
        showIdBox = true,
        showMicIcon = true,
        showLevelIcon = true,
        showVideoIcon = true,
        showMuteIcon = true,
        showMediaIcon = true,
        showAdminIcon = true,
        showAfkTime = true,
        showTyping = true,
        showStatusSpiral = true,
        showStatusEye = true,
        showStatusSwords = true,
        showStatusBottle = true,
        showId = true,
        showTitle = true,
        showTitleIcon = false,
        showTitleFlag = false,
        showCrown = false,
        showBadge = true,
        showWeapon = true,
        showStatus = true,
        showAfk = true,
        showIcons = true,
        showBubbles = true,
        iconScale = 1.3,
        bubbleWidth = 230,
        bubbleFont = '',
        bubbleFontSize = 15,
        bubbleTextCustom = false,
        bubbleTextColor = 'FFFFFF',
        bubbleKeepColors = true,
        bubbleBgCustom = false,
        bubbleBgColor = '101218',
        bubbleBgAlpha = 0.75,
        bubbleRounding = 6,
        bubbleShadow = true,
        bubbleBorder = false,
        bubbleTail = true,
        headOffset = 1.05,
        aboveHead = 0.32,
        stackTags = false,
        barWidth = 70,
        barHeight = 10,
        fontSize = 15,
    },
    labels = {
        enabled = true,
        scanInterval = 0.5,
        remove = {},
        blank = {},
    },
})

cfg.labels.remove = {'Продавец игрока', 'покупает товар', 'продаёт товар', 'продает товар', 'Редактирует'}
cfg.labels.blank = {'Управления товарами'}

local function say(text)
    sampAddChatMessage('{66CCFF}[UiTweaks]{FFFFFF} ' .. u8:decode(text), -1)
end

local function clamp(v, lo, hi)
    return math.max(lo, math.min(hi, v))
end

local function glyph(code)
    return string.char(0xE0 + math.floor(code / 4096), 0x80 + math.floor(code / 64) % 64, 0x80 + code % 64)
end

local OriginalTags = {}
do
    local address, saved, distanceAddress

    function OriginalTags.find()
        local base = getModuleHandle('samp.dll')
        if base == 0 then return false end
        local info = memory.getuint32(base + 0x26E8DC, true)
        if info == 0 then return false end
        local settings = memory.getuint32(info + 0x3D5, true)
        if settings == 0 then return false end
        address = settings + 0x38
        distanceAddress = settings + 0x27
        return true
    end

    function OriginalTags.distance()
        if not distanceAddress then return 0 end
        local ok, value = pcall(memory.getfloat, distanceAddress, true)
        if not ok or value ~= value or value <= 0 or value > 3000 then return 0 end
        return value
    end

    function OriginalTags.hide()
        if not address then return end
        if saved == nil then saved = memory.getint8(address, true) end
        memory.setint8(address, 0, true)
    end

    function OriginalTags.restore()
        if address and saved ~= nil then memory.setint8(address, saved, true) end
    end
end

local TagData = {players = {}}
do
    local function readU8(bs) return raknetBitStreamReadInt8(bs) % 256 end
    local function readU16(bs) return raknetBitStreamReadInt16(bs) % 65536 end
    local function readU32(bs) return raknetBitStreamReadInt32(bs) % 4294967296 end

    local function readString(bs, length)
        if length == 0 then return '' end
        return raknetBitStreamReadString(bs, length)
    end

    local function rgbaToArgb(value)
        return (value % 256) * 0x1000000 + math.floor(value / 256)
    end

    local STATS = {[0] = 'hp', [1] = 'maxHp', [2] = 'armor', [3] = 'maxArmor'}

    local function fresh()
        return {status = {}, afkTexts = {}}
    end

    local parse = {}

    parse[1] = function(bs, p)
        local color = readU32(bs)
        p.title = readString(bs, readU8(bs))
        p.titleColor = 0xFF000000 + math.floor(color / 256)
        p.titleIcon = readU8(bs) ~= 0
        p.titleStyle = readU8(bs)
    end

    parse[2] = function(_, p)
        p.title = nil
    end

    parse[3] = function(bs, p)
        local text = readString(bs, readU16(bs))
        p.customNick = text ~= '' and text or nil
        p.customNickUtf8 = nil
    end

    parse[4] = function(_, p)
        p.customNick = nil
        p.customNickUtf8 = nil
    end

    parse[5] = function(bs, p)
        local key, value = readU8(bs), readU16(bs)
        local stat = STATS[key]
        if stat then
            p[stat] = value
        else
            p.status[key] = value
        end
    end

    parse[6] = function(bs, p)
        for _ = 1, readU8(bs) do parse[5](bs, p) end
    end

    parse[7] = function(bs, p)
        p.afkMs = readU32(bs)
        p.afkAt = os.clock()
    end

    parse[8] = function(bs, p)
        for i = 1, 3 do
            local color = readU32(bs)
            p.afkTexts[i] = {text = readString(bs, readU8(bs)), color = color ~= 0 and rgbaToArgb(color) or nil}
        end
    end

    parse[9] = function(bs, p)
        local background, foreground = readU32(bs), readU32(bs)
        p.badge = {text = readString(bs, readU8(bs)), background = rgbaToArgb(background), color = rgbaToArgb(foreground)}
    end

    parse[10] = function(_, p)
        p.badge = nil
    end

    local floatBits = ffi.new('union { uint32_t u; float f; }')

    local function asFloat(bits)
        floatBits.u = bits
        return floatBits.f
    end

    parse[11] = function(bs, p)
        local background, color, duration, distance = readU32(bs), readU32(bs), readU32(bs), readU32(bs)
        local text = readString(bs, readU16(bs))
        if text == '' or text == ' ' then
            p.bubble = nil
            return
        end
        distance = asFloat(distance)
        if distance ~= distance or distance <= 0 or distance > 500 then distance = 30 end
        p.bubble = {
            text = text,
            color = rgbaToArgb(color),
            background = background ~= 0 and rgbaToArgb(background) or nil,
            distance = distance,
            expires = os.clock() + duration / 1000,
        }
    end

    parse[13] = function(bs)
        readU16(bs)
        readU16(bs)
    end
    parse[14] = parse[13]

    function TagData.reset(id)
        TagData.players[id] = fresh()
    end

    parse[12] = function(_, _, id)
        TagData.reset(id)
    end

    local Plugin = {}
    TagData.Plugin = Plugin
    do
        -- _chat.asi 2026-11-01: player array moved; record layout is unchanged.
        local RECORDS = 0xF2CD0
        local STRIDE = 0x1B0
        local BITS = {
            [0xb] = 0x100000, [0xd] = 0x80000, [0x11] = 0x40, [0x13] = 0x4000000,
            [14] = 0x10000, [8] = 0x40000, [4] = 0x200000, [5] = 0x400000, [6] = 0x800000,
            [9] = 0x1000000, [0x12] = 0x2000000,
        }
        local base, checkedAt = 0, -10

        local function moduleBase()
            if base ~= 0 then return base end
            local now = os.clock()
            if now - checkedAt < 5 then return 0 end
            checkedAt = now
            base = getModuleHandle('_chat.asi') or 0
            return base
        end

        local function readString(address)
            local size = memory.getuint32(address + 0x10, false)
            if size == 0 or size > 512 then return nil end
            local capacity = memory.getuint32(address + 0x14, false)
            local data = capacity > 15 and memory.getuint32(address, false) or address
            if data == 0 then return nil end
            return memory.tostring(data, size, false)
        end

        local function finite(v)
            return v == v and v > -1e6 and v < 1e6
        end

        pcall(ffi.cdef, 'uint32_t __stdcall GetTickCount(void);')

        function Plugin.readBubble(r, previous)
            local expire = memory.getuint32(r + 0x54, false)
            if expire == 0 then return nil end
            local left = expire - ffi.C.GetTickCount()
            if left >= 2147483648 then left = left - 4294967296 end
            if left <= 0 then return nil end
            local first, last = memory.getuint32(r + 0x3C, false), memory.getuint32(r + 0x40, false)
            if first == 0 or last <= first then return nil end
            local count = math.min(12, math.floor((last - first) / 0x24))
            local parts = {}
            for i = 0, count - 1 do
                local line = readString(first + i * 0x24)
                if line and line ~= '' then parts[#parts + 1] = line end
            end
            if #parts == 0 then return nil end
            local text = table.concat(parts, ' ')
            local distance = memory.getfloat(r + 0x50, false)
            if distance ~= distance or distance <= 0 or distance > 500 then distance = 30 end
            local bubble = previous and previous.utf8 and previous.text == text and previous or {}
            bubble.text, bubble.utf8 = text, true
            bubble.color = memory.getuint32(r + 0x48, false)
            local background = memory.getuint32(r + 0x4C, false)
            bubble.background = background ~= 0 and background or nil
            bubble.distance = distance
            bubble.expires = os.clock() + left / 1000
            return bubble
        end

        function Plugin.available()
            return moduleBase() ~= 0
        end

        function Plugin.read(id, p)
            local b = moduleBase()
            if b == 0 or id < 0 or id > 1003 then return false end
            local r = b + RECORDS + id * STRIDE
            local hp, armor = memory.getfloat(r + 0xA8, false), memory.getfloat(r + 0xAC, false)
            local maxHp, maxArmor = memory.getfloat(r + 0xB0, false), memory.getfloat(r + 0xB4, false)
            if not (finite(hp) and finite(armor) and finite(maxHp) and finite(maxArmor)) then return false end
            p.hp, p.armor = math.max(0, hp), math.max(0, armor)
            p.maxHp = maxHp > 0 and maxHp or nil
            p.maxArmor = maxArmor > 0 and maxArmor or nil

            local flags = memory.getuint32(r + 0x5C, false)
            local status = p.status
            for key, mask in pairs(BITS) do
                status[key] = bit.band(flags, mask) ~= 0 and 1 or 0
            end
            status[7] = bit.band(bit.rshift(flags, 4), 3)
            status[0xc] = bit.band(flags, 0xF)

            -- The plugin stores custom names as UTF-8, like titles and badges.
            local customNick = readString(r + 0x12C)
            p.customNick = customNick
            p.customNickUtf8 = customNick ~= nil

            local title = readString(r + 0xE4)
            if title and title ~= '' then
                p.title = title
                p.titleUtf8 = true
                p.titleColor = memory.getuint32(r + 0xA0, false)
                p.titleStyle = bit.band(bit.rshift(flags, 8), 0xFF)
                p.titleIcon = bit.band(flags, 0x80) ~= 0
            elseif p.titleUtf8 then
                p.title, p.titleUtf8 = nil, nil
            end
            local afkBase = memory.getuint32(r + 0xFC, false)
            if afkBase >= 2147483648 then afkBase = afkBase - 4294967296 end
            p.afkBase = afkBase

            local badge = readString(r + 0x104)
            if badge and badge ~= '' then
                p.badge = {
                    text = badge, utf8 = true,
                    background = memory.getuint32(r + 0x120, false),
                    color = memory.getuint32(r + 0x128, false),
                }
            elseif p.badge and p.badge.utf8 then
                p.badge = nil
            end

            p.bubble = Plugin.readBubble(r, p.bubble)
            p.afkTick = memory.getuint32(r + 0x100, false)
            p.fromPlugin = true
            return true
        end
    end

    parse[0] = function(bs, p, id)
        TagData.reset(id)
        p = TagData.players[id]
        if readU8(bs) ~= 0 then parse[1](bs, p) end
        parse[3](bs, p)
        parse[6](bs, p)
        parse[7](bs, p)
        if readU8(bs) ~= 0 then parse[8](bs, p) end
        if readU8(bs) ~= 0 then parse[9](bs, p) end
    end

    function TagData.handle(bs)
        raknetBitStreamIgnoreBits(bs, 8)
        if readU8(bs) ~= 0xDF then return end
        local id, kind = readU16(bs), readU8(bs)
        local handler = parse[kind]
        if id > 1003 or not handler then return end
        if not TagData.players[id] then TagData.reset(id) end
        handler(bs, TagData.players[id], id)
        if TagData.players[id] then TagData.players[id].fromPacket = true end
    end

    function TagData.get(id)
        local p = TagData.players[id]
        if not p then
            p = fresh()
            TagData.players[id] = p
        end
        if TagData.Plugin.read(id, p) then return p end
        return p.fromPacket and p or nil
    end

    function TagData.clear()
        TagData.players = {}
    end
end

addEventHandler('onReceivePacket', function(id, bs)
    if id == 34 then
        TagData.clear()
    elseif id == 220 then
        local start = raknetBitStreamGetReadOffset(bs)
        raknetBitStreamSetReadOffset(bs, 0)
        pcall(TagData.handle, bs)
        raknetBitStreamSetReadOffset(bs, start)
    end
end)

function sampev.onPlayerQuit(id)
    TagData.players[id] = nil
end

local Fonts = {}
local Icons = {list = {}, fonts = {}}
do
    local ICON_RANGE = imgui.new.ImWchar[3](0xF000, 0xF3FF, 0)

    local function range(list, from, to)
        for code = from, to do list[#list + 1] = code end
        return list
    end

    local SETS = {
        {
            res = 103, em = 36, base = 0xE000, boxY = {-157, 867}, tightX = {0xF200, 0xF259},
            codes = range(range(range({0xF25B, 0xF25D, 0xF26B}, 0xF200, 0xF227), 0xF250, 0xF259), 0xF270, 0xF27E),
        },
        {res = 104, em = 96, base = 0xE800, tight = true, codes = range({}, 0xF006, 0xF00A)},
    }

    pcall(ffi.cdef, [[
        void* __stdcall FindResourceA(void* module, const char* name, const char* type);
        void* __stdcall LoadResource(void* module, void* info);
        void* __stdcall LockResource(void* data);
        uint32_t __stdcall SizeofResource(void* module, void* info);
    ]])

    function Fonts.resource(id)
        local handle = getModuleHandle('_chat.asi')
        if not handle or handle == 0 then return nil end
        local ok, ptr, size = pcall(function()
            local module = ffi.cast('void*', handle)
            local info = ffi.C.FindResourceA(module, ffi.cast('const char*', id), ffi.cast('const char*', 10))
            if info == nil then return nil end
            local loaded = ffi.C.LoadResource(module, info)
            if loaded == nil then return nil end
            local data = ffi.C.LockResource(loaded)
            local size = ffi.C.SizeofResource(module, info)
            if data == nil or size == 0 then return nil end
            return ffi.cast('const uint8_t*', data), tonumber(size)
        end)
        if ok and ptr then return ptr, size end
        return nil
    end

    local function decompress(src, srcSize)
        local function in2(p) return src[p] * 0x100 + src[p + 1] end
        local function in3(p) return src[p] * 0x10000 + src[p + 1] * 0x100 + src[p + 2] end
        local function in4(p) return in3(p) * 0x100 + src[p + 3] end
        if srcSize < 16 or in4(0) ~= 0x57BC0000 or in4(4) ~= 0 then return nil end
        local size = in4(8)
        if size <= 0 or size > 0x4000000 then return nil end
        local out = ffi.new('uint8_t[?]', size)
        local o, i = 0, 16
        local function match(dist, n)
            local from = o - dist
            if from < 0 or o + n > size then error('bad match') end
            for k = 0, n - 1 do out[o + k] = out[from + k] end
            o = o + n
        end
        local function lit(p, n)
            if o + n > size or p + n > srcSize then error('bad literal') end
            ffi.copy(out + o, src + p, n)
            o = o + n
        end
        local ok = pcall(function()
            while i < srcSize do
                local c = src[i]
                if c >= 0x80 then match(src[i + 1] + 1, c - 0x7F); i = i + 2
                elseif c >= 0x40 then match(in2(i) - 0x3FFF, src[i + 2] + 1); i = i + 3
                elseif c >= 0x20 then local n = c - 0x1F; lit(i + 1, n); i = i + 1 + n
                elseif c >= 0x18 then match(in3(i) - 0x17FFFF, src[i + 3] + 1); i = i + 4
                elseif c >= 0x10 then match(in3(i) - 0xFFFFF, in2(i + 3) + 1); i = i + 5
                elseif c >= 0x08 then local n = in2(i) - 0x7FF; lit(i + 2, n); i = i + 2 + n
                elseif c == 0x07 then local n = in2(i + 1) + 1; lit(i + 3, n); i = i + 3 + n
                elseif c == 0x06 then match(in3(i + 1) + 1, src[i + 4] + 1); i = i + 5
                elseif c == 0x04 then match(in3(i + 1) + 1, in2(i + 4) + 1); i = i + 6
                else break end
            end
        end)
        if not ok or o ~= size then return nil end
        return out, size
    end

    local Ttf = {}
    Ttf.__index = Ttf

    local function u16(b, p) return b[p] * 0x100 + b[p + 1] end
    local function u32(b, p) return ((b[p] * 0x100 + b[p + 1]) * 0x100 + b[p + 2]) * 0x100 + b[p + 3] end
    local function s16(b, p) local v = u16(b, p); return v >= 0x8000 and v - 0x10000 or v end
    local function put16(b, p, v) b[p] = math.floor(v / 0x100) % 0x100; b[p + 1] = v % 0x100 end
    local function put32(b, p, v) put16(b, p, math.floor(v / 0x10000)); put16(b, p + 2, v % 0x10000) end

    function Ttf.open(data, size)
        local self = setmetatable({b = data, size = size, tables = {}}, Ttf)
        local count = u16(data, 4)
        for t = 0, count - 1 do
            local rec = 12 + t * 16
            self.tables[ffi.string(data + rec, 4)] = {rec = rec, off = u32(data, rec + 8), len = u32(data, rec + 12)}
        end
        for _, tag in ipairs({'cmap', 'head', 'hhea', 'hmtx', 'loca', 'glyf'}) do
            if not self.tables[tag] then return nil end
        end
        local b, t = data, self.tables
        self.upem = u16(b, t.head.off + 18)
        self.longLoca = s16(b, t.head.off + 50) ~= 0
        self.ascent = s16(b, t.hhea.off + 4)
        self.descent = s16(b, t.hhea.off + 6)
        self.metrics = u16(b, t.hhea.off + 34)
        self:findCmap()
        return self.cmap and self or nil
    end

    function Ttf:findCmap()
        local b, off = self.b, self.tables.cmap.off
        for n = 0, u16(b, off + 2) - 1 do
            local rec = off + 4 + n * 8
            local platform, encoding = u16(b, rec), u16(b, rec + 2)
            local sub = off + u32(b, rec + 4)
            local format = u16(b, sub)
            if platform == 3 and (encoding == 1 or encoding == 10) and (format == 4 or format == 12) then
                if not self.cmap or format == 12 then self.cmap, self.cmapFormat = sub, format end
            end
        end
    end

    function Ttf:glyphIndex(code)
        local b, sub = self.b, self.cmap
        if self.cmapFormat == 12 then
            for g = 0, u32(b, sub + 12) - 1 do
                local p = sub + 16 + g * 12
                local first, last = u32(b, p), u32(b, p + 4)
                if code >= first and code <= last then return u32(b, p + 8) + code - first end
            end
            return 0
        end
        local segs = u16(b, sub + 6) / 2
        local ends, starts = sub + 14, sub + 16 + segs * 2
        local deltas, offsets = starts + segs * 2, starts + segs * 4
        for s = 0, segs - 1 do
            if code <= u16(b, ends + s * 2) then
                local first = u16(b, starts + s * 2)
                if code < first then return 0 end
                local delta, ro = u16(b, deltas + s * 2), u16(b, offsets + s * 2)
                if ro == 0 then return (code + delta) % 0x10000 end
                local g = u16(b, offsets + s * 2 + ro + (code - first) * 2)
                return g == 0 and 0 or (g + delta) % 0x10000
            end
        end
        return 0
    end

    function Ttf:advance(gid)
        local i = math.min(gid, self.metrics - 1)
        return u16(self.b, self.tables.hmtx.off + i * 4)
    end

    function Ttf:bounds(gid)
        local b, t = self.b, self.tables
        local from, to
        if self.longLoca then
            from, to = u32(b, t.loca.off + gid * 4), u32(b, t.loca.off + gid * 4 + 4)
        else
            from, to = u16(b, t.loca.off + gid * 2) * 2, u16(b, t.loca.off + gid * 2 + 2) * 2
        end
        if to <= from then return nil end
        local p = t.glyf.off + from
        return s16(b, p + 2), s16(b, p + 4), s16(b, p + 6), s16(b, p + 8)
    end

    function Ttf:layers(gid)
        local colr, cpal = self.tables.COLR, self.tables.CPAL
        if not colr or not cpal then return nil end
        local b, c = self.b, colr.off
        local bases, baseOff, layerOff = u16(b, c + 2), c + u32(b, c + 4), c + u32(b, c + 8)
        local entries = u16(b, cpal.off + 2)
        local colors = cpal.off + u32(b, cpal.off + 8)
        local first = u16(b, cpal.off + 12)
        for n = 0, bases - 1 do
            local rec = baseOff + n * 6
            if u16(b, rec) == gid then
                local result = {}
                local index, count = u16(b, rec + 2), u16(b, rec + 4)
                for l = index, index + count - 1 do
                    local lr = layerOff + l * 4
                    local glyphId, palette = u16(b, lr), u16(b, lr + 2)
                    local color = {1, 1, 1, 1}
                    if palette ~= 0xFFFF and palette < entries then
                        local cr = colors + (first + palette) * 4
                        color = {b[cr + 2] / 255, b[cr + 1] / 255, b[cr] / 255, b[cr + 3] / 255}
                    end
                    result[#result + 1] = {gid = glyphId, color = color}
                end
                return result
            end
        end
        return nil
    end

    function Ttf:withCmap(map)
        local count = #map
        local tableSize = 12 + 16 + count * 12
        local at = math.ceil(self.size / 4) * 4
        local size = at + tableSize
        local out = ffi.new('uint8_t[?]', size)
        ffi.copy(out, self.b, self.size)
        put16(out, at, 0); put16(out, at + 2, 1)
        put16(out, at + 4, 3); put16(out, at + 6, 10); put32(out, at + 8, 12)
        local sub = at + 12
        put16(out, sub, 12); put16(out, sub + 2, 0); put32(out, sub + 4, 16 + count * 12)
        put32(out, sub + 8, 0); put32(out, sub + 12, count)
        for n, pair in ipairs(map) do
            local p = sub + 16 + (n - 1) * 12
            put32(out, p, pair[1]); put32(out, p + 4, pair[1]); put32(out, p + 8, pair[2])
        end
        local rec = self.tables.cmap.rec
        put32(out, rec + 8, at)
        put32(out, rec + 12, tableSize)
        return out, size
    end

    function Icons.prepare(src, srcSize, set)
        local data, size = decompress(src, srcSize)
        if not data then return nil end
        local ttf = Ttf.open(data, size)
        if not ttf then return nil end
        local scale = set.em / ttf.upem
        local map, codeOf, nextCode = {}, {}, set.base
        local icons, count = {}, 0
        for _, code in ipairs(set.codes) do
            local gid = ttf:glyphIndex(code)
            if gid > 0 then
                local icon = {layers = {}}
                local x0, y0, x1, y1 = math.huge, math.huge, -math.huge, -math.huge
                for _, layer in ipairs(ttf:layers(gid) or {{gid = gid, color = {1, 1, 1, 1}}}) do
                    local lx0, ly0, lx1, ly1 = ttf:bounds(layer.gid)
                    if lx0 then
                        local cp = codeOf[layer.gid]
                        if not cp then
                            cp = nextCode
                            nextCode = nextCode + 1
                            codeOf[layer.gid] = cp
                            map[#map + 1] = {cp, layer.gid}
                        end
                        local c = layer.color
                        icon.layers[#icon.layers + 1] = {cp = cp, yMax = ly1, r = c[1], g = c[2], b = c[3], a = c[4]}
                        x0, y0 = math.min(x0, lx0), math.min(y0, ly0)
                        x1, y1 = math.max(x1, lx1), math.max(y1, ly1)
                    end
                end
                if #icon.layers > 0 then
                    if set.tight then
                        icon.box = {x0, y0, x1, y1}
                    elseif set.tightX and code >= set.tightX[1] and code <= set.tightX[2] then
                        icon.box = {x0, set.boxY[1], x1, set.boxY[2]}
                    else
                        icon.box = {0, set.boxY[1], ttf:advance(gid), set.boxY[2]}
                    end
                    icon.aspect = (icon.box[3] - icon.box[1]) / (icon.box[4] - icon.box[2])
                    icons[code] = icon
                    count = count + 1
                end
            end
        end
        if count == 0 then return nil end
        local out, outSize = ttf:withCmap(map)
        return {
            data = out, size = outSize, icons = icons, count = count,
            first = set.base, last = nextCode - 1, scale = scale,
            pixels = set.em * (ttf.ascent - ttf.descent) / ttf.upem,
        }
    end

    function Icons.build(io)
        for _, set in ipairs(SETS) do
            local src, srcSize = Fonts.resource(set.res)
            local ok, font = pcall(Icons.prepare, src, srcSize, set)
            if src and ok and font then
                local fc = imgui.ImFontConfig()
                fc.FontDataOwnedByAtlas = false
                fc.OversampleH = 1
                fc.OversampleV = 1
                fc.PixelSnapH = false
                font.ranges = imgui.new.ImWchar[3](font.first, font.last, 0)
                font.font = io.Fonts:AddFontFromMemoryTTF(font.data, font.size, font.pixels, fc, font.ranges)
                if font.font ~= nil then
                    Icons.fonts[#Icons.fonts + 1] = font
                    for code, icon in pairs(font.icons) do
                        icon.owner = font
                        Icons.list[code] = icon
                    end
                end
            end
        end
    end

    local function resolve(icon)
        local f = icon.owner
        local quads = {}
        for _, layer in ipairs(icon.layers) do
            local g = f.font:FindGlyphNoFallback(layer.cp)
            if g ~= nil and g.Codepoint == layer.cp and g.X1 > g.X0 then
                if not f.baseline then f.baseline = g.Y0 - math.floor(-layer.yMax * f.scale) end
                quads[#quads + 1] = {
                    g.X0, g.Y0, g.X1, g.Y1, g.U0, g.V0, g.U1, g.V1,
                    math.floor(layer.r * 255 + 0.5), math.floor(layer.g * 255 + 0.5), math.floor(layer.b * 255 + 0.5), layer.a,
                }
            end
        end
        if #quads == 0 then return false end
        icon.quads = quads
        return true
    end

    function Icons.get(code)
        local icon = Icons.list[code]
        if not icon then return nil end
        if not icon.quads then
            if icon.failed or imgui.GetIO().Fonts.TexID == nil then return nil end
            if not resolve(icon) then
                icon.failed = true
                return nil
            end
        end
        return icon
    end

    function Icons.count()
        local n = 0
        for _ in pairs(Icons.list) do n = n + 1 end
        return n
    end

    function Icons.draw(dl, icon, x, y, w, h, alpha)
        local f = icon.owner
        local s = f.scale
        local box = icon.box
        local bx, by = box[1] * s, f.baseline - box[4] * s
        local k = h / ((box[4] - box[2]) * s)
        local texture = imgui.GetIO().Fonts.TexID
        for _, q in ipairs(icon.quads) do
            local a = math.floor(q[12] * alpha * 255 + 0.5)
            local color = ((a * 0x100 + q[11]) * 0x100 + q[10]) * 0x100 + q[9]
            dl:AddImage(texture,
                imgui.ImVec2(x + (q[1] - bx) * k, y + (q[2] - by) * k),
                imgui.ImVec2(x + (q[3] - bx) * k, y + (q[4] - by) * k),
                imgui.ImVec2(q[5], q[6]), imgui.ImVec2(q[7], q[8]), color)
        end
    end

    imgui.OnInitialize(function()
        local io = imgui.GetIO()
        io.IniFilename = nil
        local size = cfg.nametags.fontSize
        local main, mainSize = Fonts.resource(101)
        if main then
            Fonts.main = io.Fonts:AddFontFromMemoryCompressedTTF(main, mainSize, size, nil, io.Fonts:GetGlyphRangesCyrillic())
            local icons, iconsSize = Fonts.resource(103)
            if icons then
                local merge = imgui.ImFontConfig()
                merge.MergeMode = true
                io.Fonts:AddFontFromMemoryCompressedTTF(icons, iconsSize, size, merge, ICON_RANGE)
                Fonts.icons = true
            end
        end
        local big, bigSize = Fonts.resource(104)
        if big then
            Fonts.big = io.Fonts:AddFontFromMemoryCompressedTTF(big, bigSize, size + 5, nil, ICON_RANGE)
        end
        Icons.build(io)
    end)
end

local SystemFonts = {}
do
    pcall(ffi.cdef, [[
        long __stdcall RegOpenKeyExA(uintptr_t key, const char* subKey, uint32_t options, uint32_t access, uintptr_t* result);
        long __stdcall RegEnumValueA(uintptr_t key, uint32_t index, char* name, uint32_t* nameLen, uint32_t* reserved, uint32_t* kind, uint8_t* data, uint32_t* dataLen);
        long __stdcall RegCloseKey(uintptr_t key);
    ]])
    local KEY = 'SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Fonts'
    local ROOTS = {0x80000002, 0x80000001}

    local function fontsDir()
        return (os.getenv('WINDIR') or 'C:\\Windows') .. '\\Fonts\\'
    end

    local function read(root, list, seen)
        local ok, lib = pcall(ffi.load, 'advapi32')
        if not ok then return end
        local handle = ffi.new('uintptr_t[1]')
        if lib.RegOpenKeyExA(root, KEY, 0, 0x20019, handle) ~= 0 then return end
        local name, data = ffi.new('char[512]'), ffi.new('uint8_t[1024]')
        local nameLen, dataLen, kind = ffi.new('uint32_t[1]'), ffi.new('uint32_t[1]'), ffi.new('uint32_t[1]')
        local index = 0
        while index < 4096 do
            nameLen[0], dataLen[0] = 512, 1024
            if lib.RegEnumValueA(handle[0], index, name, nameLen, nil, kind, data, dataLen) ~= 0 then break end
            index = index + 1
            local title = ffi.string(name, nameLen[0]):gsub('%s*%(.-%)%s*$', '')
            local file = ffi.string(data, math.max(0, dataLen[0] - 1)):gsub('%z.*$', '')
            local ext = file:lower():match('%.(%a+)$')
            if title ~= '' and (ext == 'ttf' or ext == 'ttc' or ext == 'otf') and not seen[title] then
                seen[title] = true
                if not file:find(':', 1, true) then file = fontsDir() .. file end
                list[#list + 1] = {title = u8(title), path = file}
            end
        end
        lib.RegCloseKey(handle[0])
    end

    function SystemFonts.list()
        if SystemFonts.cache then return SystemFonts.cache end
        local list, seen = {}, {}
        for _, root in ipairs(ROOTS) do pcall(read, root, list, seen) end
        table.sort(list, function(a, b) return a.title:lower() < b.title:lower() end)
        SystemFonts.cache = list
        return list
    end

    function SystemFonts.path(title)
        if not title or title == '' then return nil end
        for _, item in ipairs(SystemFonts.list()) do
            if item.title == title then return item.path end
        end
        return nil
    end

    imgui.OnInitialize(function()
        local io = imgui.GetIO()
        local nt = cfg.nametags
        local path = SystemFonts.path(nt.bubbleFont)
        local size = math.max(8, math.min(40, nt.bubbleFontSize))
        if path and doesFileExist(path) then
            local ok, font = pcall(io.Fonts.AddFontFromFileTTF, io.Fonts, u8(path), size, nil, io.Fonts:GetGlyphRangesCyrillic())
            if ok and font ~= nil then Fonts.bubble = font end
        end
        if not Fonts.bubble and size ~= nt.fontSize then
            local data, dataSize = Fonts.resource(101)
            if data then Fonts.bubble = io.Fonts:AddFontFromMemoryCompressedTTF(data, dataSize, size, nil, io.Fonts:GetGlyphRangesCyrillic()) end
        end
    end)
end

local NameTags = {}
do
    local nt = cfg.nametags

    local TITLE_ICON = glyph(0xF25F)
    local AFK_ICON = glyph(0xF2FE)
    local STATUS_ICONS = {[8] = 0xF006, [4] = 0xF007, [5] = 0xF008, [6] = 0xF009, [18] = 0xF00A}
    local STATUS_ORDER = {8, 4, 5, 18}
    local STATUS_OPTION = {[8] = 'showStatusSpiral', [4] = 'showStatusEye', [5] = 'showStatusSwords', [18] = 'showStatusBottle'}
    local MUTE_KEY = 6
    local KEY = {mic = 7, voice = 0x11, crown = 0xb, level = 0xc, admin = 0xd, media = 0x13, typing = 14}
    local WEAPON_ICONS = {
        [1] = 0xF301, [2] = 0xF302, [3] = 0xF303, [4] = 0xF304, [5] = 0xF305, [6] = 0xF306,
        [7] = 0xF307, [8] = 0xF308, [9] = 0xF309, [10] = 0xF30A, [11] = 0xF30B, [12] = 0xF30C, [13] = 0xF30D,
        [14] = 0xF30E, [15] = 0xF30F, [16] = 0xF310, [17] = 0xF311, [18] = 0xF312, [22] = 0xF313,
        [23] = 0xF314, [24] = 0xF315, [25] = 0xF316, [26] = 0xF317, [27] = 0xF318, [28] = 0xF319,
        [29] = 0xF31A, [30] = 0xF31B, [31] = 0xF31C, [32] = 0xF31D, [33] = 0xF31E, [34] = 0xF31F,
        [35] = 0xF320, [36] = 0xF321, [37] = 0xF322, [38] = 0xF323, [39] = 0xF324, [40] = 0xF325,
        [41] = 0xF326, [42] = 0xF327, [43] = 0xF300, [44] = 0xF329, [45] = 0xF329, [46] = 0xF32A,
    }

    local function rgba(r, g, b, a)
        return imgui.ColorConvertFloat4ToU32(imgui.ImVec4(r, g, b, a))
    end

    local function fromArgb(value, alpha)
        local a = math.floor(value / 0x1000000) / 255
        local r = math.floor(value / 0x10000) % 256 / 255
        local g = math.floor(value / 0x100) % 256 / 255
        local b = value % 256 / 255
        return rgba(r, g, b, a * alpha)
    end

    local function fromHex(hex, alpha)
        local value = tonumber(hex, 16)
        return rgba(math.floor(value / 0x10000) / 255, math.floor(value / 0x100) % 256 / 255, value % 256 / 255, alpha)
    end

    local function status(p, key)
        return p and p.status[key] or 0
    end

    local function text(dl, x, y, color, str, alpha)
        dl:AddText(imgui.ImVec2(x + 1, y + 1), rgba(0, 0, 0, 0.9 * alpha), str)
        dl:AddText(imgui.ImVec2(x, y), color, str)
    end

    local function centered(dl, cx, y, color, str, alpha)
        local size = imgui.CalcTextSize(str)
        text(dl, cx - size.x / 2, y, color, str, alpha)
        return size
    end

    local function bar(dl, x, y, w, h, frac, fill, label, alpha)
        dl:AddRectFilled(imgui.ImVec2(x - 1, y - 1), imgui.ImVec2(x + w + 1, y + h + 1), rgba(0, 0, 0, 0.8 * alpha), 3)
        dl:AddRectFilled(imgui.ImVec2(x, y), imgui.ImVec2(x + w, y + h), rgba(0.15, 0.15, 0.15, 0.85 * alpha), 2)
        if frac > 0 then
            dl:AddRectFilled(imgui.ImVec2(x, y), imgui.ImVec2(x + w * frac, y + h), fill, 2)
        end
        if label then
            local size = imgui.CalcTextSize(label)
            text(dl, x + (w - size.x) / 2, y + (h - size.y) / 2, rgba(1, 1, 1, alpha), label, alpha)
        end
    end

    pcall(ffi.cdef, 'uint32_t __stdcall GetTickCount(void);')
    local pausedSince = {}

    local function afkMs(id, p)
        local since = pausedSince[id]
        if p and p.afkTick and p.afkTick ~= 0 then
            local elapsed = ffi.C.GetTickCount() - p.afkTick
            if elapsed < 0 then elapsed = elapsed + 4294967296 end
            return elapsed + p.afkBase
        end
        local own = since and (os.clock() - since) * 1000 or 0
        if p and p.afkBase and p.afkBase > 0 then return p.afkBase + own end
        if p and p.afkMs then return p.afkMs + (os.clock() - p.afkAt) * 1000 end
        return own
    end

    local function afkDuration(id, p)
        local seconds = math.max(0, math.floor(afkMs(id, p) / 1000))
        if seconds >= 3600 then
            return string.format('%d:%02d:%02d', math.floor(seconds / 3600), math.floor(seconds / 60) % 60, seconds % 60)
        end
        return string.format('%d:%02d', math.floor(seconds / 60), seconds % 60)
    end

    local function nickColor(id, alpha)
        local argb = sampGetPlayerColor(id)
        return rgba(
            bit.band(bit.rshift(argb, 16), 0xFF) / 255,
            bit.band(bit.rshift(argb, 8), 0xFF) / 255,
            bit.band(argb, 0xFF) / 255,
            alpha)
    end

    local Row = {}
    Row.__index = Row

    local function newRow(height, alpha)
        return setmetatable({items = {}, width = 0, height = height, alpha = alpha}, Row)
    end

    function Row:gap(w)
        self.width = self.width + w
    end

    function Row:icon(code, scale)
        local icon = Icons.get(code)
        if not icon then return false end
        local h = self.height * (scale or 1)
        local w = h * icon.aspect
        self.items[#self.items + 1] = {icon = icon, x = self.width, w = w, h = h}
        self.width = self.width + w
        return true
    end

    function Row:text(str, color)
        local size = imgui.CalcTextSize(str)
        self.items[#self.items + 1] = {text = str, color = color, x = self.width, w = size.x, h = size.y}
        self.width = self.width + size.x
    end

    function Row:draw(dl, cx, y)
        local left = cx - self.width / 2
        for _, item in ipairs(self.items) do
            local top = y + (self.height - item.h) / 2
            if item.icon then
                Icons.draw(dl, item.icon, left + item.x, top, item.w, item.h, self.alpha)
            else
                text(dl, left + item.x, top, item.color, item.text, self.alpha)
            end
        end
        return left, left + self.width
    end

    local function idBox(row, id)
        if not Icons.get(0xF27A) then return false end
        local digits = tostring(id)
        row:icon(0xF27A)
        for i = 1, #digits do row:icon(0xF270 + digits:byte(i) - 48) end
        row:icon(0xF27B)
        return true
    end

    local function nickRow(id, p, near, alpha, lineHeight)
        local name
        if p and p.customNick then
            name = p.customNickUtf8 and p.customNick or u8(p.customNick)
        else
            name = u8(sampGetPlayerNickname(id))
        end
        local row = newRow(lineHeight, alpha)
        local icons = nt.showIcons
        local space = lineHeight * 0.25

        if icons and near then
            local mic, level = status(p, KEY.mic), status(p, KEY.level) % 16
            local prefix
            if nt.showMicIcon and mic == 2 then prefix = 0xF27D
            elseif nt.showMicIcon and mic == 1 then prefix = 0xF27C
            elseif nt.showLevelIcon and level > 0 then prefix = 0xF24F + level end
            if prefix and row:icon(prefix, nt.iconScale) then row:gap(space) end
            if nt.showVideoIcon and status(p, KEY.voice) ~= 0 and row:icon(0xF27E, nt.iconScale) then row:gap(space) end
            if nt.showMuteIcon and status(p, MUTE_KEY) ~= 0 and row:icon(0xF009, nt.iconScale * 0.85) then row:gap(space) end
        end

        row:text(name, nickColor(id, alpha))

        if nt.showId and near then
            row:gap(space)
            if not (icons and nt.showIdBox and idBox(row, id)) then
                row:text(('[%d]'):format(id), nickColor(id, alpha))
            end
        end

        if icons and near then
            local suffix
            if nt.showMediaIcon and status(p, KEY.media) ~= 0 then
                suffix = 0xF26B
            elseif nt.showAdminIcon and status(p, KEY.admin) ~= 0 then
                suffix = 0xF25D
            elseif nt.showCrown and status(p, KEY.crown) ~= 0 and not (nt.showTitleFlag and p.title and (p.titleStyle or 0) > 0) then
                suffix = 0xF25B
            end
            if suffix then
                row:gap(space)
                row:icon(suffix, nt.iconScale)
            end
        end
        return row
    end

    local function titleRow(p, alpha, lineHeight)
        local row = newRow(lineHeight, alpha)
        local color = fromArgb(p.titleColor, alpha)
        if nt.showTitleIcon and p.titleIcon and Fonts.icons then row:text(TITLE_ICON .. ' ', color) end
        row:text(p.titleUtf8 and p.title or u8(p.title), color)
        local style = p.titleStyle or 0
        if nt.showTitleFlag and nt.showIcons and style > 0 then
            row:gap(lineHeight * 0.3)
            row:icon(0xF1FF + style, 1.0)
        end
        return row
    end

    local function wrapColored(str, width, defaultHex)
        local lines, line, lineWidth = {}, {}, 0
        local current = defaultHex
        local spaceWidth = imgui.CalcTextSize(' ').x
        for part in (str .. '\n'):gmatch('(.-)\n') do
            for word in part:gmatch('%S+') do
                local segments, plain = {}, ''
                local pos = 1
                while pos <= #word do
                    local s, e, hex = word:find('{(%x%x%x%x%x%x)}', pos)
                    local chunk = word:sub(pos, (s or #word + 1) - 1)
                    if chunk ~= '' then
                        segments[#segments + 1] = {text = chunk, hex = current}
                        plain = plain .. chunk
                    end
                    if not s then break end
                    current = hex
                    pos = e + 1
                end
                if plain ~= '' then
                    local w = imgui.CalcTextSize(plain).x
                    if lineWidth > 0 and lineWidth + spaceWidth + w > width then
                        lines[#lines + 1] = {segments = line, width = lineWidth}
                        line, lineWidth = {}, 0
                    end
                    if lineWidth > 0 then lineWidth = lineWidth + spaceWidth end
                    for _, seg in ipairs(segments) do
                        seg.x = lineWidth
                        line[#line + 1] = seg
                        lineWidth = lineWidth + imgui.CalcTextSize(seg.text).x
                    end
                end
            end
            if lineWidth > 0 then
                lines[#lines + 1] = {segments = line, width = lineWidth}
                line, lineWidth = {}, 0
            end
        end
        return lines
    end

    local function hexRgb(hex)
        local value = tonumber(hex, 16) or 0xFFFFFF
        return math.floor(value / 0x10000) / 255, math.floor(value / 0x100) % 256 / 255, value % 256 / 255
    end

    local function bubbleLines(bubble, str)
        local defaultHex = nt.bubbleTextCustom and nt.bubbleTextColor or ('%06X'):format(bubble.color % 0x1000000)
        local key = table.concat({str, defaultHex, tostring(nt.bubbleKeepColors), nt.bubbleWidth}, '|')
        if bubble.lines == nil or bubble.key ~= key then
            local source = nt.bubbleKeepColors and str or str:gsub('{%x%x%x%x%x%x}', '')
            bubble.lines = wrapColored(source, nt.bubbleWidth, defaultHex)
            bubble.key = key
        end
        return bubble.lines
    end

    function NameTags.renderBubble(dl, cx, bottom, bubble, str, alpha)
        if Fonts.bubble then imgui.PushFont(Fonts.bubble) end
        local lines = bubbleLines(bubble, str)
        if #lines == 0 then
            if Fonts.bubble then imgui.PopFont() end
            return bottom
        end
        local lineHeight = imgui.GetFontSize() + 1
        local width = 0
        for _, line in ipairs(lines) do width = math.max(width, line.width) end
        local pad = 5
        local tail = nt.bubbleTail and 5 or 0
        local height = #lines * lineHeight
        local top = bottom - height - pad * 2 - 4 - tail
        local left = cx - width / 2

        local bg
        if nt.bubbleBgCustom then
            local r, g, b = hexRgb(nt.bubbleBgColor)
            bg = rgba(r, g, b, nt.bubbleBgAlpha * alpha)
        elseif bubble.background then
            bg = fromArgb(bubble.background, alpha * 0.85)
        else
            local c = bubble.color
            bg = rgba(math.floor(c / 0x10000) % 256 / 255 * 0.2, math.floor(c / 0x100) % 256 / 255 * 0.2, c % 256 / 255 * 0.2, 0.75 * alpha)
        end
        local boxBottom = top + height + pad * 2
        local p1, p2 = imgui.ImVec2(left - pad, top), imgui.ImVec2(left + width + pad, boxBottom)
        dl:AddRectFilled(p1, p2, bg, nt.bubbleRounding)
        if tail > 0 then
            dl:AddTriangleFilled(imgui.ImVec2(cx - tail, boxBottom - 0.5), imgui.ImVec2(cx + tail, boxBottom - 0.5), imgui.ImVec2(cx, boxBottom + tail), bg)
        end
        if nt.bubbleBorder then
            local r, g, b = hexRgb(nt.bubbleTextCustom and nt.bubbleTextColor or ('%06X'):format(bubble.color % 0x1000000))
            dl:AddRect(p1, p2, rgba(r, g, b, 0.45 * alpha), nt.bubbleRounding, 15, 1)
        end

        for i, line in ipairs(lines) do
            local x = cx - line.width / 2
            local y = top + pad + (i - 1) * lineHeight
            for _, seg in ipairs(line.segments) do
                if nt.bubbleShadow then
                    text(dl, x + seg.x, y, fromHex(seg.hex, alpha), seg.text, alpha)
                else
                    dl:AddText(imgui.ImVec2(x + seg.x, y), fromHex(seg.hex, alpha), seg.text)
                end
            end
        end
        if Fonts.bubble then imgui.PopFont() end
        return top - 2
    end

    local function drawBubble(dl, cx, bottom, p, dist, alpha)
        local bubble = p and p.bubble
        if not bubble then return bottom end
        if os.clock() > bubble.expires then
            p.bubble = nil
            return bottom
        end
        if dist > bubble.distance then return bottom end
        local str = bubble.utf8 and bubble.text or u8(bubble.text)
        return NameTags.renderBubble(dl, cx, bottom, bubble, str, alpha)
    end

    local function drawTyping(dl, cx, bottom, alpha)
        local w, h, r = 40, 20, 3.2
        local left, top = cx - w / 2, bottom - h - 7
        local bg = rgba(0.06, 0.07, 0.09, 0.82 * alpha)
        local edge = rgba(1, 1, 1, 0.12 * alpha)
        dl:AddRectFilled(imgui.ImVec2(left, top), imgui.ImVec2(left + w, top + h), bg, h / 2)
        dl:AddRect(imgui.ImVec2(left, top), imgui.ImVec2(left + w, top + h), edge, h / 2, 15, 1)
        dl:AddTriangleFilled(imgui.ImVec2(cx - 5, top + h - 0.5), imgui.ImVec2(cx + 5, top + h - 0.5), imgui.ImVec2(cx, top + h + 6), bg)
        local t = os.clock() * 5
        for i = 0, 2 do
            local wave = (math.sin(t - i * 0.9) + 1) / 2
            local x = cx + (i - 1) * 10
            local y = top + h / 2 - wave * 2.5
            dl:AddCircleFilled(imgui.ImVec2(x, y), r, rgba(1, 1, 1, (0.35 + 0.65 * wave) * alpha), 12)
        end
        return top - 3
    end

    local function drawStatus(dl, cx, y, p, alpha)
        if not p then return y end
        if nt.showTyping and status(p, KEY.typing) ~= 0 then y = drawTyping(dl, cx, y, alpha) end
        local size = math.floor((imgui.GetFontSize() + 2) * 1.25)
        local row = newRow(size, alpha)
        local fallback = {}
        for _, key in ipairs(STATUS_ORDER) do
            if nt[STATUS_OPTION[key]] ~= false and status(p, key) ~= 0 then
                local code = STATUS_ICONS[key]
                if Icons.get(code) then
                    if #row.items > 0 then row:gap(4) end
                    row:icon(code)
                elseif Fonts.big then
                    fallback[#fallback + 1] = glyph(code)
                end
            end
        end
        if #row.items > 0 then
            row:draw(dl, cx, y - size - 1)
            y = y - size - 2
        end
        if #fallback > 0 then
            imgui.PushFont(Fonts.big)
            local text = centered(dl, cx, y - imgui.GetFontSize(), rgba(1, 1, 1, alpha), table.concat(fallback, ' '), alpha)
            imgui.PopFont()
            y = y - text.y - 1
        end
        return y
    end

    local function drawPlayer(dl, id, ped, dist, sx, sy)
        if not sampGetPlayerNickname(id) then return end
        local alpha = clamp((NameTags.maxDist - dist) / nt.fadeLen, 0, 1)
        if alpha <= 0 then return end

        local p = TagData.get(id)
        local near = dist <= NameTags.nearDist
        local lineHeight = imgui.GetFontSize() + 2
        local rowHeight = nt.showIcons and math.floor(lineHeight * 1.15) or lineHeight

        local nickY = sy - rowHeight
        local row = nickRow(id, p, near, alpha, rowHeight)
        local _, right = row:draw(dl, sx, nickY)

        if nt.showBadge and near and p and p.badge and p.badge.text ~= '' then
            local label = (p.badge.utf8 and p.badge.text or u8(p.badge.text))
            local size = imgui.CalcTextSize(label)
            local x = right + 6
            local y = nickY + (rowHeight - size.y) / 2
            dl:AddRectFilled(imgui.ImVec2(x - 3, y - 1), imgui.ImVec2(x + size.x + 3, y + size.y + 1), fromArgb(p.badge.background, alpha), 4)
            dl:AddText(imgui.ImVec2(x, y), fromArgb(p.badge.color, alpha), label)
        end

        local topY = nickY
        if nt.showTitle and p and p.title and p.title ~= '' then
            topY = topY - rowHeight
            titleRow(p, alpha, rowHeight):draw(dl, sx, topY)
        end

        local paused = sampIsPlayerPaused(id)
        if paused then
            pausedSince[id] = pausedSince[id] or os.clock()
        else
            pausedSince[id] = nil
        end
        if nt.showAfk and paused then
            local label = (Fonts.icons and AFK_ICON .. ' ' or '') .. 'AFK' .. (nt.showAfkTime and ' ' .. afkDuration(id, p) or '')
            topY = topY - lineHeight
            centered(dl, sx, topY, rgba(1, 0.8, 0.2, alpha), label, alpha)
        end

        if nt.showStatus then topY = drawStatus(dl, sx, topY, p, alpha) end
        if nt.showBubbles then drawBubble(dl, sx, topY, p, dist, alpha) end
        if not near then return end

        local hp = (p and p.hp) or math.max(0, sampGetPlayerHealth(id))
        local maxHp = math.max(hp, (p and p.maxHp and p.maxHp > 0) and p.maxHp or nt.maxHp)
        local armor = (p and p.armor) or math.max(0, sampGetPlayerArmor(id))
        local maxArmor = math.max(armor, (p and p.maxArmor and p.maxArmor > 0) and p.maxArmor or nt.maxArmor)

        local y = nickY + rowHeight + 3
        local w, h = nt.barWidth, nt.barHeight
        local weaponId = getCurrentCharWeapon(ped)
        local weapon = nt.showWeapon and Fonts.icons and WEAPON_ICONS[weaponId]
        local gap = weapon and 22 or 6
        local total = armor > 0 and (w * 2 + gap) or (w + (weapon and gap or 0))
        local x = sx - total / 2

        bar(dl, x, y, w, h, clamp(hp / maxHp, 0, 1), rgba(0.85, 0.2, 0.2, alpha), nt.showHpNumber and tostring(math.floor(hp)) or nil, alpha)
        x = x + w
        if weapon then
            local icon = glyph(weapon)
            local size = imgui.CalcTextSize(icon)
            text(dl, x + (gap - size.x) / 2, y + (h - size.y) / 2, rgba(1, 1, 1, alpha), icon, alpha)
        end
        if armor > 0 then
            bar(dl, x + gap, y, w, h, clamp(armor / maxArmor, 0, 1), rgba(0.85, 0.85, 0.9, alpha), nt.showArmorNumber and tostring(math.floor(armor)) or nil, alpha)
        end
    end

    local function layout(entries)
        local lineHeight = imgui.GetFontSize() + 2
        local rowHeight = nt.showIcons and math.floor(lineHeight * 1.15) or lineHeight
        local placed = {}
        for _, e in ipairs(entries) do
            local p = TagData.get(e.id)
            e.top = rowHeight
            if nt.showTitle and p and p.title and p.title ~= '' then e.top = e.top + rowHeight end
            if nt.showAfk and sampIsPlayerPaused(e.id) then e.top = e.top + lineHeight end
            e.bottom = e.dist <= NameTags.nearDist and (nt.barHeight + 6) or 2
            e.half = e.dist <= NameTags.nearDist and 95 or 70
            for _ = 1, 12 do
                local moved = false
                for _, o in ipairs(placed) do
                    if math.abs(e.sx - o.sx) < e.half + o.half
                        and e.sy + e.bottom > o.sy - o.top
                        and e.sy - e.top < o.sy + o.bottom then
                        e.sy = o.sy - o.top - e.bottom - 3
                        moved = true
                    end
                end
                if not moved then break end
            end
            placed[#placed + 1] = e
        end
    end

    local headBone = {}
    do
        local ok, fn = pcall(ffi.cast, 'void (__thiscall *)(void*, float*, int, bool)', 0x5E4280)
        local out = ffi.new('float[3]')

        function headBone.position(ped, px, py, pz)
            if ok then
                local pointer = getCharPointer(ped)
                if pointer and pointer ~= 0 and memory.getuint32(pointer + 0x18, false) ~= 0 then
                    fn(ffi.cast('void*', pointer), out, 8, true)
                    local x, y, z = out[0], out[1], out[2]
                    if x == x and z == z and math.abs(z - pz) < 3 and math.abs(x - px) < 3 then
                        return x, y, z + nt.aboveHead
                    end
                end
            end
            return px, py, pz + nt.headOffset
        end
    end

    function NameTags.draw()
        if Fonts.main then imgui.PushFont(Fonts.main) end
        local dl = imgui.GetBackgroundDrawList()
        local mx, my, mz = getCharCoordinates(PLAYER_PED)
        local cx, cy, cz = getActiveCameraCoordinates()
        local sampDistance = OriginalTags.distance()
        NameTags.maxDist = math.max(nt.maxDist, sampDistance)
        NameTags.nearDist = sampDistance > nt.maxDist and NameTags.maxDist or nt.nearDist
        local entries = {}
        for id = 0, 1003 do
            if sampIsPlayerConnected(id) then
                local ok, ped = sampGetCharHandleBySampPlayerId(id)
                if ok and ped ~= PLAYER_PED and doesCharExist(ped) then
                    local px, py, pz = getCharCoordinates(ped)
                    local dist = math.min(
                        getDistanceBetweenCoords3d(mx, my, mz, px, py, pz),
                        getDistanceBetweenCoords3d(cx, cy, cz, px, py, pz))
                    local hx, hy, hz = headBone.position(ped, px, py, pz)
                    if dist <= NameTags.maxDist and isPointOnScreen(hx, hy, hz, 0.2) then
                        local sx, sy = convert3DCoordsToScreen(hx, hy, hz)
                        if sx then
                            entries[#entries + 1] = {id = id, ped = ped, dist = dist, sx = sx, sy = sy}
                        end
                    end
                end
            end
        end
        table.sort(entries, function(a, b) return a.dist < b.dist end)
        if nt.stackTags then layout(entries) end
        for i = #entries, 1, -1 do
            local e = entries[i]
            drawPlayer(dl, e.id, e.ped, e.dist, e.sx, e.sy)
        end
        if Fonts.main then imgui.PopFont() end
    end
end

imgui.OnFrame(
    function() return cfg.nametags.enabled and isSampAvailable() and not isGamePaused() end,
    function(self)
        self.HideCursor = true
        NameTags.draw()
    end
)

local Labels = {}
do
    local lb = cfg.labels

    local function matches(text, list)
        if not text then return false end
        text = u8(text):gsub('{%x%x%x%x%x%x}', '')
        for _, phrase in ipairs(list) do
            if text:find(phrase, 1, true) then return true end
        end
        return false
    end

    function Labels.shouldBlock(text)
        return lb.enabled and matches(text, lb.remove)
    end

    function Labels.scan()
        if not lb.enabled then return end
        for id = 0, 2047 do
            if sampIs3dTextDefined(id) then
                local text = sampGet3dTextInfoById(id)
                if matches(text, lb.remove) then
                    sampDestroy3dText(id)
                elseif matches(text, lb.blank) then
                    pcall(sampSet3dTextString, id, ' ')
                end
            end
        end
    end

    function Labels.printNearby(radius)
        local mx, my, mz = getCharCoordinates(PLAYER_PED)
        local count = 0
        for id = 0, 2047 do
            if sampIs3dTextDefined(id) then
                local text, _, x, y, z = sampGet3dTextInfoById(id)
                if x and getDistanceBetweenCoords3d(mx, my, mz, x, y, z) <= radius then
                    sampAddChatMessage(('{AAAAAA}[3D #%d]{FFFFFF} %s'):format(id, ((text or ''):gsub('\n', ' | '))), -1)
                    count = count + 1
                end
            end
        end
        if count == 0 then say('рядом 3D-текстов нет') end
    end
end

function sampev.onCreate3DText(id, color, position, distance, testLOS, playerId, vehicleId, text)
    if Labels.shouldBlock(text) then return false end
end

addEventHandler('onScriptTerminate', function(script)
    if script == thisScript() then OriginalTags.restore() end
end)

local Settings = {}
do
    local show = imgui.new.bool(false)
    local activeTab = 1
    local nt, lb = cfg.nametags, cfg.labels
    local TABS = {'Основное', 'Ник', 'Под ником', 'Сообщения'}
    local loadedFont, loadedSize = nt.bubbleFont, nt.bubbleFontSize
    local colors = {}
    local preview = {color = 0xFFFFFFFF, text = 'Привет! {FFB347}Так будут{FFFFFF} выглядеть сообщения над игроками.'}
    local bools, floats, ints = {}, {}, {}

    function Settings.toggle()
        show[0] = not show[0]
    end

    local function save()
        config.save('ui_tweaks', cfg)
    end

    local function hint(text)
        imgui.TextColored(theme.color.Gray, text)
    end

    local function section(title, rows)
        local style = imgui.GetStyle()
        local height = rows * imgui.GetFrameHeightWithSpacing() - style.ItemSpacing.y + style.WindowPadding.y * 2
        imgui.TextColored(theme.color.Blue, title)
        imgui.BeginChild('##' .. title, imgui.ImVec2(0, height), true, imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.NoScrollWithMouse)
    end

    local function check(store, key, label, onChange)
        local id = tostring(store) .. key
        bools[id] = bools[id] or imgui.new.bool(store[key])
        bools[id][0] = store[key]
        if imgui.Checkbox(label, bools[id]) then
            store[key] = bools[id][0]
            if onChange then onChange(store[key]) end
            save()
        end
    end

    local function slider(store, key, label, min, max, format)
        local id = tostring(store) .. key
        floats[id] = floats[id] or imgui.new.float(store[key])
        floats[id][0] = store[key]
        imgui.PushItemWidth(240)
        if imgui.SliderFloat(label, floats[id], min, max, format or '%.1f') then
            store[key] = floats[id][0]
            save()
        end
        imgui.PopItemWidth()
    end

    local function sliderInt(store, key, label, min, max)
        local id = tostring(store) .. key
        ints[id] = ints[id] or imgui.new.int(store[key])
        ints[id][0] = store[key]
        imgui.PushItemWidth(240)
        if imgui.SliderInt(label, ints[id], min, max) then
            store[key] = ints[id][0]
            save()
        end
        imgui.PopItemWidth()
    end

    local function drawMain()
        section('Общее', 4)
        check(nt, 'enabled', 'Свои таблички над игроками (/nt)', function(value)
            if not value then OriginalTags.restore() end
        end)

        check(nt, 'stackTags', 'Раздвигать таблички, если наслаиваются')
        check(lb, 'enabled', 'Скрывать надписи лавок над игроками (/hl)')
        imgui.EndChild()

        section('Дальность', 3)
        slider(nt, 'maxDist', 'Максимальная дистанция', 10, 150, '%.0f м')
        slider(nt, 'nearDist', 'Полная детализация до', 5, 80, '%.0f м')
        slider(nt, 'fadeLen', 'Плавное исчезание', 1, 40, '%.0f м')
        imgui.EndChild()

        section('Положение и размер', 3)
        slider(nt, 'aboveHead', 'Высота над головой', 0, 1, '%.2f')
        slider(nt, 'headOffset', 'Высота без кости головы', 0.5, 1.6, '%.2f')
        sliderInt(nt, 'fontSize', 'Размер шрифта', 10, 24)
        imgui.EndChild()
        hint('Размер шрифта применится после перезапуска игры.')
    end

    local function drawElements()
        section('Строка ника', 5)
        check(nt, 'showIcons', 'Цветные иконки (общий выключатель)')
        check(nt, 'showId', 'ID игрока')
        check(nt, 'showIdBox', 'ID в жёлтой рамке')
        check(nt, 'showMicIcon', 'Микрофон')
        check(nt, 'showLevelIcon', 'Уровень')
        imgui.EndChild()

        section('Значки у ника', 5)
        check(nt, 'showVideoIcon', 'Камера')
        check(nt, 'showMuteIcon', 'Мут')
        check(nt, 'showMediaIcon', 'MEDIA')
        check(nt, 'showAdminIcon', 'Администратор')
        check(nt, 'showCrown', 'Корона')
        imgui.EndChild()

        section('Семья', 3)
        check(nt, 'showTitle', 'Название семьи / титул')
        check(nt, 'showTitleIcon', 'Значок у названия семьи')
        check(nt, 'showTitleFlag', 'Флаг семьи')
        imgui.EndChild()
    end

    local function drawBelow()
        section('Под ником', 6)
        check(nt, 'showHpNumber', 'Цифра HP')
        check(nt, 'showArmorNumber', 'Цифра брони')
        check(nt, 'showWeapon', 'Оружие')
        check(nt, 'showBadge', 'Плашка под ником')
        check(nt, 'showAfk', 'Метка AFK')
        check(nt, 'showAfkTime', 'Время AFK')
        imgui.EndChild()

        section('Над головой', 6)
        check(nt, 'showStatus', 'Статусы (общий выключатель)')
        check(nt, 'showTyping', 'Облачко «печатает...»')
        check(nt, 'showStatusSpiral', 'Спираль')
        check(nt, 'showStatusEye', 'Перечёркнутый глаз')
        check(nt, 'showStatusSwords', 'Скрещённые мечи')
        check(nt, 'showStatusBottle', 'Бутылка')
        imgui.EndChild()

        section('Размеры', 3)
        sliderInt(nt, 'barWidth', 'Ширина полосок', 40, 140)
        sliderInt(nt, 'barHeight', 'Высота полосок', 4, 20)
        slider(nt, 'iconScale', 'Масштаб иконок', 0.6, 2.0, '%.2f')
        imgui.EndChild()
    end

    local function colorEdit(store, key, label)
        local buf = colors[key]
        if not buf then
            buf = imgui.new.float[3]()
            colors[key] = buf
        end
        local value = tonumber(store[key], 16) or 0xFFFFFF
        buf[0], buf[1], buf[2] = math.floor(value / 0x10000) / 255, math.floor(value / 0x100) % 256 / 255, value % 256 / 255
        imgui.PushItemWidth(240)
        if imgui.ColorEdit3(label, buf) then
            local r, g, b = math.floor(buf[0] * 255 + 0.5), math.floor(buf[1] * 255 + 0.5), math.floor(buf[2] * 255 + 0.5)
            store[key] = ('%02X%02X%02X'):format(r, g, b)
            save()
        end
        imgui.PopItemWidth()
    end

    local function fontCombo()
        local current = nt.bubbleFont ~= '' and nt.bubbleFont or 'Встроенный (Arial Bold)'
        imgui.PushItemWidth(240)
        if imgui.BeginCombo('Шрифт', current) then
            if imgui.Selectable('Встроенный (Arial Bold)', nt.bubbleFont == '') then
                nt.bubbleFont = ''
                save()
            end
            for _, item in ipairs(SystemFonts.list()) do
                if imgui.Selectable(item.title, nt.bubbleFont == item.title) then
                    nt.bubbleFont = item.title
                    save()
                end
            end
            imgui.EndCombo()
        end
        imgui.PopItemWidth()
    end

    local function drawMessages()
        section('Сообщения над игроками', 3)
        check(nt, 'showBubbles', 'Показывать сообщения чата над головой')
        check(nt, 'bubbleTail', 'Хвостик у облачка')
        sliderInt(nt, 'bubbleWidth', 'Ширина облачка', 120, 420)
        imgui.EndChild()

        section('Шрифт', 2)
        fontCombo()
        sliderInt(nt, 'bubbleFontSize', 'Размер', 10, 30)
        imgui.EndChild()
        if nt.bubbleFont ~= loadedFont or nt.bubbleFontSize ~= loadedSize then
            if theme.coloredButton('blue', 'Применить шрифт', imgui.ImVec2(160, 26)) then
                save()
                thisScript():reload()
            end
            imgui.SameLine()
            hint('скрипт перезагрузится')
        end

        section('Текст', 4)
        check(nt, 'bubbleTextCustom', 'Свой цвет текста (иначе цвет от сервера)')
        colorEdit(nt, 'bubbleTextColor', 'Цвет текста')
        check(nt, 'bubbleKeepColors', 'Сохранять цветные вставки {RRGGBB} из сообщения')
        check(nt, 'bubbleShadow', 'Тень под текстом')
        imgui.EndChild()

        section('Фон', 5)
        check(nt, 'bubbleBgCustom', 'Свой цвет фона (иначе цвет от сервера)')
        colorEdit(nt, 'bubbleBgColor', 'Цвет фона')
        slider(nt, 'bubbleBgAlpha', 'Прозрачность фона', 0, 1, '%.2f')
        sliderInt(nt, 'bubbleRounding', 'Скругление', 0, 14)
        check(nt, 'bubbleBorder', 'Рамка цвета текста')
        imgui.EndChild()

        imgui.TextColored(theme.color.Blue, 'Предпросмотр')
        imgui.BeginChild('##bubblePreview', imgui.ImVec2(0, 90), true, imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.NoScrollWithMouse)
        local pos = imgui.GetWindowPos()
        local size = imgui.GetWindowSize()
        NameTags.renderBubble(imgui.GetWindowDrawList(), pos.x + size.x / 2, pos.y + size.y - 8, preview, preview.text, 1)
        imgui.EndChild()
    end

    local DRAW = {drawMain, drawElements, drawBelow, drawMessages}

    local NO_SCROLL = imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.NoScrollWithMouse
    local measured, contentHeight = {}, 420

    local function sidebar()
        imgui.BeginChild('##sidebar', imgui.ImVec2(160, contentHeight), true, NO_SCROLL)
        for i, label in ipairs(TABS) do
            local selected = activeTab == i
            if selected then imgui.PushStyleColor(imgui.Col.Button, imgui.GetStyle().Colors[imgui.Col.ButtonActive]) end
            if imgui.Button(label, imgui.ImVec2(145, 40)) then activeTab = i end
            if selected then imgui.PopStyleColor() end
            imgui.Dummy(imgui.ImVec2(0, 5))
        end
        imgui.SetCursorPosY(imgui.GetWindowHeight() - 30)
        imgui.Text('by @SpencerMSU')
        imgui.EndChild()
    end

    imgui.OnInitialize(function()
        theme.apply()
    end)

    imgui.OnFrame(function() return show[0] end, function()
        local sw, sh = getScreenResolution()
        imgui.SetNextWindowPos(imgui.ImVec2(sw / 2, sh / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.Begin('Кастомные никнеймы', show, imgui.WindowFlags.NoSavedSettings + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.AlwaysAutoResize)
        sidebar()
        imgui.SameLine()
        imgui.BeginChild('##content', imgui.ImVec2(500, contentHeight), true, NO_SCROLL)
        DRAW[activeTab]()
        measured[activeTab] = imgui.GetCursorPosY() + imgui.GetStyle().WindowPadding.y
        imgui.EndChild()
        local needed = 300
        for _, value in pairs(measured) do needed = math.max(needed, value) end
        contentHeight = math.floor(needed + 0.5)
        imgui.End()
    end)
end

function main()
    while not isSampAvailable() do wait(100) end

    local pending = {}
    local function command(name, action)
        sampRegisterChatCommand(name, function() pending[#pending + 1] = action end)
    end

    command('nt', function()
        cfg.nametags.enabled = not cfg.nametags.enabled
        if not cfg.nametags.enabled then OriginalTags.restore() end
        say(cfg.nametags.enabled and 'свои таблички' or 'родные таблички')
    end)

    command('chat', function() Settings.toggle() end)

    command('hl', function()
        cfg.labels.enabled = not cfg.labels.enabled
        say(cfg.labels.enabled and 'скрытие надписей включено' or 'скрытие надписей выключено (надписи вернутся после обновления зоны)')
    end)

    command('t3d', function() Labels.printNearby(15.0) end)

    command('ntinfo', function()
        local count, titled, bubbles, stats = 0, 0, 0, 0
        for _, p in pairs(TagData.players) do
            count = count + 1
            if p.title then titled = titled + 1 end
            if p.bubble then bubbles = bubbles + 1 end
            if p.hp then stats = stats + 1 end
        end
        local icons = Icons.count()
        say(('_chat.asi: %s, игроков %d, с HP %d, с фамой %d, с облачком %d, шрифт: %s, иконок: %d'):format(TagData.Plugin.available() and 'читается' or 'не найден', count, stats, titled, bubbles, Fonts.main and 'есть' or 'нет', icons))
    end)

    local tagsFound = OriginalTags.find()
    local nextFind = os.clock() + 2

    local nextScan = 0
    while true do
        wait(0)
        for i = 1, #pending do pending[i]() end
        if #pending > 0 then pending = {} end

        if not tagsFound and os.clock() >= nextFind then
            tagsFound = OriginalTags.find()
            nextFind = os.clock() + 2
        end
        if cfg.nametags.enabled and cfg.nametags.hideOriginal then OriginalTags.hide() end

        local now = os.clock()
        if now >= nextScan then
            nextScan = now + cfg.labels.scanInterval
            pcall(Labels.scan)
        end
    end
end
