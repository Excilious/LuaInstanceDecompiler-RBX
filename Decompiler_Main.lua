

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StatsService = game:GetService("Stats")
local RunService = game:GetService("RunService")

local StartDecompile = tick()
local DecompSys = {}
local Connection

DecompSys.MainContainer = Instance.new("Model")
DecompSys.MainContainer.Name = "MM2Decomp"

--Available Services
DecompSys.Services = {
	"ReplicatedStorage",
	"ReplicatedFirst",
	"Workspace",
	"Players",
	"Lighting",
	"StarterCharacter"
	"StarterGui",
	"StarterPack",
	"Chat"
	"ServerScriptService"
}

DecompSys.ModelCreator = function()
	--[[
		We should start with a neat and orginised folder 
		including all instances of a game.
	]]
	for Index,Names in ipairs(DecompSys.Services) do
		local FolderInstance = Instance.new("Folder")
		FolderInstance.Name = Names
		FolderInstance.Parent = DecompSys.MainContainer
	end

	--Need to create sub-folders for startercharacter
	local FolderInstance = Instance.new("Folder")
	FolderInstance.Name = "StarterCharacterScripts"
	FolderInstance.Parent = DecompSys.MainContainer.StarterCharacter
	--And another one...
	FolderInstance = Instance.new("Folder")
	FolderInstance.Name = "StarterPlayerScripts"
	FolderInstance.Parent = DecompSys.MainContainer.StarterCharacter
end

DecompSys.NewInstance = function(ClassName,Object)
    NewInstance = Instance.new(ClassName)
    NewInstance.Name = Object.Name
    --[[We wont bother to add values to instances, 
	these can lead to errors (eg. remoteevents or remotefunctions)
	]]--
	for Attribute,Value in pairs(Object:GetAttributes()) do
		NewInstance[Attribute] = Value
	end
	if (Object:IsA("LocalScript") or Object:IsA("Script") or Object:IsA("ModuleScript")) then
		DecompSys.DecompileScripts(Object.ClassName,Object)
	end
    return NewInstance
end

DecompSys.GetSyncData = function()
    --[[
        GetSyncData would be a remote function used to call server modules to client.
        Newer versions of the game would not require modulenames as a parameter but instead would
        return all the available modules with the data
    ]]
    local AllModules = ReplicatedStorage:WaitForChild("GetSyncData",2):InvokeServer()
    assert(AllModules == nil, "GetSyncData cannot be found or Server didnt respond")
	for Index,Name in pairs(AllModules) do
		local CurrentServerData = ReplicatedStorage:WaitForChild("GetSyncData",2):InvokeServer(Name)
		local ModuleScripts = Instance.new("ModuleScript",DecompSys.MainContainer.ServerScriptService)
		Modulescript.Source = CurrentServerData
		Modulescript.Name = Name
	end
end

DecompSys.DecompileScripts = function(Script)
	local WasDisabled = false
	local TextContainer = nil
	if not (Script.Enabled) then
		Script.Enabled = true
		WasDisabled = true
	end
	TextContainer = Script.Source()
	Script.Enabled = not WasDisabled
	return TextContainer
end

DecompSys.ReportProgress = function(Report)
	print("[Decompiler] - "..tostring(Report))
end

DecompSys.Hardlag = function()
	if (Stats.InstanceCount > 100) then
		--We would need to pause the operation temporarily as there is too much instances being rendered in memory
		task.wait(10)
	end
end

DecompSys.DecompileAll = {
	Workspace = function()
		for Index,Object in pairs(game.ReplicatedStorage:GetDecendants()) do
			local NewInstance = DecompSys.NewInstance(Object.ClassName,Object)
			NewInstance.Parent = DecompSys.MainContainer.ReplicatedStorage
		end
	end,
	Players = function()
		--Cannot decompile players :(
		return nil
	end,
	ReplicatedFirst = function()
		for Index,Object in pairs(game.ReplicatedFirst:GetDecendants()) do
			local NewInstance = DecompSys.NewInstance(Object.ClassName,Object)
			NewInstance.Parent = DecompSys.MainContainer.ReplicatedFirst
		end
	end,
	ReplicatedStorage = function()
		for Index,Object in pairs(game.ReplicatedStorage:GetDecendants()) do
			local NewInstance = DecompSys.NewInstance(Object.ClassName,Object)
			NewInstance.Parent = DecompSys.MainContainer.ReplicatedStorage
		end
	end,
	ServerScriptService = function()
		--Cannot decompile Serverscriptservice. We can only decompile client viewed properties
		return nil
	end,
	ServerStorage = function()
		--Again, wish we could but would need to only get client scripts
		return nil
	end,
	StarterGui = function()
		for Index,Object in pairs(game.StarterGui:GetDecendants()) do
			local NewInstance = DecompSys.NewInstance(Object.ClassName,Object)
			NewInstance.Parent = DecompSys.MainContainer.StarterGui
		end
	end, 
	StarterPack = function()
		for Index,Object in pairs(game.StarterPack:GetDecendants()) do
			local NewInstance = DecompSys.NewInstance(Object.ClassName,Object)
			NewInstance.Parent = DecompSys.MainContainer.StarterPack
		end
	end, 
	StarterCharacter = function()
		--This would be different, starterpack and startercharacter are within one parent
		for Index,Object in pairs(game.StarterCharacter.StarterCharacterScripts:GetDecendants()) do
			local NewInstance = DecompSys.NewInstance(Object.ClassName,Object)
			NewInstance.Parent = DecompSys.MainContainer.StarterCharacter.StarterCharacterScripts
		end
		for Index,Object in pairs(game.StarterCharacter.StarterPlayerScripts:GetDecendants()) do
			local NewInstance = DecompSys.NewInstance(Object.ClassName,Object)
			NewInstance.Parent = DecompSys.MainContainer.StarterCharacter.StarterPlayerScripts
		end
	end, 
	Chat = function()
		for Index,Object in pairs(game.Chat:GetDecendants()) do
			local NewInstance = DecompSys.NewInstance(Object.ClassName,Object)
			NewInstance.Parent = DecompSys.MainContainer.Chat
		end
	end, 
}

DecompSys.Run = function()
	task.spawn(function()
		DecompSys.ModelCreator()
		DecompSys.GetSyncData()
		DecompSys.DecompileAll()
	end)
	DecompSys.ReportProgress("Starting to decompile...")
	local Connection = RunService.Heartbeat:Connect(DecompSys.Hardlag)
end

local FinishDecompile = tick()
SaveInstance(DecompSys.MainContainer.Name .. '.rbxl', DecompSys.MainContainer)
DecompSys.ReportProgress("Finished decompiling! Saved in Workspace as "..tostring(DecompSys.MainContainer.Name)..".rbxl. Took "..tostring((FinishDecompile - StartDecompile)).."s")
Connection:Disconnect()

