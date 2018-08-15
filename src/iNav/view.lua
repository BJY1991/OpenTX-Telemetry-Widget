local data, config, modes, units, gpsDegMin, gpsIcon, lockIcon, hdopGraph, VERSION, SMLCD, FLASH = ...

local RIGHT_POS = SMLCD and 129 or 195
local GAUGE_WIDTH = SMLCD and 82 or 149
local X_CNTR_1 = SMLCD and 63 or 68
local X_CNTR_2 = SMLCD and 63 or 104
local tmp

local function drawDirection(heading, width, radius, x, y)
	local rad1 = math.rad(heading)
	local rad2 = math.rad(heading + width)
	local rad3 = math.rad(heading - width)
	local x1 = math.floor(math.sin(rad1) * radius + 0.5) + x
	local y1 = y - math.floor(math.cos(rad1) * radius + 0.5)
	local x2 = math.floor(math.sin(rad2) * radius + 0.5) + x
	local y2 = y - math.floor(math.cos(rad2) * radius + 0.5)
	local x3 = math.floor(math.sin(rad3) * radius + 0.5) + x
	local y3 = y - math.floor(math.cos(rad3) * radius + 0.5)
	lcd.drawLine(x1, y1, x2, y2, SOLID, FORCE)
	lcd.drawLine(x1, y1, x3, y3, SOLID, FORCE)
	if data.headingHold then
		lcd.drawFilledRectangle((x2 + x3) / 2 - 1.5, (y2 + y3) / 2 - 1.5, 4, 4, SOLID)
	else
		lcd.drawLine(x2, y2, x3, y3, SMLCD and DOTTED or SOLID, FORCE + (SMLCD and 0 or GREY_DEFAULT))
	end
end

local function drawData(txt, y, dir, vc, vm, max, ext, frac, flags)
	if data.showMax and dir > 0 then
		vc = vm
		lcd.drawText(0, y, string.sub(txt, 1, 3), SMLSIZE)
		lcd.drawText(15, y, dir == 1 and "\192" or "\193", SMLSIZE)
	else
		lcd.drawText(0, y, txt, SMLSIZE)
	end
	local tmp = (frac ~= 0 or vc < max) and ext or ""
	if frac ~= 0 and vc + 0.5 < max then
		lcd.drawText(21, y, string.format(frac, vc) .. tmp, SMLSIZE + flags)
	else
		lcd.drawText(21, y, math.floor(vc + 0.5) .. tmp, SMLSIZE + flags)
	end
end

-- Startup message
if data.startup == 2 then
	if not SMLCD then
		lcd.drawText(53, 9, "INAV Lua Telemetry")
	end
	lcd.drawText(SMLCD and 51 or 91, 17, "v" .. VERSION)
end

-- GPS
local gpsFlags = SMLSIZE + RIGHT + ((not data.telemetry or not data.gpsFix) and FLASH or 0)
tmp = RIGHT_POS - (gpsFlags == SMLSIZE + RIGHT and 0 or 1)
lcd.drawText(tmp, 17, math.floor(data.gpsAlt + 0.5) .. units[data.gpsAlt_unit], gpsFlags)
lcd.drawText(tmp, 25, config[16].v == 0 and string.format(SMLCD and "%.5f" or "%.6f", data.gpsLatLon.lat) or gpsDegMin(data.gpsLatLon.lat, true), gpsFlags)
lcd.drawText(tmp, 33, config[16].v == 0 and string.format(SMLCD and "%.5f" or "%.6f", data.gpsLatLon.lon) or gpsDegMin(data.gpsLatLon.lon, false), gpsFlags)
hdopGraph(RIGHT_POS - 30, 9, SMLSIZE)
gpsIcon(RIGHT_POS - 17, 9)
lcd.drawText(RIGHT_POS - (data.telemetry and 0 or 1), 9, data.satellites % 100, SMLSIZE + RIGHT + data.telemFlags)

-- Directionals
if data.showHead and data.startup == 0 then
	if data.telemetry then
		local indicatorDisplayed = false
		if data.showDir or data.headingRef < 0 or not SMLCD then
			lcd.drawText(X_CNTR_1 - 2, 9, "N " .. math.floor(data.heading + 0.5) % 360 .. "\64", SMLSIZE)
			lcd.drawText(X_CNTR_1 + 10, 21, "E", SMLSIZE)
			lcd.drawText(X_CNTR_1 - 14, 21, "W", SMLSIZE)
			if not SMLCD then
				lcd.drawText(X_CNTR_1 - 2, 32, "S", SMLSIZE)
			end
			drawDirection(data.heading, 140, 7, X_CNTR_1, 23)
			indicatorDisplayed = true
		end
		if not data.showDir or data.headingRef >= 0 or not SMLCD then
			if not indicatorDisplayed or not SMLCD then
				drawDirection(data.heading - data.headingRef, 145, 8, SMLCD and 63 or 133, 19)
			end
		end
	end
	if data.gpsHome ~= false and data.distanceLast >= data.distRef then
		if not data.showDir or not SMLCD then
			local o1 = math.rad(data.gpsHome.lat)
			local a1 = math.rad(data.gpsHome.lon)
			local o2 = math.rad(data.gpsLatLon.lat)
			local a2 = math.rad(data.gpsLatLon.lon)
			local y = math.sin(a2 - a1) * math.cos(o2)
			local x = (math.cos(o1) * math.sin(o2)) - (math.sin(o1) * math.cos(o2) * math.cos(a2 - a1))
			local bearing = math.deg(math.atan2(y, x)) - data.headingRef
			local rad1 = math.rad(bearing)
			local x1 = math.floor(math.sin(rad1) * 10 + 0.5) + X_CNTR_2
			local y1 = 19 - math.floor(math.cos(rad1) * 10 + 0.5)
			lcd.drawLine(X_CNTR_2, 19, x1, y1, SMLCD and DOTTED or SOLID, FORCE + (SMLCD and 0 or GREY_DEFAULT))
			lcd.drawFilledRectangle(x1 - 1, y1 - 1, 3, 3, ERASE)
			lcd.drawFilledRectangle(x1 - 1, y1 - 1, 3, 3, SOLID)
		end
	end
end

-- Flight mode
lcd.drawText((SMLCD and 46 or 83) + (modes[data.modeId].f == FLASH and 1 or 0), 33, modes[data.modeId].t, (SMLCD and SMLSIZE or 0) + modes[data.modeId].f)
if data.headFree then
	lcd.drawText(RIGHT_POS - 41, 9, "HF", FLASH + SMLSIZE)
end

-- Data & gauges
drawData("Altd", 9, 1, data.altitude, data.altitudeMax, 10000, units[data.altitude_unit], 0, (not data.telemetry or data.altitude + 0.5 >= config[6].v) and FLASH or 0)
if data.altHold then lockIcon(46, 9) end
tmp = (not data.telemetry or data.cell < config[3].v or (config[23].v == 0 and data.fuel <= config[17].v)) and FLASH or 0
drawData("Dist", data.distPos, 1, data.distanceLast, data.distanceMax, 10000, units[data.distance_unit], 0, data.telemFlags)
drawData(units[data.speed_unit], data.speedPos, 1, data.speed, data.speedMax, 1000, '', 0, data.telemFlags)
drawData("Batt", data.battPos1, 2, config[1].v == 0 and data.cell or data.batt, config[1].v == 0 and data.cellMin or data.battMin, 100, "V", config[1].v == 0 and "%.2f" or "%.1f", tmp, 1)
drawData("RSSI", 57, 2, data.rssiLast, data.rssiMin, 200, "dB", 0, (not data.telemetry or data.rssi < data.rssiLow) and FLASH or 0)
if data.showCurr then
	drawData("Curr", 33, 1, data.current, data.currentMax, 100, "A", "%.1f", data.telemFlags)
	drawData(config[23].v == 0 and "Fuel" or config[23].l[config[23].v], 41, 0, data.fuel, 0, 200, config[23].v == 0 and "%" or "", 0, tmp)
	if config[23].v == 0 then
		lcd.drawGauge(46, 41, GAUGE_WIDTH, 7, math.min(data.fuel, 99), 100)
		if data.fuel == 0 then
			lcd.drawLine(47, 42, 47, 46, SOLID, ERASE)
		end
	end
end
tmp = 100 / (4.2 - config[3].v + 0.1)
lcd.drawGauge(46, data.battPos2, GAUGE_WIDTH, 56 - data.battPos2, math.min(math.max(data.cell - config[3].v + 0.1, 0) * tmp, 98), 100)
tmp = (GAUGE_WIDTH - 2) * (math.min(math.max(data.cellMin - config[3].v + 0.1, 0) * tmp, 99) / 100) + 47
lcd.drawLine(tmp, data.battPos2 + 1, tmp, 54, SOLID, ERASE)
lcd.drawGauge(46, 57, GAUGE_WIDTH, 7, math.max(math.min((data.rssiLast - data.rssiCrit) / (100 - data.rssiCrit) * 100, 98), 0), 100)
tmp = (GAUGE_WIDTH - 2) * (math.max(math.min((data.rssiMin - data.rssiCrit) / (100 - data.rssiCrit) * 100, 99), 0) / 100) + 47
lcd.drawLine(tmp, 58, tmp, 62, SOLID, ERASE)
if not SMLCD then
	local w = config[7].v % 2 == 1 and 7 or 15
	local l = config[7].v % 2 == 1 and 205 or 197
	lcd.drawRectangle(l, 9, w, 48, SOLID)
	tmp = math.max(math.min(math.ceil(data.altitude / config[6].v * 46), 46), 0)
	lcd.drawFilledRectangle(l + 1, 56 - tmp, w - 2, tmp, INVERS)
	tmp = 56 - math.max(math.min(math.ceil(data.altitudeMax / config[6].v * 46), 46), 0)
	lcd.drawLine(l + 1, tmp, l + w - 2, tmp, SOLID, GREY_DEFAULT)
	lcd.drawText(l + 1, 58, config[7].v % 2 == 1 and "A" or "Alt", SMLSIZE)
end

-- Variometer
if config[7].v % 2 == 1 and data.startup == 0 then
	local varioSpeed = math.log(1 + math.min(math.abs(0.6 * (data.vspeed_unit == 6 and data.vspeed / 3.28084 or data.vspeed)), 10)) / 2.4 * (data.vspeed < 0 and -1 or 1)
	if SMLCD and data.armed and not data.showDir then
		lcd.drawLine(X_CNTR_2 + 17, 21, X_CNTR_2 + 19, 21, SOLID, FORCE)
		lcd.drawLine(X_CNTR_2 + 18, 21, X_CNTR_2 + 18, 21 - (varioSpeed * 12 - 0.5), SOLID, FORCE)
	elseif not SMLCD then
		lcd.drawRectangle(197, 9, 7, 48, SOLID)
		lcd.drawText(198, 58, "V", SMLSIZE)
		if data.armed then
			tmp = 33 - math.floor(varioSpeed * 23 - 0.5)
			if tmp > 33 then
				lcd.drawFilledRectangle(198, 33, 5, tmp - 33, INVERS)
			else
				lcd.drawFilledRectangle(198, tmp - 1, 5, 33 - tmp + 2, INVERS)
			end
		end
	end
end

return 0