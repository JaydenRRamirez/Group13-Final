-- Imports
local g3d = require "g3d"
local rigidBody = require(".rigidBody")

-- Constants
local gravity = -9.81
local gameCenter = {10,0,4}
local lookDirection = "x"

-- Object Creation
local background = g3d.newModel("g3dAssets/sphere.obj", "g3dAssets/starfield.png", {0,0,0}, nil, {500,500,500})
local ballCursor = g3d.newModel("g3dAssets/sphere.obj", "kenney_prototype_textures/red/texture_08.png", {10,0,4}, nil, {0.5,0.5,0.5})

local bounds = {
    rigidBody:newRigidBody("g3dAssets/cube.obj", "kenney_prototype_textures/dark/texture_03.png", {10,5,4}, nil, {2,0.5,7}, "static", "verts"),
    rigidBody:newRigidBody("g3dAssets/cube.obj", "kenney_prototype_textures/dark/texture_03.png", {10,-5,4}, nil, {2,0.5,7}, "static", "verts"),
    rigidBody:newRigidBody("g3dAssets/cube.obj", "kenney_prototype_textures/dark/texture_03.png", {10,0,-3.5}, nil, {2,5.5,0.5}, "static", "verts"),
    rigidBody:newRigidBody("g3dAssets/cube.obj", "kenney_prototype_textures/dark/texture_03.png", {10,-3,-2}, {-math.pi/4,0,0}, {2,2,0.5}, "static", "verts"),
}
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
function love.update(dt)
    -- Make camera orthographic
    -- g3d.camera.updateOrthographicMatrix()

    timer = timer + dt
    -- g3d.camera.firstPersonMovement(dt)
    if love.keyboard.isDown("escape") then love.event.push("quit") end

    -- check collisions between grabableBall and bounds
    for i = 1, #simulatedObjects do
        for j = 1, #bounds do
            collidedThisFrame = simulatedObjects[i]:resolveCollision(bounds[j])
            bounds[j]:update(dt)
        end

        simulatedObjects[i]:update(dt)
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
end