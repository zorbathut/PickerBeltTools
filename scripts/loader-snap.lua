--[[
    "name": "LoaderRedux",
    "title": "Loader Redux",
    "author": "Optera",
    "contact": "https://forums.factorio.com/memberlist.php?mode=viewprofile&u=21729",
    "homepage": "https://forums.factorio.com/viewtopic.php?f=97&t=48412",
    "description": "Adds Loaders. Rewritten add-loader with new loader snapping logic and graphics from Arch666Angel.",
--]]
local Event = require('__stdlib__/stdlib/event/event')

local SNAP_TYPES = {
    ['loader'] = true,
    ['splitter'] = true,
    ['underground-belt'] = true,
    ['transport-belt'] = true
}

local registered = false
local do_snap = settings.get('global', 'picker-loader-snapping')

-- set loader direction according to adjacent belts
local function snap_loader_to_target(loader, entity)
    if entity and entity.valid and loader and loader.valid and SNAP_TYPES[entity.type] then
        -- loader facing
        -- north 0: Loader 0 output or 4 input
        -- east	2: Loader 2 output or 6 input
        -- south 4: Loader 4 output or 0 input
        -- west	6: Loader 6 output or 2 input

        local direction = loader.direction
        local loader_type = loader.loader_type

        if loader.direction == 0 or loader.direction == 4 then -- loader and entity are aligned vertically
            if loader.position.y > entity.position.y then
                if entity.direction == 4 then
                    direction = 4
                    loader_type = 'input'
                else
                    direction = 0
                    loader_type = 'output'
                end
            elseif loader.position.y < entity.position.y then
                if entity.direction == 0 then
                    direction = 0
                    loader_type = 'input'
                else
                    direction = 4
                    loader_type = 'output'
                end
            end
        else -- loader and entity are aligned horizontally
            if loader.position.x > entity.position.x then
                if entity.direction == 2 then
                    direction = 2
                    loader_type = 'input'
                else
                    direction = 6
                    loader_type = 'output'
                end
            elseif loader.position.x < entity.position.x then
                if entity.direction == 6 then
                    direction = 6
                    loader_type = 'input'
                else
                    direction = 2
                    loader_type = 'output'
                end
            end
        end

        -- set loader_type first or the loader will end up in different positions than intended
        if loader.direction ~= direction or loader.loader_type ~= loader_type then
            loader.loader_type = loader_type
            loader.direction = direction
        end
    end
end

-- returns loaders next to a given entity
local function find_loader_by_entity(entity, supported_loader_names)
    local position = entity.position
    local box = entity.prototype.selection_box
    local area = {
        {position.x + box.left_top.x - 1, position.y + box.left_top.y - 1},
        {position.x + box.right_bottom.x + 1, position.y + box.right_bottom.y + 1}
    }
    return entity.surface.find_entities_filtered {type = 'loader', name = supported_loader_names, area = area, force = entity.force}
end

-- returns entities in front and behind a given loader
local function find_entity_by_loader(loader)
    local lbox = loader.prototype.selection_box
    local check
    if loader.direction == 0 or loader.direction == 4 then
        check = {
            {loader.position.x - .4, loader.position.y + lbox.left_top.y - 1},
            {loader.position.x + .4, loader.position.y + lbox.right_bottom.y + 1}
        }
    else
        check = {
            {loader.position.x + lbox.left_top.x - 1, loader.position.y - .4},
            {loader.position.x + lbox.right_bottom.x + 1, loader.position.y + .4}
        }
    end
    return loader.surface.find_entities_filtered {area = check, force = loader.force}
end

-- called when entity was rotated or non loader was built
local function check_for_loaders(event, supported_loader_names)
    local entity = event.created_entity or event.entity
    if SNAP_TYPES[entity.type] then
        local loaders = find_loader_by_entity(entity, supported_loader_names)
        for _, loader in pairs(loaders) do
            local entities = find_entity_by_loader(loader)
            for _, ent in pairs(entities) do
                if ent == entity and ent ~= loader and SNAP_TYPES[ent.type] then
                    snap_loader_to_target(loader, ent, event)
                end
            end
        end

        -- also scan other exit of underground belt
        if entity.type == 'underground-belt' and entity.neighbours then
            for _, loader in pairs(loaders) do
                local entities = find_entity_by_loader(find_loader_by_entity(entity.neighbours, supported_loader_names))
                for _, ent in pairs(entities) do
                    if ent == entity.neighbours and ent ~= loader and SNAP_TYPES[ent.type] then
                        snap_loader_to_target(loader, ent, event)
                    end
                end
            end
        end
    end
end

-- called when loader was built
local function snap_loader(event)
    local loader = event.created_entity or event.entity
    if loader.type == 'loader' then
        for _, entity in pairs(find_entity_by_loader(loader)) do
            if entity.valid and entity ~= loader and SNAP_TYPES[entity.type] then
                snap_loader_to_target(loader, entity, event)
                return true
            end
        end
    end
end

local build_events = {defines.events.on_built_entity, defines.events.on_robot_built_entity, defines.events.script_raised_built}
local function register_events(condition)
    if condition then
        if not registered then
        Event.register(defines.events.on_player_rotated_entity, check_for_loaders)
        Event.register(build_events, snap_loader)
        registered = true
        end
    else
        if registered then
            Event.remove(defines.events.on_player_rotated_entity, check_for_loaders)
            Event.remove(build_events)
            registered = false
        end
    end
end
register_events(do_snap)

local function settings_changed(event)
    if event.setting == 'picker-loader-snapping' then
        do_snap = settings.get('global', 'picker-loader-snapping')
        register_events(do_snap)
    end
end
Event.register(defines.events.on_runtime_mod_setting_changed, settings_changed)
