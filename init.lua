local awful = require("awful")
local wibox = require("wibox")
local naughty = require("naughty")
local gears = require("gears")

-- Importar el widgets
local network = require("widget.network")
local brightness = require("widget.brightness-slider")
local volume = require("widget.volume-slider")
local userProfile = require("widget.user-profile")
local weather = require("widget.weather")
local calendar = require("widget.calendar")

local bg_color = "#ffffff0a"
local active_color = "#ffffff73"
local icon_size = 32  -- Define el tamaño del icono

-- Crear un layout vertical
local main_layout = wibox.layout.fixed.vertical()
local Mainnotification_layout = wibox.layout.fixed.horizontal()
local control_layout = wibox.layout.fixed.vertical()
control_layout.visible = false

-- Crear una caja para el layout de notificaciones
local notification_box = wibox {
    width = 400,
    height = 600,
    ontop = true,
    visible = false,
    bg = "#000000aa",
    shape = gears.shape.rounded_rect,  -- Añadir bordes redondeados
    widget = main_layout
}

-- Posicionar la caja en la parte superior centrada
awful.placement.top(notification_box, { margins = { top = 10 }, parent = awful.screen.focused() })
awful.placement.center_horizontal(notification_box, { parent = awful.screen.focused() })

-- Crear una señal para alternar la visibilidad de la caja de notificaciones
awesome.connect_signal("toggle_notification_box", function()
    notification_box.visible = not notification_box.visible
end)

local is_notification_mode = true

local notification_button = wibox.widget {
    {
        text = "Notification",
        align = "center",
        valign = "center",
        widget = wibox.widget.textbox
    },
    widget = wibox.container.background,
    bg = is_notification_mode and active_color or bg_color,  -- Cambiar el color de fondo basado en is_notification_mode
    shape = function(cr, width, height)
        gears.shape.partially_rounded_rect(cr, width, height, true, false, false, true, 5)
    end,
    margins = 10,
    forced_width = 75,  -- Aumentar el tamaño del fondo
    forced_height = 25,  -- Aumentar el tamaño del fondo
    buttons = gears.table.join(
        awful.button({}, 1, function()
            awesome.emit_signal("set_mode", true)
        end)
    )
}

local control_button = wibox.widget {
    {
        text = "Control",
        align = "center",
        valign = "center",
        widget = wibox.widget.textbox
    },
    widget = wibox.container.background,
    bg = is_notification_mode and bg_color or active_color,  -- Cambiar el color de fondo basado en is_notification_mode
    shape = function(cr, width, height)
        gears.shape.partially_rounded_rect(cr, width, height, false, true, true, false, 5)
    end,
    margins = 10,
    forced_width = 75,  -- Aumentar el tamaño del fondo
    forced_height = 25,  -- Aumentar el tamaño del fondo
    buttons = gears.table.join(
        awful.button({}, 1, function()
            awesome.emit_signal("set_mode", false)
        end)
    )
}

awesome.connect_signal("set_mode", function(mode)
    is_notification_mode = mode
    notification_button.bg = is_notification_mode and active_color or bg_color
    control_button.bg = is_notification_mode and bg_color or active_color
    Mainnotification_layout.visible = is_notification_mode
    control_layout.visible = not is_notification_mode
end)

local button_panel = wibox.widget {
    {
        notification_button,
        control_button,
        layout = wibox.layout.fixed.horizontal,
        spacing = 0
    },
    margins = 10,
    widget = wibox.container.margin
}

-- Centrar el button_panel
local centered_button_panel = wibox.widget {
    nil,
    button_panel,
    nil,
    expand = "none",
    layout = wibox.layout.align.horizontal
}

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

-- Cosas del control_layout

local test = wibox.widget {
    {
        widget = network
    },
    forced_width = 100,
    forced_height = 100,
    widget = wibox.container.margin
}

local slider_layout = wibox.layout.fixed.vertical()
slider_layout:add(volume)
slider_layout:add(brightness)

control_layout:add(test)
control_layout:add(slider_layout)


main_layout:add(centered_button_panel)
main_layout:add(Mainnotification_layout)
main_layout:add(control_layout)


local notification_container = wibox.container.margin(notification_layout, 10, 10, 10, 10)
local notZone = wibox.layout.fixed.vertical()
local dataZone = wibox.layout.fixed.vertical()
dataZone.forced_width = 200
dataZone.spacing = 10
notZone.forced_width = 200

dataZone:add(userProfile)
dataZone:add(weather)
dataZone:add(calendar)
notZone:add(centered_clear_button)
notZone:add(notification_container)

Mainnotification_layout:add(dataZone)
Mainnotification_layout:add(notZone)