local addonName, ns = ...
_G[addonName] = ns

ns[1] = {} -- Config
ns[2] = {} -- Function
ns[3] = {} -- Locales
local C, F, L = unpack(ns)
setmetatable(L, {__index = function(_, k) return k end})

local loaded =  false

function F:IsLoaded()
    return loaded
end

function F:RemoveArrayValue(tbl,value)
    for i = #tbl,1,-1 do 
        if tbl[i] == value then
            tremove(tbl,i)
        end
    end
end

local eventHandler = CreateFrame("Frame")

eventHandler:SetScript("OnEvent",function(self,event,...)
    F:FireCallback(self,event,...)
end)


local CUSTOM_CALLBACK_PREFIX = "CUSTOM"
function F:RegisterCallback(event,callback)
    event = event:upper()
    if not eventHandler[event] then
        eventHandler[event] = {}
        -- CUSTOM_CALLBACK_PREFIX
        if not (event:sub(1,strlen(CUSTOM_CALLBACK_PREFIX)) == CUSTOM_CALLBACK_PREFIX) then
            eventHandler:RegisterEvent(event)
        end
    end
    tinsert(eventHandler[event],callback)
end

function F:FireCallback(t,event,...)
    event = event:upper()
    if eventHandler[event] then
        for _,callback in ipairs(eventHandler[event]) do callback(t,event,...) end
    end
end

function F:UnregisterCallback(event,callback)
    event = event:upper()
    if eventHandler[event] then
        F:RemoveArrayValue(eventHandler[event],callback)
    end
end

F:RegisterCallback("ADDON_LOADED",function(self,_,addon)
    if addon == addonName then
        F:FireCallback(ns,"CUSTOM_ADDON_PRELOAD")
    end
end)
F:RegisterCallback("PLAYER_LOGIN",function()
    F:FireCallback(ns,"CUSTOM_ADDON_LOAD")
end)
F:RegisterCallback("PLAYER_ENTERING_WORLD",function(self,_,isInitialLogin, isReloadingUi)
    if isInitialLogin or isReloadingUi then
        F:FireCallback(ns,"CUSTOM_ADDON_POSTLOAD")
    end
end)

local _, class = UnitClass("player")
loaded = (class == "SHAMAN")