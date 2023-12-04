local args = {...}
assert(type(args[1])=="string", "Invalid arguments")
local filename = args[1]
assert(filename:match(".3dj"), "Unsupported filetype")

local model
local hologram

local name = shell.resolve(filename)
assert(fs.exists(name), "Couldn't find file")
local file = fs.open(name, "r")
model = textutils.unserialiseJSON(file.readAll())
file.close()
hologram = {
    label = model.label,
    shapesOff = model.shapesOff,
    shapesOn = model.shapesOn,
}

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

local f = fs.open(filename:gsub(".3dj","",1)..".holo","w")
f.write(textutils.serialise(hologram))
f.close()