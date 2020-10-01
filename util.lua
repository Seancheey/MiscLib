logging = {}
logging.E = 1
logging.W = 2
logging.I = 3
logging.D = 4

function logging.should_output()
    return true
end

function print_log(msg, level)
    level = level or logging.D
    if logging.should_output(level) then
        game.print(tostring(msg))
    end
end

--- @generic T
--- @param table T
--- @return ArrayList|T
function toArrayList(table)
    return setmetatable(table or {}, ArrayList)
end

function sprite_of(name)
    assert(type(name) == "string")
    if game.item_prototypes[name] then
        return "item/" .. name
    elseif game.fluid_prototypes[name] then
        return "fluid/" .. name
    elseif game.entity_prototypes[name] then
        return "entity/" .. name
    else
        print_log("failed to find sprite path for name " .. name)
    end
end


--- @generic T
--- @param orig T
--- @return T
function deep_copy(orig, keep_metatable)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deep_copy(orig_key)] = deep_copy(orig_value)
        end
        if keep_metatable then
            setmetatable(copy, deep_copy(getmetatable(orig)))
        end
    else
        -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

--- @generic T
--- @param orig T
--- @return T
function shallow_copy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else
        copy = orig
    end
    return copy
end

--- raises error if any value is nil
function assertAllTruthy(...)
    local n = select("#", ...)
    local arg_num = 0
    for _, _ in pairs { ... } do
        arg_num = arg_num + 1
    end
    if n ~= arg_num then
        assert(false, "needs " .. n .. " arguments but only provided " .. arg_num .. " non-nil arguments")
    end
end