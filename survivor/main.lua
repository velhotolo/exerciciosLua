-- Constantes de balanceamento e cronograma
local LARGURA, ALTURA = 800, 600
local TEMPO_TROCA_INIMIGO = 40 -- Tempo (em seg) para começar a nascer morcegos
local TEMPO_ARMA2 = 20         -- Tempo para liberar a segunda arma (Orbes)
local TEMPO_BOSS = 80          -- Tempo para invocar o chefe

-- Memória Global (Estado do Jogo)
local heroi, inimigos, projeteis, balasBoss
local paredes, lama, boss
local tempo, timerSpawn, abates
local bossApareceu, estado

-- Teorema de Pitágoras para calcular distância entre duas entidades
local function distancia(x1, y1, x2, y2)
    return math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2)
end

-- Detecção de Colisão AABB (Axis-Aligned Bounding Box) entre um círculo (entidade) e retângulos (paredes)
local function bateEmParede(x, y, r)
    for _, p in ipairs(paredes) do
        -- Checa se a borda do círculo invade a área do retângulo
        if x + r > p.x and x - r < p.x + p.w and
            y + r > p.y and y - r < p.y + p.h then
            return true
        end
    end
    return false
end

-- Verifica se as coordenadas do centro (x,y) estão dentro do retângulo de lama
local function estaNaLama(x, y)
    return x > lama.x and x < lama.x + lama.w and
        y > lama.y and y < lama.y + lama.h
end

-- Testa os eixos X e Y separados.
-- Isso permite que o boneco escorregue pela parede em vez de grudar nela.
-- Li em algum artigo a respeito; não sabia dessa.
local function moverComColisao(e, dx, dy)
    if not bateEmParede(e.x + dx, e.y, e.r) then e.x = e.x + dx end
    if not bateEmParede(e.x, e.y + dy, e.r) then e.y = e.y + dy end
    -- Trava a entidade dentro dos limites da tela para não fugir da janela
    e.x = math.max(e.r, math.min(LARGURA - e.r, e.x))
    e.y = math.max(e.r, math.min(ALTURA - e.r, e.y))
end

-- Sistema de frames de invulnerabilidade  para não morrer num único milissegundo
local function ferirHeroi()
    if heroi.invul <= 0 then
        heroi.vida = heroi.vida - 1
        heroi.invul = 1 -- Fica 1 segundo imune
    end
end

-- Consolida todos os alvos válidos num caldeirão só (inimigos comuns + boss)
local function todosOsAlvos()
    local lista = {}
    for _, e in ipairs(inimigos) do table.insert(lista, e) end
    if boss then table.insert(lista, boss) end
    return lista
end

-- Varre a lista de alvos buscando a menor distância (mira automática da varinha)
local function alvoMaisProximo()
    local alvo, menorDist = nil, math.huge
    for _, e in ipairs(todosOsAlvos()) do
        local d = distancia(heroi.x, heroi.y, e.x, e.y)
        if d < menorDist then alvo, menorDist = e, d end
    end
    return alvo
end

-- Usa trigonometria (seno e cosseno) para calcular a posição orbital das orbes
-- Eu esqueci tudo que aprendi no colégio e tô estudando por um curso da Udemy. Aparentemente
-- tem valido à pena.
local function posicaoOrbe(i)
    local orbe = heroi.armas.orbe
    -- Divide 360 graus (2*PI) pela quantidade de orbes para espaçá-las igualmente
    local a = orbe.angulo + (i - 1) * (2 * math.pi / orbe.quantidade)
    return heroi.x + math.cos(a) * orbe.raio, heroi.y + math.sin(a) * orbe.raio
end

-- Zera todas as variáveis para começar ou recomeçar o jogo
local function iniciarJogo()
    heroi = {
        x = 400,
        y = 300,
        r = 14,
        vel = 180,
        vida = 10,
        invul = 0,
        armas = {
            varinha = { recarga = 0.5, timer = 0, dano = 1, velTiro = 400 },
            orbe = { quantidade = 2, angulo = 0, raio = 60, velGiro = 3, tamanho = 10, dano = 1 },
        },
    }

    inimigos, projeteis, balasBoss = {}, {}, {}
    -- Geometria hardcoded do cenário
    paredes = {
        { x = 150, y = 150, w = 120, h = 30 },
        { x = 530, y = 150, w = 120, h = 30 },
        { x = 150, y = 420, w = 120, h = 30 },
        { x = 530, y = 420, w = 120, h = 30 },
    }
    lama = { x = 40, y = 240, w = 140, h = 120 }
    boss = nil
    tempo, timerSpawn, abates = 0, 1, 0
    bossApareceu = false
    estado = "jogando"
end

-- Nasce inimigos nas bordas da tela (1=Cima, 2=Baixo, 3=Esquerda, 4=Direita)
local function criarInimigo()
    local lado = love.math.random(4)
    local x, y
    if lado == 1 then
        x, y = love.math.random(LARGURA), 15
    elseif lado == 2 then
        x, y = love.math.random(LARGURA), ALTURA - 15
    elseif lado == 3 then
        x, y = 15, love.math.random(ALTURA)
    else
        x, y = LARGURA - 15, love.math.random(ALTURA)
    end

    local e = { x = x, y = y, invul = 0 }

    -- Evolução da dificuldade com base no tempo da partida
    if tempo < TEMPO_TROCA_INIMIGO then
        e.tipo, e.r, e.vel, e.vida, e.voa = "gosma", 12, 60, 3, false
    else
        e.tipo, e.r, e.vel, e.vida, e.voa = "morcego", 9, 115, 2, true
    end
    table.insert(inimigos, e)
end

-- Máquina de estados de Spawn
local function atualizarSpawn(dt)
    -- Dispara o Boss e cessa o nascimento de mobs comuns
    if tempo >= TEMPO_BOSS and not bossApareceu then
        boss = { x = LARGURA / 2, y = 60, r = 40, vel = 45, vida = 60, vidaMax = 60, invul = 0, timerTiro = 2 }
        bossApareceu = true
    end
    if bossApareceu then return end

    timerSpawn = timerSpawn - dt
    if timerSpawn <= 0 then
        criarInimigo()
        timerSpawn = 0.8
    end
end

-- Entrada do jogador e aplicação de vetores físicos
local function atualizarHeroi(dt)
    local dx, dy = 0, 0
    if love.keyboard.isDown("left", "a") then dx = dx - 1 end
    if love.keyboard.isDown("right", "d") then dx = dx + 1 end
    if love.keyboard.isDown("up", "w") then dy = dy - 1 end
    if love.keyboard.isDown("down", "s") then dy = dy + 1 end

    -- Normalização do vetor diagonal: evita que o herói ande mais rápido se apertar cima + lado
    -- O valor 0.7071 é aprox. o cosseno/seno de 45 graus (ou 1 / raiz de 2)
    if dx ~= 0 and dy ~= 0 then dx, dy = dx * 0.7071, dy * 0.7071 end

    local vel = heroi.vel
    if estaNaLama(heroi.x, heroi.y) then vel = vel * 0.4 end -- Punição de movimento

    moverComColisao(heroi, dx * vel * dt, dy * vel * dt)
    if heroi.invul > 0 then heroi.invul = heroi.invul - dt end
end

-- Inteligência Artificial burra: sempre vai na linha reta até o herói
local function atualizarInimigos(dt)
    for _, e in ipairs(inimigos) do
        local d = distancia(e.x, e.y, heroi.x, heroi.y)
        if d > 0 then
            -- Calcula a direção e multiplica pela velocidade e tempo
            local mx = (heroi.x - e.x) / d * e.vel * dt
            local my = (heroi.y - e.y) / d * e.vel * dt

            if e.voa then
                e.x, e.y = e.x + mx, e.y + my -- Fantasmas ignoram colisão
            else
                if estaNaLama(e.x, e.y) then mx, my = mx * 0.4, my * 0.4 end
                moverComColisao(e, mx, my)
            end
        end
        if e.invul > 0 then e.invul = e.invul - dt end

        -- Se a distância for menor que a soma dos raios, significa que os círculos colidiram
        if d < e.r + heroi.r then ferirHeroi() end
    end
end

-- Execução da lógica ofensiva do jogador (Auto-fire)
local function atualizarArmas(dt)
    -- Arma 1: Varinha (Dispara em linha reta)
    local varinha = heroi.armas.varinha
    varinha.timer = varinha.timer - dt
    if varinha.timer <= 0 then
        local alvo = alvoMaisProximo()
        if alvo then
            local d = math.max(distancia(heroi.x, heroi.y, alvo.x, alvo.y), 1)
            -- Cria o projétil já com o vetor de velocidade travado na direção atual do alvo
            table.insert(projeteis, {
                x = heroi.x,
                y = heroi.y,
                r = 4,
                dano = varinha.dano,
                vx = (alvo.x - heroi.x) / d * varinha.velTiro,
                vy = (alvo.y - heroi.y) / d * varinha.velTiro,
            })
            varinha.timer = varinha.recarga
        end
    end

    -- Arma 2: Orbes (Desbloqueadas pelo tempo)
    if tempo < TEMPO_ARMA2 then return end
    local orbe = heroi.armas.orbe
    orbe.angulo = orbe.angulo + orbe.velGiro * dt
    for i = 1, orbe.quantidade do
        local ox, oy = posicaoOrbe(i)
        for _, e in ipairs(todosOsAlvos()) do
            -- Dano de contato contínuo
            if e.invul <= 0 and distancia(ox, oy, e.x, e.y) < orbe.tamanho + e.r then
                e.vida = e.vida - orbe.dano
                e.invul = 0.3 -- Dá um pequeno i-frame pro monstro não evaporar em 1 frame
            end
        end
    end
end

-- Varre projetéis DE TRÁS PRA FRENTE.
-- Se você remove o índice 2 num loop normal, o item 3 cai pro índice 2 e o loop pula ele.
-- Lendo do final pro começo, a remoção não afeta os índices não lidos.
local function atualizarProjeteis(dt)
    for i = #projeteis, 1, -1 do
        local p = projeteis[i]
        p.x, p.y = p.x + p.vx * dt, p.y + p.vy * dt

        local acertou = false
        for _, e in ipairs(todosOsAlvos()) do
            if not acertou and e.vida > 0 and
                distancia(p.x, p.y, e.x, e.y) < p.r + e.r then
                e.vida = e.vida - p.dano
                acertou = true
            end
        end

        local fora = p.x < 0 or p.x > LARGURA or p.y < 0 or p.y > ALTURA
        if acertou or fora or bateEmParede(p.x, p.y, p.r) then
            table.remove(projeteis, i) -- Destrói a bala (Garbage Collection do Lua limpa depois)
        end
    end
end

-- IA e Padrão de ataque do Chefe
local function atualizarBoss(dt)
    local d = distancia(boss.x, boss.y, heroi.x, heroi.y)
    if d > 0 then
        moverComColisao(boss, (heroi.x - boss.x) / d * boss.vel * dt,
            (heroi.y - boss.y) / d * boss.vel * dt)
    end
    if d < boss.r + heroi.r then ferirHeroi() end
    if boss.invul > 0 then boss.invul = boss.invul - dt end

    -- Padrão "Bullet Hell": Dispara 12 balas em padrão circular
    boss.timerTiro = boss.timerTiro - dt
    if boss.timerTiro <= 0 then
        for i = 1, 12 do
            local a = (i / 12) * 2 * math.pi
            table.insert(balasBoss, {
                x = boss.x,
                y = boss.y,
                r = 6,
                vx = math.cos(a) * 150,
                vy = math.sin(a) * 150
            })
        end
        boss.timerTiro = 2
    end

    if boss.vida <= 0 then
        boss = nil
        estado = "vitoria"
    end
end

-- Física idêntica à dos projéteis do herói, mas ferindo apenas o jogador
local function atualizarBalasBoss(dt)
    for i = #balasBoss, 1, -1 do
        local b = balasBoss[i]
        b.x, b.y = b.x + b.vx * dt, b.y + b.vy * dt
        local acertou = distancia(b.x, b.y, heroi.x, heroi.y) < b.r + heroi.r
        if acertou then ferirHeroi() end
        local fora = b.x < 0 or b.x > LARGURA or b.y < 0 or b.y > ALTURA
        if acertou or fora or bateEmParede(b.x, b.y, b.r) then
            table.remove(balasBoss, i)
        end
    end
end

-- Limpa os mortos. Novamente iterando de trás pra frente para manter integridade da tabela.
local function limparMortos()
    for i = #inimigos, 1, -1 do
        if inimigos[i].vida <= 0 then
            table.remove(inimigos, i)
            abates = abates + 1
        end
    end
end


-- FUNÇÕES DE DESENHO (RENDERIZAÇÃO)

local function desenharCenario()
    love.graphics.setColor(0.45, 0.3, 0.15)
    love.graphics.rectangle("fill", lama.x, lama.y, lama.w, lama.h)
    love.graphics.setColor(0.5, 0.5, 0.55)
    for _, p in ipairs(paredes) do
        love.graphics.rectangle("fill", p.x, p.y, p.w, p.h)
    end
end

local function desenharHeroi()
    -- Efeito de piscar quando invulnerável (se o valor for par, desenha)
    if heroi.invul > 0 and math.floor(heroi.invul * 10) % 2 == 0 then return end
    love.graphics.setColor(0.2, 0.6, 1)
    love.graphics.circle("fill", heroi.x, heroi.y, heroi.r)
end

local function desenharInimigo(e)
    if e.tipo == "gosma" then
        love.graphics.setColor(0.3, 0.8, 0.3)
    else
        love.graphics.setColor(0.6, 0.3, 0.8)
    end
    love.graphics.circle("fill", e.x, e.y, e.r)
end

local function desenharArmas()
    love.graphics.setColor(1, 1, 0.4)
    for _, p in ipairs(projeteis) do
        love.graphics.circle("fill", p.x, p.y, p.r)
    end
    if tempo >= TEMPO_ARMA2 then
        love.graphics.setColor(1, 0.6, 0.1)
        for i = 1, heroi.armas.orbe.quantidade do
            local ox, oy = posicaoOrbe(i)
            love.graphics.circle("fill", ox, oy, heroi.armas.orbe.tamanho)
        end
    end
end

local function desenharBoss()
    love.graphics.setColor(0.85, 0.15, 0.15)
    love.graphics.circle("fill", boss.x, boss.y, boss.r)
    love.graphics.setColor(1, 0.4, 0.4)
    for _, b in ipairs(balasBoss) do
        love.graphics.circle("fill", b.x, b.y, b.r)
    end
end

local function desenharInterface()
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Vida: " .. heroi.vida, 10, 10)
    love.graphics.print("Tempo: " .. math.floor(tempo), 10, 30)
    love.graphics.print("Abates: " .. abates, 10, 50)

    -- Barra de vida do Chefe desenhada dinamicamente usando proporção
    if boss then
        love.graphics.setColor(0.3, 0.3, 0.3)
        love.graphics.rectangle("fill", 200, 570, 400, 16)
        love.graphics.setColor(0.85, 0.15, 0.15)
        love.graphics.rectangle("fill", 200, 570, 400 * boss.vida / boss.vidaMax, 16)
    end

    love.graphics.setColor(1, 1, 1)
    if estado == "vitoria" then
        love.graphics.printf("VITORIA! Aperte R para jogar de novo", 0, 280, LARGURA, "center")
    elseif estado == "derrota" then
        love.graphics.printf("DERROTA... Aperte R para tentar de novo", 0, 280, LARGURA, "center")
    end
end


-- FUNÇÕES NATIVAS DO LÖVE

function love.load()
    love.window.setMode(LARGURA, ALTURA)
    love.window.setTitle("Survivor - Fase 1")
    iniciarJogo()
end

function love.update(dt)
    if estado ~= "jogando" then return end -- Congela a engine se não estiver jogando
    tempo = tempo + dt
    atualizarSpawn(dt)
    atualizarHeroi(dt)
    atualizarInimigos(dt)
    atualizarArmas(dt)
    atualizarProjeteis(dt)
    if boss then atualizarBoss(dt) end
    atualizarBalasBoss(dt)
    limparMortos()
    if heroi.vida <= 0 then estado = "derrota" end
end

-- O renderizador varre de baixo para cima (background, monstros, balas, herói, interface)
function love.draw()
    desenharCenario()
    for _, e in ipairs(inimigos) do desenharInimigo(e) end
    if boss then desenharBoss() end
    desenharArmas()
    desenharHeroi()
    desenharInterface()
end

function love.keypressed(tecla)
    if tecla == "escape" then love.event.quit() end
    if tecla == "r" and estado ~= "jogando" then iniciarJogo() end
end
