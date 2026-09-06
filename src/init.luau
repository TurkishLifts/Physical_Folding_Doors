--[[
    Physical_Folding_Doors by TurkishLifts

        VERSION: v1.0.3,  DATE: 6/09/2026
]]--

--!nocheck

local module = {}

local APIConnection = nil

function module.init(controller : {})
    local FoldingDoorsContainer = {}

    if APIConnection then
        APIConnection:Disconnect()
    end

    local API : BindableEvent = controller.API
    local Car : Model = controller.Car
    local Platform: BasePart = controller.Platform

    local FoldingDoor = require(script.Classes.FoldingDoor)
    local sift = require(script.Dependencies.sift)

    local Config = require(script.Config)

    local function WeldEm(Model : Model, Weld : boolean)
        for _,DoorPart in ipairs(Model:GetDescendants()) do
            if not DoorPart:IsA("BasePart") then continue end
            if DoorPart.Parent.Name:sub(1,1) ~= "D" then continue end
            if Weld == true then
                local w : WeldConstraint = DoorPart:FindFirstChildOfClass("WeldConstraint")
                if not w then
                    local nw = Instance.new("WeldConstraint")
                    nw.Parent = DoorPart
                    w = nw
                end
                w.Part0 = DoorPart
                w.Part1 = Platform
                DoorPart.Anchored = false
            else
                local w : WeldConstraint = DoorPart:FindFirstChildOfClass("WeldConstraint")
                if w then
                    w:Destroy()
                end
            end
        end
    end

    for _,CarComponent in ipairs(Car:GetChildren()) do
        if string.lower(CarComponent.Name:sub(-13)) == "folding_doors" then
            local SideName = (string.lower(CarComponent.Name):gsub("folding_doors", ""))
            local Side

            if SideName == "" then
                Side = "front"
            else 
                Side = SideName:sub(1, -2)
            end

            if FoldingDoorsContainer[Side] then continue end

            local DoorObj = FoldingDoor.new({
                Config = sift.Dictionary.merge(Config, Config.CustomSideConfig[Side]),
                DoorModel = CarComponent
            })

            FoldingDoorsContainer[Side] = DoorObj

            for _,DoorPart in ipairs(CarComponent:GetDescendants()) do
                if not DoorPart:IsA("BasePart") then continue end
                if DoorPart.Parent.Name:sub(1,1) == "D" then continue end
                local w = Instance.new("WeldConstraint")
                w.Parent = DoorPart
                w.Part0 = DoorPart
                w.Part1 = Platform
                DoorPart.Anchored = false
            end

            WeldEm(CarComponent, true)
        end
    end
    
    local function CheckTolerance(Hinge: HingeConstraint, TargetCloseAngle : number, Tolerance : number)
        if not Hinge:IsA("HingeConstraint") then return false end

        if Hinge.CurrentAngle <= TargetCloseAngle + Tolerance and Hinge.CurrentAngle >= TargetCloseAngle - Tolerance then
            return true
        end

        return false
    end

    local function HandleDoor(FoldingDoor, protocol, params)
        local LocalConfig = FoldingDoor.Config
        local OpenDelay = LocalConfig.OpenDelay or 1
 
        if protocol == "on_door_close" then
            FoldingDoor:Close()
            local ToleranceDelay = LocalConfig.ToleranceDelay or .5
            task.delay(LocalConfig.CloseTime+ToleranceDelay, function()
                local CloseTolerance = LocalConfig.CloseTolerance or 5

                local LTOPclosed = CheckTolerance(FoldingDoor.LTOP,LocalConfig.CloseAngle,CloseTolerance)
                local RTOPclosed = CheckTolerance(FoldingDoor.RTOP,LocalConfig.CloseAngle,CloseTolerance)

                local L1closed = CheckTolerance(FoldingDoor.HingeL1, LocalConfig.CloseAngle ,CloseTolerance)
                local R1closed = CheckTolerance(FoldingDoor.HingeR1, LocalConfig.CloseAngle ,CloseTolerance)

                if not LTOPclosed or not RTOPclosed or not L1closed or not R1closed then
                    FoldingDoor:Open()
                    API:Fire('door_signal', {
                        sides = 'all', 
                        request = 'open' 
                    })
                else
                    WeldEm(FoldingDoor.DoorModel,true)
                end
            end)
        elseif protocol == "on_door_open" then
            task.wait(OpenDelay)
            WeldEm(FoldingDoor.DoorModel,false)
            FoldingDoor:Open()
            API:Fire('door_signal', {
                sides = 'all', 
                request = 'open' 
            })
        elseif protocol == "on_door_closed" then
            WeldEm(FoldingDoor.DoorModel,true)
        end
    end

    APIConnection = API.Event:Connect(function(protocol, params)
        if protocol:sub(1,7) ~= "on_door" then return end

        local Side = params.side or "front"
        Side = string.lower(Side)

        local FoldingDoor = FoldingDoorsContainer[Side]

        if not FoldingDoor and Side ~= "all" then warn(`Folding Door not found for side: {Side}!`); return end

        if Side == "all" then
            for _,Door in pairs(FoldingDoorsContainer) do
                HandleDoor(Door, protocol, params)
            end
        else
            HandleDoor(FoldingDoor, protocol, params)
        end
    end)
end

return module