local addonName, L = ...

local CHARACTER_DEFAULTS = {
    AutoRepair = true,
    UseGuildRepair = false,
    ReputationRepairLimit = 5,
    VendorGreys = true,
}

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

local function selfMessage(v)
    DEFAULT_CHAT_FRAME:AddMessage(v, 1.0, 1.0, 1.0)
end

local function GetMetadata(key)
    if C_AddOns and C_AddOns.GetAddOnMetadata then
        return C_AddOns.GetAddOnMetadata(addonName, key)
    end
    return GetAddOnMetadata and GetAddOnMetadata(addonName, key)
end

local POOR_QUALITY = (Enum and Enum.ItemQuality and Enum.ItemQuality.Poor) or 0
local NUM_BAGS = NUM_BAG_SLOTS or 4

--------------------------------------------------------------------------------
-- Settings (saved variables)
--------------------------------------------------------------------------------

local function LoadSettings()
    if type(orbSellAndRepair_settings) ~= "table" then
        orbSellAndRepair_settings = {}
    end
    for k, v in pairs(CHARACTER_DEFAULTS) do
        if type(orbSellAndRepair_settings[k]) ~= type(v) then
            orbSellAndRepair_settings[k] = v
        end
    end
end

--------------------------------------------------------------------------------
-- Junk seller
--------------------------------------------------------------------------------

local function SellGreys()
    local total = 0
    for bag = 0, NUM_BAGS do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info and info.quality == POOR_QUALITY and not info.hasNoValue and not info.isLocked then
                local sellPrice = select(11, C_Item.GetItemInfo(info.itemID)) or 0
                total = total + sellPrice * (info.stackCount or 1)
                C_Container.UseContainerItem(bag, slot)
            end
        end
    end
    if total > 0 then
        selfMessage(L.SELL_GREY .. GetCoinTextureString(total))
    end
end

--------------------------------------------------------------------------------
-- Auto repair
--------------------------------------------------------------------------------

local function CanUseGuildRepair()
    return orbSellAndRepair_settings.UseGuildRepair
        and IsInGuild()
        and CanGuildBankRepair ~= nil
        and CanGuildBankRepair()
end

local function Repair()
    if not CanMerchantRepair() then
        return
    end

    local repairAllCost, canRepair = GetRepairAllCost()
    if not canRepair or repairAllCost <= 0 then
        return
    end

    local reaction = UnitReaction("npc", "player")
    if reaction and orbSellAndRepair_settings.ReputationRepairLimit > reaction then
        selfMessage(L.REPAIR_REPUT)
        return
    end

    local fromGuild = CanUseGuildRepair()
    if not fromGuild and repairAllCost > GetMoney() then
        selfMessage(L.REPAIR_MONEY)
        return
    end

    RepairAllItems(fromGuild and true or false)
    selfMessage(L.REPAIR_OK .. GetCoinTextureString(repairAllCost))
end

local function OnMerchantShow()
    if orbSellAndRepair_settings.VendorGreys then
        SellGreys()
    end
    if orbSellAndRepair_settings.AutoRepair then
        Repair()
    end
end

--------------------------------------------------------------------------------
-- Options panel (Settings API, The War Within / Midnight / Forever)
--------------------------------------------------------------------------------

local function RegisterSetting(category, key, label)
    local default = CHARACTER_DEFAULTS[key]
    local varType = type(default)
    if Settings.VarType then
        varType = (varType == "boolean") and Settings.VarType.Boolean or Settings.VarType.Number
    end
    return Settings.RegisterAddOnSetting(
        category,
        addonName .. "_" .. key,
        key,
        orbSellAndRepair_settings,
        varType,
        label,
        default
    )
end

local function CreateConfigurationPanel()
    if not (Settings and Settings.RegisterVerticalLayoutCategory) then
        return
    end

    local version = GetMetadata("Version")
    local title = version and (addonName .. " " .. version) or addonName
    local category = Settings.RegisterVerticalLayoutCategory(title)

    -- Sell greys
    local sellSetting = RegisterSetting(category, "VendorGreys", L.VendorGreysBtn.text)
    Settings.CreateCheckbox(category, sellSetting)

    -- Auto repair
    local repairSetting = RegisterSetting(category, "AutoRepair", L.AutoRepairBtn.text)
    Settings.CreateCheckbox(category, repairSetting)

    -- Minimum reputation
    local reputSetting = RegisterSetting(category, "ReputationRepairLimit", L.ReputSlider.text)
    local options = Settings.CreateSliderOptions(4, 8, 1)
    options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
        return L.REPUTATIONS[math.floor(value + 0.5)] or tostring(value)
    end)
    Settings.CreateSlider(category, reputSetting, options, L.ReputSlider.tooltip)

    -- Guild repair (only if the client has guild bank repairs)
    if CanGuildBankRepair ~= nil then
        local guildSetting = RegisterSetting(category, "UseGuildRepair", L.UseGuildRepairBtn.text)
        Settings.CreateCheckbox(category, guildSetting)
    end

    Settings.RegisterAddOnCategory(category)
end

--------------------------------------------------------------------------------
-- Load the addon
--------------------------------------------------------------------------------

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("MERCHANT_SHOW")
f:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        LoadSettings()
        CreateConfigurationPanel()
        self:UnregisterEvent("ADDON_LOADED")
    elseif event == "MERCHANT_SHOW" and orbSellAndRepair_settings then
        OnMerchantShow()
    end
end)
