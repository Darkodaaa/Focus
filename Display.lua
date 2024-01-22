local api = require("API")
local context = api.createContext()
context:loadFile("model.holo")
local stream = context:stream("model.holo")
parallel.waitForAll(
function()
    stream:start()
end,
function()
    local signal = false
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
end)