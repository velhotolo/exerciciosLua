local pixelart = require("pixelart")
local animacao = require("animacao")
local varg = require("varg")
local ESCALA = 6
local ARQUIVO = "folha_varg.png"

local folha

local quads = {}

local L, A

local anim
local heroi = { x = 400, direcao = 1, andando = false }
local VELOCIDADE = 120

local fonte
function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    fonte = love.graphics.newFont(16)
    local quadros = assert(pixelart.lerFolha(varg.quadros, varg.paleta))
    L, A = quadros[1].largura, quadros[1].altura

    local dados = love.image.newImageData(L * #quadros, A)
    for i, q in ipairs(quadros) do
        local deslocamento = (i - 1) * L
        for _, p in ipairs(q.pixels) do
            dados:setPixel(deslocamento + p.x, p.y, p.cor[1], p.cor[2], p.cor[3], 1)
        end
    end
    dados:encode("png", ARQUIVO)

    folha = love.graphics.newImage(dados)
    for i = 1, #quadros do
        quads[i] = love.graphics.newQuad((i - 1) * L, 0, L, A, folha:getDimensions())
    end
    anim = animacao.nova(#quadros, 0.12)
end

function love.keypressed(tecla)
    if tecla == "escape" then love.event.quit() end
end

function love.update(dt)
    local largura = love.graphics.getWidth()
    heroi.andando = false

    if love.keyboard.isDown("right") then
        heroi.x = heroi.x + VELOCIDADE * dt
        heroi.direcao = 1
        heroi.andando = true
    elseif love.keyboard.isDown("left") then
        heroi.x = heroi.x - VELOCIDADE * dt
        heroi.direcao = -1
        heroi.andando = true
    end

    local meio = L * ESCALA / 2
    heroi.x = math.max(meio, math.min(largura - meio, heroi.x))

    if heroi.andando then
        animacao.avancar(anim, dt)
    else
        animacao.reiniciar(anim)
    end
end

function love.draw()
    local largura, altura = love.graphics.getDimensions()
    local chao = altura * 0.75

    love.graphics.clear(0.15, 0.17, 0.22)


    love.graphics.setColor(0.25, 0.35, 0.2)
    love.graphics.rectangle("fill", 0, chao, largura, altura - chao)


    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(folha, quads[anim.quadro], heroi.x, chao, 0, ESCALA * heroi.direcao, ESCALA, L / 2, A)


    local escalaFolha = 3
    love.graphics.draw(folha, 16, 16, 0, escalaFolha, escalaFolha)

    love.graphics.setColor(1, 0.85, 0.4)
    love.graphics.rectangle("line", 16 + (anim.quadro - 1) * L * escalaFolha, 16, L * escalaFolha, A * escalaFolha)

    love.graphics.setFont(fonte)
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print(
        "Quadro " .. anim.quadro .. " de " .. #quads .. " setas esquerda e direita andam, Esc sai da aplicação", 16,
        16 + A * escalaFolha + 10)
    love.graphics.printf("Folha gravada em " .. love.filesystem.getSaveDirectory() .. "/" .. ARQUIVO, 16, altura - 50,
        largura - 32, "left")
end
