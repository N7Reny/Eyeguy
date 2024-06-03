-- options.lua

-- Function to display the options menu
eyeguy.show_options = function(player)
    local player_name = player:get_player_name()
    local config = eyeguy.read_player_config(player_name)
    
    local formspec = "size[6,4]" ..
                     "label[1.5,0.5;Block Info Options]" ..
                     "dropdown[1,1;4,1;mode;Full,Slim;" .. (config.mode == "full" and 1 or 2) .. "]" ..
                     "field[1,2;4,1;hud_x;HUD X Position;" .. config.hud_pos.x .. "]" ..
                     "field[1,3;4,1;hud_y;HUD Y Position;" .. config.hud_pos.y .. "]" ..
                     "button_exit[2,3.5;2,1;save;Save]"
    minetest.show_formspec(player:get_player_name(), "eyeguy:options", formspec)
end

-- Function to handle the formspec input
minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname == "eyeguy:options" then
        if fields.save then
            local player_name = player:get_player_name()
            local config = eyeguy.read_player_config(player_name)
            
            -- Update config with new values from the formspec
            config.mode = fields.mode == "Full" and "full" or "slim"
            config.hud_pos = {
                x = tonumber(fields.hud_x) or config.hud_pos.x,
                y = tonumber(fields.hud_y) or config.hud_pos.y
            }
            
            -- Save the updated config
            eyeguy.write_player_config(player_name, config)
            minetest.chat_send_player(player_name, "Options saved.")
        end
    end
end)
