local pet = {
    nome = "Boludo",
    fome = 100,
    alegria = 100,
    vivo = true,
    mensagem = "Estou de boa!"
}

local btnComida = { texto = "Dar Comida", x = 20, y = 200, w = 120, h = 40 }
local btnBrincar = { texto = "Brincar", x = 160, y = 200, w = 120, h = 40 }

local function checkClick(mx, my, x, y, w, h)
    return mx >= x and mx <= x + w and my >= y and my <= y + h
end

local function desenharBotao(botao)
    if not pet.vivo then
        love.graphics.setColor(0.3, 0.3, 0.3)
    else
        love.graphics.setColor(0.2, 0.6, 0.8)
    end
    love.graphics.rectangle("fill", botao.x, botao.y, botao.w, botao.h)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(botao.texto, botao.x, botao.y + 12, botao.w, "center")
end

local function desenharPet()
    if not pet.vivo then
        love.graphics.setColor(0.5, 0.5, 0.5)
    elseif pet.fome < 30 or pet.alegria < 30 then
        love.graphics.setColor(0.9, 0.2, 0.2)
    else
        love.graphics.setColor(0.2, 0.8, 0.3)
    end

    love.graphics.rectangle("fill", 100, 50, 100, 100)

    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(pet.nome .. " - " .. pet.mensagem, 0, 20, 300, "center")
    love.graphics.print("Fome: " .. math.floor(pet.fome), 100, 160)
    love.graphics.print("Alegria: " .. math.floor(pet.alegria), 100, 175)
end

function love.draw()
    desenharPet()
    desenharBotao(btnComida)
    desenharBotao(btnBrincar)
end

function love.mousepressed(x, y, button)
    if button ~= 1 then return end
    if not pet.vivo then return end

    if checkClick(x, y, btnComida.x, btnComida.y, btnComida.w, btnComida.h) then
        pet.fome = math.min(100, pet.fome + 20)
        pet.mensagem = "Nham nham"
        return
    end

    if checkClick(x, y, btnBrincar.x, btnBrincar.y, btnBrincar.w, btnBrincar.h) then
        pet.alegria = math.min(100, pet.alegria + 20)
        pet.fome = math.max(0, pet.fome - 5)
        pet.mensagem = "YAY!"
        return
    end
end

function love.keypressed(tecla)
    if tecla == "escape" then
        love.event.quit()
    elseif tecla == "r" and not pet.vivo then
        pet = {
            nome = "Boludo",
            fome = 100,
            alegria = 100,
            vivo = true,
            mensagem = "Estou de boa!"
        }
    end
end

function love.update(dt)
    if not pet.vivo then return end

    pet.fome = pet.fome - (5 * dt)
    pet.alegria = pet.alegria - (3 * dt)

    if pet.fome <= 0 or pet.alegria <= 0 then
        pet.vivo = false
        pet.fome = 0
        pet.alegria = 0
        pet.mensagem = "A morte chegou...Aperte R para recomeçar."
    elseif pet.fome < 30 then
        pet.mensagem = "Me dê comida, SEU TOLO!"
    elseif pet.alegria < 30 then
        pet.mensagem = "AwwwWRHRHR"
    end
end
