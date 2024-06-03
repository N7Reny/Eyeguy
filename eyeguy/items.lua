-- items.lua

-- Register the Eye item
minetest.register_craftitem("eyeguy:the_eye", {
    description = "The Eye",
    inventory_image = "the_eye.png",
    on_place = function(itemstack, user, pointed_thing)
        eyeguy.show_options(user) -- Show the options menu when the item is used
        return itemstack
    end,
})

-- Register a chat command to get The Eye item
minetest.register_chatcommand("get_eye", {
    description = "Get The Eye item",
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if player then
            player:get_inventory():add_item("main", "eyeguy:the_eye")
            return true, "You have received The Eye."
        else
            return false, "Player not found."
        end
    end,
})
