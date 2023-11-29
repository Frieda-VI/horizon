local RunService = game:GetService("RunService")
local Enums = {}

Enums.State = {
	["Active"] = 1,
	["Dead"] = 0,
}

Enums.Loop = {
	["BeforePhysics"] = RunService.Stepped,
	["AfterPhysics"] = RunService.Heartbeat,
	["BeforeRender"] = RunService.RenderStepped,
}

Enums["TerminateLoop"] = "END_LOOP_SEQUENCE_WORKFLOW"

return Enums
