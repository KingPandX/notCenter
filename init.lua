local awful = require("awful")
local wibox = require("wibox")
local naughty = require("naughty")
local gears = require("gears")

local bg_color = "#ffffff0a"
local icon_size = 32  -- Define el tamaño del icono

-- Crear un layout vertical
local main_layout = wibox.layout.fixed.vertical()

-- Crear una caja para el layout de notificaciones
local notification_box = wibox {
    width = 400,
    height = 600,
    ontop = true,
    visible = false,
    bg = "#000000aa",
    widget = main_layout
}

-- Posicionar la caja en la parte superior centrada
awful.placement.top(notification_box, { margins = { top = 10 }, parent = awful.screen.focused() })
awful.placement.center_horizontal(notification_box, { parent = awful.screen.focused() })

-- Crear una señal para alternar la visibilidad de la caja de notificaciones
awesome.connect_signal("toggle_notification_box", function()
    notification_box.visible = not notification_box.visible
end)

local notification_layout = wibox.layout.fixed.vertical()

local function clear_notifications()
    notification_layout:reset()
    notification_box.visible = false
end

local function remove_notification(notification)
    for i, widget in ipairs(notification_layout.children) do
        if widget == notification then
            notification_layout:remove(i)
            break
        end
    end
end

local notification_template = {
    {
        {
            {
                id = "icon_role",
                widget = wibox.widget.imagebox,
                forced_width = icon_size,  -- Usar el tamaño del icono
                forced_height = icon_size  -- Usar el tamaño del icono
            },
            margins = 5,
            widget = wibox.container.margin
        },
        {
            {
                id = "title_role",
                widget = wibox.widget.textbox
            },
            {
                id = "message_role",
                widget = wibox.widget.textbox
            },
            layout = wibox.layout.fixed.vertical
        },
        layout = wibox.layout.fixed.horizontal
    },
    margins = 5,
    widget = wibox.container.margin
}

local function create_notification(icon, title, message)
    local notification = wibox.widget {
        {
            notification_template,
            bg = bg_color,
            shape = gears.shape.rounded_rect,
            widget = wibox.container.background
        },
        margins = 5,
        widget = wibox.container.margin
    }
    notification:get_children_by_id("icon_role")[1].image = icon
    notification:get_children_by_id("title_role")[1].text = title
    notification:get_children_by_id("message_role")[1].text = message

    notification:buttons(gears.table.join(
        awful.button({}, 1, function()
            remove_notification(notification)
            if #notification_layout.children <= 0 then
                notification_box.visible = false
            end
        end)
    ))

    return notification
end

local function add_notification(icon, title, message)
    notification_layout:add(create_notification(icon, title, message))
end

naughty.connect_signal("request::display", function(n)
    add_notification(n.icon, n.title, n.message)
end)

local clear_button = wibox.widget {
    {
        {
            widget = wibox.container.background,
            bg = bg_color, -- Fondo blanco con 30% de opacidad
            shape = gears.shape.rounded_bar,
            {
                widget = wibox.container.margin,
                margins = 5,
                {
                    text = "Clear",
                    align  = 'center',
                    valign = 'center',
                    widget = wibox.widget.textbox
                }
            }
        },
        margins = 10,
        widget = wibox.container.margin
    },
    buttons = gears.table.join(
        awful.button({}, 1, function()
            clear_notifications()
        end)
    ),
    widget = wibox.container.background
}

-- Centrar el clear_button
local centered_clear_button = wibox.widget {
    nil,
    clear_button,
    nil,
    expand = "none",
    layout = wibox.layout.align.horizontal
}
main_layout:add(centered_clear_button)
local notification_container = wibox.container.margin(notification_layout, 10, 10, 10, 10)
main_layout:add(notification_container)