module(..., package.seeall);

function creator_start()
	local game = _G.game;
	local bg = _G.bg;
	_G.game.pause = true;
	_G.game.isVisible = true;
	_G.game.hero.isVisible = false;
	
	local vec_sum = _G.vec_sum;
	local vec_mult_num = _G.vec_mult_num;
	local vec_equal = _G.vec_equal;
	local vec_copy = _G.vec_copy;
	
	local type_level_name_event_text = display.newText("type file name", 100, 100, "font/PetMe64", 40);
	type_level_name_event_text.anchorX = 0;
	
	local level_name = "";
	
	function edit_level()
		local sys_path = system.pathForFile(system.DocumentsDirectory);
		level_path = sys_path.."/level/"..level_name..".json";
		print("level_path = ", level_path);
		local file = io.open( level_path, "r" );
		local level_content;
		if file then
			level_content = file:read( "*a" );
			io.close(file);
			level_content = json.decode(level_content);
			print(json.encode(level_content["block"][1]));
		end
		
		if level_content == nil then
			level_content={};
		end
		
		local world_obj = _G.world_obj;
		
		for str, val in pairs(world_obj) do
			if level_content[str] == nil then
				level_content[str]={};
			end
			for i=1, #level_content[str] do
				print("level_content[str][i]['x'] = ", level_content[str][i]["x"]);
				val.init(level_content[str][i]);
			end
		end
		
		local editor_pause = false;
		local obj_edit_end_event_pause = false;
		
		local point = {};
		local mouse_editor_event_arr = {};
		
		local obj_edit_event_arr = {};
		
		local key_press = _G.key_press;
		local key_control = _G.key_control;
		
		local obj_edit_gr = newGroup(W/2, H/2);
		
		function add_obj_edit_event(obj, event_type, event)
			table.insert(obj.edit_event_arr, {event_type, event});
			Runtime:addEventListener(event_type, event);
		end
		
		obj_edit_event_arr["move"] = function(obj)
			table.insert(obj.edit_event_arr, {"enterFrame"});
			obj.edit_event_arr[#obj.edit_event_arr][2] = function()
				local v = {0, 0};
				for str, val in pairs(key_control) do
					if key_press[str] then
						v = vec_sum(v, val);
					end
				end
				obj:translate(unpack(v));
			end
			Runtime:addEventListener("enterFrame", obj.edit_event_arr[#obj.edit_event_arr][2]);
		end
		
		obj_edit_event_arr["delete"] = function(obj)
			local val;
			if obj.tag ~= nil then
				val = world_obj[obj.tag];
			end
			if val ~= nil then
				table.remove(val, table.indexOf(val, obj));
			end
			display.remove(obj);
			-- editor_pause = false;
		end
		
		obj_edit_event_arr["rect_size"] = function(obj)
			table.insert(obj.edit_event_arr, {"enterFrame"});
			obj.edit_event_arr[#obj.edit_event_arr][2] = function()
				local v = {0, 0};
				for str, val in pairs(key_control) do
					if key_press[str] then
						v = vec_sum(v, val);
					end
				end
				obj.width = obj.width - obj.strokeWidth + v[1];
				obj.height = obj.height - obj.strokeWidth + v[2];
			end
			Runtime:addEventListener("enterFrame", obj.edit_event_arr[#obj.edit_event_arr][2]);
		end
		
		obj_edit_event_arr["move_vector"] = function(obj)
			table.insert(obj.edit_event_arr, {"enterFrame"});
			obj.edit_event_arr[#obj.edit_event_arr][2] = function()
				local v = {0, 0};
				for str, val in pairs(key_control) do
					if key_press[str] then
						v = vec_sum(v, val);
					end
				end
				obj.v = vec_sum(obj.v, v);
				display.remove(obj.v_display_obj);
				obj.v_display_obj = display.newCircle(obj.x+obj.v[1], obj.y+obj.v[2], 5);
				obj.v_display_obj:setFillColor(0,1,0);
			end
			Runtime:addEventListener("enterFrame", obj.edit_event_arr[#obj.edit_event_arr][2]);
			
			obj.edit_end_event = function()
				display.remove(obj.v_display_obj);
			end
		end
		
		obj_edit_event_arr["circle_size"] = function(obj)
			table.insert(obj.edit_event_arr, {"enterFrame"});
			obj.edit_event_arr[#obj.edit_event_arr][2] = function()
				local v = 0;
				if key_press["up"] then
					v=v+1;
				end
				if key_press["down"] then
					v=v-1;
				end
				obj.width=obj.width+v;
				obj.height=obj.height+v;
			end
			Runtime:addEventListener("enterFrame", obj.edit_event_arr[#obj.edit_event_arr][2]);
		end
		
		obj_edit_event_arr["set_image"] = function(obj)
			local w = obj.body.width;
			display.remove(obj.body);
			local danger_circle_img_arr = {"ball", "saw"};
			local h_s = 42;
			for i=1, #danger_circle_img_arr do
				local btn = newGroup(0, h_s*obj_edit_gr.numChildren, obj_edit_gr);
				local rect = display.newRect(btn, 0, 0, 40, 40);
				local text = display.newText(btn, danger_circle_img_arr[i], 0, 0, "font/PetMe64", 20);
				rect.width = text.width + 4;
				text:setFillColor(0);
				btn:addEventListener("mouse", function(event)
					if event.type == "down" then
						obj.body = display.newImageRect(obj, "image/danger/"..danger_circle_img_arr[i]..".png", w, w);
						cleanGroup(obj_edit_gr);
					end
				end);
			end
		end
		
		obj_edit_event_arr["set_line"] = function(obj)
			obj_edit_gr.x = 0;
			obj_edit_gr.y = 0;
			obj_edit_end_event_pause=true;
			-- local event_pause=false;
			
			--[[local function add_input_event(par)
				local text = par.text;
				if text.input_event then
					Runtime:removeEventListener("key", text.input_event);
				end
				local enter_event = par.enter_event;
				local left_len = par.left_len;
				if left_len==nil then
					left_len=0;
				end
				text.input_event = function(event)
					if event.phase == "down" then
						if event.keyName == "enter" then
							Runtime:removeEventListener("key", text.input_event);
							if enter_event~=nil then
								enter_event();
							end
						elseif event.keyName == "deleteBack" then
							if left_len<#text.text then
								text.text = string.sub(text.text, 1, #text.text-1);
							end
						else
							if #event.keyName == 1 then
								local key_char = event.keyName;
								if key_press["leftShift"] or key_press["rightShift"] then
									key_char = string.upper(key_char);
								end
								text.text = text.text..key_char;
							end
						end
					end
				end
				Runtime:addEventListener("key", text.input_event);
			end]]--
			
			local function add_btn(par)
				local x = par.x;
				local y = par.y;
				local text = par.text;
				local parent = par.parent;
				local tap_event = par.tap_event;
				local btn = newGroup(x, y, parent);
				btn.rect = display.newRect(btn, 0, 0, 40, 40);
				btn.text = display.newText(btn, text, 0, 0, "font/PetMe64", 20);
				btn.text:setFillColor(0);
				btn.rect.width = btn.text.width;
				if tap_event ~= nil then
					btn.tap_event = function(event)
						if event.type == "down" then
							tap_event();
						end
					end
					btn:addEventListener("mouse", btn.tap_event);
				end
				return btn;
			end
			
			local function show_obj_arr(par) -- par = {arr, parent, x, y};
				local arr = par.arr;
				local parent = par.parent;
				local x = par.x;
				local y = par.y;
				local chose_event = par.chose_event;
				local enter_event = par.enter_event;
				
				local chosen_btn = nil;
				local function chose_btn(btn)
					if chosen_btn ~= nil then
						chosen_btn.rect:setStrokeColor(0);
						chosen_btn.text.text = chosen_btn.str.."="..tostring(arr[chosen_btn.i][chosen_btn.str]);
					end
					chosen_btn=btn;
					if btn~=nil then
						chosen_btn.rect:setStrokeColor(1,1,0);
					end
					if chose_event ~= nil then
						chose_event();
					end
				end
				
				local gr = newGroup(x, y, parent);
				for i=1, #arr do
					local obj_gr = newGroup(0, 40*i, gr);
					local j=1;
					for str, val in pairs(arr[i]) do
						local btn = add_btn({ x=0, y=0, parent=obj_gr, text=str.."="..tostring(val), tap_event=nil });
						if j>1 then
							btn.x = obj_gr[j-1].x+obj_gr[j-1].width/2+4+btn.width/2;
						end
						btn.rect.strokeWidth=2;
						btn.rect:setStrokeColor(0);
						btn.i=i;
						btn.str=str;
						btn.tap_event = function(event)
							if event.type == "down" then
								chose_btn(btn);
							end
						end
						btn:addEventListener("mouse", btn.tap_event);
						j=j+1;
					end
				end
				gr.type_event = function(event)
					if event.phase == "down" and chosen_btn ~= nil then
						if event.keyName == "enter" then
							local res = tonumber( string.sub(chosen_btn.text.text, #chosen_btn.str+2, #chosen_btn.text.text) );
							if res~=nil then
								arr[chosen_btn.i][chosen_btn.str] = tonumber( string.sub(chosen_btn.text.text, #chosen_btn.str+2, #chosen_btn.text.text) );
							end
							if enter_event ~= nil then
								enter_event();
							end
							chose_btn(nil);
						elseif event.keyName == "deleteBack" then
							if #chosen_btn.text.text>#chosen_btn.str+1 then
								chosen_btn.text.text = string.sub(chosen_btn.text.text, 1, #chosen_btn.text.text-1);
							end
						elseif #event.keyName==1 then
							chosen_btn.text.text = chosen_btn.text.text..event.keyName;
						end
					end
				end
				Runtime:addEventListener("key", gr.type_event);
				
				return gr;
			end
			
			--[[local function add_input_btn(par)
				local x = par.x;
				local y = par.y;
				local text = par.text;
				local parent = par.parent;
				local tap_event = par.tap_event;
				local enter_event = par.enter_event;
				local left_len = par.left_len;
				local btn = add_btn({ x=x, y=y, parent=parent, text=text });
				btn:addEventListener("mouse", function(event)
					if event.type == "down" then
						if tap_event~=nil then
							tap_event();
						end
						add_input_event({ text=btn.text, enter_event=enter_event, left_len=left_len });
					end
				end);
				return btn;
			end]]--
			
			local line = obj.line or { {x = obj.x, y = obj.y, t = 60} };
			
			local line_obj;
			local line_gr = newGroup(0, 0, obj_edit_gr);
			
			local line_edit_gr;
			
			function line_gr.refresh()
				cleanGroup(line_gr);
				local ver={};
				for i=1, #line do
					table.insert(ver, line[i].x);
					table.insert(ver, line[i].y);
					display.newCircle(line_gr, line[i].x, line[i].y, 5);
				end
				line_obj = display.newLine(unpack(ver));
				line_gr:insert(line_obj);
				if line_edit_gr ~= nil then
					Runtime:removeEventListener("key", line_edit_gr.type_event);
					display.remove(line_edit_gr);
					line_edit_gr = show_obj_arr({ arr=line, parent=obj_edit_gr, x=W-500, y=100, enter_event=line_gr.refresh });
				end
			end
			
			line_edit_gr = show_obj_arr({ arr=line, parent=obj_edit_gr, x=W-500, y=100, enter_event=line_gr.refresh });
			
			add_obj_edit_event(obj, "mouse", function(event)
				if event.type == "down" then
					local ok = true;
					if line_edit_gr~=nil then
						for i=1, line_edit_gr.numChildren do
							for j=1, line_edit_gr[i].numChildren do
								local rect=line_edit_gr[i][j].rect;
								local rect_pos = _G.absPos(rect);
								local rect_x = rect_pos[1];
								local rect_y = rect_pos[2];
								if rect.width>=math.abs(rect_x-event.x) and rect.height>=math.abs(rect_y-event.y) then
									ok=false;
									break;
								end
							end
						end
					end
					if ok then
						table.insert(line, {x = event.x, y = event.y, t = 60});
						line_gr.refresh();
					end
				end
			end);
		end
		
		local obj_edit_arr = {};
		obj_edit_arr["block"] = {"move", "rect_size", "delete"};
		obj_edit_arr["danger_rect"] = {"move", "rect_size", "move_vector", "delete"};
		obj_edit_arr["danger_circle"] = {"move", "circle_size", "delete", "set_image", "set_line"};
		-- obj_edit_arr["next_level_portal"] = {"move", "delete"};
		obj_edit_arr["start_pos"] = {"move"};
		
		mouse_editor_event_arr["block"] = function(event)
			if event.type == "down" then
				point[1] = {x = event.x, y = event.y};
				world_obj["block"].init({x = event.x, y = event.y, width = 1, height = 1});
			elseif event.type == "drag" then
				point[2] = {x = event.x, y = event.y};
				display.remove(table.remove(world_obj["block"], #world_obj["block"]));
				local dx = point[2].x-point[1].x;
				local dy = point[2].y-point[1].y;
				world_obj["block"].init({x = point[1].x+dx/2, y = point[1].y+dy/2, width = math.abs(dx), height = math.abs(dy)});
			elseif event.type == "up" then
				-- display.newText("Hi", W/2, H/2, nil, 20);
				point={};
				
				world_obj["block"][#world_obj["block"]].tag = "block";
				
				return world_obj["block"][#world_obj["block"]];
			end
		end
		mouse_editor_event_arr["danger_rect"] = function(event)
			if event.type == "down" then
				point[1] = {x = event.x, y = event.y};
				world_obj["danger_rect"].init({x = event.x, y = event.y, width = 1, height = 1});
			elseif event.type == "drag" then
				point[2] = {x = event.x, y = event.y};
				display.remove(table.remove(world_obj["danger_rect"], #world_obj["danger_rect"]));
				local dx = point[2].x-point[1].x;
				local dy = point[2].y-point[1].y;
				world_obj["danger_rect"].init({x = point[1].x+dx/2, y = point[1].y+dy/2, width = math.abs(dx), height = math.abs(dy)});
			elseif event.type == "up" then
				-- display.newText("Hi", W/2, H/2, nil, 20);
				point={};
				
				world_obj["danger_rect"][#world_obj["danger_rect"]].tag = "danger_rect";
				
				return world_obj["danger_rect"][#world_obj["danger_rect"]];
			end
		end
		mouse_editor_event_arr["danger_circle"] = function(event)
			if event.type == "down" then
				point[1] = {x = event.x, y = event.y};
				world_obj["danger_circle"].init({x = event.x, y = event.y, width = 1});
			elseif event.type == "drag" then
				point[2] = {x = event.x, y = event.y};
				display.remove(table.remove(world_obj["danger_circle"], #world_obj["danger_circle"]));
				local dx = point[2].x-point[1].x;
				local dy = point[2].y-point[1].y;
				world_obj["danger_circle"].init({x = point[1].x, y = point[1].y, width = math.sqrt(dx*dx + dy*dy)*2});
			elseif event.type == "up" then
				-- display.newText("Hi", W/2, H/2, nil, 20);
				point={};
				
				world_obj["danger_circle"][#world_obj["danger_circle"]].tag = "danger_circle";
				
				return world_obj["danger_circle"][#world_obj["danger_circle"]];
			end
		end
		local next_level_portal = {x = W/2+100, y = H/2+100, w = 50};
		mouse_editor_event_arr["next_level_portal"] = function(event)
			if event.type == "down" then
				point[1] = {x = event.x, y = event.y};
				next_level_portal = {x = event.x, y = event.y, w = 1};
				local obj = _G.set_next_level_portal(next_level_portal);
			elseif event.type == "drag" then
				point[2] = {x = event.x, y = event.y};
				local dx = point[2].x-point[1].x;
				local dy = point[2].y-point[1].y;
				next_level_portal = {x = event.x - dx/2, y = event.y - dy/2, w = math.max(math.abs(dx), math.abs(dy))};
				_G.set_next_level_portal(next_level_portal);
			elseif event.type == "up" then
				-- display.newText("Hi", W/2, H/2, nil, 20);
				point={};
				
				local obj = _G.set_next_level_portal(next_level_portal);
				-- obj.tag = "next_level_portal";
				
				return obj;
			end
		end
		local start_pos = {x = W/2, y = H/2};
		local start_pos_obj;
		mouse_editor_event_arr["start_pos"] = function(event)
			if event.type == "down" then
				start_pos = {x = event.x, y = event.y};
				display.remove(start_pos_obj);
				start_pos_obj = display.newRect(start_pos.x, start_pos.y, _G.game.hero.body.width, _G.game.hero.body.height);
				start_pos_obj:setFillColor(1,1,0);
			end
			-- start_pos_obj.tag = "start_pos";
			return start_pos_obj;
		end
		local mouse_editor_event = mouse_editor_event_arr["block"];
		
		local btn_w = 50;
		local ico_w = btn_w/2;
		local btn_step = 10;
		
		local newGroup = _G.newGroup;
		
		local btn_gr = newGroup(50, 50);
		
		function add_btn(ico_img, event)
			local btn = newGroup((btn_w+btn_step)*btn_gr.numChildren, 0, btn_gr);
			local rect = display.newRect(btn, 0, 0, btn_w, btn_w);
			local ico = display.newImageRect(btn, "image/creator/"..ico_img..".png", ico_w, ico_w);
			
			btn:addEventListener("mouse", function(e)
				if e.type == "down" then
					mouse_editor_event = event;
					return;
				end
			end);
			
			return btn;
		end
		
		-- add_btn("block", mouse_editor_event_arr["block"]);
		
		for str, val in pairs(mouse_editor_event_arr) do
			add_btn(str, val);
		end
		
		function show_obj_edit_menu(obj)
			editor_pause = true;
			
			obj_edit_gr.x = obj.x;
			obj_edit_gr.y = obj.y;
			
			-- local I;
			-- for str, val in pairs(mouse_editor_event_arr) do
				-- if mouse_editor_event == val then
					-- I=str;
					-- break;
				-- end
			-- end
			-- print("OMG str = ", I);
			
			local event_str_arr = obj_edit_arr[obj.tag];
			local event_arr = {};
			for i=1, #event_str_arr do
				table.insert(event_arr, obj_edit_event_arr[event_str_arr[i]]);
			end
			
			local h = 20;
			local ys = 5;
			
			print("#event_arr = ", #event_arr);
			
			for i=1, #event_arr do
				local str = event_str_arr[i];
				print("OMG str = ", str);
				local event = event_arr[i];
				
				local btn = newGroup(0, (i-1)*(h+ys), obj_edit_gr);
				local rect = display.newRect(btn, 0, 0, 0, h);
				rect.strokeWidth = 2;
				rect:setStrokeColor(0);
				local text = display.newText(btn, str, 0, 0, "font/PetMe64", 20);
				-- text.fill.color = {r = 0, g = 0, b = 0, a = 1};
				text:setFillColor(0);
				rect.width = text.width+10;
				
				btn:addEventListener("mouse", function(e)
					if e.type == "down" then
						_G.cleanGroup(obj_edit_gr);
						event(obj);
					end
				end);
			end
		end
		
		function obj_edit_arr_event_init(obj)
			obj:addEventListener("mouse", function(event)
				if event.isSecondaryButtonDown and event.type == "down" and not editor_pause then
					show_obj_edit_menu(obj);
					obj.strokeWidth = 2;
					-- obj:setStrokeColor(1,1,0);
					obj.edit_event_arr = {};
					table.insert(obj.edit_event_arr, {"key"});
					obj.edit_event_arr[#obj.edit_event_arr][2] = function(event)
						if event.phase == "down" and event.keyName == "enter" and not obj_edit_end_event_pause then
							_G.cleanGroup(obj_edit_gr);
							editor_pause = false;
							obj.strokeWidth = 0;
							for i=1, #obj.edit_event_arr do
								Runtime:removeEventListener(obj.edit_event_arr[i][1], obj.edit_event_arr[i][2]);
							end
							if obj.edit_end_event then
								obj.edit_end_event();
							end
						end
					end
					Runtime:addEventListener("key", obj.edit_event_arr[#obj.edit_event_arr][2]);
					return;
				end
			end);
		end
		
		Runtime:addEventListener("mouse", function(event)
			if not editor_pause then
				if event.isPrimaryButtonDown then -- event.isSecondaryButtonDown
					mouse_editor_event(event);
				elseif not event.isSecondaryButtonDown and event.type == "up" then
					-- display.newText("hi", W/2, H/2, nil, 40);
					local obj = mouse_editor_event(event);
					if obj.tag ~= nil then
						obj_edit_arr_event_init(obj);
					end
				end
			end
		end);
		
		for str, val in pairs(world_obj) do
			for i=1, #val do
				val[i].tag = str;
				obj_edit_arr_event_init(val[i]);
			end
		end
		
		Runtime:addEventListener("key", function(event)
			if event.phase == "down" then
				if event.keyName == "s" then
					if key_press["leftCtrl"] or key_press["rightCtrl"] or key_press["leftControl"] or key_press["rightControl"] then
						local file = io.open( level_path, "w" );
						local arr = {};
						-- local block_arr = world_obj["block"];
						-- for i=1, #block_arr do
							-- arr[i] = {x = block_arr[i].x, y = block_arr[i].y, width = block_arr[i].width, height = block_arr[i].height};
						-- end
						for str, val in pairs(world_obj) do
							-- print("STR = ", str)
							arr[str]={};
							for i=1, #val do
								print("val.field unpack = ", unpack(val.field));
								table.insert(arr[str], _G.field_obj(val[i], val.field));
							end
						end
						arr["next_level_portal"] = next_level_portal;
						arr["start_pos"] = start_pos;
						file:write(json.encode(arr));
						print("json.encode(arr) = ", json.encode(arr));
						file:close();
					end
				end
			end
		end);
	end
	
	function level_name_refresh(str)
		type_level_name_event_text.text = str;
		level_name = str;
	end
	
	local shift_press = false;
	
	function type_level_name_event(event)
		if event.phase == "down" then
			if event.keyName == "enter" then
				Runtime:removeEventListener("key", type_level_name_event);
				edit_level();
			elseif event.keyName == "deleteBack" then
				level_name_refresh(string.sub(level_name, 1, #level_name-1));
			elseif event.keyName == "leftShift" or event.keyName == "rightShift" then
				shift_press = true;
			else
				if #event.keyName == 1 then
					local key_char = event.keyName;
					if shift_press then
						key_char = string.upper(key_char);
					end
					level_name_refresh(level_name..key_char);
				end
			end
		else
			if event.keyName == "leftShift" or event.keyName == "rightShift" then
				shift_press = false;
			end
		end
	end
	
	Runtime:addEventListener("key", type_level_name_event);
end