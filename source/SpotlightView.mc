using Toybox.WatchUi;
using Toybox.Graphics as Gfx;
using Toybox.Lang;
using Toybox.System as Sys;

class SpotlightView extends WatchUi.WatchFace {

    var background_color = Gfx.COLOR_BLACK;
    var width_screen, height_screen;

    var hashMarksArray = new [72];

    function initialize() {
        WatchFace.initialize();
    }

    // Load your resources here
    function onLayout(dc) {
    
        //get screen dimensions
        width_screen = dc.getWidth();
        height_screen = dc.getHeight();
         

        //get hash marks position. 12 hours, 6 ticks per hour.
        /*
        for(var i = 0; i < 72; i+=1)
        {
            hashMarksArray[i] = new [2];
            //if(i != 0 && i != 15 && i != 30 && i != 45)
            //{
                //hashMarksArray[i][0] = (i / 72.0) * Math.PI * 2;
                hashMarksArray[i][0] = (i / 120.0) * Math.PI*2;
                //if(i % 5 == 0)
                //{
                    //hashMarksArray[i][1] = -200;
                    hashMarksArray[i][1] = -200;
                    //drawHand(dc, hashMarksArray[i][0], 110, 2, hashMarksArray[i][1], false);
                //}
                //else
                //{
                //    hashMarksArray[i][1] = -200;
                    //drawHand(dc, hashMarksArray[i][0], 110, 2, hashMarksArray[i][1], false);
                //}
            //}
        }    
    */
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
    	
        // Clear the screen
        dc.setColor(background_color, Gfx.COLOR_WHITE);
        dc.fillRectangle(0,0, width_screen, height_screen);

        // Draw the hash marks
        //dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
        drawHashMarks(dc, 6, 0);
        
        drawSingleHand(dc, 6, 0); //, clockTime.hour, clockTime.min);
        
        //View.onUpdate(dc);
    }
    
    function drawHashMarks(dc, clock_hour, clock_min) {
        var center = [250,250];
        var radius = 300;
        
//        var centerX = 0;
//        var centerY = 0;
    
    	var vLong = radius - 20;
    	var vMiddle = radius - 10;
    	var vShort = radius - 5;
    	
    	var aDel = Math.PI / 60.0;
    	
        var hour;
        hour = ( ( ( clock_hour % 12 ) * 60 ) + clock_min );
        hour = hour / (12 * 60.0);
        hour = hour * Math.PI * 2;

    	var vAngle = hour;
        
        var myCenter = getCenter(hour, 200, 2, 200);
    	
        var centerX = myCenter[0];
        var centerY = myCenter[1];
        
        dc.drawText(width_screen/2, height_screen/6, Gfx.FONT_SMALL, centerX.format("%.0f") + "x" + centerY.format("%.0f") + ":" + vAngle, Gfx.TEXT_JUSTIFY_CENTER);
    	
    	dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
    	for (var i = 0; i < 60; ++i) {
	    	vAngle = aDel * i;
    		var vSin = Math.sin(vAngle);
    		var vCos = Math.cos(vAngle);
    		if (i % 12 == 0) { // 30 mins
				dc.setPenWidth(2);
				// x-buiten, y-buiten, x-binnen, y-binnen
				dc.drawLine(centerX + radius * vSin, centerY + radius * vCos,
					centerX + vMiddle * vSin, centerY + vMiddle * vCos);
    		}
    		else if (i % 6 == 0) { // Whole hours
				dc.setPenWidth(3);
				// x-buiten, y-buiten, x-binen, y-binnen
				dc.drawLine(centerX + radius * vSin, centerY + radius * vCos,
					centerX + vLong * vSin, centerY + vLong * vCos);
    		}
    		else if (i %2 == 0) {
				dc.setPenWidth(1);
				dc.drawLine(centerX + radius * vSin, centerY + radius * vCos,
					centerX + vShort * vSin, centerY + vShort * vCos);
    		}
    	}
    }
    /*
	//! Draw the hash mark symbols on the watch
    //! @param dc Device context
    function drawHashMarks(dc, clock_hour, clock_min)
    {
    	var totalmins;
    	var pct;
    	var mult = 2;
    	var overheadline = -200;
    	var minutesPerDial = 150.0;
    	var angle;
    	
    	totalmins = (( clock_hour % 12 ) * 60 ) + clock_min;
    	mult=2;
    	overheadline=-200;
    	
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
		
        //for(var i = 0; i < 60; i += 1)
        for(var i = totalmins-70; i < totalmins+70; i += 1)
        {
            if(i % 12 == 0) // 30 mins
            {
            	pct = i / minutesPerDial;
	        	angle = pct * Math.PI * mult;
                drawMark(dc, angle, 180, 2, overheadline, clock_hour, clock_min);
            }
            else if(i % 6 == 0) // Whole hours
            {
            	pct = i / minutesPerDial;
	        	angle = pct * Math.PI * mult;
                drawMark(dc, angle, 140, 2, overheadline, clock_hour, clock_min);
            }
            else if (i %2 == 0) 
            {	// 10 mins
            	pct = i / minutesPerDial;
	        	angle = pct * Math.PI * mult;
                drawMark(dc, angle, 190, 2, overheadline, clock_hour, clock_min);
            }
        }
    } */
    
    function drawMark(dc, angle, length, width, overheadLine, clock_hour, clock_min)
    {
    
        var hour;
        var distanceFromCenter = 200; 
	    var zoomfactor = 1.5;

        // Convert hours to minutes, add the minutes and
        // compute the angle.
        hour = ( ( ( clock_hour % 12 ) * 60 ) + clock_min );
        
        //hour = 9*60;
        if (hour < 540) {
        	hour = hour + 180;
        }
        else 
        {
        	hour = 540 - hour;
        }	
        hour = hour / (12 * 60.0);
        hour = hour * Math.PI * 2; 
    
        // Map out the coordinates of the watch hand
        
        var coords = [ 
            [-(width/2), 0 + overheadLine],
            [-(width/2), -length],
            [width/2, -length],
            [width/2, 0 + overheadLine]
        ];
        
        var result = new [4];
        //var centerX = width_screen / 2;
        //var centerY = height_screen / 2;
        var cos = Math.cos(angle);
        var sin = Math.sin(angle);
        
		var hourCos = Math.cos(hour);
		var hourSin = Math.sin(hour);
		
        var centerX = (width_screen / 2) + distanceFromCenter * hourCos;
        var centerY = (height_screen / 2) + distanceFromCenter * hourSin;
        
        //centerX = 0;
        //centerY = 0;
        
        //dc.drawText((width_screen/2), 100, Gfx.FONT_MEDIUM, hour.format("%.1f") + ":" + centerX.format("%.0f") + "x" + centerY.format("%.0f"),Gfx.TEXT_JUSTIFY_CENTER);
        
        // 0,0 is linksboven
   		//centerX = 0;
        //centerY = 0;
        		

        // Transform the coordinates
        for (var i = 0; i < 4; i += 1)
        {
            var x = (coords[i][0] * cos) - (coords[i][1] * sin);
            var y = (coords[i][0] * sin) + (coords[i][1] * cos);
            
            result[i] = [centerX + x, centerY + y];
            //result[i] = [ diffX + x, diffY + y];
        }

        // Draw the polygon
        dc.fillPolygon(result);
    }
    
    function getCenter(angle, length, width, overheadLine)
    {
        var coords = [ 
            [-(width/2), 0 + overheadLine],
            [-(width/2), -length],
            [width/2, -length],
            [width/2, 0 + overheadLine]
        ];
        var result = new [2];
        var centerX = width_screen / 2;
        var centerY = height_screen / 2;
        var cos = Math.cos(angle);
        var sin = Math.sin(angle);

        // Transform the coordinates
        for (var i = 0; i < 1; i += 1)
        {
            var x = (coords[i][0] * cos) - (coords[i][1] * sin);
            var y = (coords[i][0] * sin) + (coords[i][1] * cos);
            result = [ centerX + x, centerY + y];
        }
        return result;
    }        
    
    function drawHand(dc, angle, length, width, overheadLine, drawCircleOnTop)
    {
        // Map out the coordinates of the watch hand
        var coords = [ 
            [-(width/2), 0 + overheadLine],
            [-(width/2), -length],
            [width/2, -length],
            [width/2, 0 + overheadLine]
        ];
        var result = new [4];
        var centerX = width_screen / 2;
        var centerY = height_screen / 2;
        var cos = Math.cos(angle);
        var sin = Math.sin(angle);

        // Transform the coordinates
        for (var i = 0; i < 4; i += 1)
        {
            var x = (coords[i][0] * cos) - (coords[i][1] * sin);
            var y = (coords[i][0] * sin) + (coords[i][1] * cos);
            result[i] = [ centerX + x, centerY + y];
        }

        // Draw the polygon
        dc.fillPolygon(result);
    }    


	function drawSingleHand(dc, clock_hour, clock_min)
    {
        var hour, min, sec;

        // Draw the hour. Convert it to minutes and
        // compute the angle.
        hour = ( ( ( clock_hour % 12 ) * 60 ) + clock_min );
        hour = hour / (12 * 60.0);
        hour = hour * Math.PI * 2;
        dc.setColor(Gfx.COLOR_DK_RED, Gfx.COLOR_TRANSPARENT);
        
        
        // dc, angle, length, width, overheadLine, drawCircleOnTop
        drawHand(dc, hour, height_screen, 4, height_screen, false);

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
