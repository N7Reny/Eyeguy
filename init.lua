-- init.lua

-- Get the current mod name and path
local modname = minetest.get_current_modname()
local modpath = minetest.get_modpath(modname)

-- Default configuration values
eyeguy = {
    default_mode = "full", -- Default mode
    default_hud_pos = {x = 0.5, y = 0.1} -- Default HUD position
}

-- Function to get the file path for a player's config file
local function get_config_filepath(player_name)
    return minetest.get_worldpath() .. "/eyeguy_" .. player_name .. ".conf"
end

-- Function to read the player's config from file
function eyeguy.read_player_config(player_name)
    local filepath = get_config_filepath(player_name)
    local file = io.open(filepath, "r")
    if not file then
        return {mode = eyeguy.default_mode, hud_pos = eyeguy.default_hud_pos}
    end
    local config = minetest.deserialize(file:read("*all"))
    file:close()
    return config or {mode = eyeguy.default_mode, hud_pos = eyeguy.default_hud_pos}
end

-- Function to write the player's config to file
function eyeguy.write_player_config(player_name, config)
    local filepath = get_config_filepath(player_name)
    local file = io.open(filepath, "w")
    if file then
        file:write(minetest.serialize(config))
        file:close()
    end
end

-- Load additional Lua files for items and options
dofile(modpath .. "/items.lua")
dofile(modpath .. "/options.lua")

-- Function to get information about the node or player the player is looking at
local function get_looked_at_object(player)
    -- Calculate the player's eye position and look direction
    local eye_pos = vector.add(player:get_pos(), {x = 0, y = player:get_properties().eye_height, z = 0})
    local look_dir = player:get_look_dir()
    local look_point = vector.add(eye_pos, vector.multiply(look_dir, 10)) -- 10 is the max range

    -- Raycast from the eye position in the look direction
    local ray = minetest.raycast(eye_pos, look_point, false, false)
    for pointed_thing in ray do
        if pointed_thing.type == "node" then
            -- If a node is detected
            local node_pos = pointed_thing.under
            local node = minetest.get_node(node_pos)
            local nodedef = minetest.registered_nodes[node.name]
            return {
                type = "node",
                name = node.name,
                description = nodedef.description or "Unknown",
                param1 = node.param1,
                param2 = node.param2,
                pos = node_pos,
            }
        elseif pointed_thing.type == "object" then
            -- If a player is detected
            local object = pointed_thing.ref
            if object:is_player() then
                return {
                    type = "player",
                    name = object:get_player_name(),
                    pos = object:get_pos(),
                }
            end
        end
    end
    return nil
end

-- Function to update the HUD with information about the looked-at node or player
local function update_hud(player)
    local player_name = player:get_player_name()
    local config = eyeguy.read_player_config(player_name)
    
    local info = get_looked_at_object(player)
    if info then
        local text = ""
        if info.type == "node" then
            if config.mode == "full" then
                text = "Node: " .. info.name .. "\nDesc: " .. info.description
                if info.param1 then
                    text = text .. "\nParam1: " .. info.param1
                end
                if info.param2 then
                    text = text .. "\nParam2: " .. info.param2
                end
                text = text .. "\nPos: " .. minetest.pos_to_string(info.pos)
            else
                text = "Desc: " .. info.description
            end
        elseif info.type == "player" then
            text = "Player: " .. info.name .. "\nPos: " .. minetest.pos_to_string(info.pos)
        end

        -- Add background HUD element if it doesn't exist
        local hud_bg_id = player:get_meta():get_int("eyeguy_hud_bg_id")
        if hud_bg_id == 0 then
            hud_bg_id = player:hud_add({
                hud_elem_type = "image",
                position = config.hud_pos,
                scale = {x = 1, y = 1},
                text = "eyeguy_bg.png",
                alignment = {x = 0, y = 0},
                offset = {x = 0, y = 0},
            })
            player:get_meta():set_int("eyeguy_hud_bg_id", hud_bg_id)
        end

        -- Add text HUD element if it doesn't exist
        local hud_id = player:get_meta():get_int("eyeguy_hud_id")
        if hud_id == 0 then
            hud_id = player:hud_add({
                hud_elem_type = "text",
                position = config.hud_pos,
                name = "block_info",
                scale = {x = 100, y = 100},
                text = text,
                alignment = {x = 0, y = 0},
                offset = {x = 0, y = 0},
                number = 0xFFFFFF,
            })
            player:get_meta():set_int("eyeguy_hud_id", hud_id)
        end

        -- Calculate background size based on text length
        local line_count = select(2, text:gsub("\n", "\n")) + 1
        local max_line_length = 0
        for line in text:gmatch("[^\n]+") do
            if #line > max_line_length then
                max_line_length = #line
            end
        end
        local bg_width = max_line_length * 0.06 -- Adjust these values based on your text size
        local bg_height = line_count * 0.2

        -- Update the HUD elements
        player:hud_change(hud_bg_id, "scale", {x = bg_width, y = bg_height})
        player:hud_change(hud_id, "text", text)
    else
        -- Remove HUD elements if there's nothing to show
        local hud_bg_id = player:get_meta():get_int("eyeguy_hud_bg_id")
        if hud_bg_id ~= 0 then
            player:hud_remove(hud_bg_id)
            player:get_meta():set_int("eyeguy_hud_bg_id", 0)
        end

        local hud_id = player:get_meta():get_int("eyeguy_hud_id")
        if hud_id ~= 0 then
            player:hud_remove(hud_id)
            player:get_meta():set_int("eyeguy_hud_id", 0)
        end
    end
end

-- Register a global step to continuously update the HUD for all players
minetest.register_globalstep(function(dtime)
    for _, player in ipairs(minetest.get_connected_players()) do
        update_hud(player)
    end
end)
