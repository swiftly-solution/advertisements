local modes = {
    chat = MessageType.Chat,
    center = MessageType.Center,
    console = MessageType.Console,
    notify = MessageType.Notify
}

local QueuedAdvertisements = {
    chat = {},
    center = {},
    console = {},
    notify = {},
}

local LastExecution = {
    chat = GetTime(),
    center = GetTime(),
    console = GetTime(),
    notify = GetTime(),
}

function LoadAdvertisements()
    local advertisementMessages = config:Fetch("advertisements.advertisements")

    for i=1,#advertisementMessages do
        if not modes[advertisementMessages[i].mode] then
            logger:Write(LogType_t.Error, string.format("Couldn't load advertisement #%d because the type needs to be \"chat\", \"center\", \"console\" or \"notify\". Current: \"%s\"", i, advertisementMessages[i].mode))
            goto loopContinue
        end

        if (tonumber(advertisementMessages[i].time_between or 0) or 0) < 1000 then
            logger:Write(LogType_t.Error, string.format("Couldn't load advertisement #%d because the interval between messages needs to be greater or equal than 1000ms.", i))
            goto loopContinue
        end

        if type(advertisementMessages[i].messages) ~= "table" or #advertisementMessages[i].messages == 0 then
            logger:Write(LogType_t.Error, string.format("Couldn't load advertisement #%d because the message is not present in configuration file.", i))
            goto loopContinue
        end

        table.insert(QueuedAdvertisements[advertisementMessages[i].mode], { time_between = tonumber(advertisementMessages[i].time_between), messages = advertisementMessages[i].messages })
        ::loopContinue::
    end

    SetTimer(1000, function ()
        ProcessMessages("center")
        ProcessMessages("chat")
        ProcessMessages("console")
        ProcessMessages("notify")
    end)
end

function ProcessMessages(category)
    local currentMessage = QueuedAdvertisements[category][1]
    if currentMessage and GetTime() - LastExecution[category] >= currentMessage.time_between then
        local message = { currentMessage.messages[1] }
        if category == "chat" then
            message = currentMessage.messages
        end

        for i=1,#message do
            playermanager:SendMsg(modes[category], (modes[category] == MessageType.Chat and (config:Fetch("advertisements.prefix") .. " ") or ("")) .. message[i]:gsub("{players}", playermanager:GetPlayerCount()):gsub("{maxplayers}", server:GetMaxPlayers()):gsub("{map}", server:GetMap()))
        end

        LastExecution[category] = GetTime()
        table.remove(QueuedAdvertisements[category], 1)
        table.insert(QueuedAdvertisements[category], currentMessage)
    end
end