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
local ghostModel = nil

-- I have made a change

-- Constants
local gameCenter = {10,0,4}
local lookDirection = "x"

local wonGame = false
local lostGame = false
local playAgainButton = {x = 0, y = 0, width = 200, height = 60}
local quitButton = {x = 0, y = 0, width = 200, height = 60}

local languageOptionImage = love.graphics.newImage("custom_assets/darkYellowSquare.png")

local openInventoryImage = love.graphics.newImage("custom_assets/openInventoryButton.png")
local closeInventoryImage = love.graphics.newImage("custom_assets/closeInventoryButton.png")

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

local mainMenuButtonsData = {}
local inventoryButtonData = {}

local titleScreen = 1
local plinkoLevel1 = 2
local plinkoLevel2 = 3
local searchRoom1 = 4
local searchRoom2 = 5

local plinkoLevels = {plinkoLevel1, plinkoLevel2}
local searchRooms = {searchRoom1, searchRoom2}

local currentScene = titleScreen

-- Ball ammo counter
local maxBallAmmo = 5
local ballAmmo = maxBallAmmo

-- seconds before transitioning to plinko level (counts down to zero)
local timerCooldown = 60
local timer = timerCooldown

-- text
local font
local languageJson
local language = "english"
local englishFont = love.graphics.newFont(24)
local chineseFont = love.graphics.newFont("fonts/chinese.ttf", 24)
local arabicFont = love.graphics.newFont("fonts/arabic.ttf", 24)

-- 2D, sceneObjects[1][2] gives second object in first scene
local sceneObjects = {}

local function getFont(lang)
    if lang == "english" then return englishFont end
    if lang == "chinese" then return chineseFont end
    if lang == "arabic" then return arabicFont end
end

local function updateLanguage()
    font = getFont(language)
end

local function languageSetup()
    local jsonString = love.filesystem.read("languages.json")
    languageJson = json.decode(jsonString)
    updateLanguage()
end
languageSetup()


-------------------------------------------------------------------------------------------------------
---
--- Title and End Scene Creation
---
-------------------------------------------------------------------------------------------------------


local function updateButtonDimensions(buttonData)
    buttonData.width, buttonData.height = buttonData.image:getPixelDimensions()
    buttonData.width = buttonData.width * buttonData.scale
    buttonData.height = buttonData.height * buttonData.scale
end

local function createLanguageButtons()
    local tempLang = language
    for i = 1, #languageJson.supportedLanguages do
        local newButtonData = {}
        newButtonData.textData = {}
        newButtonData.imageData = {}

        newButtonData.textData.language = languageJson.supportedLanguages[i].localized
        newButtonData.textData.font = getFont(newButtonData.textData.language)

        newButtonData.textData.text = languageJson.supportedLanguages[i].native
        newButtonData.textData.width = newButtonData.textData.font:getWidth(newButtonData.textData.text)
        newButtonData.textData.height = newButtonData.textData.font:getHeight(newButtonData.textData.text)

        newButtonData.imageData.image = languageOptionImage
        newButtonData.imageData.scale = 1
        updateButtonDimensions(newButtonData.imageData)

        newButtonData.imageData.scale = {
            ["x"] = (newButtonData.textData.width / newButtonData.imageData.width) * 1.5,
            ["y"] = (newButtonData.textData.height / newButtonData.imageData.height) * 1.35
        }
        newButtonData.imageData.width = newButtonData.imageData.width * newButtonData.imageData.scale.x
        newButtonData.imageData.height = newButtonData.imageData.height * newButtonData.imageData.scale.y

        table.insert(mainMenuButtonsData, newButtonData)

        language = tempLang
        updateLanguage()
    end
end

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
    local startZ = 5
    
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

    createLanguageButtons()
    
    table.insert(sceneObjects, 1, scene)  -- Insert at beginning to make it scene 1
end

local function drawWinScreen()
    -- Background
    love.graphics.setColor(0, 255, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    -- Win text
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.print(languageJson.text[language].win, love.graphics.getWidth() / 2 - 200, love.graphics.getHeight() / 2 - 100, nil, 4, 4)
    
    -- Play Again button
    playAgainButton.x = love.graphics.getWidth() / 2 - playAgainButton.width / 2
    playAgainButton.y = love.graphics.getHeight() / 2 + 100
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("fill", playAgainButton.x, playAgainButton.y, playAgainButton.width, playAgainButton.height)
    
    love.graphics.setColor(0, 0, 0, 1)
    local buttonText = languageJson.text[language].playAgain
    local textWidth = font:getWidth(buttonText)
    love.graphics.print(buttonText, playAgainButton.x + playAgainButton.width / 2 - textWidth / 2, playAgainButton.y + 15)
    
    -- Quit Game button
    quitButton.x = love.graphics.getWidth() / 2 - quitButton.width / 2
    quitButton.y = playAgainButton.y + playAgainButton.height + 20
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("fill", quitButton.x, quitButton.y, quitButton.width, quitButton.height)
    
    love.graphics.setColor(0, 0, 0, 1)
    local quitText = languageJson.text[language].quit
    local quitTextWidth =font:getWidth(quitText)
    love.graphics.print(quitText, quitButton.x + quitButton.width / 2 - quitTextWidth / 2, quitButton.y + 15)
end

local function drawLoseScreen()
    -- Background
    love.graphics.setColor(255, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    -- Lose text
    love.graphics.setColor(255, 255, 255, 1)
    love.graphics.print(languageJson.text[language].lose, love.graphics.getWidth() / 2 - 220, love.graphics.getHeight() / 2 - 100, nil, 4, 4)
    
    -- Play Again button
    playAgainButton.x = love.graphics.getWidth() / 2 - playAgainButton.width / 2
    playAgainButton.y = love.graphics.getHeight() / 2 + 100
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("fill", playAgainButton.x, playAgainButton.y, playAgainButton.width, playAgainButton.height)
    
    love.graphics.setColor(0, 0, 0, 1)
    local buttonText = languageJson.text[language].playAgain
    local textWidth = font:getWidth(buttonText)
    love.graphics.print(buttonText, playAgainButton.x + playAgainButton.width / 2 - textWidth / 2, playAgainButton.y + 15)
    
    -- Quit Game button
    quitButton.x = love.graphics.getWidth() / 2 - quitButton.width / 2
    quitButton.y = playAgainButton.y + playAgainButton.height + 20
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("fill", quitButton.x, quitButton.y, quitButton.width, quitButton.height)
    
    love.graphics.setColor(0, 0, 0, 1)
    local quitText = languageJson.text[language].quit
    local quitTextWidth = font:getWidth(quitText)
    love.graphics.print(quitText, quitButton.x + quitButton.width / 2 - quitTextWidth / 2, quitButton.y + 15)
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

local function isInPlinkoScene()
    for i = 1, #plinkoLevels do
        if currentScene == plinkoLevels[i] then return true end
    end
    return false
end

local function isInSearchRoom()
    for i = 1, #searchRooms do
        if currentScene == searchRooms[i] then return true end
    end
    return false
end

local function pointIsBetweenBounds(pointX, pointY, boundPosX, boundPosY, boundWidth, boundHeight)
    local pointWithinX = pointX < boundPosX + boundWidth and pointX > boundPosX
    local pointWithinY = pointY < boundPosY + boundHeight and pointY > boundPosY
    return pointWithinX and pointWithinY
end

local function swapInventoryButtonImage()
    if inventoryButtonData.image == openInventoryImage then
        inventoryButtonData.image = closeInventoryImage
    else inventoryButtonData.image = openInventoryImage end
end


-----------------------------------------------------------------------------------------------------
---
--- Plinko Level Creation
---
-----------------------------------------------------------------------------------------------------


local function createInventoryButton()
    inventoryButtonData.roomData = {}
    inventoryButtonData.plinkoData = {}

    inventoryButtonData.image = openInventoryImage

    inventoryButtonData.roomData.position = {["x"] = 710, ["y"] = 10}
    inventoryButtonData.position = {}

    inventoryButtonData.roomData.scale = 0.1
    inventoryButtonData.plinkoData.scale = 0.05
    inventoryButtonData.scale = inventoryButtonData.roomData.scale

    updateButtonDimensions(inventoryButtonData)
end

local function createPlinkoScene1()
    local plinkoScene = { 
        nonSimulatedObjects = {
            -- Background
            g3d.newModel("g3dAssets/sphere.obj", "steampunkAssets/textures/wood/Substance_graph_diffuse.png", {0,0,0}, nil, {500,500,500}),

            clickPlane,
        },
        bounds = {
            -- Left Wall
            rigidBody:newRigidBody("g3dAssets/cube.obj", "kenney_prototype_textures/dark/texture_03.png", {10,10,0}, nil, {1,0.5,14}, "static", "verts"),

            -- Right Wall
            rigidBody:newRigidBody("g3dAssets/cube.obj", "kenney_prototype_textures/dark/texture_03.png", {10,-10,0}, nil, {1,0.5,14}, "static", "verts"),

            -- Ramps
            rigidBody:newRigidBody("custom_assets/ramp.obj", "kenney_prototype_textures/dark/texture_03.png", {10,-4.5,-4}, nil, {0.1,2,-1}, "static", "verts"),
            rigidBody:newRigidBody("custom_assets/ramp.obj", "kenney_prototype_textures/dark/texture_03.png", {10,4.5,-4}, nil, {0.1,-2,-1}, "static", "verts"),

            -- Upper Slopes
            rigidBody:newRigidBody("custom_assets/Rhombus.obj", "kenney_prototype_textures/dark/texture_03.png", {10,-1.5,0}, nil, {0.5,-1,0.5}, "static", "verts"),
            rigidBody:newRigidBody("custom_assets/Rhombus.obj", "kenney_prototype_textures/dark/texture_03.png", {10,1.5,0}, nil, {0.5,1,0.5}, "static", "verts"),

            -- Side winbox defenders
            rigidBody:newRigidBody("g3dAssets/cube.obj", "kenney_prototype_textures/dark/texture_03.png", {10,8,0}, nil, {0.5,2.5,0.5}, "static", "verts"),
            rigidBody:newRigidBody("g3dAssets/cube.obj", "kenney_prototype_textures/dark/texture_03.png", {10,-8,0}, nil, {0.5,2.5,0.5}, "static", "verts"),
        },
        winBoxes = {
            rigidBody:newRigidBody("g3dAssets/cube.obj", "kenney_prototype_textures/green/texture_08.png", {10,8,-3.7}, nil, {0.5,1.5,0.5}, "static", "verts"),
            rigidBody:newRigidBody("g3dAssets/cube.obj", "kenney_prototype_textures/green/texture_08.png", {10,-8,-3.7}, nil, {0.5,1.5,0.5}, "static", "verts"),
        },
        loseBoxes = {
            rigidBody:newRigidBody("g3dAssets/cube.obj", "kenney_prototype_textures/red/texture_08.png", {10,0,-6}, nil, {0.5,2,0.5}, "static", "verts"),
            rigidBody:newRigidBody("g3dAssets/cube.obj", "kenney_prototype_textures/red/texture_08.png", {10,0,0.5}, nil, {0.5,0.45,0.5}, "static", "verts"),
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
            -- Background
            g3d.newModel("g3dAssets/sphere.obj", "steampunkAssets/textures/wood/Substance_graph_diffuse.png", {0,0,0}, nil, {500,500,500}),

            clickPlane,
        },
        bounds = {
            -- Rhombus 1 (Middle)
            rigidBody:newRigidBody(
                rhombusModel, 
                rhombusTexture, 
                {10.0, -4.0, 1.5}, 
                nil, 
                defaultRhombusScale, 
                "static", 
                "verts"
            ),

            -- Rhombus 2 (Bottom-most of the top three)
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
        },
        winBoxes = {
            rigidBody:newRigidBody("g3dAssets/cube.obj", "kenney_prototype_textures/green/texture_08.png", {10,7.5,-8}, nil, {0.5,2,0.5}, "static", "verts"),
        },
        loseBoxes = {
            rigidBody:newRigidBody("g3dAssets/cube.obj", "kenney_prototype_textures/red/texture_08.png", {10,-1,-8}, nil, {0.5,6.45,0.5}, "static", "verts"),
        },
    }

    createPlinkoArrangement(plinkoScene.bounds, 10, -11, 5, 2, 18, 1.25, 1.25)

    table.insert(sceneObjects, plinkoScene)
end


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

local function parseObjects(jsonData, objects, newScene)
    newScene.nonSimulatedObjects = {}
    for objectName, object in pairs(objects) do
        local model = jsonData.models[object.model]
        local texture = jsonData.textures[object.texture]
        local translation = parseTranslation(jsonData.constants, object)
        local rotation = parseRotation(jsonData.constants, object)
        local scale = parseScale(jsonData.constants, object)
        local newObject = g3d.newModel(model, texture, translation, rotation, scale)
        table.insert(newScene.nonSimulatedObjects, newObject)
    end
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

local function parseObstacles(jsonData, playerObstacles, newScene)
    newScene.playerObstacles = {}

    for obstacleName, obstacle in pairs(playerObstacles) do
        local model = gameInventory.obstaclePrototypes[obstacle.name].modelPath
        local texture = jsonData.textures[obstacle.texture]
        local translation = parseTranslation(jsonData.constants, obstacle)
        local rotation = nil
        local scale = parseScale(jsonData.constants, obstacle)
        local newObstacle = g3d.newModel(model, texture, translation, rotation, scale)
        newObstacle["name"] = obstacle.name
        table.insert(newScene.playerObstacles, newObstacle)
    end
end

local function createScenes()
    local jsonString = love.filesystem.read("scenes.json")
    local jsonData = json.decode(jsonString)

    for sceneIndex, scene in ipairs(jsonData.scenes) do
        local newScene = {}
        parseObjects(jsonData, scene.objects, newScene)
        parseArrows(scene.arrows, newScene)
        parseObstacles(jsonData, scene.playerObstacles, newScene)

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
local continueText = languageJson.text[language].continue
local continueTextWidth = font:getWidth(continueText)
local loadingText = languageJson.text[language].loading
local loadingTextWidth = font:getWidth(loadingText)
local textY = screenHeight - 40

local prevCurrentScene = currentScene

love.graphics.print(continueText, screenWidth / 2 - continueTextWidth - 150, textY)

local function loadScenes()
    createTitleScene()
    createPlinkoScene1()
    createPlinkoScene2()
    createScenes()
end

function love.load()
    math.randomseed(os.time())
    calculateTransformPerScreenPixel()

    gameInventory = Inventory:new()

    createInventoryButton()

    loadScenes()
end


-------------------------------------------------------------------------------------------------
---
--- Input Handling
---
-------------------------------------------------------------------------------------------------
---

-- Clicking for when the inventory is up
function love.mousepressed(x, y, button, istouch, presses)
    if button == 1 then
        -- Check for play again button click on win/lose screen
        if wonGame or lostGame then
            if x >= playAgainButton.x and x <= playAgainButton.x + playAgainButton.width and
               y >= playAgainButton.y and y <= playAgainButton.y + playAgainButton.height then
                -- Reset game state
                wonGame = false
                lostGame = false
                simulatedObjects = {}
                ballAmmo = maxBallAmmo
                currentScene = titleScreen
                timer = timerCooldown

                sceneObjects = {}
                mainMenuButtonsData = {}
                loadScenes()
                return
            end
            
            -- Check for quit button click
            if x >= quitButton.x and x <= quitButton.x + quitButton.width and
               y >= quitButton.y and y <= quitButton.y + quitButton.height then
                love.event.quit()
                return
            end
        end
        
        -- Transition from title screen on tap/click
        if currentScene == titleScreen then
            local buttonPressed = false
            for i = 1, #mainMenuButtonsData do
                local buttonData = mainMenuButtonsData[i].imageData
                if pointIsBetweenBounds(
                    x,
                    y,
                    buttonData.position.x,
                    buttonData.position.y,
                    buttonData.width,
                    buttonData.height
                ) then
                    buttonPressed = true
                    language = mainMenuButtonsData[i].textData.language
                    updateLanguage()
                end
            end

            if not buttonPressed then
                currentScene = searchRoom1
                return
            end
        end
        
        local clickedItem = gameInventory:checkClick(x, y)

        if clickedItem and type(clickedItem) == "table" then
            if isInPlinkoScene() then
                currentPlacementItem = clickedItem
                gameInventory:toggle()
                swapInventoryButtonImage()
                return
            else
                gameInventory:returnItem(clickedItem.name)
                return
            end
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
        -- Check the new list of player obstacles for clicks
        local currentSceneObj = sceneObjects[currentScene]
        local currentObstacles = sceneObjects[currentScene].playerObstacles
        local currentBounds = currentSceneObj.bounds
        if currentObstacles then
            for i = 1, #currentObstacles do
                local obstacle = currentObstacles[i]

                if obstacle.name then
                    local isClicked = false

                    -- Use default AABB for simpler objects
                    if obstacle.model then
                        isClicked = obstacle.model:isPointInAABB({worldx, worldy, worldz})
                    else
                        isClicked = obstacle:isPointInAABB({worldx, worldy, worldz})
                    end

                    if isClicked then
                        gameInventory:returnItem(obstacle.name)
                        table.remove(currentObstacles, i)
                        -- Remove scene's collision bounds
                        if currentBounds then
                            for j = #currentBounds, 1, -1 do
                                if currentBounds[j] == obstacle then
                                    table.remove(currentBounds, j)
                                    break
                                end
                            end
                        end

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

            local currentSceneObj = sceneObjects[currentScene]
            if not currentSceneObj.playerObstacles then currentSceneObj.playerObstacles = {}
            end
            table.insert(currentSceneObj.playerObstacles, newObstacle)
            -- Add to the scene's collision bounds
            if currentSceneObj.bounds then
                table.insert(currentSceneObj.bounds, newObstacle)
            else
                currentSceneObj.bounds = {newObstacle}
            end
            -- Reset placement state
            currentPlacementItem = nil
            gameInventory:stopDragging()
            ghostModel = nil
            
        elseif isInPlinkoScene() then
            -- Check if ball cursor is within the orange clickPlane box
            local ballPos = {ballCursor.translation[1], ballCursor.translation[2], ballCursor.translation[3]}
            if ballAmmo > 0 and clickPlane and clickPlane.aabb and clickPlane:isPointInAABB(ballPos) then
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
                ballAmmo = ballAmmo - 1
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

        if isInPlinkoScene() or isInSearchRoom() then
            if pointIsBetweenBounds(
                x, y,
                inventoryButtonData.position.x,
                inventoryButtonData.position.y,
                inventoryButtonData.width,
                inventoryButtonData.height
            ) then
                gameInventory:toggle()
                swapInventoryButtonImage()
            end
        end
    end
end

-- transition from title screen to searching room on any input
function love.keypressed(key)
    -- Transition from title screen to searching room on any key press
    if currentScene == titleScreen then
        currentScene = searchRoom1
        return
    end
end

function love.mousemoved(x,y, dx,dy)
    local mWorldPosX, mWorldPosY, mWorldPosZ = getClickWorldPosition(x, y)
    
    if currentPlacementItem then -- Check if an item is being dragged
        placementPosition = {mWorldPosX, mWorldPosY, mWorldPosZ}
        -- Create or update the ghost model
        if not ghostModel or ghostModel.modelPath ~= currentPlacementItem.modelPath then
            local tempTexturePath = "kenney_prototype_textures/green/texture_08.png"
            local scale = {1, 1, 1}

            ghostModel = g3d.newModel(
                currentPlacementItem.modelPath,
                tempTexturePath,
                placementPosition,
                nil,
                scale
            )
            ghostModel.modelPath = currentPlacementItem.modelPath
        end
        ghostModel:setTranslation(mWorldPosX, mWorldPosY, mWorldPosZ)
    else
        ghostModel = nil
        if isInPlinkoScene() then
            ballCursor:setTranslation(mWorldPosX, mWorldPosY, mWorldPosZ)
        end
    end
end


-------------------------------------------------------------------------------------------------
---
--- Main Update and Draw Loops
---
-------------------------------------------------------------------------------------------------


function love.update(dt)
    if wonGame or lostGame then
        return
    end
    if prevCurrentScene ~= currentScene then
        simulatedObjects = {}
        prevCurrentScene = currentScene
    end

    if isInSearchRoom() then
        timer = timer - dt
        if timer <= 0 then
            currentScene = plinkoLevels[math.random(#plinkoLevels)]
            timer = timerCooldown
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
        
        -- Draw ball ammo indicators in top right corner
        love.graphics.setColor(1, 1, 1, 1)
        local ballSize = 20
        local spacing = 10
        local startX = love.graphics.getWidth() - 25
        local startY = 20
        
        for i = 1, ballAmmo do
            love.graphics.circle("fill", startX, startY + (i - 1) * (ballSize + spacing), ballSize / 2)
        end

        inventoryButtonData.position.x = startX - (inventoryButtonData.width/2)
        inventoryButtonData.position.y = startY + (maxBallAmmo * (ballSize + spacing))
        inventoryButtonData.scale = inventoryButtonData.plinkoData.scale
        updateButtonDimensions(inventoryButtonData)

        love.graphics.draw(
            inventoryButtonData.image,
            inventoryButtonData.position.x,
            inventoryButtonData.position.y,
            0,
            inventoryButtonData.scale,
            inventoryButtonData.scale
        )

    elseif isInSearchRoom() then
        if font then love.graphics.setFont(font) end
        love.graphics.print(languageJson.text[language].timer .. math.ceil(timer))

        inventoryButtonData.position.x = inventoryButtonData.roomData.position.x
        inventoryButtonData.position.y = inventoryButtonData.roomData.position.y
        inventoryButtonData.scale = inventoryButtonData.roomData.scale
        updateButtonDimensions(inventoryButtonData)

        love.graphics.draw(
            inventoryButtonData.image,
            inventoryButtonData.position.x,
            inventoryButtonData.position.y,
            0,
            inventoryButtonData.scale,
            inventoryButtonData.scale
        )
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
    -- Draw the ghost model
    if ghostModel then
        ghostModel:draw()
    end

    if wonGame then
        drawWinScreen()
    end
    if lostGame then
        drawLoseScreen()
    end

    love.graphics.setFont(font)
    love.graphics.setColor(1, 1, 1, 1)

    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()

    -- Display "Press any key to continue" on title screen
    if currentScene == titleScreen then
        local continueText = languageJson.text[language].continue
        local continueTextWidth = font:getWidth(continueText)
        local continueTextY = 40
        love.graphics.print(continueText, screenWidth / 2 - continueTextWidth / 2, continueTextY)
        love.graphics.setFont(font)

        -- Language Buttons
        local tempLang = language

        local buttonY = 350
        for i = 1, #mainMenuButtonsData do
            local imageData = mainMenuButtonsData[i].imageData
            local textData = mainMenuButtonsData[i].textData
            imageData.position = {
                ["x"] = screenWidth / 2 - imageData.width / 2,
                ["y"] = buttonY
            }
            love.graphics.draw(
                imageData.image,
                imageData.position.x,
                imageData.position.y,
                0,
                imageData.scale.x,
                imageData.scale.y
            )

            love.graphics.setFont(textData.font)
            love.graphics.print(textData.text, screenWidth / 2 - textData.width / 2, buttonY + 7)

            buttonY = buttonY + (imageData.height * imageData.scale.y) + 60
        end
        language = tempLang
        updateLanguage()
    end

    -- Only show inventory instructions if not on title screen
    if currentScene ~= titleScreen then
        if not gameInventory.isVisible and not currentPlacementItem then
            local textY = screenHeight - 40
            local bottomText
            if isInPlinkoScene() then bottomText = languageJson.text[language].pickup
            else bottomText = languageJson.text[language].search end
            local pickupTextWidth = font:getWidth(bottomText)

            love.graphics.print(bottomText, (screenWidth / 2) - (pickupTextWidth / 2), textY)
        end
    end

    gameInventory:draw()
end