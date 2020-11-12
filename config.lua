local addonName, ns = ...
local C, F, L = unpack(ns)
if not F:IsLoaded() then return end
local GetSpecialization,GetNumSpecializations,GetTalentInfo,GetActiveSpecGroup = GetSpecialization,GetNumSpecializations,GetTalentInfo,GetActiveSpecGroup

C.db = {}
local config = {
    font = STANDARD_TEXT_FONT, -- 字体
    fontSize = 12, -- 字体大小
    -- icon
    iconSize = 32, -- 图标大小
    spacing = 5, -- 图标间隔
    -- icon alpha
    CDAlpha = .6, -- CD时的图标透明度
    AuraAlpha = 1, -- 进行时的图标透明度
    -- misc
    showSpellCD = true -- 显示技能冷却时间
}
C.config = config

local watchOrderSpell = {
    [1] = { -- 元素
        [1] = 198103, -- 土元素
        [2] = 192058, -- 电能图腾
        [3] = 198067, -- 火元素
        [4] = 8143 -- 战栗图腾
    },
    [2] = { -- 增强
        [1] = 198103, -- 土元素
        [2] = 192058, -- 电能图腾
        [3] = 2484, -- 地缚图腾
        [4] = 8143 -- 战栗图腾
    },
    [3] = { -- 恢复
        [1] = 198103, -- 土元素
        [2] = 98008, -- 灵魂链接
        [3] = 108280, -- 治疗之潮
        [4] = 5394, -- 治疗之泉图腾
        [5] = 16191, -- 法力之潮图腾
        [6] = 192058, -- 电能图腾
    }
}
local function resettingSpellList()
    C.watchOrderSpell = {}
    F:initSettings(watchOrderSpell,C.watchOrderSpell)
end


function C:UpdateWatchedSpellList()
    resettingSpellList()
    local talents = C:GetWatchTalents()
    local spells = C:GetWatchSpells()
    for k,v in pairs(talents) do 
        if v.learn then
            tinsert(C.watchOrderSpell[self.db.spec],v.spell)
            if v.replace or v.passive then
                F:RemoveArrayValue(C.watchOrderSpell[self.db.spec],v.spell)
            end
            
        end
    end
end

-- learn 是否学会
-- spell 法术ID
-- replace 替代原有法术
-- passive 被动法术
local watchTalents = {
    [1] = { -- 元素
        ["4:2"] = {learn = false, spell = 192249,replace = true}, -- 风暴元素（代替火元素
        ["4:3"] = {learn = false, spell = 192222}, -- 岩浆图腾
        ["5:3"] = {learn = false, spell = 192077}, -- 狂风图腾
        ["6:2"] = {learn = false, spell = 117013,isPet =true,passive = true} -- 元素尊者（使图腾变成宠物
    },
    [2] = { -- 增强
        ["5:3"] = {learn = false, spell = 192077} -- 狂风图腾
    },
    [3] = { -- 恢复
        ["3:2"] = {learn = false, spell = 51485}, -- 陷地图腾
        ["4:2"] = {learn = false, spell = 198838}, -- 大地之墙图腾
        ["4:3"] = {learn = false, spell = 207399}, -- 先祖护佑图腾
        ["5:3"] = {learn = false, spell = 192077}, -- 狂风图腾
        ["6:3"] = {learn = false, spell = 157153,replace=true} -- 暴雨图腾（代替治疗之泉图腾
    }
}
local PetDuration = {
    [198103] = 60,   -- 元素尊者： 土元素
    [198067] = 30,   -- 元素尊者： 火元素/风暴元素
}
function C:UpdateTalent()
    self.db.spec = GetSpecialization() or 0
    if self.db.spec < GetNumSpecializations() and self.db.spec > 0 then
        local talents = watchTalents[self.db.spec]
        for k,v in pairs(talents) do 
            local tier,column = strsplit(":",k)
            local _, _, _, selected, _, spell, _, _, _, _, known = GetTalentInfo(tier, column, GetActiveSpecGroup())
            local name = F:GetActiveSpellName(spell,false)
            if name then 
                if spell == v.spell and (selected or known) then
                    v.learn = true
                else
                    v.learn = false
                end

            end
        end
        C:UpdateWatchedSpellList()
    end
end
function C:GetWatchTalentInfo(spell)
    self.db.spec = GetSpecialization() or 0
    if self.db.spec <= GetNumSpecializations() then
        local talents = watchTalents[self.db.spec]
        for k,v in pairs(talents) do
            local name = F:GetActiveSpellName(spell,false)
            if name then
                local watchName = F:GetActiveSpellName(v.spell,false)
                if name == watchName then return v end
            end
        end
    end
end
function C:GetWatchTalents()
    self.db.spec = GetSpecialization() or 0
    return watchTalents[self.db.spec]
end

function C:GetPetDuration(spell)
    local name = F:GetActiveSpellName(spell)
    for k,v in pairs(PetDuration) do 
        local watchName = F:GetActiveSpellName(k)
        if name == watchName then return v end
    end
    return 0
end

function C:GetWatchSpells()
    return self.watchOrderSpell[self.db.spec]
end

function C:GetWatchSpell(index)
    return self.watchOrderSpell[self.db.spec][index]
end

-- 特殊处理 这里用了一个magicValue 想办法干掉他
function C:IsPet(index)
    local name = F:GetActiveSpellName(self:GetWatchSpell(index))
    for k ,v in pairs(PetDuration) do 
        local watchName = F:GetActiveSpellName(k)
        local watchSpecialTalent = C:GetWatchTalentInfo(117013)
        if watchName == name and watchSpecialTalent and watchSpecialTalent.learn  then
            return true
        end
    end
    return false
end


local defaultConfig = {["pos"] = {"CENTER", "UIParent", "CENTER", 0, -230}}

F:RegisterCallback("CUSTOM_ADDON_PRELOAD", function(self)
    if not SpecialTotemBarConfig then SpecialTotemBarConfig = {} end
    F:initSettings(defaultConfig, SpecialTotemBarConfig)
    C.db.var = SpecialTotemBarConfig
    resettingSpellList()
end)
function C:VARGET(key) return self.db.var[key] end
function C:VARSET(key,value) SpecialTotemBarConfig[key] = value end
