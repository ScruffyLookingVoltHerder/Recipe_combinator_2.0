local function ends_with(str, ending)
    return ending == "" or str:sub(-#ending) == ending
 end


rc_compute={}

rc_compute.precompute=function()
print("precompute called")

storage.rc_computed_data={}
storage.rc_computed_data.recipe_for={}
storage.rc_computed_data.machines={}
storage.rc_computed_data.machines.item_map={}
storage.rc_computed_data.machines.category_map={}

rc_compute.compute_recipes_for()
rc_compute.build_machine_cache()
end

rc_compute.compute_recipes_for = function()

    local test2=0

    for name, recipe in pairs(prototypes.recipe) do 
        rc_compute.recipe_for(name, recipe)
    end

    local test=0

end

rc_compute.recipe_for=function(name,recipe)
    if not recipe.products or next(recipe.products) == nil then return end
    if not ends_with(name,"_rcomb") then return end
    local recipes_for = storage.rc_computed_data.recipe_for

for i,product in ipairs(recipe.products) do
    
    if not recipes_for[product.name] then recipes_for[product.name]={} end

    local recipes_for_product= recipes_for[product.name] 
    
   table.insert( recipes_for_product,recipe)

end



     
end

rc_compute.build_machine_cache = function()
	
	for name, prototype in pairs(prototypes.entity) do
		if prototype.crafting_categories and prototype.items_to_place_this then
			for category in pairs(prototype.crafting_categories) do
				storage.rc_computed_data.machines.category_map[category] = storage.rc_computed_data.machines.category_map[category] or {}
				for _, item in pairs(prototype.items_to_place_this) do
					storage.rc_computed_data.machines.item_map[item.name] = {}
					table.insert(storage.rc_computed_data.machines.category_map[category], item.name)
				end
			end
		end
	end
	for _, recipe in pairs(prototypes.recipe) do
		for _, product in pairs(recipe.products) do
			if storage.rc_computed_data.machines.item_map[product.name] ~= nil then
				table.insert(storage.rc_computed_data.machines.item_map[product.name], recipe.name)
			end
		end
	end
    local test=0
end





return rc_compute

