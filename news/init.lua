local wibox = require("wibox")
local gears = require("gears")
local awful = require("awful")

local imageWidth = 200
local imageHeight = 200

local update_interval = 300

local news_widget = wibox.widget {
    {
        {
            id = "image",
            widget = wibox.widget.imagebox,
            resize = true,
            forced_height = imageHeight,
            clip_shape = gears.shape.rounded_rect
        },
        {
            {
                id = "title",
                widget = wibox.widget.textbox,
                text = "Title",
                font = "Sans Bold 14"
            },
            {
                id = "author",
                widget = wibox.widget.textbox,
                text = "Author",
                font = "Sans Italic 10"
            },
            layout = wibox.layout.fixed.vertical
        },
        layout = wibox.layout.fixed.vertical
    },
    buttons = gears.table.join(
        awful.button({}, 1, function()
            awful.spawn("xdg-open 'https://example.com'")
        end)
    ),
    layout = wibox.layout.fixed.vertical
}

local function update_news_widget()
    awful.spawn.easy_async_with_shell("sh ~/.config/awesome/notCenter/news/get_news.sh", function(stdout)
        local lines = {}
        for line in stdout:gmatch("[^\r\n]+") do
            table.insert(lines, line)
        end

        if #lines >= 3 then
            news_widget:get_children_by_id("title")[1].text = lines[1]
            news_widget:get_children_by_id("image")[1].image = lines[2]
            news_widget:get_children_by_id("author")[1].text = lines[3]
            news_widget.buttons = gears.table.join(
                awful.button({}, 1, function()
                    awful.spawn("xdg-open '" .. lines[4] .. "'")
                end)
            )
        end
    end)
end

update_news_widget()

gears.timer {
    timeout = update_interval,
    autostart = true,
    callback = update_news_widget
}

return news_widget
