local client = game:GetService('Players').LocalPlayer;
if (PROTOSMASHER_LOADED) then
    return client:Kick('\nThis script crashes on ProtoSmasher, sorry! Kicked to prevent bans / issues.')
end

local scriptContext = game:GetService('ScriptContext')
local userInputService = game:GetService('UserInputService');
local runService = game:GetService('RunService');
local replicatedStorage = game:GetService('ReplicatedStorage')

local events = replicatedStorage:WaitForChild('Remotes', 10)
local killEvent = (events and events:WaitForChild('StudEvent', 10))
local chatEvents = replicatedStorage:WaitForChild('DefaultChatSystemChatEvents', 10)
local sendMessage = (chatEvents and chatEvents:WaitForChild('SayMessageRequest', 10))

local spawnLocation = workspace:WaitForChild('Structure'):WaitForChild('SpawnLocation')
local SPAWN_DISTANCE = 31

if (not killEvent) then
    return client:Kick('\nFailed to find "StudEvent".')
elseif (not sendMessage) then
    return client:Kick('\nFailed to find "SayMessageRequest".')
end

if (not firetouchinterest) then
    return client:Kick('\nExploit requires "firetouchinterest".')
elseif (not getconnections) then
    return client:Kick('\nExploit requires "getconnections".')
end

pcall(function()
    -- better hope this works
    for i, v in next, getconnections(scriptContext.Error) do
        v:Disable()
    end
end)

local function safeLoadstring(name, url)
    local success, content = pcall(game.HttpGet, game, url)
    if (not success) then
        client:Kick(string.format('Failed to load library (%s). HttpError: %s', name, content))
        return function() wait(9e9) end
    end

    local func, err = loadstring(content)
    if (not func) then
        client:Kick(string.format('Failed to load library (%s). SyntaxError: %s', name, err))
        return function() wait(9e9) end
    end

    return func
end

local maid = safeLoadstring('Maid', 'https://raw.githubusercontent.com/Quenty/NevermoreEngine/a8a2d2c1ffcf6288ec8d66f65cea593061ba2cf0/Modules/Shared/Events/Maid.lua')()
local library = safeLoadstring('UI', 'https://raw.githubusercontent.com/wally-rblx/uwuware-ui/main/main.lua')()

local mainMaid = maid.new()

local messages = {
    'ez', 
    'L', 
    'owned', 
    "you're bad", 
    "1'd",
    "You just got owned by a person using a swag script",
    "I'm a god tier player, why are you saying I'm hacking?",
    "Get destroyed by {c}",
    "Why are you so bad at the game?",
    "Ez, ez, ez, ez, ez, ez, ez, ez!",
    "{v} get good",
    "{v} you have no skillz",
    "ur dog water kid",
    "git good bud",
    "imagine not having a good gaming chair!",
    "swaghook winning!",
    "samuel on top!",
    "jack is dumb"
}

local randomObj = Random.new()
local target = nil;

local function initLogic(character)
    mainMaid:DoCleaning()

    local humanoid = character:WaitForChild('Humanoid', 10)
    local root = character:WaitForChild('HumanoidRootPart', 10)

    if (not root) or (not humanoid) then
        return
    end

    local eventSpoof = {
        [root] = {'Velocity', 'CFrame'},
        [humanoid] = {'HipHeight', 'WalkSpeed', 'JumpPower'}
    }


    for obj, list in next, eventSpoof do
        for i, property in next, list do
            local event = obj:GetPropertyChangedSignal(property);
            for i, signal in next, getconnections(event) do
                signal:Disable()
            end
        end
    end 

    local function findCurrentTool()
        local tool = character:FindFirstChildWhichIsA('Tool')
        if tool then return tool end
        return client.Backpack:FindFirstChildWhichIsA('Tool')
    end

    local sword = findCurrentTool()

    local handle = (sword and sword:FindFirstChild('Handle'))
    if (not sword) or (not handle) then
        return
    end

    -- not sure how efficient it is to make seperate threads, 
    -- but i dont want to run all of the logic in the same thread
    -- for the sole reason of making everything able to run on its own 
    
    mainMaid:GiveTask(runService.Heartbeat:connect(function()
        if library.flags.attachToTarget then
            if target then
                local pRoot = target:FindFirstChild('HumanoidRootPart')
                local pHumanoid = target:FindFirstChildWhichIsA('Humanoid')
                local player = game:GetService('Players'):GetPlayerFromCharacter(target)
            
                if (not player) then -- that ape left smh
                    target = nil;
                    return
                end

                if (not pHumanoid) or (pHumanoid.Health <= 0) then
                    target = nil;
                    return
                end

                if (not pRoot) then
                    target = nil;
                    return
                end

                local isNearSpawn = math.floor((spawnLocation.Position - pRoot.Position).magnitude) <= SPAWN_DISTANCE
                if (isNearSpawn) then
                    target = nil;
                    return
                end

                local position = (pRoot.CFrame * CFrame.new(0, 0, 5).p)
                local newCframe = CFrame.new(position, pRoot.Position)

                root.CFrame = newCframe
            end
        end
    end))

    mainMaid:GiveTask(runService.Heartbeat:connect(function()
        if (library.flags.autoAttack) then
            -- ugly hack
            if (not sword:IsDescendantOf(character)) then -- if not equipped
                if sword:IsDescendantOf(game) then -- is it still in the game (e.g. if you unequipped it)
                    humanoid:EquipTool(sword)
                else -- sorry it aint in da world bro
                    sword = findCurrentTool() -- ok we find new tool
                    handle = (sword and sword:WaitForChild('Handle')) -- plz work
                end
            end

            if (not sword) then return end -- idk how there wouldnt be a tool but ok gg

            sword:Activate()
            for i, player in next, game:GetService('Players'):GetPlayers() do
                if player == client then continue end

                local pCharacter = player.Character;
                local pRoot = (pCharacter and pCharacter:FindFirstChild('HumanoidRootPart'))
                local pHuman = (pCharacter and pCharacter:FindFirstChildWhichIsA('Humanoid'))

                if (not pRoot) then continue end
                if (not pHuman) or (pHuman.Health < 0) then continue end

                local distance = (client:DistanceFromCharacter(pRoot.Position))
                local isNearSpawn = math.floor((spawnLocation.Position - pRoot.Position).magnitude) <= SPAWN_DISTANCE

                if (isNearSpawn) then continue end

                if distance <= 15 then
                    if (not target) then target = pCharacter end

                    firetouchinterest(handle, pRoot, 0) 
                    firetouchinterest(handle, pRoot, 1)
                end
            end
        end
    end))

    mainMaid:GiveTask(runService.Heartbeat:connect(function()
        if library.flags.speedHack and library._speedHackHeld then
            root.CFrame = root.CFrame + (root.CFrame.lookVector * (library.flags.speedFactor or 0.15))
        end
    end))

    mainMaid:GiveTask(function()
        target = nil; -- remove target after next maid cleanup
    end)
    
    -- i know I could put this outside of the loop, but i guess it looks better with all of the other signals
    mainMaid:GiveTask(killEvent.OnClientEvent:connect(function(victim, killer)
        if typeof(victim) == 'Instance' and typeof(killer) == 'Instance' then
            if victim:IsA('Player') and killer:IsA('Player') and killer == client then
                if library.flags.killSay then
                    local msg = messages[randomObj:NextInteger(1, #messages)]
                    msg = msg:gsub("{c}", client.Name);
                    msg = msg:gsub("{v}", victim.Name);
                    game.ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(msg, 'All')
                end
            end
        end
    end))
end

local character = client.Character
if (character) then
    coroutine.wrap(initLogic)(character)
end
client.CharacterAdded:connect(initLogic)

local window = library:CreateWindow('SA&FYT') do
    local folder = window:AddFolder('Main') do
        folder:AddToggle({text = 'Auto attack', flag = 'autoAttack'})
        folder:AddToggle({text = 'Kill say', flag = 'killSay'})
        folder:AddToggle({text = 'Attach to back', flag = 'attachToTarget', callback = function(value)
            if (not value) then
                target = nil;
            end
        end})
        
        folder:AddToggle({text = 'Speed boost', flag = 'speedHack'})
        folder:AddSlider({text = 'Speed factor', flag = 'speedFactor', min = 0.1, max = 0.2, float = 0.01})
        folder:AddBind({text = 'Speed bind', flag = 'speedBind', hold = true, callback = function(value)
            library._speedHackHeld = (not value)
        end})
    end
    window:AddBind({text = 'UI Keybind', key = Enum.KeyCode.RightControl, callback = function()
        library:Close()
    end})
    window:AddLabel({text = 'Made by wally / BigTimbob'})
end

library:Init()
