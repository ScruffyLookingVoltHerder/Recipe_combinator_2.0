
local Event = require('__stdlib2__/stdlib/event/event')
local filter="recipe_combinator"
local cc_rate = 1
local rc_compute=require("rc_compute")
local gui = require ("gui")

local rc={}

function on_built(event)

local entity=event.entity
local combinator={}
combinator.entity=entity

local output_proxy = entity.surface.create_entity {
    name = "rc-output-proxy",
    position = entity.position,
    force = entity.force,
    create_build_effect_smoke = false,
}

local selector = entity.surface.create_entity {
    name = "rc-selector",
    position = entity.position,
    force = entity.force,
    create_build_effect_smoke = false,
}

local signal_cache=entity.surface.create_entity {
    name = "rc-signal-cache",
    position = entity.position,
    force = entity.force,
    create_build_effect_smoke = false,
}

combinator.output_proxy=output_proxy
combinator.selector=selector
combinator.signal_cache=signal_cache


local c1,c2

--connect output proxy to combinator output
c1=entity.get_wire_connector(defines.wire_connector_id.combinator_output_red,true)
c2=output_proxy.get_wire_connector(defines.wire_connector_id.circuit_red,true)
c1.connect_to(c2,false)

c1=entity.get_wire_connector(defines.wire_connector_id.combinator_output_green,true)
c2=output_proxy.get_wire_connector(defines.wire_connector_id.circuit_green,true)
c1.connect_to(c2,false)

--connect combinator input to selector input
c1=entity.get_wire_connector(defines.wire_connector_id.combinator_input_red,true)
c2=selector.get_wire_connector(defines.wire_connector_id.combinator_input_red,true)
c1.connect_to(c2,false)

c1=entity.get_wire_connector(defines.wire_connector_id.combinator_input_green,true)
c2=selector.get_wire_connector(defines.wire_connector_id.combinator_input_green,true)
c1.connect_to(c2,false)

-- connect selector output to lamp input
c1=selector.get_wire_connector(defines.wire_connector_id.combinator_output_red,true)
c2=signal_cache.get_wire_connector(defines.wire_connector_id.circuit_red,true)
c1.connect_to(c2,false)




combinator.output_proxy.destructible = false
combinator.proxy_behavior = combinator.output_proxy.get_or_create_control_behavior()
combinator.cache_behavior=combinator.signal_cache.get_or_create_control_behavior()
combinator.cache_network=combinator.cache_behavior.get_circuit_network(defines.wire_connector_id.circuit_red)

combinator.settings = {
    mode = 'ing',
    multiply_by_input = false,
    divide_by_output = false,
    restrict_to_planet=true,
	ignore_recycling=true,
}

storage.rc.data[entity.unit_number] = combinator
table.insert(storage.rc.ordered, combinator)



combinator.cache_behavior.circuit_condition={
    first_signal={type="virtual",name="signal-anything"},
    constant=0,
    comparator="≠"
}

if event.tags then combinator.settings= event.tags.settings end



end

function remove(event, create_ghosts)
local entity = event.entity

local unit_number = entity.unit_number
local combinator = storage.rc.data[unit_number]

if not combinator then return end

combinator.output_proxy.destroy()
combinator.selector.destroy()
combinator.signal_cache.destroy()

storage.rc.data[unit_number] = nil
for k, v in pairs(storage.rc.ordered) do
	if v.entity.unit_number == unit_number then
		table.remove(storage.rc.ordered, k)
		break
	end
end

local test=0
end

function update(combinator, force)
if not combinator.entity.valid then return end
if combinator.cache_behavior.circuit_condition.fulfilled == true or force then

if combinator.cache_network.signals==nil then
    combinator.cache_behavior.circuit_condition={
        first_signal={type="virtual",name="signal-anything"},
        constant=0,
        comparator="≠"
    }
    combinator.proxy_behavior.sections[1].filters={}
end

if combinator.cache_network.signals then

    local signal=combinator.cache_network.signals[1]
    combinator.cache_behavior.circuit_condition={
        first_signal={type=signal.signal.type,name=signal.signal.name,quality=signal.signal.quality},
        constant=signal.count,
        comparator="≠"
    }


if combinator.settings.mode=="ing" then find_ingredients(combinator) end
if combinator.settings.mode=="rec" then find_recipes(combinator) end
if combinator.settings.mode=="mac" then find_machines(combinator) end

end
end
end

function find_ingredients(combinator)

local input_signal = combinator.cache_network.signals[1]

local recipes = {}

-- if input signal is an item, find the recipes for it 
if not input_signal.signal.type then
recipes = storage.rc_computed_data.recipe_for[input_signal.signal.name]
end

--if input signal is a recipe, just use it.
if input_signal.signal.type=="recipe" then
	table.insert(recipes,prototypes.recipe[input_signal.signal.name])
end

if combinator.settings.ignore_recycling then recipes = filter_out_recycling(recipes) end
if combinator.settings.restrict_to_planet then recipes = filter_by_planet(combinator, recipes) end

local recipe = recipes[1]

if not recipe then return end

local ingredients = recipe.ingredients
local count=input_signal.count

local filters={}
for _,ingredient in ipairs(ingredients) do

local amount = ingredient.amount
if combinator.settings.multiply_by_input then amount = amount * count end

local type=ingredient.type
local quality = input_signal.signal.quality or "normal"
local name= ingredient.name

local filter = {min=amount,value={type=type,name=name,comparator="=",quality=quality}}
table.insert(filters,filter)

end


--combinator.proxy_behavior.sections[1].filters={{min=5,value={type="virtual",name="signal-dot",comparator="="}}}
combinator.proxy_behavior.sections[1].filters=filters

local test=0
end

function find_recipes(combinator)

local input_signal = combinator.cache_network.signals[1]

if input_signal.signal.type=="recipe" then 
	combinator.proxy_behavior.sections[1].filters={}
	return 
	end 

recipes = storage.rc_computed_data.recipe_for[input_signal.signal.name]

if combinator.settings.ignore_recycling then recipes = filter_out_recycling(recipes) end
if combinator.settings.restrict_to_planet then recipes = filter_by_planet(combinator, recipes) end


local outputs={}

for _, recipe in ipairs(recipes) do
	
	local name = recipe.name
	local quality = input_signal.signal.quality or "normal"
	local quantity = 1

	if combinator.settings.multiply_by_input then quantity = input_signal.count end

	if combinator.settings.divide_by_output then
		for x,result in ipairs(recipe.products) do
			if result.name == name or result.name.."_rcomb" == name then
				quantity = math.floor(quantity / result.amount) + (quantity % result.amount)
			end
		end
	end

	local filter = {min=quantity,value={type="recipe",name=name,comparator="=",quality=quality}}
	table.insert(outputs,filter)



local test=0
end

combinator.proxy_behavior.sections[1].filters=outputs
local test=0
end

function find_machines(combinator)

	local input_signal = combinator.cache_network.signals[1]
	if input_signal.signal.type~="recipe" then 
		combinator.proxy_behavior.sections[1].filters={}
		return 

		end 

	local recipe = prototypes.recipe[input_signal.signal.name]

	if recipe and recipe.hidden  then recipe = nil; end
	
	
	local outputs = {}
	local index = 1
	if recipe and recipe.category then
		for _, item in pairs(storage.rc_computed_data.machines.category_map[recipe.category] or {}) do
			for _, recipe in pairs(storage.rc_computed_data.machines.item_map[item]) do
				local mac_res = combinator.entity.force.recipes[recipe]
				if mac_res and not mac_res.hidden and mac_res.enabled then

					local signal = 0
					local quantity = 1

					if combinator.settings.multiply_by_input then quantity = input_signal.count end

					local filter = {min=quantity,value={type="recipe",name=item,comparator="=",quality="normal"}}
					table.insert(outputs,filter)
					

						

					index = index + 1
					break
				end
			end
		end
		combinator.proxy_behavior.sections[1].filters=outputs
	else
		combinator.proxy_behavior.sections[1].filters={}
	end
	
end

function filter_out_recycling(recipes)

local outputs={}

if recipes then
for _, recipe in ipairs(recipes) do
if not string.match(recipe.category,"recycling")  then table.insert(outputs,recipe) end
end
end

return outputs
end


function filter_by_planet(combinator, recipes)

	local outputs={}
	
	return recipes
	--[[
	for _,recipe in ipairs(recipes) do
		
	if not recipe.surface_conditions then 
		table.insert(outputs,recipe) 
	else

		local conditions_met = true
		for _, condition in ipairs(recipe.surface_conditions) do
			
			local planet_conditions = combinator.entity
			local test=0



		end
	end
end

return outputs
]]
end


function open(rc, player_index)
	local root = gui.entity(rc.entity, {
		gui.section {
			name = 'mode',
			gui.radio('ing', rc.settings.mode, {locale='mode-ing', tooltip=true}),
			gui.radio('prod', rc.settings.mode, {locale='mode-prod', tooltip=true}),
			gui.radio('rec', rc.settings.mode, {locale='mode-rec', tooltip=true}),
			gui.radio('mac', rc.settings.mode, {locale='mode-mac', tooltip=true}),
		},
		gui.section {
			name = 'misc',
			gui.checkbox('multiply-by-input', rc.settings.multiply_by_input, {tooltip=true}),
			gui.checkbox('divide-by-output', rc.settings.divide_by_output, {tooltip=true}),
			gui.checkbox('ignore-recycling', rc.settings.ignore_recycling, {tooltip=true}),
            gui.checkbox('restrict-to-planet', rc.settings.restrict_to_planet, {tooltip=true}),

		}
	}):open(player_index)
	
	update_disabled_checkboxes(rc, root)
end

function update_disabled_checkboxes(rc, root)
	disable_checkbox(rc, root, 'misc:divide-by-output', 'divide_by_output',
			(rc.settings.mode == 'rec' or rc.settings.mode == 'use') and not rc.settings.differ_output)
	disable_checkbox(rc, root, 'misc:multiply-by-input', 'multiply_by_input',
			not rc.settings.divide_by_output and not rc.settings.differ_output,
			rc.settings.divide_by_output or rc.settings.multiply_by_input)
    disable_checkbox(rc, root, 'misc:restrict-to-planet', 'restrict_to_planet',
			rc.settings.mode=='rec' or rc.settings.mode== 'ing',
			(rc.settings.mode=='rec' or rc.settings.mode== 'ing') and rc.settings.restrict_to_planet)
	disable_checkbox(rc, root, 'misc:ignore-recycling', 'ignore_recycling',
			rc.settings.mode=='rec' or rc.settings.mode== 'ing',
			(rc.settings.mode=='rec' or rc.settings.mode== 'ing') and rc.settings.ignore_recycling)
end

function disable_checkbox(rc, root, name, setting_name, enable, set_state)
	set_state = set_state or false
    local gui_name=gui.name(rc.entity, name)
	local checkbox = gui.find_element(root, gui_name)
	if checkbox.enabled ~= enable then
		checkbox.enabled = enable
		checkbox.state = set_state
		rc.settings[setting_name] = set_state
	end
end


function onload()
    cc_rate = settings.global["RC-refresh-rate"].value
    commands.add_command("rc_precompute",nil,rc_compute.precompute)
end    

function entities_pre_mined(event)
    remove(event,false)
    end

function entities_died(event)
remove(event,true)
end
      
function entities_rotate(event)
      
      
end

function run_update(tab, tick, rate)
	for i = tick % (rate + 1) + 1, #tab, (rate + 1) do update(tab[i],false); end
end

function tick(event)
run_update(storage.rc.ordered, event.tick, cc_rate)
end


function on_checked_changed(rc, name, state, element)
	local category, name = name:gsub(':.*$', ''), name:gsub('^.-:', ''):gsub('-', '_')
	if category == 'mode' then
		rc.settings.mode = name
		for _, el in pairs(element.parent.children) do
			if el.type == 'radiobutton' then
				local _, _, el_name = gui.parse_entity_gui_name(el.name)
				el.state = el_name == 'mode:'..name
			end
		end
	end
	if category == 'misc' then rc.settings[name] = state; end
	
	update_disabled_checkboxes(rc, gui.get_root(element))
	
	
	update(rc, true)
end

function check_state_changed(event)
	local element = event.element
	if element and element.valid and element.name and element.name:match('^crafting_combinator:') then
		local gui_name, unit_number, element_name = gui.parse_entity_gui_name(element.name)

		if gui_name == 'recipe_combinator' then
			on_checked_changed(storage.rc.data[unit_number], element_name, element.state, element)
		end
	end
end


local function player_setup_blueprint(event)
	log("player_setup_blueprint")
	log(serpent.block(event))
	local player = game.players[event.player_index]
	-- get new blueprint or fake blueprint when selecting a new area
	local bp = player.blueprint_to_setup
	if not bp or not bp.valid_for_read then
	  bp = player.cursor_stack
	end
	if not bp or not bp.valid_for_read then
	  return
	end
	-- get entities in blueprint
	local entities = bp.get_blueprint_entities()
	if not entities then
	  return
	end
	-- get mapping of blueprint entities to source entities
	if event.mapping.valid then
	  local map = event.mapping.get()

	  for _, bp_entity in pairs(entities) do
		if bp_entity.name == "recipe_combinator" then
		  -- set tag for our example tag-chest
		  local id = bp_entity.entity_number
		  local entity = map[id]
		  if entity then
			log("setting tag for bp_entity "..id..":"..bp_entity.name.." = "..entity.unit_number)

			settings_tag=storage.rc.data[entity.unit_number].settings
			bp.set_blueprint_entity_tag(id, "settings", settings_tag)
		  else
			log("missing mapping for bp_entity "..id..":"..bp_entity.name)
		  end
		end
	  end
	else
	  log("no entity mapping in event")
	end
  end



Event.register(defines.events.on_built_entity, on_built,Event.Filters.entity.name,filter)

--Event.register(defines.events.on_built_entity,on_built)

Event.register(defines.events.on_robot_built_entity, on_built,Event.Filters.entity.name,filter)
Event.register(defines.events.script_raised_built, on_built,Event.Filters.entity.name,filter)
Event.register(defines.events.script_raised_revive, on_built,Event.Filters.entity.name,filter)
Event.register(defines.events.on_entity_cloned, on_built,Event.Filters.entity.name,filter)

Event.register(defines.events.on_robot_pre_mined, entities_pre_mined,Event.Filters.entity.name,filter)
Event.register(defines.events.on_pre_player_mined_item, entities_pre_mined,Event.Filters.entity.name,filter)

Event.register(defines.events.on_entity_died, entities_died,Event.Filters.entity.name,filter)
Event.register(defines.events.script_raised_destroy, entities_died,Event.Filters.entity.name,filter)

Event.register(defines.events.on_player_rotated_entity, entities_rotate,Event.Filters.entity.name,filter)

Event.register(defines.events.on_tick, tick)
Event.register(defines.events.on_runtime_mod_setting_changed,
function()
	cc_rate = settings.global["RC-refresh-rate"].value
    local test=0;
end
)

function init_tables()
    storage.rc = storage.rc or {}
    storage.rc.data=storage.rc.data or {}
    storage.rc.ordered=storage.rc.ordered or {}
    
    end
    
    
Event.on_init(function()
    init_tables()
    rc_compute.precompute()
end)
    
Event.on_load(onload)

Event.on_configuration_changed(function()
    rc_compute.precompute()
end)

Event.register(defines.events.on_gui_opened,function(event)

    if not event.entity then return end
    if event.entity.name ~= "recipe_combinator" then return end
    
        local entity = event.entity
        open(storage.rc.data[entity.unit_number],event.player_index)
    end
)

Event.register(defines.events.on_gui_closed,function(event)
	local element = event.element
	if element and element.valid and element.name and element.name:match('^crafting_combinator:') then
		element.destroy()
	end
end)

Event.register(defines.events.on_gui_checked_state_changed,check_state_changed)
Event.register(defines.events.on_player_setup_blueprint,player_setup_blueprint)
