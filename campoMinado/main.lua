local COLUNAS, LINHAS = 10, 10
local MINAS = 15
local TAM = 40
local TOPO = 50

local celulas = {}
local minhasPostas = false
local abertas = 0
local bandeiras = 0
local estado = "jogando"
local tempo = 0

local function novaGrade()
    celulas = {}
    for lin = 1, LINHAS do
        celulas[lin] = {}
        for col = 1, COLUNAS do
            celulas[lin][col] = { minha = false, aberta = false, bandeira = false, vizinhas = 0 }
        end
    end
    minasPostas = false
    abertas = 0
    bandeiras = 0
    estado = "jogando"
    tempo = 0
end

local function celulaNoPonto(x, y)
    local col = math.floor(x / TAM) + 1
    local lin = math.floor((y - TOPO) / TAM) + 1
    if col < 1 or col > COLUNAS or lin < 1 or lin > LINHAS then
        return nil
    end
    return lin, col
end

local function paraCadaVizinha(lin, col, f)
    for dl = -1, 1 do
        for dc = -1, 1 do
            local l, c = lin + dl, col + dc
            local ehEla = (dl == 0 and dc == 0)
            if not ehEla and l >= 1 and l <= LINHAS and c >= 1 and c <= COLUNAS then
                f(l, c)
            end
        end
    end
end

local function porMinas(linSegura, colSegura)
    local candidatas = {}
    for lin = 1, LINHAS do
        for col = 1, COLUNAS do
            if math.abs(lin - linSegura) > 1 or math.abs(col - colSegura) > 1 then
                candidatas[#candidatas + 1] = { lin, col }
            end
        end
    end

    for i = 1, MINAS do
        local k = love.math.random(i, #candidatas)
        candidatas[i], candidatas[k] = candidatas[k], candidatas[i]
        local lin, col = candidatas[i][1], candidatas[i][2]
        celulas[lin][col].mina = true
    end

    for lin = 1, LINHAS do
        for col = 1, COLUNAS do
            local n = 0
            paraCadaVizinha(lin, col, function(l, c)
                if celulas[l][c].mina then n = n + 1 end
            end)
            celulas[lin][col].vizinhas = n
        end
    end
    minasPostas = true
end

local function revelar(lin, col)
    local c = celulas[lin][col]
    if c.aberta or c.bandeira then return end

    c.aberta = true
    abertas = abertas + 1

    if c.vizinhas == 0 and not c.minha then
        paraCadaVizinha(lin, col, revelar)
    end
end

local function abrir(lin, col)
    local c = celulas[lin][col]
    if c.aberta or c.bandeira then return end

    if not minasPostas then
        porMinas(lin, col)
    end

    if c.mina then
        estado = "perdeu"
        for l = 1, LINHAS do
            for k = 1, COLUNAS do
                if celulas[l][k].mina then celulas[l][k].aberta = true end
            end
        end
        return
    end

    revelar(lin, col)
    if abertas == LINHAS * COLUNAS - MINAS then
        estado = "venceu"
    end
end

local function marcar(lin, col)
    local c = celulas[lin][col]
    if c.aberta then return end
    c.bandeira = not c.bandeira
    if c.bandeira then
        bandeiras = bandeiras + 1
    else
        bandeiras = bandeiras - 1
    end
end

function love.mousepressed(x, y, botao)
    if estado ~= "jogando" then return end
    local lin, col = celulaNoPonto(x, y)
    if lin == nil then return end

    if botao == 1 then
        abrir(lin, col)
    elseif botao == 2 then
        marcar(lin, col)
    end
end

function love.update(dt)
    if estado == "jogando" and minasPostas then
        tempo = tempo + dt
    end
end

local fonte
local CORES = {
    { 0.35, 0.55, 1 },
    -- 1
    { 0.3,  0.8,  0.35 }, -- 2
    { 1,    0.35, 0.3 },
    -- 3
    { 0.7,  0.4,  1 },
    -- 4
    { 1,    0.6,  0.2 },
    -- 5
    { 0.3,  0.85, 0.85 }, -- 6
    { 1,    1,    1 },
    -- 7
    { 0.6,  0.6,  0.6 },
    -- 8
}
function love.load()
    fonte = love.graphics.newFont(20)
    novaGrade()
end

local function pintarCelula(lin, col)
    local c = celulas[lin][col]
    local x = (col - 1) * TAM
    local y = TOPO + (lin - 1) * TAM
    if not c.aberta then
        love.graphics.setColor(0.45, 0.47, 0.52)
        love.graphics.rectangle("fill", x + 1, y + 1, TAM - 2, TAM - 2)
        if c.bandeira then
            love.graphics.setColor(1, 0.85, 0.2)
            love.graphics.polygon("fill", x + 12, y + 8, x + 30, y + 15, x + 12, y + 22)
            love.graphics.rectangle("fill", x + 11, y + 8, 2, 24)
        end
        return
    end
    love.graphics.setColor(0.18, 0.18, 0.2)
    love.graphics.rectangle("fill", x + 1, y + 1, TAM - 2, TAM - 2)
    if c.mina then
        love.graphics.setColor(0.9, 0.2, 0.2)
        love.graphics.circle("fill", x + TAM / 2, y + TAM / 2, TAM / 4)
    elseif c.vizinhas > 0 then
        love.graphics.setColor(CORES[c.vizinhas])
        love.graphics.printf(tostring(c.vizinhas), x, y + 9, TAM, "center")
    end
end
function love.draw()
    love.graphics.setFont(fonte)
    for lin = 1, LINHAS do
        for col = 1, COLUNAS do
            pintarCelula(lin, col)
        end
    end
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Minas: " .. (MINAS - bandeiras), 10, 14)
    love.graphics.printf(string.format("%d s", math.floor(tempo)), 0, 14, COLUNAS * TAM - 10, "right")
    if estado == "perdeu" then
        love.graphics.printf("Bum! R recomeça", 0, 14, COLUNAS * TAM, "center")
    elseif estado == "venceu" then
        love.graphics.printf("Venceu! R recomeça", 0, 14, COLUNAS * TAM, "center")
    end
end

function love.keypressed(tecla)
    if tecla == "escape" then
        love.event.quit()
    elseif tecla == "r" then
        novaGrade()
    end
end
