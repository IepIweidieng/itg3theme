imp = {};

function imp.getn(Table)
	return type(Table) == "table" and
		(function() local n = 0; for i, v in pairs(Table) do n = math.max(tonumber(i) or 0, n); end return n; end)() or
		0;
end

function imp.getSize(Table)
	return type(Table) == "table" and
		(function() local n = 0; for i, v in pairs(Table) do n = n+1; end return n; end)() or
		0;
end

do
	local function _body_r(internalArgTail, internalExp, getnArg, argTail)
		return "\
			local function _internal(res, index, "..internalArgTail..")\
				res[index] = "..internalExp..";\
				if imp.getn"..getnArg.." == 0 then\
					res.n = index;\
					return res;\
				end\
				return _internal(res, index+1, "..argTail..");\
			end\
\
			return function(value, ...)\
				if imp.getn"..getnArg.." == 0 then return value == nil and {n=0} or {value; n=1}; end\
				return _internal({value; n=2}, 2, "..argTail..");\
			end;";
	end

	local _loadStr = loadstring or load;
	imp.pack = _loadStr("return {n = imp.getn{...}; ...};") or (function(...) return arg; end);
	imp.pack_c = table.pack or imp.pack;
	imp.pack_r = (_loadStr(_body_r("value, ...", "value", "{...}", "...")) or
		_loadStr(_body_r("arg", "table.remove(arg, 1)", "(arg)", "arg")))();
end

imp.unpack_c = table.unpack or function(Table)
	Table.n = imp.getn(Table);
	return unpack(Table);
end

do
	local function _internal(index, Table)
		if index == n then return Table[index]; end
		return Table[index], _internal(index+1, Table);
	end

	function imp.unpack_r(Table)
		local n = imp.getn(Table);

		if n == 0 then return; end
		if n == 1 then return Table[1]; end
		return Table[1], _internal(2, Table);
	end
end

do
	local allow_G;

	local function print_r_internal(arr, depth, meta, indentLevel)
		local str = "("..type(arr)..") "..tostring(arr);
		local depth = depth or -1;
		local indentLevel = indentLevel or 0;

		local skip = (depth == 0) or (arr == _G and not allow_G);
		allow_G = false;

		local indentStr = "    ";
		for i = 1, indentLevel do
			indentStr = "    "..indentStr;
		end

		if type(arr) == "table" then
			str = str.." Size: "..imp.getSize(arr)..(skip and "" or ":");
		end

		if not skip then
			if meta then
				local arrMeta = getmetatable(arr);
				if arrMeta then
					str = str..(type(arr) == "table" and "" or ":").."\n"..indentStr.."Metatable: "..print_r_internal(arrMeta, (depth - 1), meta, (indentLevel + 1));
				end
			end

			if type(arr) == "table" then
				for index, value in pairs(arr) do
					str = str.."\n"..indentStr.."("..type(index)..") "..tostring(index)..": "..print_r_internal(value, (depth - 1), meta, (indentLevel + 1));
				end
			end
		end

		return str;
	end

	function imp.print_r(arr, depth, meta, indentLevel)
		allow_G = true;
		return print_r_internal(arr, depth, meta, indentLevel);
	end
end

function imp.print_actor_r(actorFrame, depth, indentLevel)
	local str = "("..type(arr)..") "..tostring(actorFrame);
	local depth = depth or -1;
	local indentLevel = indentLevel or 0;

	local skip = actorFrame.GetChildren == nil or depth == 0;

	local indentStr = "    ";
	for i = 1, indentLevel do
		indentStr = "    "..indentStr;
	end

	if type(arr) == "table" then
		str = str.." Size: "..actorFrame:GetNumChildren();
	end

	if not skip then
		str = str..":";
		for key, value in pairs(actorFrame:GetChildren()) do
			if value.GetName == "function" then
				str = str.."\n"..indentStr..tostring(key)..": "..imp.print_actor_r(value, (depth - 1), (indentLevel + 1));
			else
				-- When value is an ordinary array
				for index, actor in pairs(value) do
					str = str.."\n"..indentStr..tostring(key).." ("..tostring(index).."): "..imp.print_actor_r(actor, (depth - 1), (indentLevel + 1));
				end
			end
		end
	end

	return str;
end

do
	local function copy_internal(object)
		if type(object) ~= "table" then
			return object;
		elseif lookupTable[object] then
			return lookupTable[object];
		end

		local copiedTable = {};
		lookupTable[object] = copiedTable;

		for index, value in pairs(object) do
			copiedTable[copy_internal(index)] = copy_internal(value);
		end
		return setmetatable(copiedTable, getmetatable(object));
	end

	function imp.copy(object)
		local lookupTable = {};
		return copy_internal(object);
	end
end


function imp.getSortedTable(Table)
	local copiedTable = imp.copy(Table);
	table.sort(copiedTable, function(lhs, rhs) return tostring(lhs)<tostring(rhs); end);
	return copiedTable;
end

function imp.P(Function)
	return function(...)
		local ErrorOutput = {pcall(Function, imp.unpack_c(arg))};
		if ErrorOutput[1] then
			table.remove(ErrorOutput, 1);
			return imp.unpack_c(ErrorOutput);
		else
			if SCREENMAN:GetTopScreen().PauseGame then
				SCREENMAN:GetTopScreen():PauseGame(true);
			end
			SCREENMAN:SystemMessage("Error occured in "..imp.print_r(arg[1])..":\n"..tostring(ErrorOutput[2]));
			return;
		end
	end
end

