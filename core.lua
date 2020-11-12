local addonName, ns = ...
local C, F, L = unpack(ns)
if not F:IsLoaded() then return end

local function UpdateMulti()
    local _, height = GetPhysicalScreenSize()
    local fixedHeight = 768 / height
    local scale = UIParent:GetScale()
    return fixedHeight / scale
end

function F:CreateText(font, fontSize, justifyh)
    if self.Text then return end
    self.Text = self:CreateFontString(nil, "OVERLAY")
    self.Text:SetFont(font, fontSize, "OUTLINE")
    if not justifyh then justifyh = "CENTER" end
    self.Text:SetJustifyH(justifyh)
    -- Debug("CreateButton", "CreateText", "SetPoint", self:GetWidth() / 100, self:GetHeight() / 100, justifyh)
    self.Text:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT",
                       -self:GetWidth() / 100, self:GetHeight() / 100)
    -- Debug("CreateButton", "CreateText")
end

function F:CreateIcon(multi)
    if self.Icon then return end
    if not multi then multi = UpdateMulti() end
    self.Icon = self:CreateTexture(nil, "ARTWORK")

    self.Icon:SetPoint("TOPLEFT", multi, -multi)
    self.Icon:SetPoint("BOTTOMRIGHT", -multi, multi)

    self.Icon:SetTexCoord(.08, .92, .08, .92)

end

function F:CreateCooldown()
    if self.CD then return end
    self.CD = CreateFrame("Cooldown", nil, self, "CooldownFrameTemplate")
    self.CD:SetAllPoints()
    self.CD:SetReverse(true)
end

function F:GetActiveSpellName(spell, deep)
    if not spell then return "" end
    if deep == nil then deep = true end
    if tonumber(spell) then spell = GetSpellInfo(tonumber(spell)) end
    local lastspell = spell
    if deep then
        spell = GetSpellInfo(spell)
        if not spell then spell = lastspell end
    end
    return spell
end

function F:GetActiveSpellTexture(spell)
    return GetSpellTexture(F:GetActiveSpellName(spell))
end

local actionButtonPool = {}
function F:GetActionButtonFrame(name, parent) 
    if actionButtonPool[name] then
        actionButtonPool[name]:ClearAllPoints()
        actionButtonPool[name]:SetParent(parent)
        return actionButtonPool[name]
    end
    local button = CreateFrame("Button", name, parent, "SecureActionButtonTemplate")
    button:RegisterForClicks("AnyUp")
    button:SetHighlightTexture([[Interface\Buttons\ButtonHilight-Square]],"ADD")
    button:SetPushedTexture([[Interface\Buttons\UI-Quickslot-Depress]])
    
    actionButtonPool[name] = button
    return button
end
function F:TotemButtonAcquire(frame,slot)
    local totem = F:GetActionButtonFrame(addonName.."Totem"..slot,frame)
    totem.slot = slot
    local macrotext = "/click TotemFrameTotem" .. totem.slot .. " RightButton"
    if frame.isPet then
        macrotext = "/petdismiss"
    end
    totem:SetAttribute("type2","macro")
    totem:SetAttribute("macrotext2",macrotext)

    totem:ClearAllPoints()
    totem:SetAllPoints()
    totem:Show()

    return totem
end

function F:ActionButtonAcquire(index,parent,spell,isPet)
    isPet = not not isPet
    local frame = F:GetActionButtonFrame(addonName.."ActionButton"..index,parent)
    frame.isPet = isPet
    frame:SetAttribute("type1","spell")
    frame:SetAttribute("spell1",spell)
    local size = C.config.iconSize
    frame:SetSize(size,size)


    if isPet then
        local totem = F:TotemButtonAcquire(frame,index)
        totem:SetSize(size,size)
        totem:Hide()
        frame.totem = totem
    end

    return frame
end
function F:ActionButtonRelease(frame)
    frame:Hide()
    frame:ClearAllPoints()
end
function F:ActionButtonRelaseAll()
    for k,v in pairs(actionButtonPool) do 
        F:ActionButtonRelease(v)
    end
end

function F.GetSpellCooldown(spell)
    local start, dur, enable = GetSpellCooldown(spell)
    local charges, maxCharges, startCharges, durCharges = GetSpellCharges(spell);

    local stack = charges or GetSpellCount(spell)

    
    local gcd = math.max((1.5 / (1 + (UnitSpellHaste("player") / 100))), 0.75)

    start = start or 0
    dur = dur or 0

    startCharges = startCharges or 0
    durCharges = durCharges or 0

    if enable == 0 then start, dur = 0, 0 end

    local startTime, duration = start, dur

    if charges == maxCharges then
        start, dur = 0, 0
        startCharges, durCharges = 0, 0
    elseif charges > 0 then
        startTime, duration = startCharges, durCharges
    end

    if gcd == duration then startTime, duration = 0, 0 end

    return stack, maxCharges, startTime, duration
end

function F:UpdateCooldown(frame)
    if not frame then return end 
    if not frame.spell then return end
    local stack,maxStack,start,duration = F.GetSpellCooldown(frame.spell)
    if frame.Text then
        if stack and stack > 0 then
            if maxStack > 1 then
                frame.Text:SetText(stack)
            else
                frame.Text:SetText("")
            end
        else
            frame.Text:SetText("")
        end
    end
    if frame.CD then
        local gcdstart, gcdduration = GetSpellCooldown(61304)
        if gcdstart>0 and gcdduration>0 then
        else
            frame.CD:SetCooldown(start,duration)
        end
    end
    return true
end


