-- Weapons - Max Purple Sharpness (REF)
-- By LordGregory

local version = "1.0.0"
log.info("Initializing `Weapons - Max Purple Sharpness (REF)` v"..version)

local variousDataManager = sdk.get_managed_singleton("app.VariousDataManager")
local BowData = variousDataManager._Setting._EquipDatas._WeaponBow._Values
local ChargeAxeData = variousDataManager._Setting._EquipDatas._WeaponChargeAxe._Values
local GunLanceData = variousDataManager._Setting._EquipDatas._WeaponGunLance._Values
local HammerData = variousDataManager._Setting._EquipDatas._WeaponHammer._Values
local HeavyBowgunData = variousDataManager._Setting._EquipDatas._WeaponHeavyBowgun._Values
local LanceData = variousDataManager._Setting._EquipDatas._WeaponLance._Values
local LightBowgunData = variousDataManager._Setting._EquipDatas._WeaponLightBowgun._Values
local LongSwordData = variousDataManager._Setting._EquipDatas._WeaponLongSword._Values
local RodData = variousDataManager._Setting._EquipDatas._WeaponRod._Values
local ShortSwordData = variousDataManager._Setting._EquipDatas._WeaponShortSword._Values
local SlashAxeData = variousDataManager._Setting._EquipDatas._WeaponSlashAxe._Values
local TachiData = variousDataManager._Setting._EquipDatas._WeaponTachi._Values
local TwinSwordData = variousDataManager._Setting._EquipDatas._WeaponTwinSword._Values
local WhistleData = variousDataManager._Setting._EquipDatas._WeaponWhistle._Values

for _, entry in pairs(BowData) do
    if (entry._SharpnessValList[0].m_value > 0) then
        entry._SharpnessValList[0] = 10
        entry._SharpnessValList[1] = 10
        entry._SharpnessValList[2] = 10
        entry._SharpnessValList[3] = 10
        entry._SharpnessValList[4] = 10
        entry._SharpnessValList[5] = 10
        entry._SharpnessValList[6] = 340
        for handicraftIndex = 0, entry._TakumiValList:get_size() - 1 do
            entry._TakumiValList[handicraftIndex] = 0
        end
    end
end

for _, entry in pairs(ChargeAxeData) do
    if (entry._SharpnessValList[0].m_value > 0) then
        entry._SharpnessValList[0] = 10
        entry._SharpnessValList[1] = 10
        entry._SharpnessValList[2] = 10
        entry._SharpnessValList[3] = 10
        entry._SharpnessValList[4] = 10
        entry._SharpnessValList[5] = 10
        entry._SharpnessValList[6] = 340
        for handicraftIndex = 0, entry._TakumiValList:get_size() - 1 do
            entry._TakumiValList[handicraftIndex] = 0
        end
    end
end

for _, entry in pairs(GunLanceData) do
    if (entry._SharpnessValList[0].m_value > 0) then
        entry._SharpnessValList[0] = 10
        entry._SharpnessValList[1] = 10
        entry._SharpnessValList[2] = 10
        entry._SharpnessValList[3] = 10
        entry._SharpnessValList[4] = 10
        entry._SharpnessValList[5] = 10
        entry._SharpnessValList[6] = 340
        for handicraftIndex = 0, entry._TakumiValList:get_size() - 1 do
            entry._TakumiValList[handicraftIndex] = 0
        end
    end
end

for _, entry in pairs(HammerData) do
    if (entry._SharpnessValList[0].m_value > 0) then
        entry._SharpnessValList[0] = 10
        entry._SharpnessValList[1] = 10
        entry._SharpnessValList[2] = 10
        entry._SharpnessValList[3] = 10
        entry._SharpnessValList[4] = 10
        entry._SharpnessValList[5] = 10
        entry._SharpnessValList[6] = 340
        for handicraftIndex = 0, entry._TakumiValList:get_size() - 1 do
            entry._TakumiValList[handicraftIndex] = 0
        end
    end
end

for _, entry in pairs(HeavyBowgunData) do
    if (entry._SharpnessValList[0].m_value > 0) then
        entry._SharpnessValList[0] = 10
        entry._SharpnessValList[1] = 10
        entry._SharpnessValList[2] = 10
        entry._SharpnessValList[3] = 10
        entry._SharpnessValList[4] = 10
        entry._SharpnessValList[5] = 10
        entry._SharpnessValList[6] = 340
        for handicraftIndex = 0, entry._TakumiValList:get_size() - 1 do
            entry._TakumiValList[handicraftIndex] = 0
        end
    end
end

for _, entry in pairs(LanceData) do
    if (entry._SharpnessValList[0].m_value > 0) then
        entry._SharpnessValList[0] = 10
        entry._SharpnessValList[1] = 10
        entry._SharpnessValList[2] = 10
        entry._SharpnessValList[3] = 10
        entry._SharpnessValList[4] = 10
        entry._SharpnessValList[5] = 10
        entry._SharpnessValList[6] = 340
        for handicraftIndex = 0, entry._TakumiValList:get_size() - 1 do
            entry._TakumiValList[handicraftIndex] = 0
        end
    end
end

for _, entry in pairs(LightBowgunData) do
    if (entry._SharpnessValList[0].m_value > 0) then
        entry._SharpnessValList[0] = 10
        entry._SharpnessValList[1] = 10
        entry._SharpnessValList[2] = 10
        entry._SharpnessValList[3] = 10
        entry._SharpnessValList[4] = 10
        entry._SharpnessValList[5] = 10
        entry._SharpnessValList[6] = 340
        for handicraftIndex = 0, entry._TakumiValList:get_size() - 1 do
            entry._TakumiValList[handicraftIndex] = 0
        end
    end
end

for _, entry in pairs(LongSwordData) do
    if (entry._SharpnessValList[0].m_value > 0) then
        entry._SharpnessValList[0] = 10
        entry._SharpnessValList[1] = 10
        entry._SharpnessValList[2] = 10
        entry._SharpnessValList[3] = 10
        entry._SharpnessValList[4] = 10
        entry._SharpnessValList[5] = 10
        entry._SharpnessValList[6] = 340
        for handicraftIndex = 0, entry._TakumiValList:get_size() - 1 do
            entry._TakumiValList[handicraftIndex] = 0
        end
    end
end

for _, entry in pairs(RodData) do
    if (entry._SharpnessValList[0].m_value > 0) then
        entry._SharpnessValList[0] = 10
        entry._SharpnessValList[1] = 10
        entry._SharpnessValList[2] = 10
        entry._SharpnessValList[3] = 10
        entry._SharpnessValList[4] = 10
        entry._SharpnessValList[5] = 10
        entry._SharpnessValList[6] = 340
        for handicraftIndex = 0, entry._TakumiValList:get_size() - 1 do
            entry._TakumiValList[handicraftIndex] = 0
        end
    end
end

for _, entry in pairs(ShortSwordData) do
    if (entry._SharpnessValList[0].m_value > 0) then
        entry._SharpnessValList[0] = 10
        entry._SharpnessValList[1] = 10
        entry._SharpnessValList[2] = 10
        entry._SharpnessValList[3] = 10
        entry._SharpnessValList[4] = 10
        entry._SharpnessValList[5] = 10
        entry._SharpnessValList[6] = 340
        for handicraftIndex = 0, entry._TakumiValList:get_size() - 1 do
            entry._TakumiValList[handicraftIndex] = 0
        end
    end
end

for _, entry in pairs(SlashAxeData) do
    if (entry._SharpnessValList[0].m_value > 0) then
        entry._SharpnessValList[0] = 10
        entry._SharpnessValList[1] = 10
        entry._SharpnessValList[2] = 10
        entry._SharpnessValList[3] = 10
        entry._SharpnessValList[4] = 10
        entry._SharpnessValList[5] = 10
        entry._SharpnessValList[6] = 340
        for handicraftIndex = 0, entry._TakumiValList:get_size() - 1 do
            entry._TakumiValList[handicraftIndex] = 0
        end
    end
end

for _, entry in pairs(TachiData) do
    if (entry._SharpnessValList[0].m_value > 0) then
        entry._SharpnessValList[0] = 10
        entry._SharpnessValList[1] = 10
        entry._SharpnessValList[2] = 10
        entry._SharpnessValList[3] = 10
        entry._SharpnessValList[4] = 10
        entry._SharpnessValList[5] = 10
        entry._SharpnessValList[6] = 340
        for handicraftIndex = 0, entry._TakumiValList:get_size() - 1 do
            entry._TakumiValList[handicraftIndex] = 0
        end
    end
end

for _, entry in pairs(TwinSwordData) do
    if (entry._SharpnessValList[0].m_value > 0) then
        entry._SharpnessValList[0] = 10
        entry._SharpnessValList[1] = 10
        entry._SharpnessValList[2] = 10
        entry._SharpnessValList[3] = 10
        entry._SharpnessValList[4] = 10
        entry._SharpnessValList[5] = 10
        entry._SharpnessValList[6] = 340
        for handicraftIndex = 0, entry._TakumiValList:get_size() - 1 do
            entry._TakumiValList[handicraftIndex] = 0
        end
    end
end

for _, entry in pairs(WhistleData) do
    if (entry._SharpnessValList[0].m_value > 0) then
        entry._SharpnessValList[0] = 10
        entry._SharpnessValList[1] = 10
        entry._SharpnessValList[2] = 10
        entry._SharpnessValList[3] = 10
        entry._SharpnessValList[4] = 10
        entry._SharpnessValList[5] = 10
        entry._SharpnessValList[6] = 340
        for handicraftIndex = 0, entry._TakumiValList:get_size() - 1 do
            entry._TakumiValList[handicraftIndex] = 0
        end
    end
end
