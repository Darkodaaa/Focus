local api = require("holoapi")

local hologram = api.hologram({
    path = "Test.json",
    label = "Test",
    saveTo = "Test.json",
})

local stream = api.stream({hologram=hologram})

function stream:onEnable()
    self:cast()
    while self.isEnabled do
        os.sleep(1)
    end
end

parallel.waitForAny(function() stream:enable() end, function()
    os.sleep(60)
    stream:disable()
end)