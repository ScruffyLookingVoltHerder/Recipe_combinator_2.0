local icons = require '__rusty-locale__.icons'
local debug_mode=false
local rc_name="recipe_combinator"
require("style")


data:extend {

{
    type = 'item-group',
    name = "Recipes",
    order = 'zzz[crafting-combinator]',
    icon = '__Recipe_Combinator_2.0__/graphics/recipe-book.png',
    icon_size = 64,
},
{
    type = "item-subgroup",
    name = "recipe-subgroup",
    group = "Recipes",
    order = "e"
  }

}


local rc = table.deepcopy(data.raw['arithmetic-combinator']['arithmetic-combinator'])
rc.name = rc_name
rc.minable.result = rc_name
rc.energy_source = { type = 'void' }
rc.energy_usage_per_tick = '1W'

for direction, definition in pairs(rc.multiply_symbol_sprites) do
definition.filename = '__Recipe_Combinator_2.0__/graphics/hr-combinator-displays.png'
	--rc.multiply_symbol_sprites[direction] = definition.hr_version
end


local rc_item = table.deepcopy(data.raw['item']['arithmetic-combinator'])
rc_item.name = rc_name
rc_item.place_result = rc_name
rc_item.icons = icons.of(rc)
rc_item.subgroup = 'circuit-network'
rc_item.order = 'c[combinators]-m[recipe-combinator]'

local rc_recipe = table.deepcopy(data.raw['recipe']['arithmetic-combinator'])
rc_recipe.name = rc_name
rc_recipe.results = {{type = "item", name = rc_name, amount = 1}} 
table.insert(data.raw['technology']['circuit-network'].effects, {type = 'unlock-recipe', recipe = rc.name})


local trans = {
	filename = '__Recipe_Combinator_2.0__/graphics/trans.png',
	width = 1,
	height = 1,
}
local invisible_sprite = trans
local con_point = {
	wire = {
		red = {0, 0},
		green = {0, 0},
	},
	shadow = {
		red = {0, 0},
		green = {0, 0},
	},
}


data:extend {
	rc, rc_item, rc_recipe,

	{
		type = 'constant-combinator',
		name = "rc-output-proxy",
		flags = {'placeable-off-grid'},
		collision_mask = {layers={}},
		--item_slot_count = config.RC_SLOT_COUNT,
		circuit_wire_max_distance = 10,
		sprites = {
			north = trans,
			east = trans,
			south = trans,
			west = trans,
		},
		activity_led_sprites = trans,
		activity_led_light_offsets = {{0, 0}, {0, 0}, {0, 0}, {0, 0}},
		
		circuit_wire_connection_points = {con_point, con_point, con_point, con_point},
		draw_circuit_wires = debug_mode,
	},
	{
		type = 'lamp',
		name = "rc-signal-cache",
		flags = {'placeable-off-grid'},
		collision_mask = {layers={}},
		circuit_wire_max_distance = 10,
		circuit_wire_connection_points = {con_point, con_point, con_point, con_point},
		draw_circuit_wires = debug_mode,
		
		picture_on = trans,
		picture_off = trans,
		energy_source = {type = 'void'},
		energy_usage_per_tick = '1W',
		selectable_in_game=true
	},

}



local combinators = {}

function combinators.merge_table(dst, sources)
	for _, src in pairs(sources) do
		for name, value in pairs(src) do
			dst[name] = value
		end
	end
	return dst
end

local function table_add(t, e)
end

local merge_table = combinators.merge_table

local boxsize =0.0001
local wire_conn = { wire = { red = { 0, 0 }, green = { 0, 0 } }, shadow = { red = { 0, 0 }, green = { 0, 0 } } }
local commons_attr = {
	flags = { 'placeable-off-grid' },
	collision_mask = { layers = {} },
	minable = nil,
	selectable_in_game = debug_mode,
	circuit_wire_max_distance = 64,
	sprites = invisible_sprite,
	activity_led_sprites = invisible_sprite,
	activity_led_light_offsets = { { 0, 0 }, { 0, 0 }, { 0, 0 }, { 0, 0 } },
	circuit_wire_connection_points = { wire_conn, wire_conn, wire_conn, wire_conn },
	draw_circuit_wires = debug_mode,
	collision_box = { { -boxsize, -boxsize }, { boxsize, boxsize } },
	created_smoke = nil,
	selection_box = { { -0.01, -0.01 }, { 0.01, 0.01 } },
	hidden_in_factoriopedia = true,
	maximum_wire_distance = 10

}

local 		energy_attr = {
	active_energy_usage = "0.01kW",
	energy_source = { type = "void" }
}

local selector_combinator = table.deepcopy(data.raw["selector-combinator"]["selector-combinator"])
selector_combinator       = merge_table(selector_combinator, { commons_attr, {
	name = "rc-selector",
	hidden_in_factoriopedia = true,
	max_symbol_sprites = invisible_sprite,
	min_symbol_sprites = invisible_sprite,
	count_symbol_sprites = invisible_sprite,
	random_symbol_sprites = invisible_sprite,
	stack_size_sprites = invisible_sprite,
	rocket_capacity_sprites = invisible_sprite,
	quality_symbol_sprites = invisible_sprite,
	flags={"hide-alt-info","not-on-map","not-upgradable","not-deconstructable","not-blueprintable"}
}, energy_attr })


data:extend {selector_combinator}