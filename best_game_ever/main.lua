print("amogus");

local creator = require("creator");

min = math.min;
max = math.max;
abs = math.abs;

function sign(x)
	if x>0 then
		return 1;
	elseif x==0 then
		return 0;
	else
		return -1;
	end
end

local W = display.contentWidth;
_G.W = W;
local H = display.contentHeight;
_G.H = H;

function rotate_point(x, y, cx, cy, a) -- a need in rad
	local dx=x-cx;
	local dy=y-cy;
	local a1 = math.atan2(dy, dx);
	local d = (dx^2+dy^2)^0.5;
	local a2 = a1+a;
	local nx = cx+d*math.cos(a2);
	local ny = cy+d*math.sin(a2);
	
	return {nx, ny};
end

function vec_sum(vec_1, vec_2)
	local res = {};
	for i=1, #vec_1 do
		res[i] = vec_1[i]+vec_2[i];
	end
	return res;
end
_G.vec_sum = vec_sum;

function vec_mult_num(vec, n)
	local res = {};
	for i=1, #vec do
		res[i] = n*vec[i];
	end
	return res;
end
_G.vec_mult_num = vec_mult_num;

function vec_equal(vec_1, vec_2)
	ok=true;
	for i=1, #vec_1 do
		if vec_1[i] ~= vec_2[i] then
			ok=false;
			break;
		end
	end
	return ok;
end
_G.vec_equal = vec_equal;

function vec_copy(vec)
	local res = {};
	for i=1, #vec do
		res[i] = vec[i];
	end
	return res;
end
_G.vec_copy = vec_copy;

function newGroup(x, y, par)
	local new_group = display.newGroup();
	new_group.x = x;
	new_group.y = y;
	if par~=nil then
		par:insert(new_group);
	end
	return new_group;
end
_G.newGroup = newGroup;

function cleanGroup(gr)
	while gr.numChildren > 0 do
		display.remove(gr[1]);
	end
end
_G.cleanGroup = cleanGroup;


json = require 'json';

_G.saveObj = {};
_G.saveObj["lvl"] = _G.saveObj["lvl"] or 1;

function _G.loadFile(fname, directory)
	if not directory then
		directory = system.DocumentsDirectory;
	end
	local path = system.pathForFile(fname, directory);
	if(path)then
		local file = io.open( path, "r" );
		if (file) then
			local contents = file:read( "*a" );
			io.close(file);
			if(contents and #contents>0)then
				return contents;
			end
		end
	end
	return nil
end

function _G.saveFile(fname, save_str, source)
	local path = system.pathForFile( fname, system.DocumentsDirectory);
	local file = io.open(path, "w+b");
	if file then
		--local save_str = Json.Encode(login_obj);
		file:write(save_str);          
		io.close( file )
		print("Saving("..fname.."): ok!", source);
	else
		print("Saving("..fname.."): fail!", source);
	end
end

function _G.saveGame()
	local data = json.encode(_G.saveObj);
	saveFile("save1.json", data, source)
end

function _G.loadGame()
	local data = loadFile("save1.json");
	if(data)then
		local obj = json.decode(data);
		if(obj)then -- preventing file corruption
			_G.saveObj = obj;
		end
	end
end

_G.loadGame();
_G.saveGame();



_G.field_arr = function(obj, field)
	local arr = {};
	for i=1, #field do
		table.insert(arr, obj[field[i]]);
	end
	return arr;
end

_G.field_obj = function(obj, field)
	local arr = {};
	for i=1, #field do
		arr[field[i]] = obj[field[i]];
	end
	return arr;
end

local world_obj = {};
_G.world_obj = world_obj;
world_obj["block"] = {};
world_obj["block"].init = function(par)
	local new_block = display.newRect(game, par["x"], par["y"], par["width"], par["height"]);
	new_block:setFillColor(1,0,1);
	table.insert(world_obj["block"], new_block);
	-- new_block.tag = "block";
	return new_block;
end
world_obj["block"].field = {"x", "y", "width", "height"};

-- rotate_point(x, y, cx, cy, a) -- a need in rad
world_obj["danger_rect"] = {};
world_obj["danger_rect"].init = function(par)
	local new_danger_rect = display.newRect(game, par["x"], par["y"], par["width"], par["height"]);
	new_danger_rect:setFillColor(1,0,0);
	new_danger_rect.v = par["v"] or {0, 0};
	table.insert(world_obj["danger_rect"], new_danger_rect);
	-- new_block.tag = "danger_rect";
	return new_danger_rect;
end
world_obj["danger_rect"].field = {"x", "y", "width", "height", "v"};

world_obj["danger_circle"] = {};
world_obj["danger_circle"].init = function(par)
	local new_danger_circle = newGroup(par["x"], par["y"], game);
	-- new_danger_circle.body2 = display.newCircle(new_danger_circle, 0, 0, par["width"]/2);
	new_danger_circle.body = display.newImageRect(new_danger_circle, "image/danger/saw.png", par["width"], par["width"]);
	-- new_danger_circle:setFillColor(1,0,0);
	table.insert(world_obj["danger_circle"], new_danger_circle);
	return new_danger_circle;
end
world_obj["danger_circle"].field = {"x", "y", "width"};

local bg = display.newGroup();
_G.bg = bg;
bg.rect = display.newRect(W/2, H/2, W*2, H*2);
bg.rect:setFillColor(11/255, 33/255, 59/255);

local game = display.newGroup();
_G.game = game;
game.pause = false;
game.isVisible = false;

local start_pos;

local hero = newGroup(10^9, 10^9, game);
hero.dash_n = 1;
function hero:set_dash_n(n)
	hero.dash_n = n;
	if hero.dash_n == 1 then
		hero.body:setFillColor(0.5,0,0.75);
	else
		hero.body:setFillColor(0.5,0.5,0.75);
	end
end
game.hero = hero;
local body = display.newRect(hero, 0, 0, 60, 60);
body:setFillColor(0.5,0,0.75);
hero.body = body;
local body_img = display.newImageRect(hero, "image/hero/body.png", body.width, body.height);
local ears_img = display.newImageRect(hero, "image/hero/ears.png", body.width, body.height);
ears_img:scale(1.1, 1.1);

hero.v = {0, 0};
hero.speed = 20;

function hero:death()
	if start_pos~=nil then
		hero.x = start_pos.x;
		hero.y = start_pos.y;
	end
	hero.v = {0, 0};
	hero:set_dash_n(1);
end

Runtime:addEventListener("key", function(event)
	if event.phase == "down" and event.keyName == "r" then
		hero:death();
	end
end);

local key_press = {};
_G.key_press = key_press;

local key_control = {};
key_control["left"] = {-1, 0};
key_control["right"] = {1, 0};
key_control["up"] = {0, -1};
key_control["down"] = {0, 1};
_G.key_control = key_control;



function absPos(obj)
	local x=obj.x;
	local y=obj.y;
	local obj2=obj.parent;
	while obj2~=nil do
		x=x+obj2.x;
		y=y+obj2.y;
		obj2=obj2.parent;
	end
	return {x, y};
end

function _G.rectColision(obj1, obj2)
	-- print(arrow_n);
	if math.abs( absPos(obj1)[1]-absPos(obj2)[1] )<obj1.width/2+obj2.width/2 and
		math.abs( absPos(obj1)[2]-absPos(obj2)[2] )<obj1.height/2+obj2.height/2 then
		return true;
	else
		return false;
	end
end

function distanse(x1, y1, x2, y2)
	local dx = x1-x2;
	local dy = y1-y2;
	return math.sqrt( dx*dx + dy*dy );
end

function circleColision(rect, circle)
	local rect_x = absPos(rect)[1];
	local rect_y = absPos(rect)[2];
	local A={ x=rect_x-rect.width/2, y=rect_y-rect.height/2 };
	local B={ x=rect_x+rect.width/2, y=rect_y-rect.height/2 };
	local C={ x=rect_x-rect.width/2, y=rect_y+rect.height/2 };
	local D={ x=rect_x+rect.width/2, y=rect_y+rect.height/2 };
	
	local ok=false;
	
	local cir_x = absPos(circle)[1];
	local cir_y = absPos(circle)[2];
	
	if ( ( (cir_x+circle.width/2>A.x and cir_x+circle.width/2<B.x) or (cir_x-circle.width/2>A.x and cir_x-circle.width/2<B.x) ) and cir_y>A.y and cir_y<C.y ) or
	( ( ( cir_y+circle.width/2>A.y and cir_y+circle.width/2<C.y ) or ( cir_y-circle.width/2>A.y and cir_y-circle.width/2<C.y ) ) and cir_x>A.x and cir_x<B.x )
	or distanse( A.x, A.y, cir_x, cir_y ) < circle.width/2
	or distanse( B.x, B.y, cir_x, cir_y ) < circle.width/2
	or distanse( C.x, C.y, cir_x, cir_y ) < circle.width/2
	or distanse( D.x, D.y, cir_x, cir_y ) < circle.width/2 then
		ok=true;
	end
	
	return ok;
end

--[[function ray_not_intersecting_line_max_len(A, v, C, D)
	local dx = D[1] - C[1];
	local dy = D[2] - C[2];
	
	local k1 = v[2]/v[1];
	local k2 = dy/dx;
	
	local b1 = A[2]-A[1]*k1;
	local b2 = C[2]-C[1]*k2;
	
	local null_1 = (v[1]==0);
	local null_2 = (dx==0);
	
	local min_x = min(D[1], C[1]);
	local max_x = max(D[1], C[1]);
	local min_y = min(D[2], C[2]);
	local max_y = max(D[2], C[2]);
	
	if null_1==false and null_2==false then
		local x = (b1-b2) / (k2-k1);
		local y = x*k1 + b1;
		if x>=min_x and x<=max_x and sign(x-A[1])~=-sign(v[1]) then
			return (x-A[1])/v[1];
		end
	elseif null_2==false then
		local x = A[1];
		local y = k2*x + b2;
		if x>=min_x and x<=max_x and sign(y-A[2])~=-sign(v[2]) then
			return (y-A[2])/v[2];
		end
	elseif null_1==false then
		if sign(v[1]) ~= -sign(C[1]-A[1]) and (k1*C[1]+b1>=min_y and k1*C[1]+b1<=max_y) then
			return (C[1]-A[1])/v[1];
		end
	else
		if A[1] == C[1] then
			local dy2;
			if A[2] > min_y then
				dy2 = max_y-A[2];
			else
				dy2 = min_y-A[2];
			end
			if sign(dy2) ~= -sign(v[2]) then
				return dy2/v[2];
			end
		end
	end
end]]--

function ray_not_intersecting_line_max_len(A, v, C, D)
	local dx = D[1] - C[1];
	local dy = D[2] - C[2];
	
	local k1 = v[2]/v[1];
	local k2 = dy/dx;
	
	local b1 = A[2]-A[1]*k1;
	local b2 = C[2]-C[1]*k2;
	
	local null_1 = (v[1]==0);
	local null_2 = (dx==0);
	
	local min_x = min(D[1], C[1]);
	local max_x = max(D[1], C[1]);
	local min_y = min(D[2], C[2]);
	local max_y = max(D[2], C[2]);
	
	-- test_gr:insert( display.newLine( C[1], C[2], D[1], D[2] ) );
	-- test_gr[test_gr.numChildren]:setStrokeColor(0,1,0);
	
	local E = 0.0001;
	
	if null_1==false and null_2==false then
		local x = (b1-b2) / (k2-k1);
		local y = x*k1 + b1;
		
		-- test_gr:insert( display.newText(x, 50, 50, nil, 10) );
		
		if abs(A[1]-x)<E and abs(A[2]-y)<E and x>=min_x and x<=max_x then
			-- print( "null_1==false and null_2==false; m2 = "..((C[1]-A[1])/v[1]) );
			return 0;
		elseif x>=min_x and x<=max_x then
		-- if x>=min_x and x<=max_x then
			local pdx = x-A[1];
			if pdx/v[1] > 0 then
				return pdx/v[1];
			end
		end
		
	elseif null_2==false then
		local x = A[1];
		local y = k2*x + b2;
		if x>=min_x and x<=max_x and sign(y-A[2])~=-sign(v[2]) then
			return (y-A[2])/v[2];
		end
	elseif null_1==false then
		if sign(v[1]) ~= -sign(C[1]-A[1]) and (k1*C[1]+b1>=min_y and k1*C[1]+b1<=max_y) then
			-- print( "null_1==false; m2 = "..((C[1]-A[1])/v[1]) );
			return (C[1]-A[1])/v[1];
		end
	else
		if A[1] == C[1] then
			local dy2;
			if A[2] > min_y then
				dy2 = max_y-A[2];
			else
				dy2 = min_y-A[2];
			end
			if sign(dy2) == sign(v[2]) then
				return dy2/v[2];
			end
		end
	end
end

function rect_point_arr(rect)
	local A = { absPos(rect)[1]-rect.width/2 , absPos(rect)[2]-rect.height/2 };
	local B = { absPos(rect)[1]+rect.width/2 , absPos(rect)[2]-rect.height/2 };
	local C = { absPos(rect)[1]+rect.width/2 , absPos(rect)[2]+rect.height/2 };
	local D = { absPos(rect)[1]-rect.width/2 , absPos(rect)[2]+rect.height/2 };
	return {A, B, C, D};
end

function move(body, moving_body, v)
	-- display.newRect(absPos(body)[1], absPos(body)[2], body.width, body.height);
	-- local new_pos = vec_sum({body.x, body.y}, v);
	--[[local body_pos = absPos(moving_body);
	local body_parent_pos = vec_sum(body_pos, vec_mult_num({moving_body.x, moving_body.y}, -1));
	local block = world_obj["block"];
	local near_ok = true;
	-- local x1 = absPos(moving_body)[1];
	-- local y1 = absPos(moving_body)[2];
	local x1 = moving_body.x;
	local y1 = moving_body.y;
	if v[1]>=0 then
		local min_x = 10^9;
		local near=false;
		for i=1, #block do
			local block_pos = absPos(block[i]);
			if body_pos[1]+body.width/2+v[1] > block_pos[1]-block[i].width/2 and body_pos[1] < block_pos[1] and math.abs(body_pos[2]-block_pos[2]) < (block[i].height+body.height)/2 then
				min_x=math.min(min_x, block_pos[1]-block[i].width/2);
				near=true;
			end
		end
		if near then
			moving_body.x=min_x-body.width/2-body_parent_pos[1];
			near_ok = false;
		else
			moving_body.x = moving_body.x + v[1];
		end
	else
		local max_x = -10^9;
		local near=false;
		for i=1, #block do
			local block_pos = absPos(block[i]);
			if body_pos[1]-body.width/2+v[1] < block_pos[1]+block[i].width/2 and body_pos[1] > block_pos[1] and math.abs(body_pos[2]-block_pos[2]) < (block[i].height+body.height)/2 then
				max_x=math.max(max_x, block_pos[1]+block[i].width/2);
				near=true;
			end
		end
		if near then
			moving_body.x=max_x+body.width/2-body_parent_pos[1];
			near_ok = false;
		else
			moving_body.x = moving_body.x + v[1];
		end
	end
	
	if v[2]>=0 then
		local min_y = 10^9;
		local near=false;
		for i=1, #block do
			local block_pos = absPos(block[i]);
			if body_pos[2]+body.height/2+v[2] > block_pos[2]-block[i].height/2 and body_pos[2] < block_pos[2] and math.abs(body_pos[1]-block_pos[1]) < (block[i].width+body.width)/2 then
				min_y=math.min(min_y, block_pos[2]-block[i].height/2);
				near=true;
			end
		end
		if near then
			moving_body.y=min_y-body.height/2-body_parent_pos[2];
			near_ok = false;
		else
			moving_body.y = moving_body.y + v[2];
		end
	else
		local max_y = -10^9;
		local near=false;
		for i=1, #block do
			local block_pos = absPos(block[i]);
			if body_pos[2]-body.height/2+v[2] < block_pos[2]+block[i].height/2 and body_pos[2] > block_pos[2] and math.abs(body_pos[1]-block_pos[1]) < (block[i].width+body.width)/2 then
				max_y=math.max(max_y, block_pos[2]+block[i].height/2);
				near=true;
			end
		end
		if near then
			moving_body.y=max_y+body.height/2-body_parent_pos[2];
			near_ok = false;
		else
			moving_body.y = moving_body.y + v[2];
		end
	end
	
	local x2 = moving_body.x;
	local y2 = moving_body.y;
	local dx = x2-x1;
	local dy = y2-y1;
	
	local l1 = dx/v[1];
	local l2 = dy/v[2];
	
	local dl = l2-l1;
	
	if math.abs(dl)>0.000001 then
		if dl>0 then
			moving_body.y = moving_body.y - dl * v[2];
		else
			moving_body.x = moving_body.x + dl * v[1];
		end
	end
	
	return near_ok;]]--
	
	
	
	local body_p = rect_point_arr(body);
	
	-- for i=1, #body_p do
		-- display.newCircle(body_p[i][1], body_p[i][2], 5);
	-- end
	
	local max_len=10^9;
	
	local block = world_obj["block"];
	
	for i=1, #block do
		local block_p = rect_point_arr(block[i]);
		-- for i=1, #block_p do
			-- display.newCircle(block_p[i][1], block_p[i][2], 5);
		-- end
		for j=1, #body_p do
			for k=1, #block_p do
				local max_len2 = ray_not_intersecting_line_max_len( body_p[j], v, block_p[k] , block_p[k%#block_p+1] );
				if max_len2==nil then
					max_len2 = 10^9;
				end
				max_len = min(max_len, max_len2);
			end
		end
		
		for j=1, #block_p do
			for k=1, #body_p do
				local max_len2 = ray_not_intersecting_line_max_len( block_p[j], {-v[1], -v[2]}, body_p[k] , body_p[k%#body_p+1] );
				if max_len2==nil then
					max_len2 = 10^9;
				end
				max_len = min(max_len, max_len2);
			end
		end
		
		-- test_gr:insert( display.newLine( body.x, body.y, body.x+body.v[1]*max_len, body.y+body.v[2]*max_len ) ); -- резня
	end
	
	max_len = max(0, max_len-0.002);
	
	local m = min(1, max_len);
	
	if m>0 then
		moving_body:translate(unpack( vec_mult_num(v, m) ));
	end
	
	if m>=1 then
		return true;
	end
	
	--[[local ok=true;
	
	local p1 = absPos(body);
	local x1 = p1[1];
	local y1 = p1[2];
	local x2 = x1+v[1];
	local y2 = y1+v[2];
	
	local block = world_obj["block"];
	
	for i=1, #block do
		if rectColision(block[i], {x=x2, y=y2, width=body.width, height=body.height}) then
			ok=false;
			break;
		end
	end
	
	if ok then
		moving_body:translate(unpack(v));
	end
	
	return ok;]]--
end

function clean_obj_arr(arr)
	for i=#arr, 1, -1 do
		display.remove(table.remove(arr, i));
	end
end

function add_spiral_square(par)
	local x = par.x;
	local y = par.y;
	local w = par.w;
	new_spiral_square = display.newGroup();
	new_spiral_square.x = x;
	new_spiral_square.y = y;
	-- display.newCircle(x, y, 5);
	local arr = {{w/2, -w/2}};
	local p = {w/2, -w/2};
	local s = -4;
	local a = math.rad(180);
	local w2 = w;
	local n = 3;
	while w2>0 do
		for i=1, n do
			p = vec_sum(p, vec_mult_num({math.cos(a), math.sin(a)}, w2));
			table.insert(arr, vec_copy(p));
			a=a-math.rad(90);
		end
		w2=w2+s;
		n=2;
	end
	
	local arr2 = {};
	
	for i=1, #arr do
		table.insert(arr2, arr[i][1]);
		table.insert(arr2, arr[i][2]);
	end
	
	new_spiral_square.line = display.newLine(unpack(arr2));
	new_spiral_square.width = w;
	new_spiral_square.height = w;
	new_spiral_square:insert(new_spiral_square.line);
	
	-- display.newRect(x, y, w, w);
	
	return new_spiral_square;
end
_G.add_spiral_square = add_spiral_square;

local next_level_portal;

function set_next_level_portal(par)
	display.remove(next_level_portal);
	next_level_portal = add_spiral_square(par);
	return next_level_portal;
end
_G.set_next_level_portal = set_next_level_portal;

_G.load_lvl = function(n)
	local sys_path = system.pathForFile(system.DocumentsDirectory);
	level_path = sys_path.."/level/"..tostring(n)..".json";
	local file = io.open( level_path, "r" );
	local level_content;
	if file then
		level_content = file:read( "*a" );
		io.close(file);
		level_content = json.decode(level_content);
		for str, val in pairs(world_obj) do
			if level_content[str] == nil then
				level_content[str]={};
			end
			for i=1, #level_content[str] do
				val.init(level_content[str][i]);
			end
		end
		set_next_level_portal(level_content["next_level_portal"]);
		start_pos = level_content["start_pos"];
		if start_pos~=nil then
			hero.x = start_pos.x;
			hero.y = start_pos.y;
		end
	end
end
local load_lvl = _G.load_lvl;


Runtime:addEventListener("key", function(event)
	key_press[event.keyName] = (event.phase == "down");
end);

function mouse_v_event(event)
	if event.type == "down" and hero.dash_n > 0 then
		local dx = event.x-hero.x;
		local dy = event.y-hero.y;
		local d = math.sqrt( dx*dx + dy*dy );
		hero.v = {dx/d, dy/d};
		-- hero.v[1] = math.floor(hero.v[1]*(10^3))/(10^3);
		-- hero.v[2] = math.floor(hero.v[2]*(10^3))/(10^3);
		print("hero.v = { "..(hero.v[1])..", "..(hero.v[2]).." }");
		hero:set_dash_n(hero.dash_n-1);
	end
end

Runtime:addEventListener("enterFrame", function()
	if game.pause then
		return;
	end
	
	if not move(body, hero, vec_mult_num(hero.v, hero.speed)) then
		hero.v={0,0};
		hero:set_dash_n(1);
	end
	
	if next_level_portal then
		if rectColision(hero.body, next_level_portal) then
			for str, val in pairs(world_obj) do
				clean_obj_arr(val);
			end
			_G.saveObj["lvl"] = _G.saveObj["lvl"] + 1;
			_G.saveGame();
			load_lvl(_G.saveObj["lvl"]);
		end
	end
	
	for i=1, #world_obj["danger_rect"] do
		if rectColision(body, world_obj["danger_rect"][i]) then
			hero:death();
		else
			if not move(world_obj["danger_rect"][i], world_obj["danger_rect"][i], world_obj["danger_rect"][i].v) then
				world_obj["danger_rect"][i].v = vec_mult_num(world_obj["danger_rect"][i].v, -1);
			end
		end
	end
	
	for i=1, #world_obj["danger_circle"] do
		world_obj["danger_circle"][i].rotation = world_obj["danger_circle"][i].rotation + 1;
		if circleColision(body, world_obj["danger_circle"][i].body) then
			hero:death();
		end
	end
end);

local main_menu = display.newGroup();
_G.main_menu = main_menu;
main_menu.var = {};
main_menu.choose_n = 1;

function main_menu:set_choose_n(n)
	local text = main_menu.var[main_menu.choose_n].obj;
	text.text = string.sub(text.text, 2, #text.text-1);
	if n<1 then
		n=#main_menu.var;
	elseif n>#main_menu.var then
		n=1;
	end
	main_menu.choose_n = n;
	local new_text = main_menu.var[main_menu.choose_n].obj;
	new_text.text = "<"..new_text.text..">";
end

local start_text = display.newText(main_menu, "<start>", W/2, H/2, "font/PetMe64", 40);
function start()
	game.isVisible = true;
	Runtime:addEventListener("mouse", mouse_v_event);
	load_lvl(_G.saveObj["lvl"]);
end
table.insert(main_menu.var, {obj = start_text, event = start});

local creator_text = display.newText(main_menu, "creator", W/2, H/2+100, "font/PetMe64", 40);
table.insert(main_menu.var, {obj = creator_text, event = creator.creator_start});

function choose_key_event(event)
	if event.phase == "down" then
		if event.keyName == "down" then
			-- main_menu.choose_n = main_menu.choose_n + 1;
			main_menu:set_choose_n(main_menu.choose_n + 1);
		elseif event.keyName == "up" then
			main_menu:set_choose_n(main_menu.choose_n - 1);
		elseif event.keyName == "enter" then
			main_menu.var[main_menu.choose_n].event();
			cleanGroup(main_menu);
			Runtime:removeEventListener("key", choose_key_event);
		end
	end
end;

Runtime:addEventListener("key", choose_key_event);

