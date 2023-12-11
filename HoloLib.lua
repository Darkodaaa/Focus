local api = {}

--################################
--Functions for use
--################################

function api.convert(raw)
    local json = textutils.unserialiseJSON(raw)
    local hologram = {}
    for k,v in pairs(model.shapesOff) do
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
    for k,v in pairs(model.shapesOn) do
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
            name = filename
        },
        hologram = {}
    }
    if filename:match(".holo") then
        entry.hologram = textutils.unserialise(file)
        entry.properties.type = "holo"
    elseif filename:match(".3dj") then
        entry.hologram = api.convert(file)
        entry.properties.type = "3dj"
    end

    table.insert(context.holograms, entry)
    context.hologram = entry
    return entry
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

local function stream(context, name)
    local stream = {
        state = false,
        hologram = {},
        start = function(self)
            self.state = true
            local x,y,z = gps.locate(3)
            while self.state do
                context.modem.transmit(context.holoport,context.holoport,{Protocol="HologramPing",Coords={x = x, y = y, z = z},hologram=self.hologram.shapesOff,id=os.getComputerID()})
                os.sleep(5)
            end
        end,
        stop = function(self) self.state = false end,
    }
    stream.hologram = {}
    for k,v in pairs(context.holograms) do
        if v.properties.name == name then
            stream.hologram = v.hologram
        end
    end

    return stream
end

function api.createContext(options)
    if not options then
        options = {}
    end
    return {
        holoport = options.port or 65530,
        modem = options.modem or peripheral.find("modem"),
        holograms = {},
        loadFile = loadFile,
        removeFile= removeFile,
        stream = stream,
    }
end

--[[
    local api = require("api")
    local context = api.createContext()
    context:loadFile("model.holo")
    local stream = context:stream("model.holo")
    parallel.waitForAll(
        function()
            stream:start()
        end,
        function()
            os.sleep(5)
            stream:stop()
        end
    )
    
]]

--[[
    start = function(self)
            self.state = true
            if self.hologram.shapesOn then
                parallel.waitForAny(function()
                    local signal = false
                    while self.state do
                        local lastsignal = signal
                        signal = rs.getInput("left") or rs.getInput("right") or rs.getInput("front") or rs.getInput("back") or rs.getInput("top") or rs.getInput("bottom")
                        if signal ~= lastsignal then
                            context.modem.transmit(context.holoport,context.holoport,{Protocol="HologramPing",Coords={x = x, y = y, z = z},hologram = signal and self.hologram.shapesOn or self.hologram.shapesOff,id=os.getComputerID()})
                        end
                        os.sleep(0)
                    end
                end,
                function()
                    while self.state do
                        local _, _, _, _, message = os.pullEvent("modem_message")
                        if message == "GetHolograms" then
                            context.modem.transmit(context.holoport,context.holoport,{Protocol="HologramPing",Coords={x = x, y = y, z = z},hologram=self.hologram.shapesOff,id=os.getComputerID()})
                        end
                    end
                end
                )
            else
                while self.state do
                    context.modem.transmit(context.holoport,context.holoport,{Protocol="HologramPing",Coords={x = x, y = y, z = z},hologram=self.hologram.shapesOff,id=os.getComputerID()})
                    os.sleep(5)
                end
            end
        end,
]]

return api