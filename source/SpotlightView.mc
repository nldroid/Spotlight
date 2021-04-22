using Toybox.WatchUi;
using Toybox.Graphics as Gfx;
using Toybox.Lang;
using Toybox.System as Sys;
 
class SpotlightView extends WatchUi.WatchFace {

    var background_color = Gfx.COLOR_BLACK;
    var hash_color = Gfx.COLOR_WHITE;
    var hand_color = Gfx.COLOR_RED;
    // Starting with a clock exactly the size of the face, how many
    // times to zoom in.
    var zoom_factor as Lang.Double = 2.1d; 
    // How far from the center of the clock the middle of the face should be
    // 0 means don't move, 1 means the edge of the clock will be in the middle
    // of the face
    var focal_point as Lang.Double = 0.8d;

    class HashMark {
        var angle as Lang.Double; // Angle in rad
        var length as Lang.Double; // Length of mark from edge of clock, in rad
        var width as Lang.Number; // Width of mark in pixels
        // Clock coordinates in -1.0 to +1.0 range
        var clock_xo as Lang.Double; // Outside X coordinate of mark 
        var clock_yo as Lang.Double; // Outside Y coordinate of mark
        var clock_xi as Lang.Double; // Inside X     "
        var clock_yi as Lang.Double; // Inside Y     "
        function initialize(in_angle as Lang.Double, in_length as Lang.Double, in_width as Lang.Number) {
            angle = in_angle;
            clock_xo = Math.sin(in_angle);
            clock_yo = Math.cos(in_angle);
            clock_xi = clock_xo * (1d - in_length);
            clock_yi = clock_yo * (1d - in_length);
            length = in_length;
            width = in_width;
        }
        function sin() as Lang.Double {
            return Math.sin(angle);
        }
        function cos() as Lang.Double {
            return Math.cos(angle);
        }
    }

    // Screen refers to the actual display, Clock refers to the virtual clock
    // that we're zooming in on. 
    var screen_width, screen_height;
    var screen_radius;
    var screen_center_x, screen_center_y;
    var clock_radius;

    var hash_marks = new [72];

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
        screen_radius = (screen_width + screen_height) / 4.0d;
        // -1 seems to line up better in the simulator
        screen_center_x = screen_width / 2 - 1;
        screen_center_y = screen_height / 2 - 1;

        clock_radius = screen_radius * zoom_factor;

        // get hash marks position. 12 hours, 6 hashes per hour.
        for(var i = 0; i < 72; i += 1) {
            var angle as Lang.Double = ((i as Lang.Double) / 72.0d) * 2 * Math.PI;
            var length as Lang.Double;
            var width as Lang.Number;
            if (i % 6 == 0) {
                // Hour hashes are the longest
                length = 0.10d;
                width = 3;
            } else if (i % 3 == 0) {
                // Half hour ticks
                length = 0.05d;
                width = 2;
            } else {
                // 10 minute ticks
                length = 0.025d;
                width = 1;
            }
            hash_marks[i] = new HashMark(angle, length, width);
        }    
        setLayout(Rez.Layouts.WatchFace(dc));
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
        dc.setColor(background_color, background_color);
        dc.clear();

        drawHashMarks(dc, time_angle);
        
        drawHourLine(dc, time_angle);
    }

    function roundedDrawLine(dc, x1, y1, x2, y2) {
        dc.drawLine(Math.round(x1),
                    Math.round(y1),
                    Math.round(x2),
                    Math.round(y2));
    }

    function drawHashMarks(dc, angle) {
        
    	dc.setColor(hash_color, background_color);
        // focal_point * clock_radius * Math.sin(angle) ==
        //    the offset from center of clock to the focal point.
        // Combine them with screen center to bring focal point 
        // to the center of the screen.
        var clock_center_x = screen_center_x - focal_point * clock_radius * Math.sin(angle);
        var clock_center_y = screen_center_y + focal_point * clock_radius * Math.cos(angle);
    	for (var i = 0; i < hash_marks.size(); ++i) {
            var mark = hash_marks[i];
            dc.setPenWidth(mark.width);
            // outside X, outside Y, inside X, inside Y
            roundedDrawLine(dc,
                            clock_center_x + clock_radius * mark.clock_xo,
                            clock_center_y + clock_radius * mark.clock_yo,
                            clock_center_x + clock_radius * mark.clock_xi,
                            clock_center_y + clock_radius * mark.clock_yi);
    	}
    }

    function drawHourLine(dc, angle) {
        dc.setColor(hand_color, background_color);
        dc.setPenWidth(2);
        var x1 = screen_center_x + screen_radius * Math.sin(angle);
        var y1 = screen_center_y - screen_radius * Math.cos(angle);
        var x2 = screen_center_x - screen_radius * Math.sin(angle);
        var y2 = screen_center_y + screen_radius * Math.cos(angle);        
        roundedDrawLine(dc, x1, y1, x2, y2);
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
