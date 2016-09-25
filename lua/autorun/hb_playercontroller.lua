hb_playercontroller = hb_playercontroller or {}

if GAME_DLL then
	AddCSLuaFile("hb_playercontroller/cl_init.lua")
	include("hb_playercontroller/sv_init.lua")
elseif CLIENT_DLL then
	include("hb_playercontroller/cl_init.lua")
end
