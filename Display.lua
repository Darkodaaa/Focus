local modem = peripheral.wrap("back")

local holoport = 65530
modem.open(holoport)


local hologram = {
    {x = 0, y = 1,z = 0, w = 1, h = 1, d = 1, c = 0x000000ff},
    {x = 0, y = 11,z = 1, w = 1, h = 1, d = 1, c = 0xff0000ff},
    {x = 0, y = 12,z = 0, w = 1, h = 1, d = 1, c = 0x00ff00ff},
    {x = 1, y = 12,z = 3, w = 1, h = 1, d = 1, c = 0xf0ff00ff},
    {x = 3, y = 12,z = 1, w = 1, h = 1, d = 1, c = 0xf0f0f0ff},
    {x = 2, y = 12,z = 4, w = 1, h = 1, d = 1, c = 0xf00ff0ff},
    {x = 0, y = 12,z = 2, w = 1, h = 1, d = 1, c = 0x0f0ff0ff},
}

local f = fs.open("Model.3dj","r")
local model = f.readAll()
f.close()

if model then
    local table = textutils.unserialiseJSON(model)
    hologram = {}
    for k,v in pairs(table.shapesOff) do
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
    local table = hologram
    hologram = {}
    for k,v in pairs(table) do
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
end

local x,y,z = gps.locate(3)
while true do
    modem.transmit(holoport,holoport,{Protocol="HologramPing",Coords={x = x, y = y, z = z},hologram=hologram,id=os.getComputerID()})
    os.sleep(5)
end
