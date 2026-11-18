local animacao = {}
function animacao.nova(quantidade, duracao)
    return { quantidade = quantidade, duracao = duracao, tempo = 0, quadro = 1 }
end

function animacao.avancar(a, dt)
    a.tempo = a.tempo + dt
    while a.tempo >= a.duracao do
        a.tempo = a.tempo - a.duracao
        a.quadro = a.quadro % a.quantidade + 1
    end
end

function animacao.reiniciar(a)
    a.tempo = 0
    a.quadro = 1
end

return animacao

