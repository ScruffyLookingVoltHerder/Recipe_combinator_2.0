local function ends_with(str, ending)
    return ending == "" or str:sub(-#ending) == ending
 end


rc_compute={}

rc_compute.precompute=function()
print("precompute called")

storage.rc_computed_data={}
storage.rc_computed_data.recipe_for={}

rc_compute.compute_recipes_for()
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
return rc_compute