local Object = {} 

-- Constructor function
function Object:new(interactables)
    local item = interactables or {}
    item.name = item.name or nil
    item.modelPath = item.modelPath or nil
    item.type = item.type or "Obstacle"
    item.canBePlaced = item.canBePlaced or false
    
    if item.iconPath then
        item.iconImage = love.graphics.newImage(item.iconPath)
    end

    setmetatable(item, self) 
    self.__index = self
    return item
end

return Object