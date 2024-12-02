local radioOpen = nil
local enabled = true 
local prop = `prop_cs_hand_radio`
local object = nil
local bone = 28422
local usingHandheld = false
local freeaim = false

if GetResourceKvpInt("POLICE_HANDHELD") == 0 then
    SetResourceKvpInt("POLICE_HANDHELD", 2)
end

RegisterCommand("tpolicehh", function()
    if (GetResourceKvpInt("POLICE_HANDHELD") or 1) == 1 then
        SetResourceKvpInt("POLICE_HANDHELD", 2)
    else
        SetResourceKvpInt("POLICE_HANDHELD", 1)
    end
end)

RegisterCommand("tpoliceradio", function()
    enabled = not enabled
    if not enabled then
        TriggerEvent("chat:addMessage", { args = { "Police Radio", "You have disabled the police radio animation." } })
    else
        TriggerEvent("chat:addMessage", { args = { "Police Radio", "You have enabled the police radio animation." } })
    end
end)

function CanUseRadio()
    if not enabled then return false end

    local p = PlayerPedId()
    local falling = IsPedFalling(p)
    local dead = IsPedDead(p)

    if not dead and not falling then 
        return true 
    end

    return false
end

local unarmed = `WEAPON_UNARMED`
function ShouldUseHandheld()
    if GetResourceKvpInt("POLICE_HANDHELD") == 1 then return false end

    local p = PlayerPedId()
    local has, weapon = GetCurrentPedWeapon(p, true)
    local running = IsPedSprinting(p)

    return weapon == unarmed and not running
end

RegisterCommand("+policeradio", function()
    if not enabled then return end
    if radioOpen == true then return end
    local p = PlayerPedId()

    radioOpen = true

    if DoesEntityExist(object) then
        DetachEntity(object, true, false)
        DeleteEntity(object)

        return
    end

    if ShouldUseHandheld() then
        usingHandheld = true
        local dict = nil
        if IsPedInAnyVehicle(p) then
            dict = "cellphone@in_car@ds"
        else
            dict = "cellphone@"
        end
    
        local anim = "cellphone_call_in" -- FIXME probably
    
        RequestAnimDict(dict)
        while not HasAnimDictLoaded(dict) do
            Citizen.Wait(100)
        end
    
        TaskPlayAnim(p, dict, anim, 4.0, -1, -1, 50, 0, false, false)
        Citizen.Wait(GetAnimDuration(dict, anim))
        StopAnimTask(p, dict, anim, 1.0) -- TODO: Probably dont need this
    
        RequestModel(prop)
    
        while not HasModelLoaded(prop) do
            Citizen.Wait(100)
        end
    
        object = CreateObject(prop, 0.0, 0.0, 0.0, true, true, false)
    
        local bone = GetPedBoneIndex(p, bone)
        AttachEntityToEntity(object, p, bone, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, false, false, false, 2, true)

        SetModelAsNoLongerNeeded(prop)

        TaskPlayAnim(p, dict, anim, 4.0, -1, -1, 50, 0, false, false, false)
    else
        local haswep, weapon = GetCurrentPedWeapon(p, false)
        local aim = IsPlayerFreeAiming(PlayerId())
        local dict = "random@arrests"
        local anim = nil

        if aim and weapon ~= unarmed then
            anim = "radio_chatter"
            freeaim = true
        else
            anim = "generic_radio_chatter"
        end

        RequestAnimDict(dict)
        while not HasAnimDictLoaded(dict) do
            Citizen.Wait(100)
        end
        
        TaskPlayAnim(p, dict, anim, 4.0, -1, -1, 50, 0, false, false)
    end

    SetPlayerTalkingOverride(PlayerId(), false)
end)

RegisterCommand("-policeradio", function()
    if not enabled then return end
    if radioOpen == false then return end
    local p = PlayerPedId()

    radioOpen = false

    if usingHandheld then
        if IsEntityDead(PlayerPedId()) and DoesEntityExist(object) then
            DetachEntity(object, true, false)
            DeleteEntity(object)

            return
        end

        local dict = nil
        if IsPedInAnyVehicle(p) then
            dict = "cellphone@in_car@ds"
        else
            dict = "cellphone@"
        end

        local anim = "cellphone_text_out" -- FIXME probably

        RequestAnimDict(dict)
        while not HasAnimDictLoaded(dict) do
            Citizen.Wait(100)
        end

        TaskPlayAnim(p, dict, anim, 4.0, -1, -1, 50, 0, false, false, false)
        -- Citizen.Wait(GetAnimDuration(dict, anim))
        Citizen.Wait(700)
        StopAnimTask(p, dict, anim, 1.0) -- TODO: Probably dont need this

        local count = 0
        NetworkRequestControlOfEntity(object)
        while not NetworkHasControlOfEntity(object) and count < 5000 do
            Citizen.Wait(0)
            count = count + 1
        end

        DetachEntity(object, true, false)
        DeleteEntity(object)

        usingHandheld = false
    else
        local haswep, weapon = GetCurrentPedWeapon(p, false)
        local aim = IsPlayerFreeAiming(PlayerId())
        local dict = "random@arrests"
        local anim = nil

        if aim and weapon ~= unarmed then
            anim = "radio_exit"
            freeaim = false
        else
            anim = "generic_radio_exit"
        end

        RequestAnimDict(dict)
        while not HasAnimDictLoaded(dict) do
            Citizen.Wait(100)
        end
        
        TaskPlayAnim(p, dict, anim, 4.0, -1, -1, 50, 0, false, false)
        Citizen.Wait(GetAnimDuration(dict, anim))
        StopAnimTask(p, dict, anim, 1.0)
        DisableControlAction(0, 25, false)
    end

    if not IsControlPressed(1, 249) then
        SetPlayerTalkingOverride(PlayerId(), false)
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if radioOpen and not usingHandheld and freeaim then
            DisableControlAction(0, 25, true)
        end
    end
end)

RegisterKeyMapping('+policeradio', '(Voice) TeamSpeak Push To Talk', 'mouse_button', 'f10')