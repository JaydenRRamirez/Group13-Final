-- Imports
local g3d = require "../g3d"
local vectors = require(g3d.path .. ".vectors")
local fastSubtract = vectors.subtract
local vectorAdd = vectors.add
local vectorCrossProduct = vectors.crossProduct
local vectorDotProduct = vectors.dotProduct
local vectorNormalize = vectors.normalize
local vectorMagnitude = vectors.magnitude

-- Physics World Constants
local DRAG_COEFFICIENT = 0.1

----------------------------------------------------------------------------------------------------
-- define a rigidBody class
----------------------------------------------------------------------------------------------------

local rigidBody = {}
rigidBody.__index = rigidBody

-- this returns a new instance of the rigidBody "model" class wrapper
-- objects can be of type "static" or "dynamic"
local function newRigidBody(verts, texture, translation, rotation, scale, type, colliderType, colliderParams, mass, gravity, extraParams)
    local self = setmetatable({}, rigidBody)

    self.model = g3d.newModel(verts, texture, translation, rotation, scale)
    self.type = type or "dynamic"
    self.mass = mass or 1
    self.gravity = gravity or {0, -9.81, 0}

    if self.type == "static" then
        self.mass = nil
        self.gravity = nil
    end

    if colliderType == "capsule" then
        self.collider = {
            type = "capsule",
            radius = colliderParams.radius or 1,
            centerA = colliderParams.centerA,
            centerB = colliderParams.centerB
        }
        if self.collider.centerA == nil then
            local posX, posY, posZ = self.model:getTranslation()
            self.collider.centerA = {posX, posY, posZ}
        end
        if self.collider.centerB == nil then
            local posX, posY, posZ = self.model:getTranslation()
            self.collider.centerB = {posX, posY, posZ + colliderParams.height or 2}
        end
    elseif colliderType == "sphere" then
        self.collider = {
            type = "sphere",
            radius = colliderParams.radius or 1,
            center = colliderParams.center
        }
    else 
        self.collider = {
            type = "verts"
            center = colliderParams.center
        }
    end

    if self.collider.center == nil and self.collider.type ~= "capsule" then
        local posX, posY, posZ = self.model:getTranslation()
        self.collider.center = {posX, posY, posZ}
    end

    if extraParams then
        self.elasticity = extraParams.elasticity or 0.5
    end

    self.velocity = {0,0,0}
    self.acceleration = {0,0,0}
    self.forces = {0,0,0}

    return self
end

function rigidBody:applyGravity(dt)
    if self.gravity ~= nil then
        if self.gravity[1] ~= 0 then
            self.acceleration[1] = self.gravity[1] * dt
        end
        if self.gravity[2] ~= 0 then
            self.acceleration[2] = self.gravity[2] * dt
        end
        if self.gravity[3] ~= 0 then
            self.acceleration[3] = self.gravity[3] * dt
        end
    end
end

-- returns nil if not colliding, otherwise, distance, intersectionX, intersectionY, intersectionZ, normalX, normalY, normalZ
function rigidBody:checkCollision(otherBody)
    if self.collider.type == "sphere" and otherBody.collider.type == "verts" then
        if 
        return otherBody.model:sphereIntersection(
            self.collider.center[1], 
            self.collider.center[2], 
            self.collider.center[3], 
            self.collider.radius
        )
    elseif self.collider.type == "capsule" and otherBody.collider.type == "verts" then
        return otherBody.model:capsuleIntersection(
            self.collider.centerA[1], 
            self.collider.centerA[2], 
            self.collider.centerA[3],
            self.collider.centerB[1], 
            self.collider.centerB[2], 
            self.collider.centerB[3],
            self.collider.radius
        )
    elseif self.collider.type == "verts" then
        if otherBody.collider.type == "sphere" then
            return self.model:sphereIntersection(
                otherBody.collider.center[1], 
                otherBody.collider.center[2], 
                otherBody.collider.center[3], 
                otherBody.collider.radius
            )
        elseif otherBody.collider.type == "capsule" then
            return self.model:capsuleIntersection(
                otherBody.collider.centerA[1], 
                otherBody.collider.centerA[2], 
                otherBody.collider.centerA[3],
                otherBody.collider.centerB[1], 
                otherBody.collider.centerB[2], 
                otherBody.collider.centerB[3],
                otherBody.collider.radius
            )
        end
    end
    return nil
end

function rigidBody:processCollision(otherBody, intersect_X, intersect_Y, intersect_Z, normal_X, normal_Y, normal_Z)
    local sVelRelX, sVelRelY, sVelRelZ = self.velocity[1] - otherBody.velocity[1], self.velocity[2] - otherBody.velocity[2], self.velocity[3] - otherBody.velocity[3]
    
    local impulseX, impulseY, impulseZ = vectorDotProduct(sVelRelX, sVelRelY, sVelRelZ, normal_X, normal_Y, normal_Z)
    local cOfE = (self.elasticity * self.mass + otherBody.elasticity * otherBody.mass) / (self.mass + otherBody.mass)
    cOfE = cOfE + 1
    impulseX, impulseY, impulseZ = -impulseX * cOfE, -impulseY * cOfE, -impulseZ * cOfE

    local inverseMassSum = (1 / self.mass) + (1 / otherBody.mass)
    impulseX, impulseY, impulseZ = impulseX / inverseMassSum, impulseY / inverseMassSum, impulseZ / inverseMassSum

    self.velocity[1] = self.velocity[1] + (impulseX / self.mass)
    self.velocity[2] = self.velocity[2] + (impulseY / self.mass)
    self.velocity[3] = self.velocity[3] + (impulseZ / self.mass)

    otherBody.velocity[1] = otherBody.velocity[1] - (impulseX / otherBody.mass)
    otherBody.velocity[2] = otherBody.velocity[2] - (impulseY / otherBody.mass)
    otherBody.velocity[3] = otherBody.velocity[3] - (impulseZ / otherBody.mass)
end

function rigidBody:processForces() 
    -- Apply drag force
    local speed = math.sqrt(self.velocity[1]^2 + self.velocity[2]^2 + self.velocity[3]^2)
    if speed > 0 then
        local dragMagnitude = DRAG_COEFFICIENT * speed * speed
        local dragForce = {
            -dragMagnitude * (self.velocity[1] / speed),
            -dragMagnitude * (self.velocity[2] / speed),
            -dragMagnitude * (self.velocity[3] / speed)
        }
        self.forces[1] = self.forces[1] + dragForce[1]
        self.forces[2] = self.forces[2] + dragForce[2]
        self.forces[3] = self.forces[3] + dragForce[3]
    end

    -- Update acceleration
    if self.mass ~= nil then
        self.acceleration[1] = self.forces[1] / self.mass
        self.acceleration[2] = self.forces[2] / self.mass
        self.acceleration[3] = self.forces[3] / self.mass
    end 
end

function rigidBody:applyVelocity(dt)
    self.model:translate(
        self.velocity[1] * dt,
        self.velocity[2] * dt,
        self.velocity[3] * dt
    )
    -- Update collider center
    if self.collider.type == "sphere" then
        local posX, posY, posZ = self.model:getTranslation()
        self.collider.center = {posX, posY, posZ}
    elseif self.collider.type == "capsule" then
        local posX, posY, posZ = self.model:getTranslation()
        local heightVec = vectors.subtract(self.collider.centerB, self.collider.centerA)
        local heightMag = vectorMagnitude(heightVec)
        local heightDir = vectorNormalize(heightVec)
        self.collider.centerA = {posX, posY, posZ}
        self.collider.centerB = {
            posX + heightDir[1] * heightMag,
            posY + heightDir[2] * heightMag,
            posZ + heightDir[3] * heightMag
        }
    end
end

function rigidBody:update(dt)
    if self.type == "dynamic" then
        self:applyGravity(dt)
        self:processForces()
        -- Update velocity
        self.velocity[1] = self.velocity[1] + self.acceleration[1] * dt
        self.velocity[2] = self.velocity[2] + self.acceleration[2] * dt
        self.velocity[3] = self.velocity[3] + self.acceleration[3] * dt

        self:applyVelocity(dt)

        -- Reset forces and acceleration for next frame
        self.forces = {0,0,0}
        self.acceleration = {0,0,0}
    end
end

return rigidBody