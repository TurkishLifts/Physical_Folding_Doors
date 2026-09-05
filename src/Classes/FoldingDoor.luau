--!nocheck

local FoldingDoor = {}
FoldingDoor.__index = FoldingDoor

local function CalcRPS(TargetAngle, Time)
    local Radian = TargetAngle * math.pi/180

    local RPS = Radian/Time
    return RPS
end

function FoldingDoor.new(data : {
    DoorModel: Model,
    Config: typeof(require(script.Parent.Parent.Config))
})
    local NewFoldingDoor = setmetatable({}, FoldingDoor)

    NewFoldingDoor.Config = data.Config

    local DoorModel = data.DoorModel
    NewFoldingDoor.DoorModel = DoorModel

    local FoldingDoorsMain : Model = DoorModel:FindFirstChild("Main")
    assert(FoldingDoorsMain,"Folding_Doors MAIN not found!")

    local LTOP : HingeConstraint = DoorModel:FindFirstChild("HingeL2")
    local RTOP : HingeConstraint = DoorModel:FindFirstChild("HingeR2")

    assert((LTOP and RTOP), "One of the hinges on LTOP or RTOP are not found!")

    NewFoldingDoor.LTOP = LTOP
    NewFoldingDoor.RTOP = RTOP

    local HingeL1 : HingeConstraint = FoldingDoorsMain:FindFirstChild("HingeL1")
    local HingeR1 : HingeConstraint = FoldingDoorsMain:FindFirstChild("HingeR1")

    NewFoldingDoor.HingeL1 = HingeL1
    NewFoldingDoor.HingeR1 = HingeR1

    return NewFoldingDoor
end

function FoldingDoor:Close()
    local OpenAngle = self.Config.OpenAngle or 70
    local CloseAngle = self.Config.CloseAngle or 0
    local CloseTime = self.Config.CloseTime or 2

    local CloseRPS = CalcRPS(OpenAngle-CloseAngle,CloseTime)
    self.LTOP.AngularSpeed = CloseRPS
    self.RTOP.AngularSpeed = CloseRPS

    self.LTOP.TargetAngle = CloseAngle
    self.RTOP.TargetAngle = CloseAngle
end

function FoldingDoor:Open()
    local OpenAngle = self.Config.OpenAngle or 70
    local CloseAngle = self.Config.CloseAngle or 0
    local OpenTime = self.Config.OpenTime or 2

    local OpenRPS = CalcRPS(OpenAngle-CloseAngle,OpenTime)

    self.LTOP.AngularSpeed = OpenRPS
    self.RTOP.AngularSpeed = OpenRPS

    self.LTOP.TargetAngle = OpenAngle
    self.RTOP.TargetAngle = -1*OpenAngle
end

return FoldingDoor