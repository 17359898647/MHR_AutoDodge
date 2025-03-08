Open = false
sdk.hook(sdk.find_type_definition("app.GUI000004"):get_method("update"), function(args) --onOpen
    --print("In Update!")
    if Open == true then
        --print("In Update In Open!")
        local GUI000004 = sdk.to_managed_object(args[2]);
        local SRCList = GUI000004._ScrList
        if SRCList ~= nil then
            local SRCListItems = SRCList:get_SelectedItem()
            SRCListItems:set_Enabled(true)
            SRCListItems:set_Selected(true)
            SRCListItems:set_CanSelect(true)
            SRCListItems:set_CanDecide(true)
        end
    end
end)

sdk.hook(sdk.find_type_definition("app.GUI000004"):get_method("onOpen"), function(args) --onOpen
    Open = true
end)