local modes, labels, data, FILE_PATH, env = ...
local lang

if data.lang ~= "cn" then
	local tmp = FILE_PATH .. "lang_" .. data.lang .. ".luac"
	local fh = io.open(tmp)
	if fh ~= nil then
		io.close(fh)
		lang = loadScript(tmp, env)(modes, labels)
		collectgarbage()
	end
end

if data.voice ~= "cn" then
	local fh = io.open(FILE_PATH .. data.voice .. "/on.wav")
	if fh ~= nil then
		io.close(fh)
	else
		data.voice = "cn"
	end
end

return lang
