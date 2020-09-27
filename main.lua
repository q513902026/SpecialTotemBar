local addon, ns = ...
local C, F, L = unpack(ns)
if not F:IsLoaded() then return end

local CreateFrame,GetTotemInfo,UnitExists,InCombatLockdown = CreateFrame,GetTotemInfo,UnitExists,InCombatLockdown
local MAX_TOTEMS = MAX_TOTEMS 

local HiddenFrame = CreateFrame("Frame")
HiddenFrame:Hide()
local mainFrame = CreateFrame("Frame",nil,UIParent)
local function CreateButton(index)
    local spell = F:GetActiveSpellName(C:GetWatchSpell(index))
    local frame = F:ActionButtonAcquire(index,mainFrame,spell,C:IsPet(index))
    frame.spell = spell
    F.CreateCooldown(frame)
    F.CreateIcon(frame)
    F.CreateText(frame,C.config.font,C.config.fontSize,"RIGHT")
    
    F:UpdateCooldown(frame)

    frame.Icon:SetTexture(F:GetActiveSpellTexture(spell))
    frame:SetAlpha(C.config.CDAlpha)
    return frame
end

local frames = {}
ns.frames = frames
local function CreateButtons()
    for i=1 , #frames do 
        F:ActionButtonRelease(frames[i])
        frames[i] = nil
    end
    
    local watchSpell = C:GetWatchSpells()
    for i = 1, #watchSpell do 
        local frame = CreateButton(i)
        F:TotemButtonAcquire(HiddenFrame,i)
        if frame then
            if i == 1 then
                frame:SetPoint("LEFT",mainFrame)
            else
                frame:SetPoint("LEFT",frames[i-1],"RIGHT",C.config.speacing,0)
            end
            frame:Show()
            frames[i] = frame
        end
    end
end
local state = {}
local function CreateTotem(frame,slot)
    return F:TotemButtonAcquire(frame,slot)
end

local function UpdateTotemTable()
    local s = state
    for i =1,MAX_TOTEMS do 
        local haveToten,name,start,duration,icon = GetTotemInfo(i)
        local frameTotem = _G["TotemFrameTotem" .. i]
        if not s[i] then
            s[i] = {index = i, slot = frameTotem.slot, show = haveToten, name = name, lastname = "", start = start, dur = duration, icon = icon, btnFunc = CreateTotem}
        else
            s[i].show = haveToten
            s[i].lastname = s[i].name ~= "" and s[i].name or s[i].lastname
            s[i].slot = frameTotem.slot
            s[i].name = name
            s[i].start = start
            s[i].dur = duration
            s[i].icon = icon
        end

    end
end

local function UpdateTotem(_,_,slot)
    UpdateTotemTable()
    for k,v in pairs(state) do 
        if v.lastname ~= "" or v.name ~= "" then 
            for i,frame in pairs(frames) do 
                if frame.isPet == false then 
                    if v.dur > 0 then 
                        if v.name ~= "" and (v.name:find(frame.spell) or frame.spell:find(v.name)) then 
                            local totem = v.btnFunc(frame,v.slot)
                            frame.totem = totem
                            F:FireCallback(frame,"CUSTOM_SPELL_DURATION_START",v.start,v.dur)
                            break
                        end
                    else
                        if frame.totem and v.lastname ~="" and (v.lastname:find(frame.spell) or frame.spell:find(v.lastname)) then
                            frame.totem:Hide()
                            frame.totem = nil
                            F:FireCallback(frame,"CUSTOM_SPELL_DURATION_END")
                            frame:SetAlpha(C.config.CDAlpha)
                            if C.config.showSpellCD then
                                frame.CD:SetCooldown(0,0)
                                frame.aura = false
                                F:UpdateCooldown(frame)
                            else
                                frame.CD:Hide()
                            end

                        end

                    end

                end
            end

        end
    end

end
local function UpdatePet(self,event,unit)
    local start = GetTime()
    if unit == "player" then
        if UnitExists("pet") then
            local name = UnitName("pet")
            if not name then return end
            for i,frame in pairs(frames) do
                if frame.isPet then
                    if frame.spell ~= "" and name ~="" and (frame.spell:find(name) or name:find(frame.spell)) then
                        local startTime,duration = frame.CD:GetCooldownTimes()
                        startTime = (startTime or 0) / 1000
                        duration = (duration or 0) / 1000
                        
                        if frame.aura then
                            frame.totem:Show()
                            C_Timer.After(0.1,function()
                                F:FireCallback(frame,"CUSTOM_SPELL_DURATION_END")
                            end)
                        end
                        if duration == 0 and startTime == 0 then
                            local dur = C:GetPetDuration(frame.spell) or 0
                            if dur > 0 then
                                F:FireCallback(frame,"CUSTOM_SPELL_DURATION_START",start,dur)
                            end
                        end
                    end
                end
            end
        end
    end
end
local function UpdateCooldown()
    for i,v in pairs(frames) do 
        if not InCombatLockdown() then
            if v.aura and v.totem then
                v.totem:Show()
            end
        end
        if v.aura == false then
            F:UpdateCooldown(v)
        end

    end

end
F:RegisterCallback("CUSTOM_SPELL_DURATION_START",function(self,event,start,dur)
    self.Text:SetText("")
    self.CD:SetCooldown(start,dur)
    self.aura = true
    self.CD:Show()
    self:SetAlpha(C.config.AuraAlpha)
end)
F:RegisterCallback("CUSTOM_SPELL_DURATION_END",function(self,event)
    self:SetAlpha(C.config.CDAlpha)
        self.CD:SetCooldown(0,0)
        self.aura = false
        F:UpdateCooldown(self)
        if self.totem then self.totem:Hide() end
        if not  C.config.showSpellCD then
            self.CD:Hide()
        end

end)
local function UpdateMainFramePos(self)
    self:ClearAllPoints()
    local pos = C:VARGET("pos")
    self:SetPoint(unpack(pos))
end


local function init(self)
    self.mainFrame = mainFrame

    C:UpdateTalent()
    CreateButtons()

    mainFrame:SetSize(C.config.iconSize * 4 + C.config.spacing * 4,C.config.iconSize)
    F:FireCallback(mainFrame,"CUSTOM_MAINFRAME_CREATE")
    
    UpdateMainFramePos(mainFrame)

    F:RegisterCallback("PLAYER_TOTEM_UPDATE",UpdateTotem)
    F:RegisterCallback("UNIT_PET",UpdatePet)
    F:RegisterCallback("PLAYER_TALENT_UPDATE",function() 
        C:UpdateTalent()
        CreateButtons()
    end)

    F:RegisterCallback("CUSTOM_COOLDOWN_UPDATE",UpdateCooldown)
    mainFrame:SetScript("OnUpdate",function(self,elapsed)
        self.elapsed = (self.elapsed or 0) + elapsed
        if self.elapsed > .5 then
            F:FireCallback(self,"CUSTOM_COOLDOWN_UPDATE")
            self.elapsed = 0
        end
    end)
end

F:RegisterCallback("CUSTOM_ADDON_LOAD",init)
F:RegisterCallback("CUSTOM_ADDON_POSTLOAD",function(self,event)
    C:UpdateTalent()
    for i =1 , MAX_TOTEMS do 
        UpdateTotem(self,event,i)
    end
    UpdateMainFramePos(mainFrame)

end)