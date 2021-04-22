using Toybox.WatchUi;
using Toybox.Graphics as Gfx;
using Toybox.Lang;
using Toybox.System as Sys;

class SpotlightView extends WatchUi.WatchFace {

    const BACKGROUND_COLOR = Gfx.COLOR_BLACK;
    const HASH_MARK_COLOR = Gfx.COLOR_WHITE;
    const HOUR_LINE_COLOR = Gfx.COLOR_RED;
    // Starting with a clock exactly the size of the face, how many
    // times to zoom in.
    const ZOOM_FACTOR as Double = 2.1f;
    // How far from the center of the clock the middle of the face should be
    // 0 means don't move, 1 means the edge of the clock will be in the middle
    // of the face
    const FOCAL_POINT as Double = 0.8f;
    // How far from the center of the clock the number should be printed
    const TEXT_POSITION as Double = 0.8f;
    const TEXT_FONT = Gfx.FONT_SMALL;

    // Screen refers to the actual display, Clock refers to the virtual clock
    // that we're zooming in on.
    var screen_width, screen_height;
    var screen_radius;
    var screen_center_x, screen_center_y;
    var clock_radius;

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

        clock_radius = screen_radius * ZOOM_FACTOR;

        // pre-calculate as much as we can using static parameters
        for(var i = 0; i < NUM_HASH_MARKS; i += 1) {
            var angle as Float = ((i as Float) / 72.0f) * 2 * Math.PI;
            var length as Float;
            if (i % 6 == 0) {
                // Hour hashes are the longest
                length = 0.10f;
                hash_marks_width[i] = 3;
                var hour as Number = i / 6;
                if (hour == 0) {
                    hour = 12;
                }
                hash_marks_label[i] = hour.format("%d");
            } else {
                if (i % 3 == 0) {
                    // Half hour ticks
                    length = 0.05f;
                    hash_marks_width[i] = 2;
                } else {
                    // 10 minute ticks
                    length = 0.025f;
                    hash_marks_width[i] = 1;
                }
                hash_marks_label[i] = "";
            }
            hash_marks_clock_xo[i] = Math.sin(angle);
            hash_marks_clock_yo[i] = -Math.cos(angle);
            hash_marks_clock_xi[i] = hash_marks_clock_xo[i] * (1 - length);
            hash_marks_clock_yi[i] = hash_marks_clock_yo[i] * (1 - length);
        }
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() {
    }

    // Update the view
    function onUpdate(dc) {
    	var clockTime = Sys.getClockTime();
        // calculate angle for hour hand for the current time
        var time_seconds = ((((clockTime.hour % 12) * 60) + clockTime.min) * 60) + clockTime.sec;
        var time_angle = Math.PI * 2 * time_seconds / (12 * 60 * 60);

    	// setAntiAlias has only been around since 3.2.0
    	// this way we support older models
	    if(dc has :setAntiAlias) {
	        dc.setAntiAlias(true);
	    }
        // Clear the screen
        dc.setColor(BACKGROUND_COLOR, BACKGROUND_COLOR);
        dc.clear();

        drawHashMarks(dc, time_angle);

        drawHourLine(dc, time_angle);
    }

    function onPartialUpdate( dc ) {
    	onUpdate(dc);
    }

    function drawHashMarks(dc, angle) {

    	dc.setColor(HASH_MARK_COLOR, BACKGROUND_COLOR);
        // FOCAL_POINT * clock_radius * Math.sin(angle) ==
        //    the offset from center of clock to the focal point.
        // Combine them with screen center to bring focal point
        // to the center of the screen.
        var clock_center_x = screen_center_x - FOCAL_POINT * clock_radius * Math.sin(angle);
        var clock_center_y = screen_center_y + FOCAL_POINT * clock_radius * Math.cos(angle);
        var index_guess = (72.0f * angle / (2 * Math.PI)).toNumber();
        var dist;
        // For performance reasons, we do this once, instead of every loop
        if (Math has :round) {
            for (var i = 0; i < NUM_HASH_MARKS; ++i) {
            	dist = (i - index_guess).abs();
            	if (dist <= 9 || dist >= 63) {
	                dc.setPenWidth(hash_marks_width[i]);
	                // outside X, outside Y, inside X, inside Y
	                var xo = Math.round(clock_center_x + clock_radius * hash_marks_clock_xo[i]);
	                var yo = Math.round(clock_center_y + clock_radius * hash_marks_clock_yo[i]);
	                var xi = Math.round(clock_center_x + clock_radius * hash_marks_clock_xi[i]);
	                var yi = Math.round(clock_center_y + clock_radius * hash_marks_clock_yi[i]);
	                dc.drawLine(xo, yo, xi, yi);
	                if (hash_marks_label[i] != "") {
	                    var text_x = Math.round(clock_center_x + clock_radius * hash_marks_clock_xo[i] * TEXT_POSITION);
	                    var text_y = Math.round(clock_center_y + clock_radius * hash_marks_clock_yo[i] * TEXT_POSITION);
	                    dc.drawText(text_x, text_y, TEXT_FONT, hash_marks_label[i],
	                                Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
	                }
	            }
            }
        } else {
            // Should be identical to above, but without Math.round
            for (var i = 0; i < NUM_HASH_MARKS; ++i) {
            	dist = (i - index_guess).abs();
            	if (dist <= 9 || dist >= 63) {
                    dc.setPenWidth(hash_marks_width[i]);
                    // outside X, outside Y, inside X, inside Y
                    var xo = clock_center_x + clock_radius * hash_marks_clock_xo[i];
                    var yo = clock_center_y + clock_radius * hash_marks_clock_yo[i];
                    var xi = clock_center_x + clock_radius * hash_marks_clock_xi[i];
                    var yi = clock_center_y + clock_radius * hash_marks_clock_yi[i];
                    dc.drawLine(xo, yo, xi, yi);
                    if (hash_marks_label[i] != "") {
                        var text_x = clock_center_x + clock_radius * hash_marks_clock_xo[i] * TEXT_POSITION;
                        var text_y = clock_center_y + clock_radius * hash_marks_clock_yo[i] * TEXT_POSITION;
                        dc.drawText(text_x, text_y, TEXT_FONT, hash_marks_label[i],
                                    Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
                    }
                }
            }
        }
    }

    function drawHourLine(dc, angle) {
        dc.setColor(HOUR_LINE_COLOR, BACKGROUND_COLOR);
        dc.setPenWidth(2);
        var x1, y1, x2, y2 as Number;
        // 2 * radius so that we definitely overshoot, for square screens
        if (Math has :round) {
            x1 = Math.round(screen_center_x + 2 * screen_radius * Math.sin(angle));
            y1 = Math.round(screen_center_y - 2 * screen_radius * Math.cos(angle));
            x2 = Math.round(screen_center_x - 2 * screen_radius * Math.sin(angle));
            y2 = Math.round(screen_center_y + 2 * screen_radius * Math.cos(angle));
        } else {
            x1 = screen_center_x + 2 * screen_radius * Math.sin(angle);
            y1 = screen_center_y - 2 * screen_radius * Math.cos(angle);
            x2 = screen_center_x - 2 * screen_radius * Math.sin(angle);
            y2 = screen_center_y + 2 * screen_radius * Math.cos(angle);
        }
        dc.drawLine(x1, y1, x2, y2);
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() {
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() {
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() {
    }

}
