-- Imports
local g3d = require "g3d"
local vectors = require(g3d.path .. ".vectors")
local fastSubtract = vectors.subtract
local vectorAdd = vectors.add
local vectorCrossProduct = vectors.crossProduct
local vectorDotProduct = vectors.dotProduct
local vectorNormalize = vectors.normalize
local vectorMagnitude = vectors.magnitude

-- Physics World Constants
local DRAG_COEFFICIENT = 0.1
local SPEED_SCALAR = 0.1

----------------------------------------------------------------------------------------------------
-- define a rigidBody class
----------------------------------------------------------------------------------------------------

local rigidBody = {}
rigidBody.__index = rigidBody

-- this returns a new instance of the rigidBody "model" class wrapper
-- objects can be of type "static" or "dynamic"
function rigidBody:newRigidBody(verts, texture, translation, rotation, scale, type, colliderType, colliderParams, extraParams, mass, gravity)
    local self = setmetatable({}, rigidBody)

    print("Verts path: ", verts)
    print("Texture path: ", texture)
    print("Scale: ", scale)
    print("colliderType: ", colliderType)
    print("colliderParams: ", colliderParams)
    print("Extra Params: ", extraParams)
    self.model = g3d.newModel(verts, texture, translation, rotation, scale)
    self.type = type or "dynamic"
    self.mass = mass or 1
    self.gravity = gravity or {0, 0, -9.81}

    if self.type == "static" then
        self.mass = nil
        self.gravity = nil
    end

    if colliderType == "capsule" then
        self.collider = {
            type = "capsule",
            radius = colliderParams.radius or 1,
            centerA = colliderParams.centerA or self.model:getTranslationVector(),
            centerB = colliderParams.centerB or {
                self.model:getTranslationVector()[1], 
                self.model:getTranslationVector()[2], 
                self.model:getTranslationVector()[3] + (colliderParams.height or 2)
            }
        }
    elseif colliderType == "sphere" then
        self.collider = {
            type = "sphere",
            radius = colliderParams.radius or 1,
            center = colliderParams.center or self.model:getTranslationVector()
        }
    else 
        self.collider = {
            type = "verts",
            center = self.model:getTranslationVector()
        }
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
    local cOfE
    if self.mass == nil and otherBody.mass ~= nil then
        cOfE = self.elasticity
    elseif otherBody.mass == nil and self.mass ~= nil then
        cOfE = otherBody.elasticity
    else
        return
    end
    cOfE = (self.elasticity * self.mass + otherBody.elasticity * otherBody.mass) / (self.mass + otherBody.mass)
    cOfE = cOfE + 1
    impulseX, impulseY, impulseZ = -impulseX * cOfE, -impulseY * cOfE, -impulseZ * cOfE

    local inverseMassSum = (1 / self.mass) + (1 / otherBody.mass)
    impulseX, impulseY, impulseZ = impulseX / inverseMassSum, impulseY / inverseMassSum, impulseZ / inverseMassSum

    if self.mass ~= nil then
        self.velocity[1] = self.velocity[1] + (impulseX / self.mass)
        self.velocity[2] = self.velocity[2] + (impulseY / self.mass)
        self.velocity[3] = self.velocity[3] + (impulseZ / self.mass)
    end

    if otherBody.mass ~= nil then
        otherBody.velocity[1] = otherBody.velocity[1] - (impulseX / otherBody.mass)
        otherBody.velocity[2] = otherBody.velocity[2] - (impulseY / otherBody.mass)
        otherBody.velocity[3] = otherBody.velocity[3] - (impulseZ / otherBody.mass)
    end
end

function rigidBody:resolveCollision(otherBody)
    local distance, intersect_X, intersect_Y, intersect_Z, normal_X, normal_Y, normal_Z = self:checkCollision(otherBody)
    if distance then
        self:processCollision(otherBody, intersect_X, intersect_Y, intersect_Z, normal_X, normal_Y, normal_Z)
        return true
    end
    return false
end

-- Applies drage to force and updates acceleration
function rigidBody:processForces(dt) 
    -- Apply drag force
    local dragX = -DRAG_COEFFICIENT * (self.velocity[1] ^ 2)
    local dragY = -DRAG_COEFFICIENT * (self.velocity[2] ^ 2)
    local dragZ = -DRAG_COEFFICIENT * (self.velocity[3] ^ 2)

    self.forces[1] = self.forces[1] + dragX
    self.forces[2] = self.forces[2] + dragY
    self.forces[3] = self.forces[3] + dragZ

    -- Update acceleration based on total forces
    self.acceleration[1] = self.forces[1] / self.mass
    self.acceleration[2] = self.forces[2] / self.mass
    self.acceleration[3] = self.forces[3] / self.mass
end

function rigidBody:applyVelocity(dt)
    self.model:translate(
        self.position[1] + self.velocity[1] * dt,
        self.position[2] + self.velocity[2] * dt,
        self.position[3] + self.velocity[3] * dt
    )
    -- Update collider center
    if self.collider.type == "sphere" then
        local posX, posY, posZ = self.model:getTranslation()
        self.collider.center = {posX, posY, posZ}
    elseif self.collider.type == "capsule" then
        local posX, posY, posZ = self.model:getTranslation()
        local heightVecX, heightVecY, heightVecZ = fastSubtract(
            self.collider.centerB[1], 
            self.collider.centerB[2], 
            self.collider.centerB[3], 
            self.collider.centerA[1], 
            self.collider.centerA[2], 
            self.collider.centerA[3]
        )
        local heightMag = vectorMagnitude(heightVecX, heightVecY, heightVecZ)
        local heightDirX, heightDirY, heightDirZ = vectorNormalize(heightVecX, heightVecY, heightVecZ)
        self.collider.centerA = {posX, posY, posZ}
        self.collider.centerB = {
            posX + heightDirX * heightMag,
            posY + heightDirY * heightMag,
            posZ + heightDirZ * heightMag
        }
    end
end

function rigidBody:draw()
    self.model:draw()
end

function rigidBody:update(dt)
    if self.type == "dynamic" then
        self:processForces()
        self:applyGravity(dt)
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