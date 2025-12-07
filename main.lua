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

local wonGame = false
local lostGame = false

local leftArrowImage = love.graphics.newImage("custom_assets/arrowLeft.png")
local rightArrowImage = love.graphics.newImage("custom_assets/arrowRight.png")
local upArrowImage = love.graphics.newImage("custom_assets/arrowUp.png")
local downArrowImage = love.graphics.newImage("custom_assets/arrowDown.png")
local arrowScale = 0.05

-- Objects
local ballCursor = g3d.newModel("g3dAssets/sphere.obj", "kenney_prototype_textures/red/texture_08.png", {10,0,4}, nil, {0.25,0.25,0.25})
local clickPlane = g3d.newModel("g3dAssets/cube.obj", "kenney_prototype_textures/orange/texture_03.png", {10,0,9}, nil, {0.1,10,1})

-- keep track of all rigid bodies that need to have movement physics simulated
local simulatedObjects = {}

local titleScreen = 1
local plinkoLevel1 = 2
local plinkoLevel2 = 3
local searchRoom1 = 4
local searchRoom2 = 5

local plinkoLevels = {plinkoLevel1, plinkoLevel2}
local searchRooms = {searchRoom1, searchRoom2}

local currentScene = titleScreen

-- seconds before transitioning to plinko level (counts down to zero)
local timer = 60

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

-- 2D, sceneObjects[1][2] gives second object in first scene
local sceneObjects = {}

local winBoxes = {}

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


-------------------------------------------------------------------------------------------------------
---
--- Title and End Scene Creation
---
-------------------------------------------------------------------------------------------------------


-- Function for creating the title scene with cube-formed-letters
local function createTitleScene()
    local scene = { nonSimulatedObjects = {} }
    
    -- Letter patterns (5x7 grid for each letter, 1 = cube present, 0 = empty)
    local letterPatterns = {
        D = {
            {1,1,1,0,0},
            {1,0,0,1,0},
            {1,0,0,0,1},
            {1,0,0,0,1},
            {1,0,0,0,1},
            {1,0,0,1,0},
            {1,1,1,0,0}
        },
        I = {
            {1,1,1,1,1},
            {0,0,1,0,0},
            {0,0,1,0,0},
            {0,0,1,0,0},
            {0,0,1,0,0},
            {0,0,1,0,0},
            {1,1,1,1,1}
        },
        L = {
            {1,0,0,0,0},
            {1,0,0,0,0},
            {1,0,0,0,0},
            {1,0,0,0,0},
            {1,0,0,0,0},
            {1,0,0,0,0},
            {1,1,1,1,1}
        },
        R = {
            {1,1,1,1,1},
            {1,0,0,0,1},
            {1,0,0,0,1},
            {1,1,1,1,1},
            {1,0,1,0,0},
            {1,0,0,1,0},
            {1,0,0,0,1}
        },
        O = {
            {0,1,1,1,0},
            {1,0,0,0,1},
            {1,0,0,0,1},
            {1,0,0,0,1},
            {1,0,0,0,1},
            {1,0,0,0,1},
            {0,1,1,1,0}
        },
        K = {
            {1,0,0,0,1},
            {1,0,0,1,0},
            {1,0,1,0,0},
            {1,1,0,0,0},
            {1,0,1,0,0},
            {1,0,0,1,0},
            {1,0,0,0,1}
        },
        P = {
            {1,1,1,1,1},
            {1,0,0,0,1},
            {1,0,0,0,1},
            {1,1,1,1,1},
            {1,0,0,0,0},
            {1,0,0,0,0},
            {1,0,0,0,0}
        },
        C = {
            {0,1,1,1,0},
            {1,0,0,0,1},
            {1,0,0,0,0},
            {1,0,0,0,0},
            {1,0,0,0,0},
            {1,0,0,0,1},
            {0,1,1,1,0}
        }
    }
    
    local letters = {"K", "C", "I", "L","C", "P", "O", "R", "D"} -- Sorry I had to spell it backwards for positioning
    local cubeSize = 0.4
    local spacing = 0.1
    local letterSpacing = 0.8
    
    -- Calculate total width of title to center it
    local totalWidth = (#letters * (5 * (cubeSize + spacing) + letterSpacing)) - letterSpacing
    
    -- Starting position for the title (centered, slightly left)
    local startX = 16
    local startY = -totalWidth / 2 + 0.3
    local startZ = 1
    
    -- Create each letter
    for letterIndex, letter in ipairs(letters) do
        local pattern = letterPatterns[letter]
        local letterOffsetY = (letterIndex - 1) * (5 * (cubeSize + spacing) + letterSpacing)
        
        -- Create cubes for this letter based on pattern
        for row = 1, #pattern do
            for col = 1, #pattern[row] do
                if pattern[row][col] == 1 then
                    local posX = startX
                    local posY = startY + letterOffsetY + (4 - col) * (cubeSize + spacing)  -- Mirror horizontally
                    local posZ = startZ - (row - 1) * (cubeSize + spacing)
                    
                    local cube = g3d.newModel(
                        "g3dAssets/cube.obj",
                        "kenney_prototype_textures/orange/texture_01.png",
                        {posX, posY, posZ},
                        {0, math.pi/2, 0},  -- Rotate 90 degrees around Y-axis to face camera
                        {cubeSize, cubeSize, cubeSize}
                    )
                    table.insert(scene.nonSimulatedObjects, cube)
                end
            end
        end
    end
    
    table.insert(sceneObjects, 1, scene)  -- Insert at beginning to make it scene 1
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


------------------------------------------------------------------------------------------------------
---
--- Utility Functions
---
------------------------------------------------------------------------------------------------------


local function createPlinkoArrangement(plinkoScene, startX, startY, startZ, rows, cols, spacingVert, spacingHorz)
    for row = 0, rows - 1 do
        for col = 0, cols - 1 do
            local offsetY = (row % 2) * (spacingHorz / 2)
            local posY = startY + col * spacingHorz + offsetY
            local posZ = startZ + row * spacingVert
            table.insert(plinkoScene, rigidBody:newRigidBody("g3dAssets/sphere.obj", "kenney_prototype_textures/dark/texture_03.png", 
                {startX, -posY, posZ}, 
                nil, 
                {0.2,0.2,0.2}, 
                "static", 
                "verts"
            ))
        end
    end
end

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


-----------------------------------------------------------------------------------------------------
---
--- Plinko Level Creation
---
-----------------------------------------------------------------------------------------------------


local function createPlinkoScene1()
    local plinkoScene = { 
        nonSimulatedObjects = {
            -- Background
            g3d.newModel("g3dAssets/sphere.obj", "g3dAssets/starfield.png", {0,0,0}, nil, {500,500,500}),

            clickPlane,
        },
        bounds = {
            -- Left Wall
            rigidBody:newRigidBody("g3dAssets/cube.obj", "kenney_prototype_textures/dark/texture_03.png", {10,10,4}, nil, {1,0.5,10.5}, "static", "verts"),

            -- Right Wall
            rigidBody:newRigidBody("g3dAssets/cube.obj", "kenney_prototype_textures/dark/texture_03.png", {10,-10,4}, nil, {1,0.5,10.5}, "static", "verts"),
            
            -- Floor
            rigidBody:newRigidBody("g3dAssets/cube.obj", "kenney_prototype_textures/dark/texture_03.png", {10,0,-7}, nil, {1,10.5,0.5}, "static", "verts"),

            -- Ramps
            rigidBody:newRigidBody("custom_assets/ramp.obj", "kenney_prototype_textures/purple/texture_03.png", {10,-3,-2}, nil, {0.1,1,-1}, "static", "verts"),
            rigidBody:newRigidBody("custom_assets/ramp.obj", "kenney_prototype_textures/purple/texture_03.png", {10,3,-2}, nil, {0.1,-1,-1}, "static", "verts"),
            rigidBody:newRigidBody("custom_assets/star.obj", "kenney_prototype_textures/purple/texture_03.png", {10,0,-2}, nil, {1,1,1}, "static", "verts")
        },
        winBoxes = {
            rigidBody:newRigidBody("g3dAssets/cube.obj", "kenney_prototype_textures/green/texture_08.png", {10,7,0}, nil, {0.5,0.5,0.5}, "static", "verts"),
            rigidBody:newRigidBody("g3dAssets/cube.obj", "kenney_prototype_textures/green/texture_08.png", {10,-7,0}, nil, {0.5,0.5,0.5}, "static", "verts"),
        },
        loseBoxes = {
            rigidBody:newRigidBody("g3dAssets/cube.obj", "kenney_prototype_textures/red/texture_08.png", {10,0,-5}, nil, {0.5,0.5,0.5}, "static", "verts"),
        },
    }
    createPlinkoArrangement(plinkoScene.bounds, 10, -9, 3, 4, 15, 1.25, 1.25)

    table.insert(sceneObjects, plinkoScene)
end

local function createPlinkoScene2()
        local texture = "kenney_prototype_textures/dark/texture_03.png"
    local rhombusTexture = "kenney_prototype_textures/dark/texture_01.png"

    local rhombusModel = "custom_assets/Rhombus.obj"
    local defaultRhombusScale = {0.1, 6, 0.5}
    local negativeRhombusScale = {0.1, -6, 0.5}
    local smallRhombusScale = {0.1, 1, 0.2}

    local plinkoScene = {
        nonSimulatedObjects = {
            clickPlane,
        },
        bounds = {
            -- Rhombus 1 (Top-most)
            -- rigidBody:newRigidBody(
            --     rhombusModel, 
            --     rhombusTexture, 
            --     {10.0, 5.0, 5.0}, 
            --     nil,
            --     negativeRhombusScale, 
            --     "static", 
            --     "verts"
            -- ),
            
            -- Rhombus 2 (Middle)
            rigidBody:newRigidBody(
                rhombusModel, 
                rhombusTexture, 
                {10.0, -4.0, 1.5}, 
                nil, 
                defaultRhombusScale, 
                "static", 
                "verts"
            ),

            -- Rhombus 3 (Bottom-most of the top three)
            rigidBody:newRigidBody(
                rhombusModel, 
                rhombusTexture, 
                {10, 4, -1.5}, 
                nil, 
                negativeRhombusScale, 
                "static", 
                "verts"
            ),

            rigidBody:newRigidBody(
                rhombusModel, 
                rhombusTexture, 
                {10, 5, -6.5}, 
                nil, 
                smallRhombusScale, 
                "static", 
                "verts"
            ),

            rigidBody:newRigidBody(
                rhombusModel, 
                rhombusTexture, 
                {10, 2, -6}, 
                nil, 
                smallRhombusScale, 
                "static", 
                "verts"
            ),

            rigidBody:newRigidBody(
                rhombusModel, 
                rhombusTexture, 
                {10, -1, -5.5}, 
                nil, 
                smallRhombusScale, 
                "static", 
                "verts"
            ),

            rigidBody:newRigidBody(
                rhombusModel, 
                rhombusTexture, 
                {10, -4, -5}, 
                nil, 
                smallRhombusScale, 
                "static", 
                "verts"
            ),
        }
    }

    createPlinkoArrangement(plinkoScene.bounds, 10, -11, 5, 2, 18, 1.25, 1.25)

    table.insert(sceneObjects, plinkoScene)
end

---------------------------------------------------------------------------------------------------------
---
--- Door Creation Functions
---
---------------------------------------------------------------------------------------------------------


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


-----------------------------------------------------------------------------------------------------
---
--- Scene Creation from JSON
---
-----------------------------------------------------------------------------------------------------


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
    for i = 1, 3 do
        local translationValue
        if i == 1 then translationValue = object.translation["x"]
        elseif i == 2 then translationValue = object.translation["y"]
        else translationValue = object.translation["z"] end
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

local function parseArrows(arrows, newScene)
    newScene.arrows = {}
    for arrowName, arrow in pairs(arrows) do
        local newArrow = {}

        if arrow.direction == "left" then newArrow.image = leftArrowImage
        elseif arrow.direction == "up" then newArrow.image = upArrowImage
        elseif arrow.direction == "right" then newArrow.image = rightArrowImage
        else newArrow.image = downArrowImage end

        newArrow.width, newArrow.height = newArrow.image:getPixelDimensions()
        newArrow.width = newArrow.width * arrowScale
        newArrow.height = newArrow.height * arrowScale

        newArrow.position = arrow.position
        newArrow.scale = arrowScale
        newArrow.targetScene = arrow.targetScene

        table.insert(newScene.arrows, newArrow)
    end
end

local function createScenes()
    local jsonString = love.filesystem.read("scenes.json")
    local jsonData = json.decode(jsonString)

    for sceneIndex, scene in ipairs(jsonData.scenes) do
        local newScene = { nonSimulatedObjects = {} }
        for objectName, object in pairs(scene.objects) do
            local model = jsonData.models[object.model]
            local texture = jsonData.textures[object.texture]
            local translation = parseTranslation(jsonData.constants, object)
            local rotation = parseRotation(jsonData.constants, object)
            local scale = parseScale(jsonData.constants, object)
            local newObject = g3d.newModel(model, texture, translation, rotation, scale)
            table.insert(newScene.nonSimulatedObjects, newObject)
        end

        parseArrows(scene.arrows, newScene)

        table.insert(sceneObjects, newScene)
    end
end


-------------------------------------------------------------------------------------------------
---
--- Game Initialization
---
-------------------------------------------------------------------------------------------------


local screenWidth = love.graphics.getWidth()
local screenHeight = love.graphics.getHeight()
local continueText = languageJson[language].continue
local continueTextWidth = instructionFont:getWidth(continueText)
local textY = screenHeight - 40

local prevCurrentScene = currentScene

love.graphics.print(continueText, screenWidth / 2 - continueTextWidth - 150, textY)

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

    local startingStar = rigidBody:newRigidBody(
        star.modelPath,
        "kenney_prototype_textures/purple/texture_03.png", 
        {10, 0, 0},
        nil,
        {1, 1, 1},
        "static", 
        "verts"
    )


    startingStar.name = star.name

    --print(ramp)
    --gameInventory.addItem(obstaclePrototypes["Ramp"])

    createTitleScene()
    createPlinkoScene1()
    createPlinkoScene2()
    createScenes()
    --table.insert(sceneObjects[currentScene], ramp)
    if not sceneObjects[currentScene].inventoryObjects then sceneObjects[currentScene].inventoryObjects = {} end
    table.insert(sceneObjects[currentScene].inventoryObjects, startingStar)
    print("Test obstacle 'Star' placed in scene 1. Try clicking it!")
end


-------------------------------------------------------------------------------------------------
---
--- Input Handling
---
-------------------------------------------------------------------------------------------------


-- Clicking for when the inventory is up
function love.mousepressed(x, y, button, istouch, presses)
    if button == 1 then
        -- Transition from title screen on tap/click
        if currentScene == titleScreen then
            currentScene = searchRoom1
            return
        end
        
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
        for i = #sceneObjects[currentScene], 1, -1 do
            local obstacle = sceneObjects[currentScene][i]
                
            if obstacle.name then
                local isClicked = false
                    
                -- Use default AABB for simpler objects
                isClicked = obstacle.model:isPointInAABB({worldx, worldy, worldz})
                    
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

local function isInPlinkoScene()
    for i = 1, #plinkoLevels do
        if currentScene == plinkoLevels[i] then return true end
    end
    return false
end

local function pointIsBetweenBounds(pointX, pointY, boundPosX, boundPosY, boundWidth, boundHeight)
    local pointWithinX = pointX < boundPosX + boundWidth and pointX > boundPosX
    local pointWithinY = pointY < boundPosY + boundHeight and pointY > boundPosY
    return pointWithinX and pointWithinY
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
            local collisionStatic = "static"
    
            local newObstacle = rigidBody:newRigidBody(
                currentPlacementItem.modelPath or "g3dAssets/cube.obj",
                texturePath,
                placementPosition,
                nil,
                scale,
                collisionStatic,
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
            
        elseif isInPlinkoScene() then
            -- Check if ball cursor is within the orange clickPlane box
            local ballPos = {ballCursor.translation[1], ballCursor.translation[2], ballCursor.translation[3]}
            if clickPlane and clickPlane.aabb and clickPlane:isPointInAABB(ballPos) then
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

        else
            if sceneObjects[currentScene].arrows then
                for i = 1, #sceneObjects[currentScene].arrows do
                    local arrow = sceneObjects[currentScene].arrows[i]
                    if pointIsBetweenBounds(
                        x, y,
                        arrow.position.x,
                        arrow.position.y,
                        arrow.width,
                        arrow.height
                    ) then
                        currentScene = arrow.targetScene
                    end
                end
            end
        end
    end
end

-- Press I to bring up inventory and P to pause
local isPaused = false
function love.keypressed(key)
    -- Transition from title screen to searching room on any key press
    if currentScene == titleScreen then
        currentScene = searchRoom1
        return
    end
    
    if key == "i" then
        gameInventory:toggle()
    end

    if key == "p" then
        isPaused = not isPaused
    end

    -- DElETE THIS ONCE GAME IS DONE ------------------ for testing, changes scene on number keys
    local sceneNumber = tonumber(key)
    if sceneNumber and sceneNumber >= 1 and sceneNumber <= #sceneObjects then
        currentScene = sceneNumber
        print("Switched to scene " .. sceneNumber)
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


-------------------------------------------------------------------------------------------------
---
--- Main Update and Draw Loops
---
-------------------------------------------------------------------------------------------------


function love.update(dt)
    if wonGame or lostGame or isPaused then
        return
    end
    if prevCurrentScene ~= currentScene then
        simulatedObjects = {}
        prevCurrentScene = currentScene
    end
    -- Make camera orthographic
    -- g3d.camera.updateOrthographicMatrix()

    -- g3d.camera.firstPersonMovement(dt)
    if love.keyboard.isDown("escape") then love.event.push("quit") end

    if currentScene >= searchRoom1 then
        timer = timer - dt
        if timer <= 0 then
            timer = 60
            currentScene = plinkoLevel1
        end
    end

    -- check collisions between simulated balls and bounds
    if isInPlinkoScene() then
        for i = 1, #simulatedObjects do 
            if sceneObjects[currentScene].bounds == nil then
                break
            end

             -- Check collision with all bounds in the scene
            for j = 1, #sceneObjects[currentScene].bounds do
                if sceneObjects[currentScene].bounds[j].model then
                    -- Passes in min and max point of given AABB scene object and checks with simulated object, resolves collision if intersecting
                    if simulatedObjects[i].model:AABBIntersection(sceneObjects[currentScene].bounds[j].model.aabb.minPoint, sceneObjects[currentScene].bounds[j].model.aabb.maxPoint) then
                        simulatedObjects[i]:resolveCollision(sceneObjects[currentScene].bounds[j])
                    end
                end
            end
            simulatedObjects[i]:update(dt)
        end
    end

    -- check collision between ball and win/lose boxes
    for i = 1, #simulatedObjects do
        if sceneObjects[currentScene].winBoxes then

            for winBoxInd = 1, #sceneObjects[currentScene].winBoxes do
                local wonThisFrame = sceneObjects[currentScene].winBoxes[winBoxInd].model:isPointInAABB(simulatedObjects[i].position)
                if wonThisFrame then
                    wonGame = true
                    print("win")
                    table.remove(simulatedObjects, i)
                    return
                end
            end
            
        end
        if sceneObjects[currentScene].loseBoxes then

            for loseBoxInd = 1, #sceneObjects[currentScene].loseBoxes do
                local lostThisFrame = sceneObjects[currentScene].loseBoxes[loseBoxInd].model:isPointInAABB(simulatedObjects[i].position)
                if lostThisFrame then
                    lostGame = true
                    print("lose")
                    table.remove(simulatedObjects, i)
                    return
                end
            end

        end
    end
end

local function drawFromTable(objectTable)
    if objectTable then
        for i = 1, #objectTable do
            objectTable[i]:draw()
        end
    end
end

function love.draw() 
    if isInPlinkoScene() and not currentPlacementItem then
        ballCursor:draw()

    elseif currentScene >= searchRoom1 then
        if font then love.graphics.setFont(font) end
        love.graphics.print(languageJson[language].timer .. math.ceil(timer))
    end

    for i = 1, #simulatedObjects do
        simulatedObjects[i]:draw()
    end

    -- Draw scene specific objects --
        for propertyName, property in pairs(sceneObjects[currentScene]) do
            if type(property) == "table" and propertyName ~= "arrows" then
                drawFromTable(property)
            end
        end

        if sceneObjects[currentScene].arrows then
            for i = 1, #sceneObjects[currentScene].arrows do
                local arrow = sceneObjects[currentScene].arrows[i]
                love.graphics.draw(
                    arrow.image,
                    arrow.position.x,
                    arrow.position.y,
                    0,
                    arrowScale,
                    arrowScale
                )
            end
        end
    ---------------------------------

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

    -- Display "Press any key to continue" on title screen
    if currentScene == titleScreen then
        if font then love.graphics.setFont(font) end
        local continueText = languageJson[language].continue
        local continueTextWidth = (font or instructionFont):getWidth(continueText)
        love.graphics.print(continueText, screenWidth / 2 - continueTextWidth / 2, 40)
        love.graphics.setFont(instructionFont)
    end

    -- Only show inventory instructions if not on title screen
    if currentScene ~= titleScreen then
        local openInvText = languageJson[language].openInv
        local openInvTextWidth = instructionFont:getWidth(openInvText)

        love.graphics.print(openInvText, screenWidth / 2 - openInvTextWidth - 150, textY)

        if not gameInventory.isVisible and not currentPlacementItem then
            local pickupText = languageJson[language].pickup
            local pickupTextWidth = instructionFont:getWidth(pickupText)

            love.graphics.print(pickupText, screenWidth / 2 + 150, textY)
        end
    end
    gameInventory:draw()
end