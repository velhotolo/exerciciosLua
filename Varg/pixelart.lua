local pixelart = {}

function pixelart.lerQuadro(texto, paleta)
    local linhas = {}
    for linha in texto:gmatch("[^\n]+") do
        linha = linha:match("^%s*(.-)%s*$")
        if linha ~= "" then linhas[#linhas + 1] = linha end
    end
    if #linhas == 0 then return nil, "quadro vazio" end

    local largura = #linhas[1]
    local pixels = {}
    for y, linha in ipairs(linhas) do
        if #linha ~= largura then
            return nil, "linha " .. y .. " tem " .. #linha .. " caracteres; esperava " .. largura
        end
        for x = 1, largura do
            local letra = linha:sub(x, x)
            if letra ~= "." then
                local cor = paleta[letra]
                if not cor then
                    return nil, "a letra '" .. letra .. "' da linha " .. y .. " não está na paleta"
                end
                pixels[#pixels + 1] = { x = x - 1, y = y - 1, cor = cor }
            end
        end
    end
    return { largura = largura, altura = #linhas, pixels = pixels }
end

function pixelart.lerFolha(textos, paleta)
    local quadros = {}
    for i, texto in ipairs(textos) do
        local q, erro = pixelart.lerQuadro(texto, paleta)
        if not q then return nil, "quadro" .. i .. ": " .. erro end
        if i > 1 and (q.largura ~= quadros[1].largura or q.altura ~= quadros[1].altura) then
            return nil,
                "quadro " .. i .. " tem tamanho diferente do quadro 1"
        end
        quadros[i] = q
    end
    return quadros
end

return pixelart
