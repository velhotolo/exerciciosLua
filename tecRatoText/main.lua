local TILE = 40
local heroi = { cx = 3, cy = 3 }
local fada = { x = 500, y = 300 }
local marcador = nil
local nome = "Tolo"
local editandoNome = false


local tempoPasso = 0

function love.load()
    love.keyboard.setKeyRepeat(true)
end

function love.update(dt)
    local v = 220 * dt


    if love.keyboard.isDown("a") then fada.x = fada.x - v end
    if love.keyboard.isDown("d") then fada.x = fada.x + v end
    if love.keyboard.isDown("w") then fada.y = fada.y - v end
    if love.keyboard.isDown("s") then fada.y = fada.y + v end


    if love.mouse.isDown(3) then
        local mx, my = love.mouse.getPosition()
        local dx = mx - fada.x
        local dy = my - fada.y
        local dist = math.sqrt(dx * dx + dy * dy)

        if dist > v then
            fada.x = fada.x + (dx / dist) * v
            fada.y = fada.y + (dy / dist) * v
        else
            fada.x, fada.y = mx, my
        end
    end


    if marcador then
        tempoPasso = tempoPasso + dt
        if tempoPasso >= 0.15 then
            tempoPasso = 0

            if heroi.cx < marcador.cx then
                heroi.cx = heroi.cx + 1
            elseif heroi.cx > marcador.cx then
                heroi.cx = heroi.cx - 1
            elseif heroi.cy < marcador.cy then
                heroi.cy = heroi.cy + 1
            elseif heroi.cy > marcador.cy then
                heroi.cy = heroi.cy - 1
            else
                marcador = nil
            end
        end
    end
end

function love.keypressed(key)
    if editandoNome then
        if key == "return" then
            editandoNome = false
        elseif key == "backspace" then
            local utf8 = require("utf8")
            local fim = utf8.offset(nome, -1)
            if fim then nome = nome:sub(1, fim - 1) end
        end
        return
    end


    local dx, dy = 0, 0
    if key == "left" then dx = -1 end
    if key == "right" then dx = 1 end
    if key == "up" then dy = -1 end
    if key == "down" then dy = 1 end

    if dx ~= 0 or dy ~= 0 then
        heroi.cx = heroi.cx + dx
        heroi.cy = heroi.cy + dy


        local W, H = love.graphics.getDimensions()
        local maxCX = math.floor(W / TILE) - 1
        local maxCY = math.floor(H / TILE) - 1


        heroi.cx = math.max(0, math.min(heroi.cx, maxCX))
        heroi.cy = math.max(0, math.min(heroi.cy, maxCY))


        marcador = nil
    end

    if key == "return" then editandoNome = true end
end

function love.textinput(t)
    if editandoNome then nome = nome .. t end
end

function love.mousepressed(x, y, botao)
    if botao == 1 then
        marcador = { cx = math.floor(x / TILE), cy = math.floor(y / TILE) }
    elseif botao == 2 then
        marcador = nil
    end
end

function love.draw()
    local g = love.graphics
    local W, H = g.getDimensions()

    g.setColor(0.2, 0.2, 0.25)
    for x = 0, W, TILE do g.line(x, 0, x, H) end
    for y = 0, H, TILE do g.line(0, y, W, y) end

    local mx, my = love.mouse.getPosition()
    local mcx, mcy = math.floor(mx / TILE), math.floor(my / TILE)
    g.setColor(1, 1, 1, 0.15)
    g.rectangle("fill", mcx * TILE, mcy * TILE, TILE, TILE)

    if marcador then
        g.setColor(1, 0.3, 0.3)
        g.rectangle("line", marcador.cx * TILE + 4, marcador.cy * TILE + 4, TILE - 8, TILE - 8)
    end

    g.setColor(0.3, 0.8, 1)
    g.rectangle("fill", heroi.cx * TILE + 6, heroi.cy * TILE + 6, TILE - 12, TILE - 12)

    g.setColor(1, 1, 1)
    g.printf(nome, heroi.cx * TILE - 40, heroi.cy * TILE - 18, TILE + 80, "center")

    g.setColor(1, 0.6, 1)
    g.circle("fill", fada.x, fada.y, 8)

    g.setColor(1, 1, 1)
    g.print(
        ("Setas: herói (grade) WASD: fada (livre) Enter: renomear\nMouse: casa (%d, %d) Segure R3: Fada Segue"):format(
            mcx,
            mcy), 10, H - 36)

    if editandoNome then g.print("Digite o nome e tecle Enter", 10, 10) end
end
