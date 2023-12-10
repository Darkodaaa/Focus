local modem = peripheral.find("modem")
local modules = peripheral.find("neuralInterface")

local canvas = modules.canvas3d().create()
local holoport = 65530
modem.open(holoport)
local cache = {}
local event, side, channel, replyChannel, data, distance
local x,y,z = gps.locate()
canvas.recenter()

local Config = {--The configuration of your client
    RenderDist = 20,--In blocks.
    AlwaysRecenter = false,--If it should always recenter the canvas.(Can lead to holograms not rendering at the right place!)
    Xray = false,--If the holograms should be seen through blocks.
}

local function Render()
    canvas.clear()
    for kk,hologram in pairs(cache) do
        if hologram.dist < Config.RenderDist then
            for k,cube in pairs(hologram.body) do
                local box = canvas.addBox(hologram.coords.x+cube.x-x, hologram.coords.y+cube.y-y, hologram.coords.z+cube.z-z, cube.w, cube.h, cube.d, cube.c)
                box.setDepthTested(not Config.Xray)
            end
        end
    end
    if Config.AlwaysRecenter then canvas.recenter() end
end

local function Check(data)--Checks for malformed data
    if not data then return false, "Missing data" end
    if not data.id then return true, "Id not provided" end
    if not data.hologram then return false, "Hologram missing" end
    if not data.Protocol then return true, "Protocol not specified" end
    if not data.Coords then return false, "Coordinates not provided" end
    if not data.Coords.x or data.Coords.y or data.Coords.z then return false, "Cooridiantes missing" end
    return true, ""
end

local function Main()
    modem.transmit(holoport, holoport, {protocol="Connect", id = os.getComputerID()})
    while true do
        repeat
            event, side, channel, replyChannel, data, distance = os.pullEventRaw()
            if event == "terminate" then
                print("Terminated")
                canvas.clear()
                return nil
            end
        until event == "modem_message" and data.Protocol == "HologramPing"

        local ok, err = Check(data)
        if ok then
            cache[data.id or math.random(0,5000)] = {body = data.hologram,dist = distance,coords=data.Coords}
        else
            print(err)
        end

        Render()
    end
end


local function Relocate()
    while true do
        if Config.AlwaysRecenter then
            x,y,z = gps.locate()
        end
        os.sleep(2)
    end
end

parallel.waitForAny(Main,Relocate)
