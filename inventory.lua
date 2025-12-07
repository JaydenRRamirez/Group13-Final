local Object = require("objects") 

local Inventory = {}
local inventorySlots = 64
local padding = 10
local uiWidth = 300
local uiHeight = 200
local slotsRow = 4

function Inventory:new()
    local inv = {
        isVisible = false, 
        items = {},  
        selectedItemIndex = nil,
        isDragging = false,
        x = love.graphics.getWidth() / 2 - uiWidth / 2,
        y = 50,
        obstaclePrototypes = {}
    }
    
    setmetatable(inv, self)
    self.__index = self
    return inv
end

--- Item Management

--function Inventory:addItem(item)
  --  if item and item.type == "Obstacle" then
    --    local itemName = item.name
        
      --  if self.items[itemName] then
        --    self.items[itemName].count = self.items[itemName].count + 1
        --else
          --  self.items[itemName] = {
            --    prototype = item,
              --  count = 1
            --}
        --end
        --print("Added" .. itemName .. " to inventory. count: " .. self.items[itemName].count)
    --end
--end

-- Adding through a prototype if it doesn't exist, or increment
function Inventory:addItem(item)
    local itemName = item.name

    if self.items[itemName] then
        self.items[itemName].count = self.items[itemName].count + 1
    else
        self.items[itemName] = {
            prototype = item,
            count = 1
        }
        self.obstaclePrototypes[itemName] = item
    end
    print("Added " .. itemName .. " to inventory. Count: " .. self.items[itemName].count)
end

function Inventory:getDisplayedStacks()
    local stacks = {}
    for _, stack in pairs(self.items) do
        table.insert(stacks, stack)
    end
    return stacks
end

function Inventory:selectItem(index)
    local stacks = self:getDisplayedStacks()
    if stacks[index] and stacks[index].count > 0 then
        self.selectedItemIndex = index
        print("Selected item: " .. stacks[index].prototype.name)
        return stacks[index]
    end
end

function Inventory:returnItem(itemName)
    local stack = self.items[itemName]

    if stack then
        stack.count = stack.count + 1
        print("Returned " .. itemName .. " to inventory. Count: "  .. stack.count)
        return true
    else
        local prototype = self.obstaclePrototypes[itemName]
        if prototype then
            self.items[itemName] = {
                prototype = prototype,
                count = 1
            }
            print("Returned " .. itemName .. " to inventory. Count: 1")
            return true
        end
    end
    return false
end

--- UI Interaction

function Inventory:toggle()
    self.isVisible = not self.isVisible
    if not self.isVisible then
        self.selectedItemIndex = nil
    end
end

-- Handles mouse clicks for the UI
function Inventory:checkClick(clickX, clickY)
    if not self.isVisible then return end

    -- Check for the click in Inventory Bounds
    if clickX >= self.x and clickX <= self.x + uiWidth and
       clickY >= self.y and clickY <= self.y + uiHeight then
        
        local localX = clickX - self.x - padding
        local localY = clickY - self.y - padding

        local slotSize = 64
        local slotSpacing = slotSize + padding
        
        -- Check which slot was clicked
        local col = math.floor(localX / slotSpacing)
        local row = math.floor(localY / slotSpacing)

        if localX % slotSpacing < slotSize and localY % slotSpacing < slotSize then
            local index = row * slotsRow + col + 1
            local stacks = self:getDisplayedStacks()
            
            if stacks[index] and stacks[index].count > 0 then
                self:selectItem(index)
                self.isDragging = true
                stacks[index].count = stacks[index].count - 1
                return stacks[index].prototype
            end
        end
        return true
    end
    return false
end

--- Inventory UI

function Inventory:draw()
    if not self.isVisible then return end
    
    local stacks = self:getDisplayedStacks()

    love.graphics.push()
    
    -- Inventory Background
    love.graphics.setColor(0.1, 0.1, 0.1, 0.9)
    love.graphics.rectangle("fill", self.x, self.y, uiWidth, uiHeight)

    -- Inventory Slots
    for i, stack in ipairs(stacks) do
        local item = stack.prototype
        local col = (i - 1) % slotsRow
        local row = math.floor((i - 1) / slotsRow)
        
        local drawX = self.x + padding + col * (inventorySlots + padding)
        local drawY = self.y + padding + row * (inventorySlots + padding)
        
        -- Slot Background
        love.graphics.setColor(0.3, 0.3, 0.3, 1)
        love.graphics.rectangle("fill", drawX, drawY, inventorySlots, inventorySlots)
        
        -- Highlight for Clicked Slot
        if i == self.selectedItemIndex then
            love.graphics.setColor(1, 0.8, 0, 1)
            love.graphics.setLineWidth(3)
            love.graphics.rectangle("line", drawX, drawY, inventorySlots, inventorySlots)
            love.graphics.setLineWidth(1)
        end
        
        -- Item Icon
        if item.iconImage then
            love.graphics.setColor(1, 1, 1, 1)
            local scale = inventorySlots / math.max(item.iconImage:getWidth(), item.iconImage:getHeight())
            love.graphics.draw(item.iconImage, drawX, drawY, 0, scale, scale)
        end

        -- Draw Item Count
        if stack.count > 0 then
            love.graphics.setColor(1, 1, 1, 1)
            local currentFont = love.graphics.getFont()
            local countFont = love.graphics.newFont(16)
            love.graphics.setFont(countFont)
            local countText = tostring(stack.count)
            local countX = drawX + inventorySlots - countFont:getWidth(countText) - 2
            local countY = drawY + inventorySlots - countFont:getHeight() - 2

            love.graphics.print(countText, countX, countY)
            love.graphics.setFont(currentFont)
        end
    end
    
    love.graphics.pop()
end

-- Selected Item and Dragging
function Inventory:getSelectedItem()
    if self.selectedItemIndex then
        local stacks = self:getDisplayedStacks()
        return stacks[self.selectedItemIndex].prototype
    end
    return nil
end

function Inventory:stopDragging()
    self.isDragging = false
    self.selectedItemIndex = nil
end

return Inventory