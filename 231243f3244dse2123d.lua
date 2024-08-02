local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")

local Player = game:GetService("Players").LocalPlayer

local NotifGui = Instance.new("ScreenGui")
NotifGui.Name = "AkaliNotif"
NotifGui.Parent = RunService:IsStudio() and Player.PlayerGui or game:GetService("CoreGui")

-- Funktion zum Erstellen und Positionieren des Containers
local function CreateContainer(Position)
    local Container = Instance.new("Frame")
    Container.Name = "Container"
    Container.Position = Position or UDim2.new(1, -330, 1, -220) -- Standardposition, wenn keine Position angegeben wird
    Container.Size = UDim2.new(0, 300, 0.5, 0)
    Container.BackgroundTransparency = 1
    Container.Parent = NotifGui
    return Container
end

local Container = CreateContainer()

----------------------------------------------------------------------------------------------------

local function Image(ID, Button)
    local NewImage = Instance.new(string.format("Image%s", Button and "Button" or "Label"))
    NewImage.Image = ID
    NewImage.BackgroundTransparency = 1
    return NewImage
end

local function Round2px()
    local NewImage = Image("http://www.roblox.com/asset/?id=5761488251")
    NewImage.ScaleType = Enum.ScaleType.Slice
    NewImage.SliceCenter = Rect.new(2, 2, 298, 298)
    NewImage.ImageColor3 = Color3.fromRGB(30, 30, 30)
    return NewImage
end

local function Shadow2px()
    local NewImage = Image("http://www.roblox.com/asset/?id=5761498316")
    NewImage.ScaleType = Enum.ScaleType.Slice
    NewImage.SliceCenter = Rect.new(17, 17, 283, 283)
    NewImage.Size = UDim2.fromScale(1, 1) + UDim2.fromOffset(30, 30)
    NewImage.Position = -UDim2.fromOffset(15, 15)
    NewImage.ImageColor3 = Color3.fromRGB(30, 30, 30)
    return NewImage
end

local Padding = 10
local DescriptionPadding = 10
local InstructionObjects = {}
local TweenTime = 1
local TweenStyle = Enum.EasingStyle.Sine
local TweenDirection = Enum.EasingDirection.Out

local LastTick = tick()

local function CalculateBounds(TableOfObjects)
    local TableOfObjects = typeof(TableOfObjects) == "table" and TableOfObjects or {}
    local X, Y = 0, 0
    for _, Object in next, TableOfObjects do
        X += Object.AbsoluteSize.X
        Y += Object.AbsoluteSize.Y
    end
    return { X = X, Y = Y, x = X, y = Y }
end

local CachedObjects = {}

local function Update()
    local DeltaTime = tick() - LastTick
    local PreviousObjects = {}
    for CurObj, Object in next, InstructionObjects do
        local Label, Delta, Done = Object[1], Object[2], Object[3]
        if not Done then
            if Delta < TweenTime then
                Object[2] = math.clamp(Delta + DeltaTime, 0, 1)
                Delta = Object[2]
            else
                Object[3] = true
            end
        end
        local NewValue = TweenService:GetValue(Delta, TweenStyle, TweenDirection)
        local CurrentPos = Label.Position
        local PreviousBounds = CalculateBounds(PreviousObjects)
        local TargetPos = UDim2.new(0, 0, 0, PreviousBounds.Y + (Padding * #PreviousObjects))
        Label.Position = CurrentPos:Lerp(TargetPos, NewValue)
        table.insert(PreviousObjects, Label)
    end
    CachedObjects = PreviousObjects
    LastTick = tick()
end

RunService:BindToRenderStep("UpdateList", 0, Update)

local TitleSettings = {
    Font = Enum.Font.GothamSemibold,
    Size = 14
}

local DescriptionSettings = {
    Font = Enum.Font.Gotham,
    Size = 14
}

local MaxWidth = (Container.AbsoluteSize.X - Padding - DescriptionPadding - 50) -- Adjusted for the icon width

local function Label(Text, Font, Size, Button)
    local Label = Instance.new(string.format("Text%s", Button and "Button" or "Label"))
    Label.Text = Text
    Label.Font = Font
    Label.TextSize = Size
    Label.BackgroundTransparency = 1
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.RichText = true
    Label.TextColor3 = Color3.fromRGB(255, 255, 255)
    return Label
end

local function TitleLabel(Text)
    return Label(Text, TitleSettings.Font, TitleSettings.Size)
end

local function DescriptionLabel(Text)
    return Label(Text, DescriptionSettings.Font, DescriptionSettings.Size)
end

local PropertyTweenOut = {
    Text = "TextTransparency",
    Fram = "BackgroundTransparency",
    Imag = "ImageTransparency"
}

local function FadeProperty(Object)
    local Prop = PropertyTweenOut[string.sub(Object.ClassName, 1, 4)]
    TweenService:Create(Object, TweenInfo.new(0.25, TweenStyle, TweenDirection), {
        [Prop] = 1
    }):Play()
end

local function SearchTableFor(Table, For)
    for _, v in next, Table do
        if v == For then
            return true
        end
    end
    return false
end

local function FindIndexByDependency(Table, Dependency)
    for Index, Object in next, Table do
        if typeof(Object) == "table" then
            local Found = SearchTableFor(Object, Dependency)
            if Found then
                return Index
            end
        else
            if Object == Dependency then
                return Index
            end
        end
    end
end

local function ResetObjects()
    for _, Object in next, InstructionObjects do
        Object[2] = 0
        Object[3] = false
    end
end

local function FadeOutAfter(Object, Seconds)
    wait(Seconds)
    FadeProperty(Object)
    for _, SubObj in next, Object:GetDescendants() do
        FadeProperty(SubObj)
    end
    wait(0.25)
    table.remove(InstructionObjects, FindIndexByDependency(InstructionObjects, Object))
    ResetObjects()
end

return {
    Notify = function(Properties)
        local Properties = typeof(Properties) == "table" and Properties or {}
        local Title = Properties.Title
        local Description = Properties.Description
        local Duration = Properties.Duration or 5
        local ImageID = Properties.ImageID or "17649496928" -- Default ImageID if none is provided
        local AutoImageScale = Properties.AutoImageScale or false -- Default to false if not provided
        local ContainerPosition = Properties.ContainerPosition -- New field for Container Position

        -- Optionally create a new container if position is provided
        if ContainerPosition then
            Container:Destroy() -- Remove the existing container if it exists
            Container = CreateContainer(ContainerPosition) -- Create a new container with the provided position
        end

        if Title or Description then -- Check that user has provided title and/or description
            local Y = Title and 26 or 0
            if Description then
                local TextSize = TextService:GetTextSize(Description, DescriptionSettings.Size, DescriptionSettings.Font, Vector2.new(0, 0))
                for i = 1, math.ceil(TextSize.X / MaxWidth) do
                    Y += TextSize.Y
                end
                Y += 8
            end
            local NewLabel = Round2px()
            NewLabel.Size = UDim2.new(1, 0, 0, Y)
            NewLabel.Position = UDim2.new(-1, 20, 0, CalculateBounds(CachedObjects).Y + (Padding * #CachedObjects))

            -- Create and set up the icon
            local Icon = Image(string.format("rbxthumb://type=Asset&id=%s&w=150&h=150", ImageID))
            Icon.Size = AutoImageScale and UDim2.new(0, 40, 0, Y) or UDim2.new(0, 40, 0, 40) -- Adjust size based on AutoImageScale
            Icon.Position = UDim2.new(0, 5, 0, AutoImageScale and 0 or (Y - 40) / 2) -- Adjust position based on AutoImageScale
            Icon.Parent = NewLabel

            if Title then
                local NewTitle = TitleLabel(Title)
                NewTitle.Size = UDim2.new(1, -60, 0, 26) -- Adjusted size for the title to make space for the icon
                NewTitle.Position = UDim2.fromOffset(50, 0) -- Adjusted position to make space for the icon
                NewTitle.Parent = NewLabel
            end
            if Description then
                local NewDescription = DescriptionLabel(Description)
                NewDescription.TextWrapped = true
                NewDescription.Size = UDim2.new(1, -60, 1, Title and -26 or 0) -- Adjusted size for the description to make space for the icon
                NewDescription.Position = UDim2.fromOffset(50, Title and 26 or 0) -- Adjusted position to make space for the icon
                NewDescription.TextYAlignment = Enum.TextYAlignment[Title and "Top" or "Center"]
                NewDescription.Parent = NewLabel
            end
            Shadow2px().Parent = NewLabel
            NewLabel.Parent = Container
            table.insert(InstructionObjects, { NewLabel, 0, false })
            coroutine.wrap(FadeOutAfter)(NewLabel, Duration)
        end
    end,
}
