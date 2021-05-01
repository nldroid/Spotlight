using Toybox.WatchUi;
using Toybox.Graphics as Gfx;
using Toybox.Lang;
using Toybox.System as Sys;
using Toybox.Application.Properties;

class SpotlightView extends WatchUi.WatchFace {

    var background_color as Number = Gfx.COLOR_BLACK;
    var hash_mark_color = Gfx.COLOR_WHITE;
    var hour_line_color = Gfx.COLOR_RED;
    var hash_mark_low_power_color = Gfx.COLOR_DK_GRAY;
    var hour_line_low_power_color = Gfx.COLOR_DK_RED;
    // Starting with a clock exactly the size of the face, how many
    // times to zoom in.
    var zoom_factor as Float = 2.1f;
    // How far from the center of the clock the middle of the face should be
    // 0 means don't move, 1 means the edge of the clock will be in the middle
    // of the face
    var focal_point as Float = 0.8f;
    // How far from the center of the clock the number should be printed
    var text_position as Float = 0.8f;
    var text_visible as Boolean = true;
    var text_visible_low_power as Boolean = false;
    var text_font = Gfx.FONT_SMALL;
    var text_color as Number = Gfx.COLOR_WHITE;
    var text_low_power_color as Number = Gfx.COLOR_DK_GRAY;
    var roman_numerals as Boolean = false;
    // Hash mark sizes:
    // l = hour, m = 30 min, s = 10 min
    // l = length, w = width
    var mark_ll as Float = 0.1f;
    var mark_lw as Number = 3;
    var mark_ml as Float = 0.05f;
    var mark_mw as Number = 2;
    var mark_sl as Float = 0.025f;
    var mark_sw as Number = 1;

    // Screen refers to the actual display, Clock refers to the virtual clock
    // that we're zooming in on.
    var screen_width, screen_height;
    var screen_radius;
    var screen_center_x, screen_center_y;
    var clock_radius;

    // Whether or not we're in low-power mode
    var low_power as Boolean = false;
    // Whether or not we're hidden. No need to draw if we are.
    var face_hidden as Boolean = false;

    // Instead of an Array of Objects, separate Arrays, because older watches
    // can't handle lots of Objects
    const NUM_HASH_MARKS = 72;
    var hash_marks_angle as Array<Float> = new Float[NUM_HASH_MARKS]; // Angle in rad
    var hash_marks_width as Array<Number> = new Float[NUM_HASH_MARKS]; // Width of mark in pixels
    var hash_marks_clock_xo as Array<Float> = new Float[NUM_HASH_MARKS]; // Outside X coordinate of mark
    // Clock coordinates in -1.0 to +1.0 range
    var hash_marks_clock_yo as Array<Float> = new Float[NUM_HASH_MARKS]; // Outside Y coordinate of mark
    var hash_marks_clock_xi as Array<Float> = new Float[NUM_HASH_MARKS]; // Inside X     "
    var hash_marks_clock_yi as Array<Float> = new Float[NUM_HASH_MARKS]; // Inside Y     "
    var hash_marks_label as Array<String> = new [NUM_HASH_MARKS]; // Hour label

    function initialize() {
        WatchFace.initialize();
    }

    // Since toNumberWithBase() doesn't seem to throw any exception
    // on format errors, and even with `as Number` a `null` can happily
    // be assigned, use a convenience function for reading colors from
    // settings. Also catch exceptions, because they apparently happen
    // in some cases.
    function getColor(key, default_color as Number) as Number {
        try {
        	var color = Properties.getValue(key);
        	// Only string instances have the toNumberWithBase function
            if (color != null && color instanceof String) {
            	// We expect the string to be exact 6 long (FFFFFF)
            	if (color.length() == 6) {
                	return color.toNumberWithBase(16);
            	} else {
            		Sys.println("Property \"" + key + "\" in function getColor had length: " + color.length());
            	}   	
            }
        } catch (e) {
        	Sys.println("Exception while reading property \"" + key + "\":");
        	e.printStackTrace();
        }
        return default_color;
    }

    // Convenience functions for floats, numbers and booleans, for
    // exceptions that seem to happen on some devices. 
    function getFloat(key, default_value as Float) as Float {
        try {
            var value = Properties.getValue(key);
            if (value != null) {
	            if (value instanceof Float) {
	                return value;
	            } else if (value instanceof String) {
	                Sys.println("Property \"" + key + "\" in function getFloat was a string: " + value);
	                return value.toFloat();
	            }	
	        }    
        } catch (e) {
            Sys.println("Exception while reading property \"" + key + "\":");
            e.printStackTrace();
        }
        return default_value;
    }
    
    function getNumber(key, default_value as Number) as Number {
        try {
            var value = Properties.getValue(key);
            if (value != null) {
            	if (value instanceof Number) {
                	return value;
                } else if (value instanceof String) {
	                Sys.println("Property \"" + key + "\" in function getNumber was a string: " + value);
	                return value.toNumber();
	            }	
                	
            }
        } catch (e) {
            Sys.println("Exception while reading property \"" + key + "\":");
            e.printStackTrace();
        }
        return default_value;
    }
    
    function getBoolean(key, default_value as Boolean) as Boolean {
        try {
            var value as Boolean or Null = Properties.getValue(key);
            if (value != null) {
            	if (value instanceof Boolean) {
                	return value;
                } else if (value instanceof String) {
	                Sys.println("Property \"" + key + "\" in function getBoolean was a string: " + value);
	                if (value.toLower() == "true") {
	                    return true;
	                } else if (value.toLower() == "false") {
	                    return false;
	                } else {
	                    return default_value;
	                }
				}                	
            }
        } catch (e) {
            Sys.println("Exception while reading property \"" + key + "\":");
            e.printStackTrace();
        }
        return default_value;
    }

    // Here we check all the settings (if possible) and do all the
    // pre-calculations we can.
    // According to https://take4-blue.com/en/program/garmin/creating-a-garmin-watch-face-performance-2/
    // this should actually be slower, but it seems faster. Possibly Garmin
    // fixed the SDK some.
    function setupData() {
        if (Toybox.Application has :Properties) {
            zoom_factor = getFloat("zoomFactor", zoom_factor);
            focal_point = getFloat("focalPoint", focal_point);
            text_position = getFloat("textPosition", text_position);
            text_visible = getBoolean("textVisible", text_visible);
            text_visible_low_power = getBoolean("textVisibleLowPower", text_visible_low_power);
            text_font = getNumber("font", text_font);
            text_color = getColor("fontColor", text_color);
            text_low_power_color = getColor("fontLowPowerColor", text_color);
            switch (getNumber("numerals", roman_numerals ? 1 : 0)) {
                case 0:
                    roman_numerals = false;
                    break;
                case 1:
                    roman_numerals = true;
                    break;
            }
            background_color = getColor("backgroundColor", background_color);
            hash_mark_color = getColor("hashMarkColor", hash_mark_color);
            hour_line_color = getColor("hourLineColor", hour_line_color);
            hash_mark_low_power_color = getColor("hashMarkLowPowerColor", hash_mark_low_power_color);
            hour_line_low_power_color = getColor("hourLineLowPowerColor", hour_line_low_power_color);
            mark_ll = getFloat("markLargeLength", mark_ll);
            mark_lw = getNumber("markLargeWidth", mark_lw);
            mark_ml = getFloat("markMediumLength", mark_ml);
            mark_mw = getNumber("markMediumWidth", mark_mw);
            mark_sl = getFloat("markSmallLength", mark_sl);
            mark_sw = getNumber("markSmallWidth", mark_sw);
        }

        clock_radius = screen_radius * zoom_factor;

        // pre-calculate as much as we can using static parameters
        for(var i = 0; i < NUM_HASH_MARKS; i += 1) {
            var angle as Float = ((i as Float) / 72.0f) * 2 * Math.PI;
            var length as Float;
            if (i % 6 == 0) {
                // Hour hashes are the longest
                length = mark_ll;
                hash_marks_width[i] = mark_lw;
                var hour as Number = i / 6;
                if (hour == 0) {
                    hour = 12;
                }
                if (roman_numerals) {
                    switch (hour) {
                        case 1:
                            hash_marks_label[i] = "I";
                            break;
                        case 2:
                            hash_marks_label[i] = "II";
                            break;
                        case 3:
                            hash_marks_label[i] = "III";
                            break;
                        case 4:
                            hash_marks_label[i] = "IV";
                            break;
                        case 5:
                            hash_marks_label[i] = "V";
                            break;
                        case 6:
                            hash_marks_label[i] = "VI";
                            break;
                        case 7:
                            hash_marks_label[i] = "VII";
                            break;
                        case 8:
                            hash_marks_label[i] = "VIII";
                            break;
                        case 9:
                            hash_marks_label[i] = "IX";
                            break;
                        case 10:
                            hash_marks_label[i] = "X";
                            break;
                        case 11:
                            hash_marks_label[i] = "XI";
                            break;
                        case 12:
                            hash_marks_label[i] = "XII";
                            break;
                    }
                } else {
                    hash_marks_label[i] = hour.format("%d");
                }
            } else {
                if (i % 3 == 0) {
                    // Half hour ticks
                    length = mark_ml;
                    hash_marks_width[i] = mark_mw;
                } else {
                    // 10 minute ticks
                    length = mark_sl;
                    hash_marks_width[i] = mark_sw;
                }
                hash_marks_label[i] = "";
            }
            hash_marks_clock_xo[i] = Math.sin(angle);
            hash_marks_clock_yo[i] = -Math.cos(angle);
            hash_marks_clock_xi[i] = hash_marks_clock_xo[i] * (1 - length);
            hash_marks_clock_yi[i] = hash_marks_clock_yo[i] * (1 - length);
        }
    }

    // Load your resources here
    function onLayout(dc) {
        // get screen dimensions
        screen_width = dc.getWidth();
        screen_height = dc.getHeight();
        // if the screen isn't round/square, we'll use a diameter
        // that's the average of the two. And of course radius is
        // half that.
        screen_radius = (screen_width + screen_height) / 4.0f;
        // -1 seems to line up better in the simulator
        screen_center_x = screen_width / 2 - 1;
        screen_center_y = screen_height / 2 - 1;
        setupData();
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() {
        face_hidden = false;
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() {
        face_hidden = true;
    }

    // Update the view
    function onUpdate(dc) {
        if (face_hidden) {
            return;
        }
        var clockTime = Sys.getClockTime();
        // calculate angle for hour hand for the current time
        var time_seconds = ((((clockTime.hour % 12) * 60) + clockTime.min) * 60) + clockTime.sec;
        var time_angle = Math.PI * 2 * time_seconds / (12 * 60 * 60);

        // setAntiAlias has only been around since 3.2.0
        // this way we support older models
        if(dc has :setAntiAlias) {
            dc.setAntiAlias(true);
        }
        // Clear the screen with background color. To keep people from
        // being stupid, always use black in lower power mode.
        if (low_power) {
            dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
        } else {
            dc.setColor(background_color, background_color);
        }
        dc.clear();

        drawHashMarks(dc, time_angle);

        drawHourLine(dc, time_angle);
    }

    // Only for performance measuring. Don't need this during normal
    // operation, since while we use seconds to calculate the angle,
    // we don't need to do that in low power mode.
    function onPartialUpdate(dc) {
        //onUpdate(dc);
    }

    function drawHashMarks(dc, angle) {
        // focal_point * clock_radius * Math.sin(angle) ==
        //    the offset from center of clock to the focal point.
        // Combine them with screen center to bring focal point
        // to the center of the screen.
        // Add 0.5f to turn the implicit floor that drawLine does
        // into a round.
        // This is much much faster than using Math.round(), which
        // isn't available on older platforms. We're only dealing
        // with positive X/Y values, so this works nicely.
        var clock_center_x as Float = screen_center_x - focal_point * clock_radius * Math.sin(angle) + 0.5f;
        var clock_center_y as Float = screen_center_y + focal_point * clock_radius * Math.cos(angle) + 0.5f;
        var index_guess = (72.0f * angle / (2 * Math.PI)).toNumber();
        var dist;
        // Determine what colors and visibility to use outside of the loop
        var m_color as Number;
        var t_visible as Boolean;
        var t_color as Number;
        if (low_power) {
            m_color = hash_mark_low_power_color;
            t_visible = text_visible_low_power;
            t_color = text_low_power_color;
        } else {
            m_color = hash_mark_color;
            t_visible = text_visible;
            t_color = text_color;
        }
        for (var i = 0; i < NUM_HASH_MARKS; ++i) {
            dist = (i - index_guess).abs();
            if (dist <= 9 || dist >= 63) {
                dc.setPenWidth(hash_marks_width[i]);
                // Transparent background so people can get their numbers nice and close
                // or overlaying lines.
                dc.setColor(m_color, Gfx.COLOR_TRANSPARENT);
                // outside X, outside Y, inside X, inside Y
                var xo = clock_center_x + clock_radius * hash_marks_clock_xo[i];
                var yo = clock_center_y + clock_radius * hash_marks_clock_yo[i];
                var xi = clock_center_x + clock_radius * hash_marks_clock_xi[i];
                var yi = clock_center_y + clock_radius * hash_marks_clock_yi[i];
                dc.drawLine(xo, yo, xi, yi);
                // Digits trigger burn-in protection, so don't draw them in
                // low power mode
                if (t_visible && hash_marks_label[i] != "") {
                    // No text in low power, so no need to set a different color
                    dc.setColor(t_color, Gfx.COLOR_TRANSPARENT);
                    var text_x = clock_center_x + clock_radius * hash_marks_clock_xo[i] * text_position;
                    var text_y = clock_center_y + clock_radius * hash_marks_clock_yo[i] * text_position;
                    dc.drawText(text_x, text_y, text_font, hash_marks_label[i],
                                Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
                }
            }
        }
    }

    function drawHourLine(dc, angle) {
        var x1, y1, x2, y2 as Number;
        // 2 * radius so that we definitely overshoot, for square screens
        // Again, adding 0.5f to do implicit round instead of floor in
        // drawLine.
        if (low_power) {
            // For burn-in protection on OLED screens, don't draw the hour
            // line at the center of the screen. Instead we do two thinner
            // lines near the edges of the screen. This close to the center,
            // a width of 2 actually triggered detection at the tip.
            dc.setPenWidth(1);
            dc.setColor(hour_line_low_power_color, background_color);
            x1 = screen_center_x + 2 * screen_radius * Math.sin(angle) + 0.5f;
            y1 = screen_center_y - 2 * screen_radius * Math.cos(angle) + 0.5f;
            x2 = screen_center_x + 0.5 * screen_radius * Math.sin(angle) + 0.5f;
            y2 = screen_center_y - 0.5 * screen_radius * Math.cos(angle) + 0.5f;
            dc.drawLine(x1, y1, x2, y2);
            x1 = screen_center_x - 2 * screen_radius * Math.sin(angle) + 0.5f;
            y1 = screen_center_y + 2 * screen_radius * Math.cos(angle) + 0.5f;
            x2 = screen_center_x - 0.5 * screen_radius * Math.sin(angle) + 0.5f;
            y2 = screen_center_y + 0.5 * screen_radius * Math.cos(angle) + 0.5f;
            dc.drawLine(x1, y1, x2, y2);
        } else {
            dc.setPenWidth(2);
            dc.setColor(hour_line_color, background_color);
            x1 = screen_center_x + 2 * screen_radius * Math.sin(angle) + 0.5f;
            y1 = screen_center_y - 2 * screen_radius * Math.cos(angle) + 0.5f;
            x2 = screen_center_x - 2 * screen_radius * Math.sin(angle) + 0.5f;
            y2 = screen_center_y + 2 * screen_radius * Math.cos(angle) + 0.5f;
            dc.drawLine(x1, y1, x2, y2);
        }
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() {
        low_power = false;
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() {
        low_power = true;
    }

}
