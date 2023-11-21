local enigma = get_mod("Enigma")

local hm = {
    safe_hooks = {}
}
enigma.managers.hook = hm

local hook_target = function(object, func_name)
    return tostring(object).."."..tostring(func_name)
end

local init_hook_safe = function(hook_manager, object, func_name)
    local hook_target_key = hook_target(object, func_name)
    hook_manager.safe_hooks[hook_target_key] = {}
    enigma:hook_safe(object, func_name, function(...)
        for _,hook in ipairs(hook_manager.safe_hooks[hook_target_key]) do
            --enigma:info("Invoking safe_hook "..hook.mod_id.."/"..hook_target(hook.object, hook.func_name).."/"..tostring(hook.hook_id))
            enigma:pcall(hook.func, ...) -- Pcall even within the hook_safe, this was if one func fails, the rest still execute
        end
    end)
end

hm.hook_safe = function(self, mod_id, object, func_name, func, hook_id)
    local hook_target_key = hook_target(object, func_name)
    local hook_target_table = self.safe_hooks[hook_target_key]
    if not hook_target_table then
        init_hook_safe(self, object, func_name)
        hook_target_table = self.safe_hooks[hook_target_key]
    end
    local new_hook = {
        mod_id= mod_id,
        object=  object,
        func_name = func_name,
        func = func,
        hook_id = hook_id
    }
    table.insert(self.safe_hooks[hook_target_key], new_hook)
end

hm.unhook_safe = function(self, mod_id, object, func_name, hook_id)
    local hook_target_key = hook_target(object, func_name)
    local hook_target_table = self.safe_hooks[hook_target_key]
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