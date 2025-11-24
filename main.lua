-- Imports
local g3d = require "g3d"

-- Constants
local gravity = -9.81

-- Object Creation
-- local earth = g3d.newModel("g3dAssets/sphere.obj", "g3dAssets/earth.png", {0,0,4})
-- local moon = g3d.newModel("g3dAssets/sphere.obj", "g3dAssets/moon.png", {-5,0,4}, nil, {0.5,0.5,0.5})
local background = g3d.newModel("g3dAssets/sphere.obj", "g3dAssets/starfield.png", {0,0,0}, nil, {500,500,500})
local clickDetectPlane = g3d.newModel("g3dAssets/plane.obj", nil, {10,0,4}, {0,math.pi/2,0}, {100,100,1})
local grabableBall = g3d.newModel("g3dAssets/sphere.obj", "kenney_prototype_textures/red/texture_08.png", {10,0,4}, nil, {0.5,0.5,0.5})

local bounds = g3d.newModel("custom_assets/plinkoBounds.obj", "kenney_prototype_textures/dark/texture_03.png", {10,0,4}, {math.pi/2,0,0}, {1,10,10})
local timer = 0

function gravityEffect(object, dt)
    local posX, posY, posZ = object:getTranslation()
    local newY = posY + gravity * dt
    if newY < 0 then
        newY = 0
    end
    object:setTranslation(posX, newY, posZ)
end

local prevScreenWidth = love.graphics.getWidth()
local prevRadsPerPixelX = g3d.camera.fov / prevScreenWidth
-- Function that returns a single normalized raycast vector from the camera towards the mouse position
function getMouseRaycastVector(mouseX, mouseY)
    local camX, camY, camZ = g3d.camera.position[1], g3d.camera.position[2], g3d.camera.position[3]
    if prevScreenWidth ~= love.graphics.getWidth() then
        prevRadsPerPixelX = g3d.camera.fov / love.graphics.getWidth()
        prevScreenWidth = love.graphics.getWidth()
    end
    local offsetY = -(mouseX - love.graphics.getWidth()/2) * prevRadsPerPixelX
    local offsetZ = -(mouseY - love.graphics.getHeight()/2) * prevRadsPerPixelX

    local dx, dy, dz = g3d.camera.getLookVector()
    local dirX, dirY, dirZ = 100, math.cos(offsetY) * 100, math.cos(offsetZ) * 100
    return dirX , dirY, dirZ
end

function love.mousemoved(x,y, dx,dy)
    -- g3d.camera.firstPersonLook(dx,dy)
    local rayDirX, rayDirY = getMouseRaycastVector(x,y)

    local intersectDist, intersectX, intersectY, intersectZ = g3d.collisions.rayIntersection(
        clickDetectPlane.verts, 
        nil, 
        g3d.camera.position[1], 
        g3d.camera.position[2], 
        g3d.camera.position[3],
        rayDirX,
        rayDirY,
        rayDirZ
    )
    if intersectDist == nil then
        return
    end
    grabableBall:setTranslation(intersectX, intersectY, intersectZ)
end

function love.update(dt)
    timer = timer + dt
    -- moon:setTranslation(math.cos(timer)*5, 0, math.sin(timer)*5 +4)
    -- moon:setRotation(0, math.pi - timer, 0)
    -- g3d.camera.firstPersonMovement(dt)
    if love.keyboard.isDown("escape") then love.event.push("quit") end
end

function love.draw()
    -- earth:draw()
    -- moon:draw()
	
    background:draw()
	grabableBall:draw()
    clickDetectPlane:draw()
	bounds:draw()
end