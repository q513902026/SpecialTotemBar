local addonName, ns = ...
local C, F, L = unpack(ns)
if not F:IsLoaded() then return end

local CreateFrame,InCombatLockdown = CreateFrame,InCombatLockdown


local function init(self)
    local f = self.mover
    if not f then
        local f = CreateFrame("Frame",addonName.."MainFrameMover",self)
        f:SetMovable(true)
        self:SetMovable(true)
        self:SetUserPlaced(true)
        self:SetClampedToScreen(true)

        f:SetAllPoints()
        f:EnableMouse(true)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", function(_) self:StartMoving() end)
        f:SetScript("OnDragStop", function(_)
            self:StopMovingOrSizing()
            local orig, _, tar, x, y = self:GetPoint()
            C:VARSET("pos",{orig,"UIParent",tar,x,y})
        end)
        f:SetFrameStrata("DIALOG")
        f:Hide()
        
        local texture = f:CreateTexture('ARTWORK')
        texture:SetColorTexture(1, 1, 1)
        texture:SetAlpha(0.5)
        texture:SetAllPoints()
        
        self.mover = f
    end
    mover = self.mover

    F.registerCMD("SPECIALTOTEMBARMOVER",{"specialtotembar","stb"},function()
        if InCombatLockdown() then
            UIErrorsFrame:AddMessage("请在战斗外调整位置")
            return
        end
        if mover:IsShown() then
            F:FireCallback(mover,"CUSTOM_MOVER_HIDE")
        else
            F:FireCallback(mover,"CUSTOM_MOVER_SHOW")
        end
        return true
    end)


end

F:RegisterCallback("CUSTOM_MOVER_SHOW",function(self)
    self:Show()
    self:EnableMouse(true)
end)
F:RegisterCallback("CUSTOM_MOVER_Hide",function(self)
    self:Hide()
    self:EnableMouse(false)
end)
F:RegisterCallback("CUSTOM_MAINFRAME_CREATE",init)

F:RegisterCallback("CUSTOM_MAINFRAME_SIZE_UPDATE",function(self,_,width,height)
    self.mover:SetSize(width,height)
end)

