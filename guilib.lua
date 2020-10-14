--- @type ArrayList
local ArrayList = require("array_list")
local assertAllTruthy = require("assert_not_null")

--- @class GuiLib
--- @type GuiLib
local GuiLib = {}
GuiLib.listeningEvents = ArrayList.new()

--- @class event
--- @field player_index player_index
--- @field element LuaGuiElement

--- @alias EventHandler fun(e: event)

--- @type table<defines.events, table<player_index, table<string, EventHandler>>>
GuiLib.guiHandlers = {}
--- @type table<defines.events,table<string, EventHandler>>
GuiLib.globalGuiHandlers = {}

GuiLib.rootName = "left"

--- This function should be called in control.lua
--- @param event defines.events
function GuiLib.listenToEvent(event)
    GuiLib.listeningEvents:add(event)
    GuiLib.guiHandlers[event] = {}
    GuiLib.globalGuiHandlers[event] = {}
    script.on_event(event, function(e)
        -- handle global events
        for gui_path, handle in pairs(GuiLib.globalGuiHandlers[event]) do
            if e.element.name == gui_path then
                handle(e)
                return
            end
        end

        if not GuiLib.guiHandlers[event][e.player_index] then
            return
        end

        -- handle player events
        for path, handle in pairs(GuiLib.guiHandlers[event][e.player_index]) do
            if e.element == GuiLib.elem_of(path, e.player_index) then
                handle(e)
                return
            end
        end
    end
    )
end

--- register a *handler* that handles *event* for gui element *gui_elem* of player with *player_index*
--- @param player_index number
--- @param gui_elem LuaGuiElement
--- @param event defines.events
--- @param handler fun(e)
function GuiLib.registerGuiHandler(player_index, gui_elem, event, handler)
    assertAllTruthy(player_index, gui_elem, event, handler)
    assert(type(handler) == "function", "handler should be a function")
    assert(gui_elem.name ~= "", "gui's name can't be nil")
    assert(GuiLib.guiHandlers[event] ~= nil, "event is not listened, please call GuiLib.listenToEvent(event) first")

    local gui_path = GuiLib.path_of(gui_elem)
    for _, elem_name in pairs(GuiLib.__split_path(gui_path)) do
        assert(elem_name ~= "", "there is an element in path of " .. gui_elem.name .. "without name")
    end
    GuiLib.guiHandlers[event][player_index][gui_path] = handler
end

--- register a global handler for a certain event for gui element with gui_path
--- this function is particularly useful for events handling on script loading stage, where no player is availiable
function GuiLib.registerPersistentGuiHandler(gui_path, event, handler)
    assertAllTruthy(gui_path, event, handler)

    GuiLib.globalGuiHandlers[event] = GuiLib.globalGuiHandlers[event] or {}
    GuiLib.globalGuiHandlers[event][gui_path] = handler
end

function GuiLib.unregisterGuiHandler(player_index, gui_elem, event)
    assertAllTruthy(player_index, gui_elem, event)

    GuiLib.guiHandlers[event][player_index][GuiLib.path_of(gui_elem)] = nil
end

function GuiLib.unregisterGuiChildrenEventHandlers(player_index, gui_parent, event)
    for _, child in pairs(gui_parent.children) do
        GuiLib.unregisterGuiHandler(player_index, child, event)
    end
end

--- unregister all handlers of gui_elem and its children
function GuiLib.unregisterAllHandlers(player_index, gui_elem)
    assertAllTruthy(player_index, gui_elem)

    for _, event in pairs(GuiLib.listeningEvents) do
        if GuiLib.guiHandlers[player_index] and GuiLib.guiHandlers[event][player_index] then
            GuiLib.guiHandlers[event][player_index][GuiLib.path_of(gui_elem)] = nil
        end
    end
    for _, child in pairs(gui_elem.children) do
        GuiLib.unregisterAllHandlers(player_index, child)
    end
end

--- @return LuaGuiElement root gui of player for this mod
function GuiLib.gui_root(player_index)
    assertAllTruthy(player_index)

    local root = game.players[player_index].gui[GuiLib.rootName]
    assert(root ~= nil, "unable to find player's gui root")
    return root
end

--- @param gui_elem LuaGuiElement
--- @return string the path of a gui element represented by "root_name|parent_name|my_name ..."
function GuiLib.path_of(gui_elem)
    assertAllTruthy(gui_elem)

    local current_element = gui_elem
    local path = ""
    while current_element and current_element.name ~= GuiLib.rootName do
        path = current_element.name .. "|" .. path
        current_element = current_element.parent
    end
    path = GuiLib.rootName .. "|" .. path
    return path
end

-- returns the path of a gui element represented by a list in order of [elem_name, parent_name, ... , root_name]
function GuiLib.__split_path(str)
    local t = {}
    for s in string.gmatch(str, "([^|]+)") do
        table.insert(t, s)
    end
    return t
end

--- @param path string guilib path for the GuiElement
--- @param player_index player_index
--- @return LuaGuiElement
function GuiLib.elem_of(path, player_index)
    assertAllTruthy(path, player_index)

    local path_list = GuiLib.__split_path(path)
    local i = 1
    local current_element = GuiLib.gui_root(player_index)

    while i < #path_list do
        local found = false
        for _, child in ipairs(current_element.children) do
            if child.name == path_list[i + 1] then
                current_element = child
                i = i + 1
                found = true
                break
            end
        end
        if not found then
            return nil
        end
    end

    return current_element
end
