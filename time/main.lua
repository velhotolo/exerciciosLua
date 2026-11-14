local Timer = require("timer")

local heroi = { x = 400, y = 300, vx = 0, vy = 0 }
local ACEL = 1800
local ATRITO = 6
local VMAX = 320

local dash = { pronto = true, recarga = 1.2, restante = 0 }
local moedas = {}
local pontos = 0

function love.load()
    love.math.setRandomSeed(os.time())
    Timer.every(1.5, function()
        local W, H = love.graphics.getDimensions()
        table.insert(moedas, {
            x = love.math.random(30, W - 30),
            y = love.math.random(30, H - 30),
            vida = 5
        })
    end)
end

function love.update(dt)
    Timer.update(dt)

    local ix, iy = 0, 0
    if love.keyboard.isDown("left", "a") then ix = ix - 1 end
    if love.keyboard.isDown("right", "d") then ix = ix + 1 end
    if love.keyboard.isDown("up", "w") then iy = iy - 1 end
    if love.keyboard.isDown("down", "s") then iy = iy + 1 end
    if ix ~= 0 and iy ~= 0 then ix, iy = ix * 0.7071, iy * 0.7071 end

    heroi.vx = heroi.vx + ix * ACEL * dt
    heroi.vy = heroi.vy + iy * ACEL * dt

    local fator = math.exp(-ATRITO * dt)
    heroi.vx, heroi.vy = heroi.vx * fator, heroi.vy * fator

    local v = math.sqrt(heroi.vx ^ 2 + heroi.vy ^ 2)
    if v > VMAX and not dash.ativo then
        heroi.vx, heroi.vy = heroi.vx / v * VMAX, heroi.vy / v * VMAX
    end

    heroi.x = heroi.x + heroi.vx * dt
    heroi.y = heroi.y + heroi.vy * dt
    if not dash.pronto then
        dash.restante = math.max(0, dash.restante - dt)
    end

    for i = #moedas, 1, -1 do
        local m = moedas[i]
        m.vida = m.vida - dt
        local dx, dy = m.x - heroi.x, m.y - heroi.y
        if dx * dx + dy * dy < 30 * 30 then
            pontos = pontos + 1
            table.remove(moedas, i)
        elseif m.vida <= 0 then
            table.remove(moedas, i)
        end
    end
end

function love.keypressed(key)
    if key == "space" and dash.pronto then
        local v = math.sqrt(heroi.vx ^ 2 + heroi.vy ^ 2)
        if v > 1 then
            heroi.vx, heroi.vy = heroi.vx / v * 1100, heroi.vy / v * 1100
            dash.pronto, dash.ativo, dash.restante = false, true, dash.recarga
            Timer.after(0.15, function() dash.ativo = false end)
            Timer.after(dash.recarga, function() dash.pronto = true end)
        end
    end
end

function love.draw()
    local g = love.graphics
    for _, m in ipairs(moedas) do
        -- pisca quando está para sumir
        if m.vida > 1.5 or math.floor(m.vida * 10) % 2 == 0 then
            g.setColor(1, 0.85, 0.2)
            g.circle("fill", m.x, m.y, 8)
        end
    end
    g.setColor(dash.ativo and { 1, 1, 1 } or { 0.3, 0.8, 1 })
    g.circle("fill", heroi.x, heroi.y, 16)
    g.setColor(1, 1, 1)
    g.print("Dash (Espaço)", 10, 10)
    g.rectangle("line", 120, 12, 100, 12)
    local f = dash.pronto and 1 or 1 - dash.restante / dash.recarga
    g.rectangle("fill", 120, 12, 100 * f, 12)
    g.print("Moedas: " .. pontos, 10, 32)
    g.print(("Velocidade: %.0f px/s"):format(math.sqrt(heroi.vx ^ 2 + heroi.vy ^ 2)), 10, 54)
end
