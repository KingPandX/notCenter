local awful = require("awful")
local wibox = require("wibox")
local naughty = require("naughty")
local gears = require("gears")

-- Importar el widgets
local airplanemode = require("widget.airplane-mode")
local blue_light = require("widget.blue-light")
local poweroff = require("widget.end-session")
local cpu = require("widget.cpu-meter.init")
local ram = require("widget.ram-meter.init")
local temp = require("widget.temperature-meter")
local brightness = require("widget.brightness-slider")
local volume = require("widget.volume-slider")


local news = require("notCenter.news")
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
    width = 900,
    height = 700,
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
    notification:get_children_by_id("title_role")[1].markup = title
    notification:get_children_by_id("message_role")[1].markup = message

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

control_layout.spacing = 10

local firstBlock = wibox.layout.fixed.horizontal()

firstBlock.spacing = 10

local togglesBox = wibox.layout.fixed.vertical()

local togglesBG = wibox.widget {
    {
        togglesBox,
        widget = wibox.container.margin,
        margins = 10
    },
    widget = wibox.container.background,
    bg = bg_color,
    shape = gears.shape.rounded_rect
}

togglesBox.spacing = 10
togglesBox:add(airplanemode)
togglesBox:add(blue_light)

local slider_layout = wibox.layout.fixed.vertical()

local sliderBG = wibox.widget {
    {
        slider_layout,
        widget = wibox.container.margin,
        margins = 10
    },
    widget = wibox.container.background,
    bg = bg_color,
    shape = gears.shape.rounded_rect
}

slider_layout:add(volume)
slider_layout:add(brightness)

firstBlock:add(togglesBG)
firstBlock:add(sliderBG)

local secondBlock = wibox.layout.fixed.vertical()
secondBlock:add(cpu)
secondBlock:add(ram)
secondBlock:add(temp)

local secondBlockBG = wibox.widget {
    {
        secondBlock,
        widget = wibox.container.margin,
        margins = 10
    },
    widget = wibox.container.background,
    bg = bg_color,
    shape = gears.shape.rounded_rect
}

local centermargin = wibox.widget {
    {
        firstBlock,
        secondBlockBG,
        layout = wibox.layout.fixed.vertical,
        spacing = 10
    },
    widget = wibox.container.margin,
    margins = 10
}
control_layout:add(centermargin)

main_layout:add(centered_button_panel)
main_layout:add(Mainnotification_layout)
main_layout:add(control_layout)


local notification_container = wibox.container.margin(notification_layout, 10, 10, 10, 10)
local notZone = wibox.layout.fixed.vertical()
local dataZone = wibox.layout.fixed.vertical()

local center_calendar = wibox.widget {
    nil,
    {
        calendar,
        widget = wibox.container.margin,
        margins = 10
    },
    nil,
    expand = "none",
    layout = wibox.layout.align.horizontal
}

local center_news = wibox.widget {
    nil,
    {
        {
            news,
            widget = wibox.container.margin,
            margins = 10
        },
        widget = wibox.container.background,
        bg = bg_color,
        shape = gears.shape.rounded_rect
    },
    nil,
    expand = "none",
    layout = wibox.layout.align.horizontal
}

local center_weather = wibox.widget {
    nil,
    {
        weather,
        widget = wibox.container.margin,
    },
    nil,
    expand = "none",
    layout = wibox.layout.align.horizontal
}


dataZone.forced_width = 370
dataZone.spacing = 10
notZone.forced_width = 530

local dataWidth = 320

news.forced_width = dataWidth
weather.forced_width = dataWidth
calendar.forced_width = dataWidth

dataZone:add(center_news)
dataZone:add(center_weather)
dataZone:add(center_calendar)
notZone:add(centered_clear_button)
notZone:add(notification_container)

Mainnotification_layout:add(dataZone)
Mainnotification_layout:add(notZone)