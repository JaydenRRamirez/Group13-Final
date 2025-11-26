-- Imports
local g3d = require "g3d"

-- Constants
local gravity = -9.81
local gameCenter = {10,0,4}
local lookDirection = "x"

-- Object Creation
-- local earth = g3d.newModel("g3dAssets/sphere.obj", "g3dAssets/earth.png", {0,0,4})
-- local moon = g3d.newModel("g3dAssets/sphere.obj", "g3dAssets/moon.png", {-5,0,4}, nil, {0.5,0.5,0.5})
local background = g3d.newModel("g3dAssets/sphere.obj", "g3dAssets/starfield.png", {0,0,0}, nil, {500,500,500})
local grabableBall = g3d.newModel("g3dAssets/sphere.obj", "kenney_prototype_textures/red/texture_08.png", {10,0,4}, nil, {0.5,0.5,0.5})

local boundsOld = g3d.newModel("custom_assets/plinkoBounds.obj", "kenney_prototype_textures/dark/texture_03.png", {10,0,4}, {math.pi/2,0,0}, {1,10,10})
local bounds = {
    g3d.newModel("g3dAssets/cube.obj", "kenney_prototype_textures/dark/texture_03.png", {10,5,4}, nil, {2,0.5,7}),
    g3d.newModel("g3dAssets/cube.obj", "kenney_prototype_textures/dark/texture_03.png", {10,-5,4}, nil, {2,0.5,7}),
    g3d.newModel("g3dAssets/cube.obj", "kenney_prototype_textures/dark/texture_03.png", {10,0,-4}, nil, {2,5.5,0.5}),
}
local timer = 0

local transformPerScreenPixel = 0
-- Function that gets the transform height and width per screen pixel based on how far gameCenter is from the camera
function calculateTransformPerScreenPixel()
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
function getMouseLookVector(mouseX, mouseY)
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

function love.load()
    calculateTransformPerScreenPixel()
end

local rayDirX, rayDirY = 0,0
function love.mousemoved(x,y, dx,dy)
    -- g3d.camera.firstPersonLook(dx,dy)
    rayDirX, rayDirY = getMouseLookVector(x,y)
    grabableBall:setTranslation(10, -rayDirX * transformPerScreenPixel, -rayDirY * transformPerScreenPixel)
end

-- setup image assets to be switched out
collidingTexture = love.graphics.newImage("kenney_prototype_textures/green/texture_08.png")
defaultBallTexture = love.graphics.newImage("kenney_prototype_textures/red/texture_08.png")
defaultBoundTexture = love.graphics.newImage("kenney_prototype_textures/dark/texture_03.png")

local collidedThisFrame = false
local distance, it_x, it_y, it_z, n_x, n_y, n_z
local bcenter_x, bcenter_y, bcenter_z
local bradius = 0.5
function love.update(dt)
    -- Make camera orthographic
    -- g3d.camera.updateOrthographicMatrix()

    timer = timer + dt
    -- moon:setTranslation(math.cos(timer)*5, 0, math.sin(timer)*5 +4)
    -- moon:setRotation(0, math.pi - timer, 0)
    -- g3d.camera.firstPersonMovement(dt)
    if love.keyboard.isDown("escape") then love.event.push("quit") end

    -- check collisions between grabableBall and bounds
    collidedThisFrame = false
    for i = 1, #bounds do
        bcenter_x, bcenter_y, bcenter_z = grabableBall:getTranslation()
        distance, it_x, it_y, it_z, n_x, n_y, n_z = bounds[i]:sphereIntersection(bcenter_x, bcenter_y, bcenter_z, bradius)
        if distance then
            -- print("Collided with bound "..i)
            collidedThisFrame = true
            bounds[i]:setTexture(collidingTexture) -- Change color on collision
        else
            -- print("No collision")
            bounds[i]:setTexture(defaultBoundTexture) -- Reset color if no collision
        end
    end

    if collidedThisFrame then
        grabableBall:setTexture(collidingTexture)
    else
        grabableBall:setTexture(defaultBallTexture)
    end
end

function love.draw()
    -- earth:draw()
    -- moon:draw()
	
    background:draw()
	grabableBall:draw()
	for i = 1, #bounds do
        bounds[i]:draw()
    end
end