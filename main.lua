-- Card game
require "lunit"
local instructions = require "instructions"
module("main", lunit.testcase, package.seeall)

local faces = require "card-faces"
function getimg(cardname)
    return "img/"..faces[cardname]
end

DESCRIPTION = instructions.description

local image = love.graphics.newImage(getimg("AH"))
local cardscale = 0.20

resy         = 720
resx         = 1280
aspect_ratio = resx/resy
height       = 300

local aspect_rate_nazi = true
if aspect_rate_nazi then
    width = height * aspect_ratio
else
    width = 367
end

scale       = 0.6
height      = math.floor(height * scale)
width       = math.floor(width  * scale)
cellwidth   = resx/width
cellheight  = resy/height

function paint(c)
    love.graphics.setColor(c[1], c[2], c[3])
end

function love.load()
    math.randomseed(os.time())
    love.graphics.setBackgroundColor(210, 215, 205)
    font = love.graphics.newFont("fonts/UbuntuMono-R.ttf", 16)
    love.graphics.setFont(font)
end

local running = false
function love.draw()
    love.graphics.setColor(120, 120, 120)
    love.graphics.print(DESCRIPTION, 5, 15+20)
    love.graphics.setColor(255, 255, 255)
    love.graphics.draw(image, 0, 0, 0, cardscale, cardscale)
end

function love.update(dt)
    if love.keyboard.isDown("up")  then
    end
    if love.keyboard.isDown("down")  then
    end
    if love.keyboard.isDown("left")  then
    end
    if love.keyboard.isDown("right")  then
    end
end

local clock = os.clock
function sleep(n)  -- seconds
    local t0 = clock()
    while clock() - t0 <= n do end
end

