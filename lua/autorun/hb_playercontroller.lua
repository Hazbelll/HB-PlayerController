hb_playercontroller = hb_playercontroller or {}

if (SERVER) then
	AddCSLuaFile("hb_playercontroller/cl_init.lua")
	include("hb_playercontroller/sv_init.lua")
elseif (CLIENT) then
	include("hb_playercontroller/cl_init.lua")
end