-- Imports
local g3d = require "../g3d"

----------------------------------------------------------------------------------------------------
-- define a rigidBody class
----------------------------------------------------------------------------------------------------

local rigidBody = {}
rigidBody.__index = rigidBody

-- this returns a new instance of the rigidBody "model" class wrapper
-- objects can be of type "static" or "dynamic"
local function newRigidBody(verts, texture, translation, rotation, scale, type, mass, gravity)
    local self = setmetatable({}, rigidBody)

    self.model = g3d.newModel(verts, texture, translation, rotation, scale)
    self.type = type or "dynamic"
    self.mass = mass or 1
    self.gravity = gravity or {0, -9.81, 0}

    if self.type == "static" then
        self.mass = nil
        self.gravity = nil
    end

    self.velocity = {0,0,0}
    self.forces = {0,0,0}

    return self
end

function rigidBody:applyGravity(dt)
    if self.gravity ~= nil then
        local posX, posY, posZ = self.model:getTranslation()
        local newX, newY, newZ = posX, posY, posZ
        if self.gravity[1] ~= 0 then
            newX = posX + self.gravity[1] * dt
        end
        if self.gravity[2] ~= 0 then
            newY = posY + self.gravity[2] * dt
        end
        if self.gravity[3] ~= 0 then
            newZ = posZ + self.gravity[3] * dt
        end
        self.model:setTranslation(newX, newY, newZ)
    end
end

function rigidBody:checkCollision(otherBody)
    -- Collision detection logic would go here
end