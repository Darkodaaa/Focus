local modem = peripheral.find("modem")
local modules = peripheral.find("neuralInterface")

local canvas = modules.canvas3d().create()
local holoport = 65530
modem.open(holoport)
local cache = {}
local event, side, channel, replyChannel, data, distance
local x,y,z = gps.locate()
canvas.recenter()

local Config = {--The configuration of your client.
    RenderDist = 20,--In blocks.(Calculated from the distance given from the "modem_message" event.)
    AlwaysRecenter = false,--If it should always recenter the canvas.(Can lead to holograms not rendering at the right place!)
    Xray = false,--If the holograms should be seen through blocks.(It makes the holograms look very glithcy if it consists of more than one cube!)
}

local function Render()
    canvas.clear()
    for kk,hologram in pairs(cache) do
        if hologram.dist < Config.RenderDist then
            --Rendering holograms
            for k,cube in pairs(hologram.body) do
                local box = canvas.addBox(hologram.coords.x+cube.x-x, hologram.coords.y+cube.y-y, hologram.coords.z+cube.z-z, cube.w, cube.h, cube.d, cube.c)
                box.setDepthTested(not Config.Xray)
            end
        end
    end
    if Config.AlwaysRecenter then canvas.recenter() end --Configurable
end

local function Check(data)--Checks for malformed data
    --Chacking if the required data exists
    if not data then return false, "Missing data" end
    if not data.id then return true, "Id not provided" end
    if not data.hologram then return false, "Hologram missing" end
    if not data.Protocol then return true, "Protocol not specified" end
    if not data.Coords then return false, "Coordinates not provided" end
    if not data.Coords.x or not data.Coords.y or not data.Coords.z then return false, "Cooridiantes missing" end

    --Checking data types
    if type(data) ~= "table" then
        return false, "Data is not the right data type \""..type(data).."\". It should be: \"table\""
    end
    local dataTypes = {
        id = "number",
        hologram = "table",
        Protocol = "string",
        Coords = "table",
    }
    for k,v in pairs(dataTypes) do
        if type( data[k]) ~= v then
            return false, k.." is not the right data type \""..type(data[v]).."\". It should be: \""..v.."\"."
        end
    end
    for k,v in pairs(data.Coords) do
        if type( v) ~= "number" then
            return false, k.."in coords is not the right data type \""..type(data.Coords[v]).."\".. It should be: \"number\"."
        end
    end
    return true, ""
end

local function Main()
    modem.transmit(holoport, holoport, {protocol="Connect", id = os.getComputerID()})
    local logged = {}
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
            local islogged = false
            for k,v in pairs(logged) do
                if v == data.id then islogged = true end
            end
            if not islogged then
                local col = term.getTextColor()
                term.setTextColor(colors.red)
                print(err.." Id: "..data.id or -1)
                term.setTextColor(col)
                table.insert(logged, data.id)
            end
        end

        Render()
    end
end

parallel.waitForAll(Main,function()
    if not Config.AlwaysRecenter then return end --Configurable
    while true do
        x,y,z = gps.locate()
        os.sleep(2)
    end
end)
