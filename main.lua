-- Imports
local g3d = require "g3d"
local json = require "extensions/json"
local rigidBody = require(".rigidBody")
local Object = require("objects")
local Inventory = require("inventory")

local gameInventory
local currentPlacementItem = nil
local placementPosition = {10, 0, 4}
local obstaclePrototypes = {}

-- Constants
local gameCenter = {10,0,4}
local lookDirection = "x"

-- Object Creation
local background = g3d.newModel("g3dAssets/sphere.obj", "g3dAssets/starfield.png", {0,0,0}, nil, {500,500,500})
local ballCursor = g3d.newModel("g3dAssets/sphere.obj", "kenney_prototype_textures/red/texture_08.png", {10,0,4}, nil, {0.25,0.25,0.25})

local clickPlane = g3d.newModel("g3dAssets/cube.obj", "kenney_prototype_textures/orange/texture_03.png", {10,0,9}, nil, {0.1,10,1})

-- 2D, sceneObjects[1][2] gives second object in first scene
local sceneObjects = {
    {
        -- Left Wall
        rigidBody:newRigidBody("g3dAssets/cube.obj", "kenney_prototype_textures/dark/texture_03.png", {10,10,4}, nil, {1,0.5,10.5}, "static", "verts"),

        -- Right Wall
        rigidBody:newRigidBody("g3dAssets/cube.obj", "kenney_prototype_textures/dark/texture_03.png", {10,-10,4}, nil, {1,0.5,10.5}, "static", "verts"),
        
        -- Floor
        rigidBody:newRigidBody("g3dAssets/cube.obj", "kenney_prototype_textures/dark/texture_03.png", {10,0,-7}, nil, {1,10.5,0.5}, "static", "verts"),

        -- Ramps
        rigidBody:newRigidBody("custom_assets/ramp.obj", "kenney_prototype_textures/purple/texture_03.png", {10,-3,-2}, nil, {0.1,1,-1}, "static", "verts"),
        rigidBody:newRigidBody("custom_assets/ramp.obj", "kenney_prototype_textures/purple/texture_03.png", {10,3,-2}, nil, {0.1,-1,-1}, "static", "verts"),

        rigidBody:newRigidBody("custom_assets/star.obj", "kenney_prototype_textures/purple/texture_03.png", {10,0,-2}, nil, {1,1,1}, "static", "verts"),
    }
}

local winBoxes = {
    rigidBody:newRigidBody("g3dAssets/cube.obj", "kenney_prototype_textures/green/texture_08.png", {10,7,0}, nil, {0.5,0.5,0.5}, "static", "verts"),
    rigidBody:newRigidBody("g3dAssets/cube.obj", "kenney_prototype_textures/green/texture_08.png", {10,-7,0}, nil, {0.5,0.5,0.5}, "static", "verts"),
}

local loseBoxes = {
    rigidBody:newRigidBody("g3dAssets/cube.obj", "kenney_prototype_textures/red/texture_08.png", {10,0,-5}, nil, {0.5,0.5,0.5}, "static", "verts"),
}
local wonGame = false
local lostGame = false

-- keep track of all rigid bodies that need to be physics simulated aren't static
local simulatedObjects = {}

-- 1 = plinko level
-- rest correspond to different rooms
local currentScene = 2

-- seconds before transitioning to plinko level
local timerLength = 2
local secondsElapsed = 0

-- contains all door objects
-- 2D, doors[2][2] gives second door in first room (corresponds to currentScene)
local doors = {{}}

-- map from door objects (rigidbody) to currentScene number
local doorMap = {}

-- text
local font
local instructionFont
local languageJson
local language = "english"

local function languageSetup()
    local jsonString = love.filesystem.read("languages.json")
    languageJson = json.decode(jsonString)
    if language == "english" then
        love.graphics.newFont(24)
        instructionFont = love.graphics.newFont(12)

    elseif language == "chinese" then
        font = love.graphics.newFont("fonts/chinese.ttf", 24)
        instructionFont = love.graphics.newFont("fonts/chinese.ttf", 12)

    elseif language == "arabic" then
        love.graphics.newFont("fonts/arabic.ttf", 24)
        instructionFont = love.graphics.newFont("fonts/arabic.ttf", 10)
    end
end
languageSetup()

local function createPlinkoArrangement(containerTable, startX, startY, startZ, rows, cols, spacingVert, spacingHorz)
    for row = 0, rows - 1 do
        for col = 0, cols - 1 do
            local offsetY = (row % 2) * (spacingHorz / 2)
            local posY = startY + col * spacingHorz + offsetY
            local posZ = startZ + row * spacingVert
            table.insert(containerTable, rigidBody:newRigidBody("g3dAssets/sphere.obj", "kenney_prototype_textures/purple/texture_08.png", 
                {startX, -posY, posZ}, 
                nil, 
                {0.2,0.2,0.2}, 
                "static", 
                "verts"
            ))
        end
    end
end
createPlinkoArrangement(sceneObjects[1], 10, -9, 3, 4, 15, 1.25, 1.25)

local function createDoor(doorConfig)
    local door = rigidBody:newRigidBody(
        "g3dAssets/cube.obj",
        "kenney_prototype_textures/light/texture_06.png",
        doorConfig[1],
        nil,
        {0.1, 1, 1.5},
        "static",
        "verts"
    )
    doorMap[door] = doorConfig[2]
    return door
end

-- doorOptions = table of arbitrary length composing of objects with a point {x, y, z} and target Scene
local function createDoors(scene, doorOptions)
    local allDoors = {}
    for i = 1, #doorOptions do
        local door = createDoor(doorOptions[i])
        table.insert(allDoors, door)
        table.insert(scene, door)
    end
    return allDoors
end

-- local function createScene1()
--     local scene = {}
--     local doorOptions = {{{10, 0, 0}, 3}}
--     local allDoors = createDoors(scene, doorOptions)
--     table.insert(doors, allDoors)
-- end

-- local function createScene2()
--     local scene = {}
--     local doorOptions = {{{10, 0, 5}, 2}}
--     local allDoors = createDoors(scene, doorOptions)

--     table.insert(sceneObjects, scene)
--     table.insert(doors, allDoors)
-- end

local function parseTranslationString(constants, translationValue)
    local newValue
    local currIndex
    if string.sub(translationValue, 1, 1) ~= "-" then
        newValue = 1
        currIndex = 1
    else
        newValue = -1
        currIndex = 2
    end
    
    local mathIndex = string.find(translationValue, "+", currIndex) or string.find(translationValue, "-", currIndex)
    if mathIndex == nil then
        return newValue * constants[string.sub(translationValue, currIndex)]
    else
        newValue = newValue * constants[string.sub(translationValue, currIndex, mathIndex-1)]
        if string.sub(translationValue, mathIndex, mathIndex) == "+" then
            return newValue + string.sub(translationValue, mathIndex+1)
        else
            return newValue - string.sub(translationValue, mathIndex+1)
        end
    end
end

local function parseTranslation(constants, object)
    local translation = {}
    for xyz, translationValue in pairs(object.translation) do
        local newValue
        if type(translationValue) == "string" then
            newValue = parseTranslationString(constants, translationValue)
        else
            newValue = translationValue
        end

        table.insert(translation, newValue)
    end

    return translation
end

local function parseRotation(constants, object)
    if object.rotation == nil then
        return nil
    end
    if type(object.rotation) == "string" then
        local rotation = constants[object.rotation]
        for xyz, rotationValue in pairs(rotation) do
            if rotationValue == "PI/2" then
                rotation[xyz] = math.pi/2
            elseif rotationValue == "PI" then
                rotation[xyz] = math.pi
            end
        end
        return {rotation.x, rotation.y, rotation.z}
    end
    return {0,0,0}
end

local function parseScale(constants, object)
    local scale = constants[object.scale]
    return {scale.x, scale.y, scale.z}
end

local function createScenes()
    local jsonString = love.filesystem.read("scenes.json")
    local jsonData = json.decode(jsonString)

    for sceneIndex, scene in ipairs(jsonData.scenes) do
        local newScene = {}
        for objectName, object in pairs(scene) do
            local model = jsonData.models[object.model]
            local texture = jsonData.textures[object.texture]
            local translation = parseTranslation(jsonData.constants, object)
            local rotation = parseRotation(jsonData.constants, object)
            local scale = parseScale(jsonData.constants, object)
            local newObject = g3d.newModel(model, texture, translation, rotation, scale)
            table.insert(newScene, newObject)
        end
        table.insert(sceneObjects, newScene)
    end
end
createScenes()

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

local function drawWinScreen()
    -- Background
    love.graphics.setColor(0, 255, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    -- Placeholder for win screen drawing logic
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.print(languageJson[language].win, love.graphics.getWidth() / 2 - 100, love.graphics.getHeight() / 2 - 10, nil, 4, 4)
end

local function drawLoseScreen()
    -- Background
    love.graphics.setColor(255, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    -- Placeholder for lose screen drawing logic
    love.graphics.setColor(255, 255, 255, 1)
    love.graphics.print(languageJson[language].lose, love.graphics.getWidth() / 2 - 100, love.graphics.getHeight() / 2 - 10, nil, 4, 4)
end

function love.load()
    calculateTransformPerScreenPixel()

    gameInventory = Inventory:new()

    -- Obstacle Items
    local cone = Object:new({
        name = "Cone",
        type = "Obstacle",
        modelPath = "custom_assets/Cone.obj",
        iconPath = "custom_assets/cone-metal.png" 
    })
    
    local halfPipe = Object:new({
        name = "Half Pipe",
        type = "Obstacle",
        modelPath = "custom_assets/halfpipe.obj",
        iconPath = "custom_assets/half-pipe.png"
    })

    local ramp = Object:new({
        name = "Ramp",
        type = "Obstacle",
        modelPath = "custom_assets/ramp.obj",
        iconPath = "custom_assets/ramp-steampunk.png"
    })

    local star = Object:new({
        name = "Star",
        type = "Obstacle",
        modelPath = "custom_assets/star.obj",
        iconPath = "custom_assets/star-steampunk.png"
    })

    -- Store the items for quick lookup for returns
    obstaclePrototypes[cone.name] = cone
    obstaclePrototypes[halfPipe.name] = halfPipe
    obstaclePrototypes[ramp.name] = ramp
    obstaclePrototypes[star.name] = star

    gameInventory.obstaclePrototypes = obstaclePrototypes
end

-- Clicking for when the inventory is up
function love.mousepressed(x, y, button, istouch, presses)
    if button == 1 then
        local clickedItem = gameInventory:checkClick(x, y)

        if clickedItem and type(clickedItem) == "table" then
            currentPlacementItem = clickedItem
            gameInventory:toggle() 
            return
        end

        if currentPlacementItem then
            -- Do nothing here. We handle the placement on love.mousereleased.
            return
        end

        -- Blocking clicking outside of the Inventory
        if gameInventory.isVisible then
            return
        end

        -- Check to return them to Inventory
        local worldx, worldy, worldz = getClickWorldPosition(x, y)
        if currentScene == 1 then
            for i = #sceneObjects[currentScene], 1, -1 do
                local obstacle = sceneObjects[currentScene][i]
                
                if obstacle.name then
                    local isClicked = false
                    
                    -- Check if custom pickup bounds exist (for the Conveyer)
                    if obstacle.pickupExtents then
                        -- Use the model's translation for current world position
                        local pos = obstacle.model.translation 
                        local extents = obstacle.pickupExtents
                        
                        -- Manual bounds check against the generous box
                        if worldx >= (pos[1] - extents[1]) and worldx <= (pos[1] + extents[1]) and
                           worldy >= (pos[2] - extents[2]) and worldy <= (pos[2] + extents[2]) and
                           worldz >= (pos[3] - extents[3]) and worldz <= (pos[3] + extents[3]) then
                            isClicked = true
                        end
                    else
                        -- Use the default AABB check for all other objects (Pistons, Ramps)
                        isClicked = obstacle.model:isPointInAABB({worldx, worldy, worldz})
                    end
                    
                    if isClicked then
                        gameInventory:returnItem(obstacle.name)
                        table.remove(sceneObjects[currentScene], i)
                        print("Returned obstacle: " .. obstacle.name .. " to inventory.")
                        return
                    end
                end
            end
        end
    end
end

local defaultScale = {1, 1, 1}
local defaultTexture = "kenney_prototype_textures/purple/texture_03.png"
function love.mousereleased(x, y, button)
    if button == 1 then
        if currentPlacementItem then

            local scale = defaultScale
            local texturePath = defaultTexture
            local collisionShape = "verts"
            local collisionParams = nil 
    
            local newObstacle = rigidBody:newRigidBody(
                currentPlacementItem.modelPath or "g3dAssets/cube.obj",
                texturePath,
                placementPosition,
                nil,
                scale,
                collisionShape,
                collisionParams
            )

            newObstacle.name = currentPlacementItem.name
            
            --Save custom extents to the object
            if collisionShape == "box" and collisionParams and collisionParams.extents then
                newObstacle.pickupExtents = collisionParams.extents
            end
            table.insert(sceneObjects[currentScene], newObstacle)
            print("Placed obstacle: " .. currentPlacementItem.name)
            -- Reset placement state
            currentPlacementItem = nil
            gameInventory:stopDragging()
        else
            if (clickPlane:isPointInAABB({ballCursor.translation[1], ballCursor.translation[2], ballCursor.translation[3]})) then
                local physBall = rigidBody:newRigidBody(
                    "g3dAssets/sphere.obj",
                    "kenney_prototype_textures/light/texture_08.png", 
                    {ballCursor.translation[1], ballCursor.translation[2], ballCursor.translation[3]}, 
                    nil, 
                    {0.25,0.25,0.25}, 
                    "dynamic", 
                    "sphere", 
                    {radius=0.25},
                    {lockedAxes={true, false, false}} -- Lock X axis
                )
                table.insert(simulatedObjects, physBall)
            end
        end
    end
end

-- Press I to bring up inventory
function love.keypressed(key)
    if key == "i" then
        gameInventory:toggle()
    end
end

function love.mousemoved(x,y, dx,dy)
    local mWorldPosX, mWorldPosY, mWorldPosZ = getClickWorldPosition(x, y)
    
    -- g3d.camera.firstPersonLook(dx,dy)

    if currentPlacementItem then -- Check if an item is being dragged
        placementPosition = {mWorldPosX, mWorldPosY, mWorldPosZ}
    else
        ballCursor:setTranslation(mWorldPosX, mWorldPosY, mWorldPosZ)
    end
end

local collidedThisFrame, wonThisFrame, lostThisFrame = false, false, false
local isPaused = false
function love.update(dt)
    if wonGame or lostGame then
        return
    end
    -- Make camera orthographic
    -- g3d.camera.updateOrthographicMatrix()

    -- g3d.camera.firstPersonMovement(dt)
    if love.keyboard.isDown("escape") then love.event.push("quit") end
    if love.keyboard.isDown("p") then isPaused = not isPaused end

    if not isPaused then
        if currentScene ~= 1 then
            secondsElapsed = secondsElapsed + dt
            if secondsElapsed >= timerLength then
                currentScene = 1
                secondsElapsed = 0
            end
        end

        -- check collisions between simulated balls and bounds
        for i = 1, #simulatedObjects do
            for j = 1, #sceneObjects[1] do
                if simulatedObjects[i].model:AABBIntersection(sceneObjects[1][j].model.aabb.minPoint, sceneObjects[1][j].model.aabb.maxPoint) then
                    collidedThisFrame = simulatedObjects[i]:resolveCollision(sceneObjects[1][j])
                end
                sceneObjects[1][j]:update(dt)
            end
            simulatedObjects[i]:update(dt)
        end

        -- check collision between ball and win/lose boxes
        for i = 1, #simulatedObjects do
            for winBoxInd = 1, #winBoxes do
                wonThisFrame = winBoxes[winBoxInd].model:isPointInAABB(simulatedObjects[i].position)
                if wonThisFrame then
                    wonGame = true
                    -- remove ball from simulation
                    table.remove(simulatedObjects, i)
                    return
                end
            end
            for loseBoxInd = 1, #loseBoxes do
                lostThisFrame = loseBoxes[loseBoxInd].model:isPointInAABB(simulatedObjects[i].position)
                if lostThisFrame then
                    lostGame = true
                    -- remove ball from simulation
                    table.remove(simulatedObjects, i)
                    return
                end
            end
        end
    end
end

function love.draw()
    -- earth:draw()
    -- moon:draw()
	
    if currentScene == 1 then
        background:draw()
    end

    if currentScene == 1 then
        if not currentPlacementItem then
            ballCursor:draw()
        end
        clickPlane:draw()

        for i = 1, #winBoxes do
            winBoxes[i]:draw()
        end
        for i = 1, #loseBoxes do
            loseBoxes[i]:draw()
        end
    else
        if font then love.graphics.setFont(font) end
        love.graphics.print(languageJson[language].timer .. (timerLength - math.floor(secondsElapsed)))
    end

    for i = 1, #simulatedObjects do
        simulatedObjects[i]:draw()
    end
    for i = 1, #sceneObjects[currentScene] do
        sceneObjects[currentScene][i]:draw()
    end

    if wonGame then
        drawWinScreen()
    end
    if lostGame then
        drawLoseScreen()
    end

    love.graphics.setFont(instructionFont)
    love.graphics.setColor(1, 1, 1, 1)

    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local textY = screenHeight - 40

    local openInvText = languageJson[language].openInv
    local openInvTextWidth = instructionFont:getWidth(openInvText)

    love.graphics.print(openInvText, screenWidth / 2 - openInvTextWidth - 150, textY)

    if not gameInventory.isVisible and not currentPlacementItem then
        local pickupText = languageJson[language].pickup
        local pickupTextWidth = instructionFont:getWidth(pickupText)

        love.graphics.print(pickupText, screenWidth / 2 + 150, textY)
    end
    gameInventory:draw()
end