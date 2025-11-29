-- Imports
local g3d = require "g3d"
local rigidBody = require(".rigidBody")

-- Constants
local gravity = -9.81
local gameCenter = {10,0,4}
local lookDirection = "x"

-- Level Constants
local platformWidth = 6.0;
local platformHeight = 12.0;
local thickness = 0.5;
local pegZlocation = 4.0;

-- Object Lists
local slots = {};

-- Positions
local topZ = pegZlocation + platformHeight / 2;
local bottomZ = pegZlocation - platformHeight / 2;

local numSlots = 5
local dividerWidth = 0.05
local totalWidth = platformWidth
local slotWidth = totalWidth / numSlots
local dividerZ = bottomZ - thickness * 2
local dividerHeight = 0.5

-- We need numSlots + 1 dividers
local firstDividerY = -(totalWidth / 2)

for i = 0, numSlots do
    local dividerY = firstDividerY + (i * slotWidth)
    local divider = g3d.newModel(
        "g3dAssets/cube.obj",
        "kenney_prototype_textures/red/texture_03.png",
        {10, dividerY, dividerZ},
        nil,
        {thickness, dividerWidth, dividerHeight} -- X, Y, Z scale
    )
    table.insert(slots, divider);
end

-- Base Bounds (Walls and Floor/Back)
local bounds = {
    -- Right Wall
    rigidBody:newRigidBody("g3dAssets/cube.obj", "kenney_prototype_textures/dark/texture_03.png", {10,5,4}, nil, {2,0.5,7}, "static", "verts"),
    -- Left Wall
    rigidBody:newRigidBody("g3dAssets/cube.obj", "kenney_prototype_textures/dark/texture_03.png", {10,-5,4}, nil, {2,0.5,7}, "static", "verts"),
    -- Floor (or Back wall if Z is depth)
    rigidBody:newRigidBody("g3dAssets/cube.obj", "kenney_prototype_textures/dark/texture_03.png", {10,0,-4}, nil, {2,5.5,0.5}, "static", "verts")
}

-- Object Creation
local background = g3d.newModel("g3dAssets/sphere.obj", "g3dAssets/starfield.png", {0,0,0}, nil, {500,500,500})
local ballCursor = g3d.newModel("g3dAssets/sphere.obj", "kenney_prototype_textures/red/texture_08.png", {10,0,4}, nil, {0.5,0.5,0.5})

local bounds = {
    rigidBody:newRigidBody("g3dAssets/cube.obj", "kenney_prototype_textures/dark/texture_03.png", {10,5,4}, nil, {2,0.5,7}, "static", "verts"),
    rigidBody:newRigidBody("g3dAssets/cube.obj", "kenney_prototype_textures/dark/texture_03.png", {10,-5,4}, nil, {2,0.5,7}, "static", "verts"),
    rigidBody:newRigidBody("g3dAssets/cube.obj", "kenney_prototype_textures/dark/texture_03.png", {10,0,-3.5}, nil, {2,5.5,0.5}, "static", "verts"),
    rigidBody:newRigidBody("custom_assets/ramp.obj", "kenney_prototype_textures/orange/texture_03.png", {10,-3,-2}, nil, {2,1,-1}, "static", "verts"),
}

-- Plinko Pegs Grid
local pegRadius = 0.15
local pegSpacingY = 2.0 -- Horizontal spacing
local pegSpacingZ = 2.0 -- Vertical spacing
local pegStartRowZ = topZ - 1.0
local pegEndRowZ = dividerZ + 1.0
local pegTexture = "kenney_prototype_textures/purple/texture_08.png"

local yCenter = gameCenter[2]
local yLimit = platformWidth / 2 - pegRadius

local rowCount = 0
for z = pegStartRowZ, pegEndRowZ, -pegSpacingZ do
    rowCount = rowCount + 1
    local yOffset = 0
    -- Staggering: shift every other row by half the spacing
    if rowCount % 2 == 0 then
        yOffset = pegSpacingY / 2
    end
    
    -- Loop from -Y limit to +Y limit
    local y = -yLimit + yOffset
    while y <= yLimit do
        -- Only place pegs within the Y bounds
        if y >= -yLimit and y <= yLimit then
            local peg = rigidBody:newRigidBody(
                "g3dAssets/sphere.obj",
                pegTexture,
                {gameCenter[1], y, z},
                nil,
                {pegRadius, pegRadius, pegRadius},
                "static",
                "sphere",
                {radius = pegRadius}
            )
            table.insert(bounds, peg)
        end
        y = y + pegSpacingY
    end
end

local timer = 0

-- keep track of all rigid bodies that need to be physics simulated aren't static
local simulatedObjects = {}


local transformPerScreenPixel = 0
-- Function that gets the transform height and width per screen pixel based on how far gameCenter is from the camera
local function calculateTransformPerScreenPixel()
    local distance
    if lookDirection == "x" then
        distance = math.abs(gameCenter[1] - g3d.camera.position[1])
    elseif lookDirection == "y" then
        distance = math.abs(gameCenter[2] - g3d.camera.position[2])
    elseif lookDirection == "z" then
        distance = math.abs(gameCenter[3] - g3d.camera.position[3])
    end
    -- Assuming a simple perspective projection, the transform per screen pixel
    -- can be approximated as follows:
    transformPerScreenPixel = 2 * (distance * math.tan(g3d.camera.fov / 2)) / love.graphics.getHeight()
end


-- Returns a normalized direction vector from screen center to mouse position
-- Returns: dx, dy (2D vector components)
local function getMouseLookVector(mouseX, mouseY)
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    
    -- Calculate offset from screen center
    local dx = mouseX - screenWidth / 2
    local dy = mouseY - screenHeight / 2
    
    -- Normalize the vector
    local magnitude = math.sqrt(dx * dx + dy * dy)
    
    if magnitude == 0 then
        -- Mouse is at center, return zero vector
        return 0, 0
    end
    
    return dx, dy
end


local function getClickWorldPosition(mouseX, mouseY)
    local worldX, worldY, worldZ
    if mouseX == nil or mouseY == nil then
        mouseX, mouseY = love.mouse.getPosition()
    end
    local rayDirX, rayDirY = getMouseLookVector(mouseX, mouseY)
    if lookDirection == "x" or lookDirection == "-x" then
        worldX = gameCenter[1]
    elseif lookDirection == "y" or lookDirection == "-y" then
        worldY = gameCenter[2]
    elseif lookDirection == "z" or lookDirection == "-z" then
        worldZ = gameCenter[3]
    end

    local sign = -1
    if lookDirection.sub(1,1) == "-" then sign = 1 end 
    
    if worldX then
        worldY = sign * rayDirX * transformPerScreenPixel
        worldZ = sign * rayDirY * transformPerScreenPixel
    elseif worldY then
        worldX = sign * rayDirX * transformPerScreenPixel
        worldZ = sign * rayDirY * transformPerScreenPixel
    elseif worldZ then
        worldX = sign * rayDirX * transformPerScreenPixel
        worldY = sign * rayDirY * transformPerScreenPixel
    end

    return worldX, worldY, worldZ
end

function love.load()
    calculateTransformPerScreenPixel()
end

function love.mousepressed(x, y, button, istouch, presses)
    if button == 1 then
        local mWorldPosX, mWorldPosY, mWorldPosZ = getClickWorldPosition(x, y)
        local physBall = rigidBody:newRigidBody("g3dAssets/sphere.obj", "kenney_prototype_textures/orange/texture_08.png", 
            {mWorldPosX, mWorldPosY, mWorldPosZ}, 
            nil, 
            {0.5,0.5,0.5}, 
            "dynamic", 
            "sphere", 
            {radius=0.5}
        )
        table.insert(simulatedObjects, physBall)
    end
end

function love.mousemoved(x,y, dx,dy)
    -- g3d.camera.firstPersonLook(dx,dy)
    local mWorldPosX, mWorldPosY, mWorldPosZ = getClickWorldPosition(x, y)
    ballCursor:setTranslation(mWorldPosX, mWorldPosY, mWorldPosZ)
end

local collidedThisFrame = false
local isPaused = false
function love.update(dt)
    -- Make camera orthographic
    -- g3d.camera.updateOrthographicMatrix()

    timer = timer + dt
    -- g3d.camera.firstPersonMovement(dt)
    if love.keyboard.isDown("escape") then love.event.push("quit") end
    if love.keyboard.isDown("p") then isPaused = not isPaused end

    if not isPaused then
        -- check collisions between grabableBall and bounds
        for i = 1, #simulatedObjects do
            for j = 1, #bounds do
                collidedThisFrame = simulatedObjects[i]:resolveCollision(bounds[j])
                bounds[j]:update(dt)
            end
            simulatedObjects[i]:update(dt)
        end
    end
end

function love.draw()
    -- earth:draw()
    -- moon:draw()
	
    background:draw()
	ballCursor:draw()

    for i = 1, #simulatedObjects do
        simulatedObjects[i]:draw()
    end
	for i = 1, #bounds do
        bounds[i]:draw()
    end

    for i = 1, #slots do
        slots[i]:draw();
    end
end