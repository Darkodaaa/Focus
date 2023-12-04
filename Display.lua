local modem = peripheral.wrap("back")

local holoport = 65530
modem.open(holoport)
local args = {...}
local modelfile = args[1] or "model.holo"

local hologram = {}
if modelfile:match(".holo") then
    local f = fs.open(modelfile, "r")
    hologram = textutils.unserialise(f.readAll())
    f.close()
elseif modelfile:match(".3dj") then
    local f = fs.open(modelfile, "r")
    local model = textutils.unserialiseJSON(f.readAll())
    f.close()
    assert(model,"Invalid model")
    
    for k,v in pairs(model.shapesOff) do
        hologram[k] = {
            x = v.bounds[1]/16,
            y = v.bounds[2]/16+1,
            z = v.bounds[3]/16,
            w = (v.bounds[4]/16-v.bounds[1]/16),
            h = (v.bounds[5]/16-v.bounds[2]/16),
            d = (v.bounds[6]/16-v.bounds[3]/16),
            c = tonumber("0x"..v.tint.."ff")
        }
    end
else
    error("Invalid model extension")
end


local x,y,z = gps.locate(3)
if hologram.shapesOn then
    parallel.waitForAny(function()
        local signal = false
        while true do
            local lastsignal = signal
            signal = rs.getInput("left") or rs.getInput("right") or rs.getInput("front") or rs.getInput("back") or rs.getInput("top") or rs.getInput("bottom")
            if signal ~= lastsignal then
                modem.transmit(holoport,holoport,{Protocol="HologramPing",Coords={x = x, y = y, z = z},hologram = signal and hologram.shapesOn or hologram.shapesOff,id=os.getComputerID()})
            end
            os.sleep(0)
        end
    end,
    function()
        while true do
            local _, _, _, _, message = os.pullEvent("modem_message")
            if message == "GetHolograms" then
                modem.transmit(holoport,holoport,{Protocol="HologramPing",Coords={x = x, y = y, z = z},hologram=hologram.shapesOff,id=os.getComputerID()})
            end
        end
    end
    )
else
    while true do
        modem.transmit(holoport,holoport,{Protocol="HologramPing",Coords={x = x, y = y, z = z},hologram=hologram.shapesOff,id=os.getComputerID()})
        os.sleep(5)
    end
end