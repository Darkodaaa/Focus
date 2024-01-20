local lib = {}

--################################
--Functions for libary use
--################################

local function getIndex(table, filter)
    for k,v in pairs(table) do
        if pcall(filter(v)) then
            return k
        end
    end
end

--################################
--Functions for use
--################################

function lib.convert(raw)
    local json = textutils.unserialiseJSON(raw)
    local hologram = {}
    for k,v in pairs(json.shapesOff) do
        hologram.shapesOff[k] = {
            x = v.bounds[1]/16,
            y = v.bounds[2]/16+1,
            z = v.bounds[3]/16,
            w = (v.bounds[4]/16-v.bounds[1]/16),
            h = (v.bounds[5]/16-v.bounds[2]/16),
            d = (v.bounds[6]/16-v.bounds[3]/16),
            c = tonumber("0x"..v.tint.."ff")
        }
    end
    for k,v in pairs(json.shapesOn) do
        hologram.shapesOn[k] = {
            x = v.bounds[1]/16,
            y = v.bounds[2]/16+1,
            z = v.bounds[3]/16,
            w = (v.bounds[4]/16-v.bounds[1]/16),
            h = (v.bounds[5]/16-v.bounds[2]/16),
            d = (v.bounds[6]/16-v.bounds[3]/16),
            c = tonumber("0x"..v.tint.."ff")
        }
    end
    return hologram
end


--################################
--Functions for transforms
--################################

--[[ Transforms are currently not working well
local transform = {}

function transform.setPos(self, x, y, z)
    local hologram = self.hologram
    x, y, z = x or 0, y or 0, z or 0
    self.offset.x = x
    self.offset.y = y
    self.offset.z = z
    for k,state in pairs(hologram) do
        for k,v in pairs(state) do
            state[k].x = v.x+x/8
            state[k].y = v.y+y/8
            state[k].z = v.z+z/8
        end
    end
end

function transform.getPos(self)
    return self.offset.x, self.offset.y, self.offset.z
end

function transform.move(self, x, y, z)
    local hologram = self.hologram
    x, y, z = x or 0, y or 0, z or 0
    local offset = {self:getPos()}
    print(textutils.serialise(offset))
    self:setPos(self.offset.x + x, self.offset.y + y, self.offset.z + z)
end
]]
--################################
--Functions for the context
--################################

local function loadFile(context, filename)
    local f
    f = fs.open(filename, "r")
    if not f then
        f = fs.open(shell.resolve(filename), "r")
    end
    assert(f, "Couldn't open file")
    local file = f.readAll()
    f.close()

    local entry = {
        properties = {
            name = filename,
            label = "",
            hasTransform = false
        },
        hologram = {}
    }
    if filename:match(".holo") then
        entry.hologram = textutils.unserialise(file)
        entry.properties.type = "holo"
    elseif filename:match(".3dj") then
        entry.hologram = lib.convert(file)
        entry.properties.type = "3dj"
    end

    entry.properties.label = entry.hologram.label
    entry.hologram.label = nil
    table.insert(context.holograms, entry)
    return entry
end

local function saveFile(context, filename)
    local f = fs.open(filename, "w")
    assert(f, "Couldn't open file")
    f.write(context.holograms[getIndex(context.holograms2, function(v) return v.properties.name == filename end)])
    f.close()
end

local function removeFile(context, name)
    local entry = {}
    for k,v in pairs(context.holograms) do
        if v.properties.name == name then
            entry = v
            context.holograms[k] = nil
        end
    end
    return entry
end

local function changeFile(context, filename)
    local entry = {}
    for k,v in pairs(context.holograms) do
        if v.properties.name == name then
            entry = v
            context.holograms[k] = context.loadFile({}, filename)
        end
    end
    return entry
end

local function cast(context, x, y, z, hologram, state)
    if type(hologram) == "string" then
        hologram = context.holograms[getIndex(context.holograms2, function(v) return v.properties.name == hologram end)]
    elseif type(hologram) == "number" then
        hologram = context.holograms[hologram]
    end
    if not hologram[state] then error("Invalid state: "..state) end
    context.modem.transmit(context.holoport,context.holoport,{Protocol="HologramPing",Coords={x = x, y = y, z = z},hologram=hologram[state],id=os.getComputerID()})
end

local function stream(context, name)
    local stream = {
        running = false,
        hologram = {},
        state = "shapesOff",
        cast = function(self)
            local x, y, z = gps.locate(3)
            context:cast(x, y, z, self.hologram, self.state)
        end,
        start = function(self)
            self.running = true
            while self.running do
                self:cast()
                os.sleep(5)
            end
        end,
        stop = function(self) self.running = false end,
        setState = function(self, state)
            if not self.hologram[state] then error("Invalid state: "..state) end
            self.state = state
        end,
    }
    --for k,v in pairs(transform) do stream[k] = v end
    stream.hologram = {}
    for k,v in pairs(context.holograms) do
        if v.properties.name == name then
            stream.hologram = v.hologram
        end
    end

    return stream
end

local function getTransform(context, name)
    return context.holograms[name].properties.hasTransform and context.holograms.transform[name] or nil
end

function lib.createContext(options)
    if not options then
        options = {}
    end
    return {
        holoport = options.port or 65530,
        modem = options.modem or peripheral.find("modem"),
        holograms = {},
        loadFile = loadFile,
        saveFile = saveFile,
        removeFile= removeFile,
        changeFile= changeFile,
        cast = cast,
        stream = stream,
    }
end

return lib
--[[
local api = require("API")
local context = api.createContext()
context:loadFile("model.holo")
local stream = context:stream("model.holo")
parallel.waitForAll(
    function()
        stream:start()
    end,
    function()
        while true do
            local lastsignal = signal
            signal = rs.getInput("left") or rs.getInput("right") or rs.getInput("front") or rs.getInput("back") or rs.getInput("top") or rs.getInput("bottom")
            if signal ~= lastsignal then
                stream:setState(signal and "shapesOn" or "shapesOff")
            end
            os.sleep()
        end
        --os.sleep(10)
        --stream:stop()
    end
)
]]