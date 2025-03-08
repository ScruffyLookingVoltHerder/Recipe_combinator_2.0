
local function ends_with(str, ending)
    return ending == "" or str:sub(-#ending) == ending
 end

local function process_recipe(name, recipe)

    if not recipe.results or next(recipe.results) == nil then return end
    if ends_with(name,"_rcomb") then return end
    

    local new_recipe=table.deepcopy(recipe)
    new_recipe.name=new_recipe.name.."_rcomb"
    new_recipe.hide_from_signal_gui = false
    new_recipe.show_amount_in_title = true
    new_recipe.subgroup="recipe-subgroup"

    data.raw.recipe[name.."_rcomb"]=new_recipe


    for techname, tech in pairs(data.raw.technology) do
        local test=0
        if tech.effects then
            
      
        for k,v in ipairs(tech.effects)do
          if (v.type=="unlock-recipe") and (v.recipe==name) then
            local new_effect={type="unlock-recipe", recipe=name.."_rcomb"}

            table.insert(tech.effects,new_effect)
            print("add recipe to tech for "..name)

            local test=0
          end
        end
    end
end




end




 --Generate signals for all existing recipes that need it
for name, recipe in pairs(data.raw['recipe']) do process_recipe(name, recipe); end
