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

    local FoldingDoorsMain : Model

    if data.Config.DoorType == "Double" then
        FoldingDoorsMain = DoorModel:FindFirstChild("Main")
        assert(FoldingDoorsMain,"Folding_Doors MAIN not found!")
    end

    local LTOP : HingeConstraint = DoorModel:FindFirstChild("HingeL2")
    local RTOP : HingeConstraint = DoorModel:FindFirstChild("HingeR2")

    assert((LTOP and RTOP), "One of the hinges on LTOP or RTOP are not found!")

    NewFoldingDoor.LTOP = LTOP
    NewFoldingDoor.RTOP = RTOP

    local HingeL1 : HingeConstraint 
    local HingeR1 : HingeConstraint

    if data.Config.DoorType == "Double" then
        HingeL1 = FoldingDoorsMain:FindFirstChild("HingeL1")
        HingeR1 = FoldingDoorsMain:FindFirstChild("HingeR1")
    else
        HingeL1 = DoorModel:FindFirstChild("HingeL1")
        HingeR1 = DoorModel:FindFirstChild("HingeR1")
    end

    assert((HingeL1 and HingeR1), "HingeL1 or HingeR1 not found in Main!")
    
    NewFoldingDoor.HingeL1 = HingeL1
    NewFoldingDoor.HingeR1 = HingeR1

    return NewFoldingDoor
end

function FoldingDoor:Close()
    local OpenAngle = self.Config.OpenAngle or 90
    local CloseAngle = self.Config.CloseAngle or 0
    local CloseTime = self.Config.CloseTime or 2
    local CloseRPS = CalcRPS(OpenAngle-CloseAngle,CloseTime)
    if self.Config.DoorType == "Double" then
        self.LTOP.AngularSpeed = CloseRPS
        self.RTOP.AngularSpeed = CloseRPS

        self.LTOP.TargetAngle = CloseAngle
        self.RTOP.TargetAngle = CloseAngle
    else    
        self.LTOP.AngularSpeed = CloseRPS
        self.RTOP.AngularSpeed = CloseRPS

        self.LTOP.TargetAngle = CloseAngle
        self.RTOP.TargetAngle = CloseAngle

        self.HingeL1.AngularSpeed = CloseRPS*2
        self.HingeR1.AngularSpeed = CloseRPS*2

        self.HingeL1.TargetAngle = CloseAngle
        self.HingeR1.TargetAngle = CloseAngle
    end
end

function FoldingDoor:Open()
    local OpenAngle = self.Config.OpenAngle or 90
    local CloseAngle = self.Config.CloseAngle or 0
    local OpenTime = self.Config.OpenTime or 2

    local OpenRPS = CalcRPS(OpenAngle-CloseAngle,OpenTime)
    if self.Config.DoorType == "Double" then
        self.LTOP.AngularSpeed = OpenRPS
        self.RTOP.AngularSpeed = OpenRPS

        self.LTOP.TargetAngle = OpenAngle
        self.RTOP.TargetAngle = -1*OpenAngle
    else    
        self.LTOP.AngularSpeed = OpenRPS
        self.RTOP.AngularSpeed = OpenRPS

        self.LTOP.TargetAngle = OpenAngle
        self.RTOP.TargetAngle = OpenAngle

        self.HingeL1.AngularSpeed = OpenRPS*2
        self.HingeR1.AngularSpeed = OpenRPS*2

        self.HingeL1.TargetAngle = 180
        self.HingeR1.TargetAngle = -180
    end
end

return FoldingDoor