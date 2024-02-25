local api = {}
local modem = peripheral.find("modem")
local packetv = 1.0
assert(modem,"No modem found")

local function loadJson(path)
    assert(type(path) == "string", "Invalid path type: " .. type(path))
    assert(path:match(".json"), "Invalid file type ")
    local f = fs.open(path, "r")
    local json = textutils.unserialiseJSON(f:readAll())
    local err = "Missing: "
    err = json.properties and err or err.."properties, "
    err = json.cubes and err or err.."cubes, "
    err = json.groups and err or err.."groups, "
    assert(err=="Missing: ", err.."not found.")
    f:close()
    return json
end

local function contains(table, value)
    for k, v in pairs(table) do
        if v == value then return true end
    end
    return false
end

local function resolveCoords(x, y, z, coords)
    if not x or not y or not z then
        x = x or coords[1]
        y = y or coords[2]
        z = z or coords[3]
    end
    return x, y, z
end

local function newInstance(class)
    local instance = {}
    for k, v in pairs(class) do
        instance[k] = v
    end
    return instance
end

local function instanceOf(obj)
    return obj.instance.properties.instanceType
end

local function makeVirtual(obj, name)
    table.insert(obj.virtual, name)
end

local function isVirtual(obj, name)
    for k,v in pairs(obj.virtual) do
        if k == name then return true end
    end
    return false
end

local function initClass()
    return {
        keys = {
            "keys",
            "virtual",
            "properties",
            "makeVirtual",
            "newInstance",
            "instanceOf",
        },
        virtual = {},
        properties = {
            allowAddingValues=false,
        },
        makeVirtual = makeVirtual,
        isVirtual = isVirtual,
        newInstance = newInstance,
        instanceOf = instanceOf,
    }
end

local function loadClass(obj, Constructor)
    local function isProtected(key)
        if (isVirtual(obj, key)) then
            return false
        end
        if (obj[key] == nil) then
            return not obj.properties.allowAddingValues
        end
        for k, v in pairs(obj.keys) do
            if k == key then return true end
        end
        return false
    end
    obj = Constructor(obj,{})
    local metatable = {
        __metatable = {},
        __call = Constructor,
        __newindex = function(self, k, v)
            return isProtected(k) and nil or rawset(self, k, v)
        end,
        --[[__pairs = function (t)
            return function (t, k)
                local k, v
                repeat
                    k, v= next(t,k)
                until k == nil or not isProtected(k)
                return k, v
            end, t, nil
        end]]
    }
    return setmetatable(obj, metatable)
end

--Cube class declaration
local cube = initClass()

--- Cube class
--- @param options table Values that can be set at init. 
--- @param colors table The color of the cube can be specified in options
--- @param pivot table The pivot of the cube can be specified in options
--- @param position table The position of the cube can be specified in options
--- @param dimensions table The dimensions of the cube can be specified in options
--- @return table An instance of the Cube class
local function Constructor(self, options)
    local instance = self:newInstance()
    instance.properties.instanceType = "cube"

    instance.color = options.color or "ffffffff"
    instance.pivot = options.pivot or {x=0,y=0,z=0}
    instance.positon = options.positon or {x=0,y=0,z=0}
    instance.dimensions = options.dimensions or {w=0,h=0,d=0}
    return instance
end

--- Return the color of the given cube as a hex string
---@return string The color of the given cube in hex as a string
function cube:getColorHex()
    return self.color
end

--- Sets the color of the given cube as a hex string
--- @param col string The hex color to set to the cube
--- @return string The previous color of the given cube
function cube:setColorHex(col)
    assert(type(col) == "string","Invalid argument #1 color must be as string")
    local hex = self.color
    self.color = hex
    return hex
end

--- Gets the color of the given cube as rgb values
--- @return number The red value of the color of the cube
--- @return number The green value of the color of the cube
--- @return number The blue value of the color of the cube
function cube:getColorRGB()
    local hex = self.color
    return tonumber("0x" .. hex:sub(1, 2)), tonumber("0x" .. hex:sub(3, 4)), tonumber("0x" .. hex:sub(5, 6))
end

--- Sets to color of the cube by rgb values
--- @param number The red value of the color
--- @param number The green value of the color
--- @param number The blue value of the color
--- @return number The red value of the previous color
--- @return number The green value of the previous color
--- @return number The blue value of the previous color
function cube:setColorRGB(r, g, b)
    assert(type(r) == "number", "Invalid argument #1 red must be a number")
    assert(type(g) == "number", "Invalid argument #2 green must be a number")
    assert(type(b) == "number", "Invalid argument #3 blue must be a number")
    local r, g, b = self:getColorRGB()
    self:setColorHex(string.format("%02X%02X%02X", r, g, b))
    return r, g, b
end

--- Gets the pivot of the cube
--- @return table The pivot of the cube
function cube:getPivot()
    return self.Pivot
end

--- Sets the pivot of the cube
--- @param table The pivot containing x, y and z value of the postion of the pivot
--- @param number x The x position of the pivot
--- @param number y The y position of the pivot
--- @param number z The z position of the pivot
--- @return table The pervious pivot of the cube
function cube:setPivot(...)
    local args = {...}
    local oldPivot = self.Pivot
    local pivot = {x=0,y=0,z=0}
    if #args == 1 then
        assert(type(args[1]) == "table" and #args[1] == 3, "Invalid argument. If you provide one argument the type has to be a table with the pivot's coordinates.")
        pivot.x = args[1][1] or args[1].x or 0
        pivot.y = args[1][2] or args[1].y or 0
        pivot.z = args[1][3] or args[1].z or 0
    elseif #args == 3 then
        assert(#args == 3 and type(args[1]) == "number" and type(args[2]) == "number" and type(args[3]) == "number", "Invalid argument. If you provide three arguments the types have to numbers.")
        pivot.x = args[1] or 0
        pivot.y = args[2] or 0
        pivot.z = args[3] or 0 
    end
    self.pivot = pivot
    return oldPivot
end

--- Gets the position of the cube
--- @return table The postion of the cube
function cube:getPosition()
    return self.Position
end

--- Sets the position of the cube
--- @param table The position of the cube
--- @param number The x position of the cube
--- @param number The y position of the cube
--- @param number The z position of the cube
--- @return table The previous position of the cube
function cube:setPosition(...)
    local args = {...}
    local oldPosition = self.Position
    local position = {x=0,y=0,z=0}
    if #args == 1 then
        assert(type(args[1]) == "table" and #args[1] == 3, "Invalid argument. If you provide one argument the type has to be a table with the cubes's coordinates.")
        position.x = args[1][1] or args[1].x
        position.y = args[1][2] or args[1].y
        position.z = args[1][3] or args[1].z
    elseif #args == 3 then
        assert(#args == 3 and type(args[1]) == "number" and type(args[2]) == "number" and type(args[3]) == "number", "Invalid argument. If you provide three arguments the types have to numbers.")
        position.x = args[1] or 0
        position.y = args[2] or 0
        position.z = args[3] or 0 
    end
    self.position = position
    return oldPosition
end

--- Gets the dimensions of the cube in width, height and depth
--- @returns table The dimensions of the cube
function cube:getDimensions()
    return self.Dimensions
end

--- Sets the dimensions of the cube in width, height and depth
--- @param table dimensions The dimensions of the cube
--- @param number width The width of the cube
--- @param number height The height of the cube
--- @param number depth The depth of the cube
--- @return table The previous dimensions of the cube
function cube:setDimensions(...)
    local args = {...}
    local oldDimensions = self.Dimensions
    local dimensions = {w=0,h=0,d=0}
    if #args == 1 then
        assert(type(args[1]) == "table" and #args[1] == 3, "Invalid argument. If you provide one argument the type has to be a table with the cubes's dimensions.")
        dimensions.w = args[1][1] or args[1].w
        dimensions.h = args[1][2] or args[1].h
        dimensions.d = args[1][3] or args[1].d
    elseif #args == 3 then
        assert(#args == 3 and type(args[1]) == "number" and type(args[2]) == "number" and type(args[3]) == "number", "Invalid argument. If you provide three arguments the types have to numbers.")
        dimensions.w = args[1] or 0
        dimensions.h = args[2] or 0
        dimensions.d = args[3] or 0 
    end
    self.dimensions = dimensions
    return oldDimensions
end

api.cube = loadClass(cube, Constructor)

--Group class declaration
local group = initClass()

local function Constructor(self, options)
    local instance = self:newInstance()
    instance.properties.instanceType = "group"

    instance.children = options.children or {}
    instance.name = options.name or "Group_"..math.random(1,99)--Making sure the name is unique
    instance.pivot = options.pivot or {x=0,y=0,z=0}
    return instance
end

function group:getPivot()
    return self.Pivot
end

function group:setPivot(...)
    local args = {...}
    local oldPivot = self.Pivot
    local pivot = {x=0,y=0,z=0}
    if #args == 1 then
        assert(type(args[1]) == "table" and #args[1] == 3, "Invalid argument. If you provide one argument the type has to be a table with the pivots coordinates.")
        pivot.x = args[1][1] or args[1].x
        pivot.y = args[1][2] or args[1].y
        pivot.z = args[1][3] or args[1].z
    elseif #args == 3 then
        assert(#args == 3 and type(args[1]) == "number" and type(args[2]) == "number" and type(args[3]) == "number", "Invalid argument. If you provide three arguments the types have to numbers.")
        pivot.x = args[1] or 0
        pivot.y = args[2] or 0
        pivot.z = args[3] or 0 
    end
    self.pivot = pivot
    return oldPivot
end

function group:setName(name)
    local oldName = self.name
    self.name = name
    return oldName
end

function group:getName()
    return self.name
end

function group:addChild(...)
    local args = {...}
    assert((type(args[1]) == "table" and instanceOf(arg[1]) == "group") or type(args[1]) == "number", "Invalid argument type must be either group or number")
    local child = instanceOf(arg[1]) == "group" and args[2] or args[1]
    assert(contains(self.children, child), "Group already contains child.")
    return table.insert(self.children, child)
end

function group:getChild(id)
    return self.children[id]
end

function group:removeChild(id)
    local child = self.children[id]
    self.children[id] = nil
    return child
end

api.group = loadClass(group, Constructor)

--Hologram class declaration
local hologram = initClass()

local function Constructor(self, options)
    local instance = self:newInstance()

    instance.label = {displayText = "", coords = {x=0,y=0,z=0}}
    if type(options.label) == "string" then
        instance.label.displayText = options.label
    elseif type(options.label) == "table" then
        instance.label = options.label
    end
    instance.path = options.path or ""
    instance.saveTo = options.saveTo
    instance.port = options.port or 65530
    instance.animations = options.animations or {}

    local hologram = options.path and loadJson(options.path) or {properties = {label = {displayTeyt = "",position = {x = 0,y = 0,z = 0,},}},cubes = {},groups = {},}--Default hologram
    for k,v in pairs(hologram) do
        instance[k] = v
    end

    local ok, err = pcall(modem.open, instance.port)
    if not ok then print("Error occured in hologram's port: "..err) end
    return instance
end

function hologram:loadFile(path)
    self.path = path
    self.hologram = loadJson(self.path)
end

function hologram:save(path)
    path = path or self.saveTo
    assert(path, "I am telling you rn this path is not real!(It is a nil value)")
    local f = fs.open(path, "w")
    f.write(textutils.serialiseJSON(self.hologram))
    f:close()
end

function hologram:getLabel()
    return self.label
end

function hologram:setLabel(label)
    assert(label.displayText, "Set a valid display text. Format: label = {displayText = \"\", coords = {x=0,y=0,z=0}}")
    assert(label.coords and type(label.coords) == "table" and type(label.coords.x) == "number" and type(label.coords.y) == "number" and type(label.coords.z) == "number", "Set a valid coords. Format: label = {Set valid coords. Format: label = {displayText = \"\", coords = {x=0,y=0,z=0}}")
    local old = self:getLabel()
    self.label = label
    return old 
end

function hologram:setLabelText(label)
    local old = self:getLabel().displayText
    self.label.displayText = label
    return old
end

function hologram:setLabelPos(x, y, z)
    assert(type(x) == "number", "Invalid x position type: " .. type(x))
    assert(type(y) == "number", "Invalid y position type: " .. type(y))
    assert(type(z) == "number", "Invalid z position type: " .. type(z))
    local old = self:getLabel().coords
    self.label.coords = {x=x, y=y, z=z}
    return old
end

function hologram:getSavePath()
    return self.savePath
end

function hologram:setSavePath(path)
    local old = self:getSavePath()
    self.saveTo = path or self.saveTo
    return self.saveTo
end

function hologram:getPort()
    return self.port
end

function hologram:setPort(port)
    assert(type(port) == "number", "Invalid port type: " .. type(port))
    assert(port < 0 or port > 65535, "Invalid port range: " .. port)
    local old = self.port
    self.port = port
    return old
end

function hologram:getAnimations()
    return self.animations
end

function hologram:getAnimation(name)
    return self.animations[name]
end

function hologram:addAnimation(name, animation)
    assert(self.animations[name], "Animation "..name.." already exists.")
    assert(instanceOf(animation) ~= "animation", "Invalid animation format "..instanceOf(animation) or type(animation))
    self.animations[name] = animation
end

function hologram:removeAnimation(name)
    assert(not self.animations[name], "Animation "..name.." does not exists.")
    local old = self.animations[name]
    self.animations[name] = nil
    return old
end

function hologram:getCubes()
    return self.cubes
end

function hologram:getCube(id)
    return self.cubes[id]
end

function hologram:addCube(cube)
    -- TODO: must be an instance of cube
    local id = #self.cubes + 1
    self.cubes[id] = cube
    return id
end

function hologram:setCube(id, cube)
    assert(type(id) ~= "number", "Id type must be a number. Type: "..type(id))
    assert(instanceOf(cube) ~="cube", "Cube must be an instance of cube. Instance: "..instanceOf(cube).."type cube")
    local old = self.cubes[id]
    self.cubes[id] = cube
    return old
end

function hologram:getGroup(name)
    for k, v in pairs(self.groups) do
        if v.name == name then
            return v, k
        end
    end
    return nil
end

function hologram:addGroup(group)
    -- TODO check for the group to be instance of group class
    local index = #self.groups + 1
    self.groups[index] = group
    return index
end

function hologram:removeGroup(name)
    local old,index = self:getGroup(name)
    if not index then return end
    self.groups[index] = nil
    return old
end

function hologram:cast(x, y, z, state)
    x, y, z = resolveCoords(x,y,z, {gps.locate()})
    local hologram = state~=nil and self.hologram[state] or self.hologram
    print("Casted:",self.port,self.port,textutils.serialise({Protocol="HologramPing",Coords={x = x, y = y, z = z},id=os.getComputerID()},{ compact = true, allow_repetitions = true }))
    modem.transmit(self.port,self.port,{Protocol="HologramPing",packetVer=packetv,Coords={x = x, y = y, z = z},hologram=hologram,id=os.getComputerID()})
end

function hologram:kill()
    modem.transmit(self.port, self.port, {Protocol="HologramKill",packetVer=packetv, id=os.getComputerID()})
end

api.hologram = loadClass(hologram, Constructor)

--Stream class declaration

local stream = initClass()

local function Constructor(self, options)
    local instance = self:newInstance()
    instance.properties.instanceType = "stream"

    instance.isEnabled = options.isEnabled or false
    instance.hologram = options.hologram
    instance.offset = {x = 0, y = 1, z = 0}
    return instance
end

function stream:cast(x, y, z, state)
    x, y, z = resolveCoords(x,y,z, {gps.locate()})
    local offset = self:getOffset()
    x, y, z = x + offset.x, y + offset.y, z + offset.z
    self.hologram:cast(x, y, z, state)
end

function stream:enable()
    self.isEnabled = true
    self:onEnableNest()
end

function stream:disable()
    self.isEnabled = false
    self:onDisable()
end

function stream:setHologram(hologram)
    self.hologram = hologram
end

function stream:getOffset()
    return self.offset
end

function stream:setOffset(x, y, z)
    x, y, z = resolveCoords(x,y,z, self:getOffset())
    self.offset = {x=x, y=y, z=z}
end

function stream:onEnableNest()
    parallel.waitForAny(function() self:onEnable() end,function()
        while self.isEnabled do
            local event, side, channel, replyChannel, data, distance
            repeat
                event, side, channel, replyChannel, data, distance = os.pullEvent("modem_message")
            until type(data) == "table" and type(data.id) == "number" and type(data.position) == "table" and data.Protocol == "ClientConnect"
            self:onClientConnect(data.id, data.position, distance)
        end
    end)
end

function stream:onEnable()
    while self.isEnabled do
        self:cast()
        os.sleep(5)
    end
end
stream:makeVirtual("onEnable")

function stream:onDisable()
    self.hologram:kill()
end
stream:makeVirtual("onDisable")

function stream:onClientConnect(id, pos, distance)
    self:cast()
end
stream:makeVirtual("onClientConnect")

api.stream = loadClass(stream, Constructor)

return api