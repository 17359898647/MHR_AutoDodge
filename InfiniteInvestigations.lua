local function pre_nuke(args)
	return sdk.PreHookResult.SKIP_ORIGINAL
end

local function post_nuke(retval)
	return retval
end

sdk.hook(sdk.find_type_definition("app.QuestUtil"):get_method("decreaseKeepQuestRemain"), pre_nuke, post_nuke)
sdk.hook(sdk.find_type_definition("app.QuestUtil"):get_method("increaseKeepQuestRemain"), pre_nuke, post_nuke)