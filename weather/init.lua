local wibox = require('wibox')
local awful = require('awful')
local gears = require('gears')
local naughty = require('naughty')
local beautiful = require('beautiful')
local dpi = beautiful.xresources.apply_dpi
local config_dir = gears.filesystem.get_configuration_dir()
local widget_icon_dir = config_dir .. 'widget/weather/icons/'
local clickable_container = require('widget.clickable-container')
local json = require('library.json')

local config = require('configuration.config')
local secrets = {
	key = config.widget.weather.key,
	lon = config.widget.weather.lon,
	lat = config.widget.weather.lat,
	update_interval = config.widget.weather.update_interval,
	units = config.widget.weather.units
}

local weather_icon_widget = wibox.widget {
	{
		id = 'icon',
		image = widget_icon_dir .. 'weather-error.svg',
		resize = true,
		forced_height = dpi(45),
		forced_width = dpi(45),
		widget = wibox.widget.imagebox,
	},
	layout = wibox.layout.fixed.horizontal
}

local sunrise_icon_widget = wibox.widget {
	{
		id = 'sunrise_icon',
		image = widget_icon_dir .. 'sunrise.svg',
		resize = true,
		forced_height = dpi(18),
		forced_width = dpi(18),
		widget = wibox.widget.imagebox,
	},
	layout = wibox.layout.fixed.horizontal
}

local sunset_icon_widget = wibox.widget {
	{
		id = 'sunset_icon',
		image = widget_icon_dir .. 'sunset.svg',
		resize = true,
		forced_height = dpi(18),
		forced_width = dpi(18),
		widget = wibox.widget.imagebox,
	},
	layout = wibox.layout.fixed.horizontal
}

local refresh_icon_widget = wibox.widget {
	{
		id = 'refresh_icon',
		image = widget_icon_dir .. 'refresh.svg',
		resize = true,
		forced_height = dpi(18),
		forced_width = dpi(18),
		widget = wibox.widget.imagebox,
	},
	layout = wibox.layout.fixed.horizontal
}

local refresh_button = clickable_container(refresh_icon_widget)
refresh_button:buttons(
	gears.table.join(
		awful.button(
			{},
			1,
			nil,
			function()
				awesome.emit_signal('widget::weather_fetch')
				awesome.emit_signal('widget::forecast_fetch')
			end
		)
	)
)

local refresh_widget = wibox.widget {
	refresh_button,
	bg = beautiful.transparent,
	shape = gears.shape.circle,
	widget = wibox.container.background
}

local weather_desc_temp = wibox.widget {
	{
		id 	   = 'description',
		markup = 'Dust and clouds, -1000°C',
		font   = 'Inter Regular 10',
		align  = 'left',
		valign = 'center',
		widget = wibox.widget.textbox
	},
	id = 'scroll_container',
	max_size = 345,
	speed = 75,
	expand = true,
	direction = 'h',
	step_function = wibox.container.scroll
					.step_functions.waiting_nonlinear_back_and_forth,
	fps = 30,
	layout = wibox.container.scroll.horizontal,
}

local weather_location = wibox.widget {
	{
		id 	   = 'location',
		markup = 'Earth, Milky Way',
		font   = 'Inter Regular 10',
		align  = 'left',
		valign = 'center',
		widget = wibox.widget.textbox
	},
	id = 'scroll_container',
	max_size = 345,
	speed = 75,
	expand = true,
	direction = 'h',
	step_function = wibox.container.scroll
					.step_functions.waiting_nonlinear_back_and_forth,
	fps = 30,
	layout = wibox.container.scroll.horizontal,
}

local weather_sunrise = wibox.widget {
	markup = '00:00',
	font   = 'Inter Regular 10',
	align  = 'center',
	valign = 'center',
	widget = wibox.widget.textbox
}

local weather_sunset = wibox.widget {
	markup = '00:00',
	font   = 'Inter Regular 10',
	align  = 'center',
	valign = 'center',
	widget = wibox.widget.textbox
}

local weather_data_time = wibox.widget {
	markup = '00:00',
	font   = 'Inter Regular 10',
	align  = 'center',
	valign = 'center',
	widget = wibox.widget.textbox
}

local weather_forecast_tooltip = awful.tooltip {
	text = 'Loading...',
	objects = {weather_icon_widget},
	mode = 'outside',
	align = 'right',
	preferred_positions = {'left', 'right', 'top', 'bottom'},
	margin_leftright = dpi(8),
	margin_topbottom = dpi(8)
}

local weather_report =  wibox.widget {
	{
		{
			layout = wibox.layout.fixed.horizontal,
			spacing = dpi(10),
			{
				layout = wibox.layout.align.vertical,
				expand = 'none',
				nil,
				weather_icon_widget,
				nil
			},
			{
				layout = wibox.layout.align.vertical,
				expand = 'none',
				nil,
				{
					layout = wibox.layout.fixed.vertical,
					weather_location,
					weather_desc_temp,
					{
						layout = wibox.layout.fixed.horizontal,
						spacing = dpi(7),
						{
							layout = wibox.layout.fixed.horizontal,
							spacing = dpi(3),
							sunrise_icon_widget,
							weather_sunrise
						},
						{
							layout = wibox.layout.fixed.horizontal,
							spacing = dpi(3),
							sunset_icon_widget,
							weather_sunset
						},
						{
							layout = wibox.layout.fixed.horizontal,
							spacing = dpi(3),
							refresh_widget,
							weather_data_time
						}
					}
				},
				nil				
			}
		},
		margins = dpi(10),
		widget = wibox.container.margin
	},
	forced_height = dpi(92),
	bg = beautiful.groups_bg,
	shape = function(cr, width, height)
		gears.shape.partially_rounded_rect(cr, width, height, true, true, true, true, beautiful.groups_radius) 
	end,
	widget = wibox.container.background	
}

-- Return weather symbol
local get_weather_symbol = function()
	local symbol_tbl = {
		['metric'] = '°C',
		['imperial'] = '°F'
	}

	return symbol_tbl[secrets.units]
end

-- Create openweathermap script based on pass mode
-- Mode must be `forecast` or `weather`
local create_weather_script = function(mode)
	local weather_script = [[ ]]
	.. 'API_KEY="' .. secrets.key .. '"\n' 
	.. 'LON="' .. secrets.lon .. '"\n' 
	.. 'LAT="' .. secrets.lat .. '"\n' ..
	[[
		weather=$(curl -sf "http://api.openweathermap.org/data/2.5/weather?APPID=${API_KEY}&lon=${LON}&lat=${LAT}&units=metric")

		if [ ! -z "$weather" ]; then
		  code=$(echo $weather | jq -r ".weather[0].icon")
		  desc=$(echo $weather | jq -r ".weather[0].description")
		  location=$(echo $weather | jq -r ".name")
		  sunrise=$(date -d @$(echo $weather | jq ".sys.sunrise") +'%H:%M')
		  sunset=$(date -d @$(echo $weather | jq ".sys.sunset") +'%H:%M')
		  data_receive=$(date +'%H:%M')
		  
		  echo $code
		  echo $desc 
		  echo $location 
		  echo $sunrise 
		  echo $sunset 
		  echo $data_receive
		else
		  printf "error"
		fi
	]]
	return weather_script
end

awesome.connect_signal(
	'widget::weather_update', 
	function(code, desc, location, sunrise, sunset, data_receive)
		local widget_icon_name = 'weather-error'

		local icon_tbl = {
			['01d'] = 'sun_icon.svg',
			['01n'] = 'moon_icon.svg',
			['02d'] = 'dfew_clouds.svg',
			['02n'] = 'nfew_clouds.svg',
			['03d'] = 'dscattered_clouds.svg',
			['03n'] = 'nscattered_clouds.svg',
			['04d'] = 'dbroken_clouds.svg',
			['04n'] = 'nbroken_clouds.svg',
			['09d'] = 'dshower_rain.svg',
			['09n'] = 'nshower_rain.svg',
			['10d'] = 'd_rain.svg',
			['10n'] = 'n_rain.svg',
			['11d'] = 'dthunderstorm.svg',
			['11n'] = 'nthunderstorm.svg',
			['13d'] = 'snow.svg',
			['13n'] = 'snow.svg',
			['50d'] = 'dmist.svg',
			['50n'] = 'nmist.svg',
			['...'] = 'weather-error.svg'
		}

		widget_icon_name = icon_tbl[code]

		weather_icon_widget.icon:set_image(widget_icon_dir .. widget_icon_name)
		weather_icon_widget.icon:emit_signal('widget::redraw_needed')
		
		weather_desc_temp.description:set_markup(desc)
		weather_location.location:set_markup(location)
		weather_sunrise:set_markup(sunrise)
		weather_sunset:set_markup(sunset)
		weather_data_time:set_markup(data_receive)

	end
)

-- Fetch weather report

local function UpdateWeather()
	awful.spawn.easy_async_with_shell(
		create_weather_script('weather'),
		function(stdout)
			local weather_data = {}
			for line in stdout:gmatch("[^\r\n]+") do
				table.insert(weather_data, line)
			end

			awesome.emit_signal(
				'widget::weather_update',
				weather_data[1],
				weather_data[2],
				weather_data[3],
				weather_data[4],
				weather_data[5],
				weather_data[6]
			)
		end
	)
end

-- Update weather report
gears.timer {
	timeout = secrets.update_interval,
	call_now = true,
	autostart = true,
	callback = function()
		UpdateWeather()
	end
}

return weather_report
