local heroi = { nome = "Tolo", nivel = 3, hp = 34, hpMax = 50, mp = 12, mpMax = 20 }
local opcoes = { "Atacar", "Técnica", "Item", "Fugir" }
local escolha = 1
local fonteGrande, fontePequena
local dialogo = "Um slime azul bloqueia o corredor. Ele parece mais curioso do que " ..
    "perigoso, mas a sua espada já está meio fora da bainha..."

function love.load()
    fonteGrande = love.graphics.newFont(22)
    fontePequena = love.graphics.newFont(13)
    love.graphics.setBackgroundColor(0.08, 0.2, 0.12)
end

local function janela(x, y, w, h)
    local g = love.graphics
    g.setColor(0.05, 0.08, 0.35, 0.92)
    g.rectangle("fill", x, y, w, h, 8, 8)
    g.setColor(1, 1, 1)
    g.setLineWidth(3)
    g.rectangle("line", x, y, w, h, 8, 8)
    g.setLineWidth(1)
    g.setColor(0.6, 0.7, 1)
    g.rectangle("line", x + 5, y + 5, w - 10, h - 10, 5, 5)
end

local function barra(x, y, w, h, valor, maximo, cor)
    local g = love.graphics
    local fracao = math.max(0, math.min(1, valor / maximo))
    g.setColor(0.15, 0.15, 0.2)
    g.rectangle("fill", x, y, w, h, 3, 3)
    g.setColor(cor)
    g.rectangle("fill", x, y, w * fracao, h, 3, 3)
    g.setColor(1, 1, 1)
    g.rectangle("line", x, y, w, h, 3, 3)
    g.setFont(fontePequena)
    g.printf(valor .. "/" .. maximo, x, y + (h - fontePequena:getHeight()) / 2, w, "center")
end

function love.draw()
    local g = love.graphics
    local W, H = g.getDimensions()

    -- status do herói

    janela(20, 20, 280, 130)
    g.setColor(1, 1, 1)
    g.setFont(fonteGrande)
    g.print(heroi.nome, 40, 34)
    g.setFont(fontePequena)
    g.printf("Nv " .. heroi.nivel, 40, 42, 240, "right")

    local f = heroi.hp / heroi.hpMax
    local corHp = f > 0.5 and { 0.3, 0.85, 0.4 } or (f > 0.25 and { 0.95, 0.8, 0.2 } or { 0.9, 0.25, 0.2 })

    barra(40, 75, 240, 20, heroi.hp, heroi.hpMax, corHp)
    barra(40, 105, 240, 20, heroi.mp, heroi.mpMax, { 0.3, 0.5, 1 })

    janela(W - 220, 20, 200, 20 + #opcoes * 30)
    g.setFont(fonteGrande)
    for i, texto in ipairs(opcoes) do
        local y = 38 + (i - 1) * 30
        g.setColor(i == escolha and { 1, 1, 0.5 } or { 1, 1, 1 })
        g.print(texto, W - 180, y)
        if i == escolha then
            g.polygon("fill", W - 200, y + 6, W - 200, y + 22, W - 188, y + 14)
        end
    end

    janela(20, H - 140, W - 40, 120)
    g.setColor(1, 1, 1)
    g.setFont(fonteGrande)
    g.printf(dialogo, 45, H - 120, W - 90, "left")

    g.setFont(fontePequena)
    g.setColor(0.7, 0.7, 0.7)
    g.print("Setas: menu D: dano C: cura", 20, H - 16)
end

function love.keypressed(key)
    if key == "down" then escolha = escolha % #opcoes + 1 end
    if key == "up" then escolha = (escolha - 2) % #opcoes + 1 end
    if key == "d" then heroi.hp = math.max(0, heroi.hp - 7) end
    if key == "c" then heroi.hp = math.min(heroi.hpMax, heroi.hp + 10) end
end
