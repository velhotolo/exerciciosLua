local LARGURA, ALTURA = 800, 600
local PONTOS_PARA_VENCER = 5

local raqueteE = { x = 30, y = 250, w = 12, h = 100, vel = 420, pontos = 0 }
local raqueteD = { x = 550, y = 250, w = 12, h = 100, vel = 420, pontos = 0 }

local bola = { x = 394, y = 294, w = 12, h = 12, vx = 0, vy = 0 }

local estado = "saque"
local sacador = 1

local function colide(a, b)
    return a.x < b.x + b.w and b.x < a.x + a.w and
        a.y < b.y + b.h and b.y < a.y + a.h
end

local VEL_INICIAL = 300
local VEL_MAXIMA = 900

local function centralizarBola()
    bola.x = LARGURA / 2 - bola.w / 2
    bola.y = ALTURA / 2 - bola.h / 2
    bola.vx, bola.vy = 0, 0
end

local function sacar()
    local angulo = math.rad(love.math.random(-30, 30))
    bola.vx = math.cos(angulo) * VEL_INICIAL * sacador
    bola.vy = math.sin(angulo) * VEL_INICIAL
    estado = "jogando"
end

local function quicarNasParedes()
    if bola.y < 0 then
        bola.y = 0
        bola.vy = -bola.vy
    elseif bola.y + bola.h > ALTURA then
        bola.y = ALTURA - bola.h
        bola.vy = -bola.vy
    end
end

local function rebater(r, lado)
    if not colide(bola, r) then return end

    if bola.vx * lado > 0 then return end

    local centroBola = bola.y + bola.h / 2
    local centroRaquete = r.y + r.h / 2
    local onde = (centroBola - centroRaquete) / (r.h / 2)
    onde = math.max(-1, math.min(1, onde))

    local velocidade = math.sqrt(bola.vx ^ 2 + bola.vy ^ 2) * 1.05
    velocidade = math.min(velocidade, VEL_MAXIMA)
    local angulo = onde * math.rad(60)

    bola.vx = math.cos(angulo) * velocidade * lado
    bola.vy = math.sin(angulo) * velocidade

    if lado == 1 then
        bola.x = r.x + r.w
    else
        bola.x = r.x - bola.w
    end
end

local function marcarPonto(quem, proximoSacador)
    quem.pontos = quem.pontos + 1
    centralizarBola()
    sacador = proximoSacador
    if quem.pontos >= PONTOS_PARA_VENCER then
        estado = "fim"
    else
        estado = "saque"
    end
end
local function conferirPonto()
    if bola.x + bola.w < 0 then
        marcarPonto(raqueteD, -1)
    elseif bola.x > LARGURA then
        marcarPonto(raqueteE, 1)
    end
end

local function moverRaquete(r, teclaCima, teclaBaixo, dt)
    if love.keyboard.isDown(teclaCima) then
        r.y = r.y - r.vel * dt
    end
    if love.keyboard.isDown(teclaBaixo) then
        r.y = r.y + r.vel * dt
    end
    -- não deixa a raquete sair da tela
    r.y = math.max(0, math.min(ALTURA - r.h, r.y))
end
function love.update(dt)
    moverRaquete(raqueteE, "w", "s", dt)
    moverRaquete(raqueteD, "up", "down", dt)
    if estado ~= "jogando" then return end
    bola.x = bola.x + bola.vx * dt
    bola.y = bola.y + bola.vy * dt
    quicarNasParedes()
    rebater(raqueteE, 1)
    rebater(raqueteD, -1)
    conferirPonto()
end

local fontePlacar, fonteAviso
function love.load()
    fontePlacar = love.graphics.newFont(48)
    fonteAviso = love.graphics.newFont(20)
    centralizarBola()
end

function love.draw()
    -- linha do meio, tracejada
    love.graphics.setColor(0.4, 0.4, 0.4)
    for y = 0, ALTURA, 40 do
        love.graphics.rectangle("fill", LARGURA / 2 - 2, y + 10, 4, 20)
    end
    -- raquetes e bola
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", raqueteE.x, raqueteE.y, raqueteE.w, raqueteE.h)
    love.graphics.rectangle("fill", raqueteD.x, raqueteD.y, raqueteD.w, raqueteD.h)
    love.graphics.rectangle("fill", bola.x, bola.y, bola.w, bola.h)
    -- placar
    love.graphics.setFont(fontePlacar)
    love.graphics.printf(tostring(raqueteE.pontos), 0, 30, LARGURA / 2 - 40, "right")
    love.graphics.printf(tostring(raqueteD.pontos), LARGURA / 2 + 40, 30, LARGURA / 2 - 40, "left")
    -- avisos
    love.graphics.setFont(fonteAviso)
    if estado == "saque" then
        love.graphics.printf("Espaço saca", 0, ALTURA - 60, LARGURA, "center")
    elseif estado == "fim" then
        local vencedor = "Esquerda"
        if raqueteD.pontos > raqueteE.pontos then vencedor = "Direita" end
        love.graphics.printf(vencedor .. " venceu! R recomeça", 0, ALTURA / 2 - 80, LARGURA, "center")
    end
end

function love.keypressed(tecla)
    if tecla == "escape" then
        love.event.quit()
    elseif tecla == "space" and estado == "saque" then
        sacar()
    elseif tecla == "r" and estado == "fim" then
        raqueteE.pontos = 0
        raqueteD.pontos = 0
        sacador = 1
        centralizarBola()
        estado = "saque"
    end
end
