local modem = peripheral.find("modem")
local modules = peripheral.find("neuralInterface")

local canvas = modules.canvas3d().create()
local holoport = 65530
modem.open(holoport)
local cache = {}
local logged = {}
local event, side, channel, replyChannel, data, distance
local x,y,z = gps.locate()
canvas.recenter()

local Config = {--The configuration of your client.
    RenderDist = 20,--In blocks.(Calculated from the distance given from the "modem_message" event.)
    AlwaysRecenter = false,--If the should canvas to be recentered constantly.(Can lead to holograms not rendering at the right place!)
    Xray = false,--If the holograms should be seen through blocks.(It makes the holograms look very glithcy if it consists of more than one cube!)
    Debug = false, --The program will print debug information about holograms and events.
}

local function Check(data)--Checks for malformed data
    --Chacking if the required data exists
    if not data then return false, "Missing data." end
    if not data.id then return true, "Id not provided." end
    if not data.hologram then return false, "Hologram missing." end
    if not data.hologram.properties then return true, "Hologram properties missing." end
    if not data.hologram.cubes then return false, "Hologram cubes missing." end
    if not data.hologram.groups then return false, "Hologram groups missing." end
    if not data.Protocol then return true, "Protocol not specified." end
    if not data.Coords then return false, "Coordinates not provided." end
    if not data.Coords.x or not data.Coords.y or not data.Coords.z then return false, "Cooridiantes missing." end

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

local function addHologram(packet)
    local ok, err = Check(packet)
    if ok then
        if Config.Debug then print("DEBUG: Added hologram from: "..packet.id.." distance: "..packet.distance.." coords: "..textutils.serialise(packet.Coords)) end
        local entry = packet.hologram
        entry.dist = packet.distance
        entry.coords = packet.Coords
        cache[packet.id or math.random(0,5000)] = entry
    else
        local islogged = false
        for k,v in pairs(logged) do
            if v == packet.id then islogged = true end
        end
        if not islogged then
            local col = term.getTextColor()
            term.setTextColor(colors.red)
            print(err.." Id: "..packet.id or -1)
            term.setTextColor(col)
            table.insert(logged, packet.id)
        end
    end
end

local function removeHologram(packet)
    for k,v in pairs(cache) do
        if k == packet.id then
            if Config.Debug then print("DEBUG: Removed hologram from cache with id: "..k) end
            cache[k] = nil
        end
    end
end

local function Render()
    while true do
        canvas.clear()
        for id,hologram in pairs(cache) do
            if hologram.dist < Config.RenderDist then
                --Rendering holograms
                local label = canvas.addFrame({
                hologram.label.coords.x+hologram.coords.x-x,
                hologram.label.coords.y+hologram.coords.y-y,
                hologram.label.coords.z+hologram.coords.z-z})
                local w,h = label.getSize()
                label.setPosition(
                hologram.label.coords.x+hologram.coords.x-x-w/2,
                hologram.label.coords.y+hologram.coords.y-y-h/2,
                hologram.label.coords.z+hologram.coords.z-z)
                label.addText({w/2,h/2},hologram.label.displayText)
                label.setRotation(hologram.label.rotation.pitch or 0,hologram.label.rotation.yaw or 0, hologram.label.rotation.roll or 0)
                for k,cube in pairs(hologram.cubes) do
                    if Config.Debug then print("DEBUG: Rendering cube: ",
                    (hologram.coords.x-x)+cube.position.x/16,
                    (hologram.coords.y-y)+cube.position.y/16,
                    (hologram.coords.z-z)+cube.position.z/16,
                    cube.dimensions.w, cube.dimensions.h, cube.dimensions.d, cube.color) end
                    local box = canvas.addBox(
                    (hologram.coords.x-x)+cube.position.x/16,
                    (hologram.coords.y-y)+cube.position.y/16,
                    (hologram.coords.z-z)+cube.position.z/16,
                    cube.dimensions.w/16, cube.dimensions.h/16, cube.dimensions.d/16, tonumber("0x"..cube.color)
                    )
                    box.setDepthTested(not Config.Xray)
                end
            end
        end
        if Config.AlwaysRecenter then canvas.recenter() end --Configurable
        os.sleep(0)
    end
end


local function Main()
    modem.transmit(holoport, holoport, {Protocol="ClientConnect", id = os.getComputerID(), position = {x=x, y=y, z=z}})
    while true do
        repeat
            event, side, channel, replyChannel, data, distance = os.pullEventRaw()
            if event == "terminate" then
                canvas.clear()
                return nil
            end
        until event == "modem_message" and channel == holoport

        data.distance = distance
        if data.Protocol == "HologramPing" then
            addHologram(data)
        elseif data.Protocol == "HologramKill" then
            removeHologram(data)
        end
    end
end

local function Recenter()
    if not Config.AlwaysRecenter then return end --Configurable
    while true do
        x,y,z = gps.locate()
        os.sleep(2)
    end
end

parallel.waitForAll(Main, Recenter, Render)