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
local WORLD_GRAVITY = {0, 0, -9.81}
local DEFAULT_ELASTICITY = 0.66

----------------------------------------------------------------------------------------------------
-- define a rigidBody class
----------------------------------------------------------------------------------------------------

local rigidBody = {}
rigidBody.__index = rigidBody

-- this returns a new instance of the rigidBody "model" class wrapper
-- objects can be of type "static" or "dynamic"
function rigidBody:newRigidBody(verts, texture, translation, rotation, scale, type, colliderType, colliderParams, extraParams, mass, gravity)
    local self = setmetatable({}, rigidBody)

    self.model = g3d.newModel(verts, texture, translation, rotation, scale)
    self.type = type or "dynamic"
    self.mass = mass or 1
    self.gravity = gravity or WORLD_GRAVITY

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
        self.elasticity = extraParams.elasticity
        self.lockedAxes = extraParams.lockedAxes
    end
    if self.elasticity == nil then
        self.elasticity = DEFAULT_ELASTICITY
    end
    if self.lockedAxes == nil then
        self.lockedAxes = {false, false, false}
    end

    self.position = self.model.translation
    self.velocity = {0,0,0}

    self.angularVel = {0,0,0}

    return self
end

function rigidBody:applyGravity(dt)
    if self.gravity then
        if self.gravity[1] ~= 0 then
            self.velocity[1] = self.velocity[1] + self.gravity[1] * dt
        end
        if self.gravity[2] ~= 0 then
            self.velocity[2] = self.velocity[2] + self.gravity[2] * dt
        end
        if self.gravity[3] ~= 0 then
            self.velocity[3] = self.velocity[3] + self.gravity[3] * dt
        end
    end
end

function rigidBody:setTranslate(x, y, z)
    if self.lockedAxes[1] then x = self.position[1] end
    if self.lockedAxes[2] then y = self.position[2] end
    if self.lockedAxes[3] then z = self.position[3] end
    self.model:setTranslation(x, y, z)
end

function rigidBody:applyLinearImpulse(impulseX, impulseY, impulseZ)
    if self.mass then
        if self.lockedAxes[1] then impulseX = 0 end
        if self.lockedAxes[2] then impulseY = 0 end
        if self.lockedAxes[3] then impulseZ = 0 end

        self.velocity[1] = self.velocity[1] + (impulseX / self.mass)
        self.velocity[2] = self.velocity[2] + (impulseY / self.mass)
        self.velocity[3] = self.velocity[3] + (impulseZ / self.mass)
    end
end

function rigidBody:applyAngularImpulse(impulseX, impulseY, impulseZ)
    if self.mass then
        self.angularVel[1] = self.angularVel[1] + impulseX
        self.angularVel[2] = self.angularVel[2] + impulseY
        self.angularVel[3] = self.angularVel[3] + impulseZ
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

function rigidBody:processCollision(otherBody, distance, intersect_X, intersect_Y, intersect_Z, normal_X, normal_Y, normal_Z)
    local cOfE, inverseSelfMass, inverseOtherMass
    if self.mass == nil and otherBody.mass ~= nil then
        cOfE = self.elasticity
        inverseSelfMass = 0
        inverseOtherMass = 1 / otherBody.mass
    elseif otherBody.mass == nil and self.mass ~= nil then
        cOfE = otherBody.elasticity
        inverseSelfMass = 1 / self.mass
        inverseOtherMass = 0
    elseif self.mass and otherBody.mass then
        cOfE = (self.elasticity * self.mass + otherBody.elasticity * otherBody.mass) / (self.mass + otherBody.mass)
        inverseSelfMass = 1 / self.mass
        inverseOtherMass = 1 / otherBody.mass
    else
        return
    end
    local inverseMassSum = inverseSelfMass + inverseOtherMass

    if self.collider.type ~= "verts" then
        distance = self.collider.radius - distance
    end

    self.model:setTranslation(
        self.position[1] + (normal_X * distance * (inverseSelfMass / inverseMassSum)),
        self.position[2] + (normal_Y * distance * (inverseSelfMass / inverseMassSum)),
        self.position[3] + (normal_Z * distance * (inverseSelfMass / inverseMassSum))
    )
    otherBody.model:setTranslation(
        otherBody.position[1] - (normal_X * distance * (inverseOtherMass / inverseMassSum)),
        otherBody.position[2] - (normal_Y * distance * (inverseOtherMass / inverseMassSum)),
        otherBody.position[3] - (normal_Z * distance * (inverseOtherMass / inverseMassSum))
    )

    local relSelfX, relSelfY, relSelfZ = fastSubtract(
        intersect_X, 
        intersect_Y, 
        intersect_Z, 
        self.position[1], 
        self.position[2], 
        self.position[3]
    )
    local relOtherX, relOtherY, relOtherZ = fastSubtract(
        intersect_X, 
        intersect_Y, 
        intersect_Z, 
        otherBody.position[1], 
        otherBody.position[2], 
        otherBody.position[3]
    )

    local angularVelSelfX, angularVelSelfY, angularVelSelfZ = vectorCrossProduct(
        self.angularVel[1], 
        self.angularVel[2], 
        self.angularVel[3], 
        relSelfX, 
        relSelfY, 
        relSelfZ
    )

    local angularVelOtherX, angularVelOtherY, angularVelOtherZ = vectorCrossProduct(
        otherBody.angularVel[1], 
        otherBody.angularVel[2], 
        otherBody.angularVel[3], 
        relOtherX, 
        relOtherY, 
        relOtherZ
    )

    local fullVelSelfX, fullVelSelfY, fullVelSelfZ = vectorAdd(
        self.velocity[1], 
        self.velocity[2], 
        self.velocity[3], 
        angularVelSelfX, 
        angularVelSelfY, 
        angularVelSelfZ
    )

    local fullVelOtherX, fullVelOtherY, fullVelOtherZ = vectorAdd(
        otherBody.velocity[1], 
        otherBody.velocity[2], 
        otherBody.velocity[3], 
        angularVelOtherX, 
        angularVelOtherY, 
        angularVelOtherZ
    )

    local contactVelX, contactVelY, contactVelZ = fastSubtract( 
        fullVelOtherX, 
        fullVelOtherY, 
        fullVelOtherZ, 
        fullVelSelfX, 
        fullVelSelfY, 
        fullVelSelfZ
    )

    local impulseForce = vectorDotProduct(contactVelX, contactVelY, contactVelZ, normal_X, normal_Y, normal_Z)

    local crossSelfX, crossSelfY, crossSelfZ = vectorCrossProduct(relSelfX, relSelfY, relSelfZ, normal_X, normal_Y, normal_Z)
    local crossOtherX, crossOtherY, crossOtherZ = vectorCrossProduct(relOtherX, relOtherY, relOtherZ, normal_X, normal_Y, normal_Z)
    local inertiaSelfX, inertiaSelfY, inertiaSelfZ = vectorCrossProduct(crossSelfX, crossSelfY, crossSelfZ, relSelfX, relSelfY, relSelfZ)
    local inertiaOtherX, inertiaOtherY, inertiaOtherZ = vectorCrossProduct(crossOtherX, crossOtherY, crossOtherZ, relOtherX, relOtherY, relOtherZ)

    local angularEffect = vectorDotProduct(
        inertiaSelfX + inertiaOtherX,
        inertiaSelfY + inertiaOtherY,
        inertiaSelfZ + inertiaOtherZ,
        normal_X,
        normal_Y,
        normal_Z
    )

    -- Formula if it had angular effect: j = (-(1 + cOfE) * impulseForce) / (inverseMassSum + angularEffect)
    local j = (-(1 + cOfE) * impulseForce) / inverseMassSum

    local fullImpulseX, fullImpulseY, fullImpulseZ = normal_X * j, normal_Y * j, normal_Z * j

    if self.mass ~= nil then
        self:applyLinearImpulse(-fullImpulseX, -fullImpulseY, -fullImpulseZ)
        -- self:applyAngularImpulse(
        --     vectorCrossProduct(
        --         relSelfX, 
        --         relSelfY, 
        --         relSelfZ, 
        --         -fullImpulseX, 
        --         -fullImpulseY, 
        --         -fullImpulseZ
        --     )
        -- )
    end

    if otherBody.mass ~= nil then
        otherBody:applyLinearImpulse(fullImpulseX, fullImpulseY, fullImpulseZ)
        -- otherBody:applyAngularImpulse(
        --     vectorCrossProduct(
        --         relOtherX, 
        --         relOtherY, 
        --         relOtherZ, 
        --         fullImpulseX, 
        --         fullImpulseY, 
        --         fullImpulseZ
        --     )
        -- )
    end
end

function rigidBody:resolveCollision(otherBody)
    local distance, intersect_X, intersect_Y, intersect_Z, normal_X, normal_Y, normal_Z = self:checkCollision(otherBody)
    if distance then
        self:processCollision(otherBody, distance, intersect_X, intersect_Y, intersect_Z, normal_X, normal_Y, normal_Z)
        return true
    end
    return false
end

-- Applies drage to force and updates acceleration
function rigidBody:processForces(dt) 
    if self.mass then
        -- Apply drag force
        local dragX = DRAG_COEFFICIENT * (self.velocity[1] ^ 2)
        local dragY = DRAG_COEFFICIENT * (self.velocity[2] ^ 2)
        local dragZ = DRAG_COEFFICIENT * (self.velocity[3] ^ 2)

        local signX, signY, signZ = 1, 1, 1
        if self.velocity[1] > 0 then signX = -1 end
        if self.velocity[2] > 0 then signY = -1 end
        if self.velocity[3] > 0 then signZ = -1 end

        self.velocity[1] = self.velocity[1] + (dragX / self.mass) * dt * signX
        self.velocity[2] = self.velocity[2] + (dragY / self.mass) * dt * signY
        self.velocity[3] = self.velocity[3] + (dragZ / self.mass) * dt * signZ
    end
end

function rigidBody:applyVelocity(dt)
    self.model:setTranslation(
        self.position[1] + self.velocity[1] * dt,
        self.position[2] + self.velocity[2] * dt,
        self.position[3] + self.velocity[3] * dt
    )
    -- Update collider center
    if self.collider.type == "sphere" then
        self.collider.center = {self.position[1], self.position[2], self.position[3]}
    elseif self.collider.type == "capsule" then
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
        self.collider.centerA = {self.position[1], self.position[2], self.position[3]}
        self.collider.centerB = {
            self.position[1] + heightDirX * heightMag,
            self.position[2] + heightDirY * heightMag,
            self.position[3] + heightDirZ * heightMag
        }
    end
end

function rigidBody:draw()
    self.model:draw()
end

function rigidBody:update(dt)
    if self.type == "dynamic" then
        self:applyGravity(dt)
        self:processForces(dt)
        self:applyVelocity(dt)
    end
end

return rigidBody