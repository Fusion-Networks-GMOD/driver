ARGON = ARGON or {}
ARGON.Driver = ARGON.Driver or {}

function ARGON.Driver:LoadServer(...)
    if not SERVER then return end

    local ar = {...}

    print(" Driver -> Loading " .. ar[1] .. " as a serversided file")

    if string.match(ar[1], ".lua") then
        include(ar[1])
    else
        include(ar[1] .. ".lua")
    end
end

function ARGON.Driver:LoadShared(...)
    local ar = {...}

    print(" Driver -> Loading " .. ar[1] .. " as a shared file")

    if string.match(ar[1], ".lua") then
        include(ar[1])
        AddCSLuaFile(ar[1])
    else
        AddCSLuaFile(ar[1] .. ".lua")
        include(ar[1] .. ".lua")
    end
end

function ARGON.Driver:LoadClient(...)
    local ar = {...}

    print(" Driver -> Loading " .. ar[1] .. " as a clientsided file")

    if string.match(ar[1], ".lua") then
        if SERVER then
            AddCSLuaFile(ar[1])
        elseif CLIENT then
            include(ar[1])
        end
    else
        if SERVER then
            AddCSLuaFile(ar[1] .. ".lua")
        elseif CLIENT then
            include(ar[1] .. ".lua")
        end
    end
end

ARGON.Driver:LoadServer("mysqloo/sv_mysqloocore")
