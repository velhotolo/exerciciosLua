local ui = {}

function ui.window(x, y, w, h)
    local g = love.graphics
    g.setColor(0.05, 0.08, 0.35, 0.92)
    g.rectangle("fill", x, y, w, h, 8, 8)
    g.setColor(1, 1, 1)
    g.setLineWidth(1)
end

return ui
