local enigma = get_mod("Enigma")

local hm = {
    prehooks = {},
    hooks = {}
}
enigma.managers.hook = hm

local hook_target = function(object, func_name)
    return tostring(object).."."..tostring(func_name)
end

local init_hook_safe = function(hook_manager, object, func_name)
    local hook_target_key = hook_target(object, func_name)
    hook_manager.prehooks[hook_target_key] = {}
    hook_manager.hooks[hook_target_key] = {}
    enigma:hook(object, func_name, function(func, ...)
        for _,hook in ipairs(hook_manager.prehooks[hook_target_key]) do
            enigma:pcall(hook.func, ...)
        end
        local _1,_2,_3,_4,_5,_6,_7,_8,_9,_10 = func(...)
        for _,hook in ipairs(hook_manager.hooks[hook_target_key]) do
            enigma:pcall(hook.func, ...)
        end
        -- Guess I'll have to find out the hard way if someone ever hooks a function that returns more than 10 values
        -- But it's probably not worth it to always pack and unpack the return value
        return _1,_2,_3,_4,_5,_6,_7,_8,_9,_10
    end)
end

hm.prehook_safe = function(self, mod_id, object, func_name, func, hook_id)
    local hook_target_key = hook_target(object, func_name)
    local hook_target_table = self.prehooks[hook_target_key]
    if not hook_target_table then
        init_hook_safe(self, object, func_name)
        hook_target_table = self.prehooks[hook_target_key]
    end
    local new_hook = {
        mod_id= mod_id,
        object=  object,
        func_name = func_name,
        func = func,
        hook_id = hook_id
    }
    table.insert(self.prehooks[hook_target_key], new_hook)
end

hm.unprehook_safe = function(self, mod_id, object, func_name, hook_id)
    local hook_target_key = hook_target(object, func_name)
    local hook_target_table = self.prehooks[hook_target_key]
    if not hook_target_table then
        return
    end
    local index
    for i,v in ipairs(hook_target_table) do
        if (v.mod_id == mod_id) and (v.hook_id == hook_id) then
            index = i
            break
        end
    end
    if index then
        table.remove(hook_target_table, index)
    end
end

hm.hook_safe = function(self, mod_id, object, func_name, func, hook_id)
    local hook_target_key = hook_target(object, func_name)
    local hook_target_table = self.hooks[hook_target_key]
    if not hook_target_table then
        init_hook_safe(self, object, func_name)
        hook_target_table = self.hooks[hook_target_key]
    end
    local new_hook = {
        mod_id= mod_id,
        object=  object,
        func_name = func_name,
        func = func,
        hook_id = hook_id
    }
    table.insert(self.hooks[hook_target_key], new_hook)
end

hm.unhook_safe = function(self, mod_id, object, func_name, hook_id)
    local hook_target_key = hook_target(object, func_name)
    local hook_target_table = self.hooks[hook_target_key]
    if not hook_target_table then
        return
    end
    local index
    for i,v in ipairs(hook_target_table) do
        if (v.mod_id == mod_id) and (v.hook_id == hook_id) then
            index = i
            break
        end
    end
    if index then
        table.remove(hook_target_table, index)
    end
end