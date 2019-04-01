local addonName, ns = ...
local function checkClass()
    local _, class = UnitClass("player")
    return class and (class == "SHAMAN" or false)
end
if not checkClass() then checkClass = nil return end
_G[addonName] = ns

SpecialTotemBarConfig = {}

local defaultConfig = {"CENTER", "UIParent", "CENTER", 0, -230}


ns.Buttons = {}
ns.db = {}
ns.Mult = 1


ns.config = {
        --FONT
        font = STANDARD_TEXT_FONT, -- 字体
        fontSize = 12, --字体大小
        --icon
        iconSize = 32, -- 图标大小
        spacing = 5, --图标间隔
        --icon alpha
        CDAlpha = .6, -- CD时的图标透明度
        AuraAlpha = 1, -- 进行时的图标透明度
        --misc
        showSpellCD = true, -- 显示技能冷却时间
        debug = false, -- 调试DEBUG
}
local spellConfig = {
    [1] = {
        [1] = 198103,
        [2] = 192058,
        [3] = 198067,
        [4] = 8143,
    },
    [2] = {
        [1] = 198103,
        [2] = 192058,
        [3] = 2484,
        [4] = 8143,
    },
    [3] = {
        [1] = 198103,
        [2] = 98008,
        [3] = 108280,
        [4] = 5394,
    },
}
local function resetSpellConfig()
    spellConfig = {
        [1] = {
            [1] = 198103,
            [2] = 192058,
            [3] = 198067,
            [4] = 8143,
        },
        [2] = {
            [1] = 198103,
            [2] = 192058,
            [3] = 2484,
            [4] = 8143,
        },
        [3] = {
            [1] = 198103,
            [2] = 98008,
            [3] = 108280,
            [4] = 5394,
        },
    }
end
local db = ns.db
local talents = {
    [1] = {--元素
        ["4:2"] = {learn = false, spell = 192249}, -- 风暴元素（代替火元素
        ["4:3"] = {learn = false, spell = 192222}, -- 岩浆图腾
        ["5:3"] = {learn = false, spell = 192077}, -- 狂风图腾
        ["6:2"] = {learn = false, spell = 117013}, -- 元素尊者（使图腾变成宠物
    },
    [2] = {-- 增强
        ["5:3"] = {learn = false, spell = 192077}, -- 狂风图腾
    },
    [3] = {--恢复
        ["3:2"] = {learn = false, spell = 51485}, --陷地图腾
        ["4:2"] = {learn = false, spell = 198838}, --大地之墙图腾
        ["4:3"] = {learn = false, spell = 207399}, --先祖护佑图腾
        ["5:3"] = {learn = false, spell = 192077}, --狂风图腾
        ["6:3"] = {learn = false, spell = 157153}, --暴雨图腾（代替治疗之泉图腾
    },
}
db.spec = GetSpecialization()
db.selectedTalent = {}
db.spellDur = {}
local function UpdateMult()
    local _, height = GetPhysicalScreenSize()
    local fixedHeight = 768 / height
    local scale = UIParent:GetScale()
    return fixedHeight / scale
end

local function checkClass()
    local _, class = UnitClass("player")
    return class and (class == "SHAMAN" or false)
end

local function initSettings(source, target)
    for i, j in pairs(source) do
        if type(j) == "table" then
            if target[i] == nil then target[i] = {} end
            for k, v in pairs(j) do
                if target[i][k] == nil then
                    target[i][k] = v
                end
            end
        else
            if target[i] == nil then target[i] = j end
        end
    end
    for i in pairs(target) do
        if source[i] == nil then target[i] = nil end
    end
end

local function Debug(...)
    if ns.config.debug then
        print(...)
    end
end

function ns:CreateText(justifyh)
    if self.Text then return end
    self.Text = self:CreateFontString(nil, "OVERLAY")
    self.Text:SetFont(ns.config.font, ns.config.fontSize, "OUTLINE")
    if not justifyh then justifyh = "CENTER" end
    self.Text:SetJustifyH(justifyh)
    Debug("CreateButton", "CreateText", "SetPoint", self:GetWidth() / 100, self:GetHeight() / 100, justifyh)
    self.Text:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -self:GetWidth() / 100, self:GetHeight() / 100)
    Debug("CreateButton", "CreateText")
end

function ns:CreateIcon()
    if self.Icon then return end
    self.Icon = self:CreateTexture(nil, "ARTWORK")
    
    Debug("CreateButton ", "CreateIcon", "CreateTexture", self.Icon)
    
    self.Icon:SetPoint("TOPLEFT", ns.Mult, -ns.Mult)
    self.Icon:SetPoint("BOTTOMRIGHT", -ns.Mult, ns.Mult)
    
    Debug("CreateButton ", "CreateIcon", "SetPoint", ns.Mult)
    
    self.Icon:SetTexCoord(.08, .92, .08, .92)
    
    Debug("CreateButton ", "CreateIcon", "SetTexCoord", self.Icon)
end

function ns:CreateCD()
    if self.CD then return end
    self.CD = CreateFrame("Cooldown", nil, self, "CooldownFrameTemplate")
    self.CD:SetAllPoints()
    self.CD:SetReverse(true)
end

local function GetActiveSpellName(spell, deep)
    if not spell then return "" end
    if deep == nil then deep = true end
    if tonumber(spell) then spell = GetSpellInfo(tonumber(spell)) end
    local lastspell = spell
    if deep then
        spell = GetSpellInfo(spell)
        if not spell then
            spell = lastspell
        end
    end
    return spell
end

function ns:GetActionSpell(index)
    local name = self.config.spellConfig[index]
    return GetActiveSpellName(name)
end

function ns:GetSpellTexture(index)
    local name = self:GetActionSpell(index)
    return GetSpellTexture(name)
end

local frames = {}
local petframes = {}
local function GetActionButtonFrame(name, parent)
    if frames[name] then
        if frames[name]:GetParent() ~= parent then
            frames[name]:SetParent(parent)
        end
        return frames[name]
    end
    local button = CreateFrame("Button", name, parent, "SecureActionButtonTemplate")
    button:RegisterForClicks("AnyUp")
    
    frames[name] = button
    return button
end

function ns:CreateTotemButton(frame, slot)
    if frame.usePet then slot = 20 - slot end
    local button = GetActionButtonFrame(addonName .. "Totem" .. slot .. "Button", frame)
    button.slot = slot
    local macrotext = "/click TotemFrameTotem" .. slot .. " RightButton"
    if frame.usePet then
        macrotext = "/petdismiss"
    end
    button:SetAttribute("type2", "macro")
    button:SetAttribute("macrotext2", macrotext)
    
    button:SetSize(self.config.iconSize, self.config.iconSize)
    button:ClearAllPoints()
    button:SetAllPoints()
    button:Show()
    return button
end

function ns:CreateActionButton(frame, index, usePet)
    if usePet == nil then usePet = false end
    local button = GetActionButtonFrame(addonName .. "ActionButton" .. index, frame)
    button.usePet = usePet
    if usePet then
        button.Totem = self:CreateTotemButton(button, index)
        button.Totem:Hide()
    end
    button:SetAttribute("type1", "spell")
    button:SetAttribute("spell1", self:GetActionSpell(index))
    button:SetSize(self.config.iconSize, self.config.iconSize)
    --button:ClearAllPoints()
    --button:SetAllPoints()
    if usePet then
        tinsert(petframes, button)
    end
    return button
end

ns.state = {}
function ns:UpdateTotemTable()
    local s = self.state
    for i = 1, 4 do
        Debug("UpdateTotemTable", "Find", i)
        local haveToten, name, start, dur, icon = GetTotemInfo(i)
        Debug("UpdateTotemTable", i, haveToten, name, start, dur, icon)
        local button = _G["TotemFrameTotem" .. i]
        if not s[i] then
            s[i] = {index = i, slot = button.slot, show = haveToten, name = name, lastname = "", start = start, dur = dur, icon = icon, btnFunc = self.CreateTotemButton}
        else
            s[i].show = haveToten
            s[i].lastname = s[i].name ~= "" and s[i].name or s[i].lastname
            s[i].slot = button.slot
            s[i].name = name
            s[i].start = start
            s[i].dur = dur
            s[i].icon = icon
        end
    end
end

function ns:GetSpellCooldown(spell)
    local name = GetActiveSpellName(spell)
    local start, dur, enable = GetSpellCooldown(name)
    local charges, maxCharges, startCharges, durCharges = GetSpellCharges(name);
    local stack = charges or GetSpellCount(name)
    local gcd = math.max((1.5 / (1 + (UnitSpellHaste("player") / 100))), 0.75)
    Debug(name, start, dur)
    Debug(name, charges, maxCharges, startCharges, durCharges)
    
    start = start or 0
    dur = dur or 0
    
    startCharges = startCharges or 0
    durCharges = durCharges or 0
    if enable == 0 then
        start, dur = 0, 0
    end
    local startTime, duration = start, dur
    if charges == maxCharges then
        start, dur = 0, 0
        startCharges, durCharges = 0, 0
    elseif charges > 0 then
        startTime, duration = startCharges, durCharges
    end
    if gcd == duration then
        startTime, duration = 0, 0
    end
    Debug(name, startTime, duration)
    return stack, maxCharges, startTime, duration
end

--/dump SpecialTotemBar.state
function ns:UpdateTotem()
    self:UpdateTotemTable()
    Debug("UpdateTotem")
    for key, value in pairs(self.state) do
        Debug("UpdateTotem", "Loop", key, value, value.name or "")
        if value.lastname ~= "" or value.name ~= "" then
            for idx, btn in pairs(self.Buttons) do
                if btn.usePet == false then
                    Debug("UpdateTotem", "DeepLoop", idx, btn.spell, value.show, value.show and value.dur > 0 and (value.name:find(btn.spell) or btn.spell:find(value.name)))
                    if value.dur > 0 then
                        if value.name ~= "" and (value.name:find(btn.spell) or btn.spell:find(value.name)) then
                            local totem = value.btnFunc(ns, btn, value.slot)
                            btn.Totem = totem
                            btn.Text:SetText("")
                            btn.CD:SetCooldown(value.start, value.dur)
                            btn.aura = true
                            Debug("UpdateTotem", "DeepLoop", "CD SET", idx, btn.spell, value.start, value.dur)
                            btn.CD:Show()
                            btn:SetAlpha(ns.config.AuraAlpha)
                            break
                        end
                    else
                        Debug("UpdateTotem", "DeepLoop", "CLEARCHECK", idx, value.lastname, btn.spell, value.lastname:find(btn.spell) or btn.spell:find(value.lastname))
                        if btn.Totem and value.lastname ~= "" and (value.lastname:find(btn.spell) or btn.spell:find(value.lastname)) then
                            btn.Totem:Hide()
                            btn.Totem = nil
                            btn:SetAlpha(ns.config.CDAlpha)
                            if ns.config.showSpellCD then
                                btn.CD:SetCooldown(0, 0)
                                btn.aura = false
                                ns:UpdateCDCooldown(btn)
                            else
                                btn.CD:Hide()
                            end
                            Debug("UpdateTotem", "DeepLoop", "CLEAR", idx, value.lastname, btn.spell)
                            break
                        end
                    end
                end
            end
        end
    end
end
function ns:UpdateCDCooldown(btn)
    if not btn then return end
    if not btn.spell then return end
    local stack, _, start, dur = ns:GetSpellCooldown(btn.spell)
    Debug(btn.spell, stack, start, dur)
    if btn.Text then
        if stack and stack > 0 then
            btn.Text:SetText(stack)
        else
            btn.Text:SetText("")
        end
    end
    if btn.CD then
        btn.CD:SetCooldown(start, dur)
    end
    return true
end

function ns:IsTalentSelected(spell)
    local name = GetActiveSpellName(spell, false)
    return db.selectedTalent[name] or false
end
local function FindSpellConfigIndex(spell)
    for key, value in pairs(ns.config.spellConfig) do
        if value == spell then
            return key
        end
    end

end

local function updateSpellList()
    resetSpellConfig()
    local spell = spellConfig[db.spec]
    if db.spec == 1 then
        if ns:IsTalentSelected(192222) then
            spell[5] = 192222
        end
        if ns:IsTalentSelected(192077) then
            local index = 5
            if ns:IsTalentSelected(192222) then
                index = 6
            else
                index = 5
            end
            spell[index] = 192077
        end
    end
    if db.spec == 2 then
        if ns:IsTalentSelected(51485) then
            spell[3] = 51485
        end
        if ns:IsTalentSelected(192077) then
            spell[5] = 192077
        end
    end
    if db.spec == 3 then
        if ns:IsTalentSelected(207399) then
            spell[5] = 207399
        elseif ns:IsTalentSelected(198838) then
            spell[5] = 198838
        end
        if ns:IsTalentSelected(192077) then
            local index = 5
            if ns:IsTalentSelected(207399) or ns:IsTalentSelected(198838) then
                index = 6
            else
                index = 5
            end
            spell[index] = 192077
        end
    end
    
    
    ns.config.spellConfig = spell
end

function ns:CheckTalent()
    db.spec = GetSpecialization()
    if db.spec > 0 then
        local talent = talents[db.spec]
        for k, v in pairs(talent) do
            local tier, column = strsplit(":", k)
            local _, _, _, selected, _, spell, _, _, _, _, known = GetTalentInfo(tier, column, GetActiveSpecGroup())
            local name = GetActiveSpellName(spell, false)
            if name then
                if spell == v.spell and (selected or known) then
                    db.selectedTalent[name] = true
                else
                    db.selectedTalent[name] = false
                end
            end
        end
        updateSpellList()
        for i, v in pairs({[198103] = 60, [198067] = 30}) do
            local name = GetActiveSpellName(i)
            if name then
                db.spellDur[name] = v
            end
        end
    end

end

local function TryUsePet(index)
    if not ns:IsTalentSelected(117013) then return false end
    local name = ns:GetActionSpell(index)
    for _, v in ipairs({198103, 198067}) do
        local n = GetActiveSpellName(v)
        if n ~= "" and name ~= "" and (n:find(name) or name:find(n)) then
            return true
        end
    end
    
    return false
end

function ns:CreateButton(index)
    Debug("CreateButton", "START", index)
    local totem = self:CreateActionButton(self.mainFrame, index, TryUsePet(index))
    
    totem.spell = self:GetActionSpell(index)
    Debug("CreateButton", "GetActionSpell", index, totem.spell)
    
    totem:SetSize(self.config.iconSize, self.config.iconSize)
    
    self.CreateCD(totem)
    
    self.CreateIcon(totem)
    
    self.CreateText(totem, "RIGHT")
    
    ns:UpdateCDCooldown(totem)
    
    totem.Icon:SetTexture(self:GetSpellTexture(index))
    totem:SetAlpha(ns.config.CDAlpha)
    return totem
end

local HiddenFrame
function ns:CreateButtons()
    local btns = self.Buttons
    --print(#btns, #ns.config.spellConfig)
    for i = 1, #btns do
        btns[i]:Hide()
        btns[i] = nil
    end
    
    HiddenFrame = HiddenFrame or CreateFrame("Frame")
    HiddenFrame:Hide()
    for i = 1, #ns.config.spellConfig or 4 do
        btns[i] = self:CreateButton(i)
        self:CreateTotemButton(HiddenFrame, i)
        if btns[i] then
            Debug("CreateButton ", i, btns[i])
            if i == 1 then
                btns[i]:SetPoint("LEFT", self.mainFrame)
            else
                btns[i]:SetPoint("LEFT", btns[i - 1], "RIGHT", self.config.spacing, 0)
            end
            btns[i]:Show()
        end
    
    end
end

local function GetSpellAuraDur(spell)
    local name = GetActiveSpellName(spell)
    for k, v in pairs(db.spellDur) do
        if k:find(name) or name:find(k) then
            return v
        end
    end
    return 0
end

function ns:UPE(...)
    local start = GetTime()
    local unit = ...
    if unit == "player" then
        if UnitExists("pet") then
            local name = UnitName("pet")
            if not name then return end
            for idx, btn in pairs(petframes) do
                if btn.usePet then
                    if btn.spell ~= "" and name ~= "" and (btn.spell:find(name) or name:find(btn.spell)) then
                        local startTime, duration = btn.CD:GetCooldownTimes()
                        startTime = (startTime or 0) / 1000
                        duration = (duration or 0) / 1000
                        
                        if btn.aura then
                            btn.Totem:Show()
                            C_Timer.After(0.1, function()
                                if not UnitExists("pet") then
                                    btn.aura = false
                                    btn:SetAlpha(ns.config.CDAlpha)
                                    --btn.CD:SetCooldown(0, 0)
                                    ns:UpdateCDCooldown(btn)
                                    btn.Totem:Hide()
                                end
                            end)
                        end
                        if duration == 0 and startTime == 0 then
                            local dur = GetSpellAuraDur(btn.spell) or 0
                            if dur > 0 then
                                btn.aura = true
                                btn.Text:SetText("")
                                btn.CD:SetCooldown(start, dur)
                                btn.CD:Show()
                                btn:SetAlpha(ns.config.AuraAlpha)
                            end
                        end
                    
                    end
                end
            end
        
        end
    end
end

local function UpdateMainFramePos(f)
    f:ClearAllPoints()
    Debug("ClearAllPoints")
    Debug("CHECK Vars", SpecialTotemBarConfig)
    if SpecialTotemBarConfig then
        f:SetPoint(unpack(SpecialTotemBarConfig))
        return
    end
    f:SetPoint(unpack(defaultConfig.FramePos))
end

local function ShowMover()
    local mover = ns.mainFrame.mover
    mover:Show()
    mover:EnableMouse(true)
end

local function HideMover()
    local mover = ns.mainFrame.mover
    mover:Hide()
    mover:EnableMouse(false)
end

local function InitSlashCMD()
    SlashCmdList["SPECIALTOTEMBARMOVER"] = function()
        if InCombatLockdown() then
            UIErrorsFrame:AddMessage("请在战斗外调整位置")
            return
        end
        if ns.mainFrame.mover:IsShown() then
            
            HideMover()
            Debug("HideMover")
        else
            
            ShowMover()
            Debug("ShowMover")
        end
        return true
    end
    SLASH_SPECIALTOTEMBARMOVER1 = "/specialtotembar"
    SLASH_SPECIALTOTEMBARMOVER2 = "/stb"
end


function ns:Init()
    
    if not checkClass() then return end
    
    self.Mult = UpdateMult()
    
    Debug("Init", "UpdateMult", self.Mult)
    
    self.mainFrame = CreateFrame("Frame", nil, UIParent)
    
    local f = ns.mainFrame
    
    if not f.mover then
        local mover = CreateFrame('Frame', addonName .. "MainFrameMover", f)
        mover:SetMovable(true)
        f:SetMovable(true)
        f:SetUserPlaced(true)
        f:SetClampedToScreen(true)
        
        mover:SetAllPoints()
        mover:EnableMouse(true)
        mover:RegisterForDrag("LeftButton")
        mover:SetScript("OnDragStart", function()f:StartMoving() end)
        mover:SetScript("OnDragStop", function()
            f:StopMovingOrSizing()
            local orig, _, tar, x, y = f:GetPoint()
            SpecialTotemBarConfig = {orig, "UIParent", tar, x, y}
        end)
        mover:SetFrameStrata("DIALOG")
        mover:Hide()
        
        Debug("Init", "CreateMover", "CreateTex")
        local texture = mover:CreateTexture('ARTWORK')
        texture:SetColorTexture(1, 1, 1)
        texture:SetAlpha(0.5)
        texture:SetAllPoints()
        
        f.mover = mover
    end
    
    Debug("Init", "CreateMover", f.mover)
    
    Debug("Init", "CreateBar", f)
    
    self:CheckTalent()
    self:CreateButtons()
    
    
    Debug("Init", "CreateButtons", "End")
    
    f:SetSize(self.config.iconSize * 4 + self.config.spacing * 4, self.config.iconSize)
    
    UpdateMainFramePos(f)
    
    Debug("Init", "SetPoint", "End", f:GetFrameStrata())
    
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:RegisterEvent("PLAYER_TOTEM_UPDATE")
    f:RegisterEvent("PLAYER_TALENT_UPDATE")
    f:RegisterEvent("UNIT_PET")
    f:SetScript("OnUpdate", function(self, elasp)
        self.elapsed = (self.elapsed or 0) + elasp
        if self.elapsed > .5 then
            for i, v in pairs(ns.Buttons) do
                if not InCombatLockdown() then
                    if v.aura and v.Totem then
                        v.Totem:Show()
                    --print("Show",v:GetName(),v.Totem:GetName(),v.Totem.slot,v.Totem:IsShown())
                    end
                end
                if v.aura == false then
                    ns:UpdateCDCooldown(v)
                end
            end
            
            self.elapsed = 0
        end
    end)
    
    f:SetScript("OnEvent", function(_, event, ...)
        if event == "UNIT_PET" then
            ns:UPE(...)
        end
        
        if event == "PLAYER_TALENT_UPDATE" then
            ns:CheckTalent()
            ns:CreateButtons()
            return
        end
        
        if event == "PLAYER_ENTERING_WORLD" then
            ns:CheckTalent()
            for i = 1, 4 do
                ns:UpdateTotem(i)
            end
            return
        end
        if event == "PLAYER_TOTEM_UPDATE" then
            local slot = ...
            return ns:UpdateTotem(slot)
        end
    end)
    Debug("Init", "InitSlashCMD", InitSlashCMD)
    InitSlashCMD()
    Debug("Init", "Over")
end


local run = CreateFrame("Frame")
run:RegisterEvent("PLAYER_LOGIN")
run:RegisterEvent("ADDON_LOADED")
run:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        
        ns:Init()
    end
    if event == "ADDON_LOADED" then
        local addon = ...
        if addon == addonName then
            
            if not SpecialTotemBarConfig then
                SpecialTotemBarConfig = {}
            end
            initSettings(defaultConfig, SpecialTotemBarConfig)
            self:UnregisterEvent("ADDON_LOADED")
        end
    end
end)
