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
                box.setDepthTested(Config.Xray)
            end
        end
    end
    if Config.AlwaysRecenter then canvas.recenter() end
end

local function Main()
    while true do
        repeat
            event, side, channel, replyChannel, data, distance = os.pullEventRaw()
            if event == "terminate" then
                print("Terminated")
                canvas.clear()
                return nil
            end
        until event == "modem_message" and data.Protocol == "HologramPing"

        cache[data.id] = {body = data.hologram,dist = distance,coords=data.Coords}

        Render()
    end
end


local function Relocate()
    if not Config.AlwaysRecenter then return nil end
    while true do
        x,y,z = gps.locate()
        os.sleep(2)
    end
end

parallel.waitForAny(Main,Relocate)