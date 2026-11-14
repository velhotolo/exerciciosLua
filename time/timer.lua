local Timer = { lista = {} }

function Timer.after(segundos, fn)
    local t = { resta = segundos, fn = fn }
    table.insert(Timer.lista, t)
    return t
end

function Timer.every(segundos, fn)
    local t = { rest = segundos, fn = fn, repetir = segundos }
    table.insert(Timer.lista, t)
    return t
end

function Timer.cancel(t)
    for i, item in ipairs(Timer.lista) do
        if item == t then
            table.remove(Timer.lista, i); return
        end
    end
end

function Timer.update(dt)
    for i = #Timer.lista, 1, -1 do
        local t = Timer.lista[i]
        t.rest = t.rest - dt
        if t.rest <= 0 then
            t.fn()
            if t.repetir then
                t.rest = t.rest + t.repetir
            else
                table.remove(Timer.lista, i)
            end
        end
    end
end

return Timer
