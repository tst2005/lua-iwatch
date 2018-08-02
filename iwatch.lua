#! /usr/bin/env lua

local targetdir = assert( arg[1], "Usage: iwatch.lua <directory> <file>")
local targetfile = assert( arg[2], "Usage: iwatch.lua <directory> <filepattern>")
local runcmdargs = table.concat(arg, " ", 3)

local inotify = require 'inotify'
local handle = inotify.init()

-- Watch for new files and renames
local wd = handle:addwatch(targetdir, inotify.IN_CREATE, inotify.IN_MOVE)

local hashes = {}

local function doaction(name)
	local fd = io.popen("test -f "..name.." && md5sum "..name, "r")
	local hash = fd:read("*a"):gsub("\n$","")
	fd:close()
	if hash ~= "" then
		if hashes[name] ~= nil and hashes[name] == hash then
			io.stderr:write("\n# running: "..runcmdargs.."\n")
			local fd = io.popen(runcmdargs, "r")
			while true do
				local line = fd:read("*l")
				if not line then break end
				print(line)
			end
			fd:close()
			io.stderr:write("# ended\n")
		else
			--print("hash["..name.."]="..hash)
			hashes[name]=hash
		end
	end
end

for ev in handle:events() do
	if string.find(ev.name, targetfile) then
		--print(ev.name .. ' was created or renamed')
		doaction(ev.name)
	end
end

-- Done automatically on close, I think, but kept to be thorough
handle:rmwatch(wd)

handle:close()
