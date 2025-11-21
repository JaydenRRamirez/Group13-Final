--load 3DreamEngine
local dream = require("3DreamEngine")

--optionally set settings
dream:setBloom(3)

--init (applies settings)
dream:init()

--loads a object
local yourObject = dream:loadObject("3DreamExampleAssets/monkey/object")

--creates a light
local light = dream:newLight("point", dream.vec3(3, 2, 1), dream.vec3(1.0, 0.75, 0.2), 50.0)

--add shadow to light source
light:addNewShadow()

function love.draw()
	--prepare for rendering
	dream:prepare()
	
	--add light
	dream:addLight(light)
	
	--rotate, offset and draw
	yourObject:resetTransform()
	yourObject:rotateY(love.timer.getTime())
	yourObject:translate(0, 0, -3)
	dream:draw(yourObject)
	
	--render
	dream:present()
end

function love.update()
	--update resource loader
	dream:update()
end