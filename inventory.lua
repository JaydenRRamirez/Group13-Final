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
    }
    
    setmetatable(inv, self)
    self.__index = self
    return inv
end

--- Item Management

function Inventory:addItem(item)
    if item and item.type == "Obstacle" then
        table.insert(self.items, item)
        print("Added " .. item.name .. " to inventory.")
    end
end

function Inventory:selectItem(index)
    if self.items[index] then
        self.selectedItemIndex = index
        print("Selected item: " .. self.items[index].name)
    end
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
            
            if self.items[index] then
                self:selectItem(index)
                self.isDragging = true
                return self.items[index]
            end
        end
        return true
    end
    return false
end

--- Inventory UI

function Inventory:draw()
    if not self.isVisible then return end
    
    love.graphics.push()
    
    -- Inventory Background
    love.graphics.setColor(0.1, 0.1, 0.1, 0.9)
    love.graphics.rectangle("fill", self.x, self.y, uiWidth, uiHeight)

    -- Inventory Slots
    for i, item in ipairs(self.items) do
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
    end
    
    love.graphics.pop()
end

-- Selected Item and Dragging
function Inventory:getSelectedItem()
    if self.selectedItemIndex then
        return self.items[self.selectedItemIndex]
    end
    return nil
end

function Inventory:stopDragging()
    self.isDragging = false
    self.selectedItemIndex = nil
end

return Inventory