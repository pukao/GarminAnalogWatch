//
// Copyright 2016-2017 by Garmin Ltd. or its subsidiaries.
// Subject to Garmin SDK License Agreement and Wearables
// Application Developer Agreement.
//

using Toybox.Graphics;
using Toybox.Lang;
using Toybox.Math;
using Toybox.System;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.WatchUi;
using Toybox.Application;
using Toybox.ActivityMonitor;


var partialUpdatesAllowed = false;

// This implements an analog watch face
// Original design by Austen Harbour
class AnalogView extends WatchUi.WatchFace
{
    var isAwake;
    var screenCenterPoint;

    // Initialize variables for this view
    function initialize() {
        WatchFace.initialize();
    }

    // Configure the layout of the watchface for this device
    function onLayout(dc) {
        screenCenterPoint = [dc.getWidth()/2, dc.getHeight()/2];
    }

    // This function is used to generate the coordinates of the 4 corners of the polygon
    // used to draw a watch hand. The coordinates are generated with specified length,
    // tail length, and width and rotated around the center point at the provided angle.
    // 0 degrees is at the 12 o'clock position, and increases in the clockwise direction.
    function drawHandCoordinates(dc, centerPoint, angle, handLength, tailLength, width) {
        // Map out the coordinates of the watch hand
		// rotate the angle 90 degrees ( PI/2 rad) backwards
        angle -= Math.PI / 2;
        var cos = Math.cos(angle);
        var sin = Math.sin(angle);


        var x = (handLength * cos) + centerPoint[0];
        var y = (handLength * sin) + centerPoint[1];

        dc.setPenWidth(width);
        dc.drawLine(centerPoint[0], centerPoint[1], x, y);

        dc.fillCircle(x, y, width / 2);
    }

    // Draws the clock tick marks around the outside edges of the screen.
    function drawHashMarks(dc) {
        var width = dc.getWidth();
        var height = dc.getHeight();

        var sX, sY;
        var eX, eY;
        var outerRad = width / 2;
        var innerRad = outerRad - 8;

        dc.setPenWidth(1);
        for (var i = 0; i < 60 * Math.PI / 30; i += (Math.PI / 30)) {
            sY = outerRad + innerRad * Math.sin(i);
            eY = outerRad + outerRad * Math.sin(i);
            sX = outerRad + innerRad * Math.cos(i);
            eX = outerRad + outerRad * Math.cos(i);
            dc.drawLine(sX, sY, eX, eY);
        }

        innerRad -= 4;
        dc.setPenWidth(2);
        for (var i = 0; i < 12 * Math.PI / 6; i += (Math.PI / 6)) {
            sY = outerRad + innerRad * Math.sin(i);
            eY = outerRad + outerRad * Math.sin(i);
            sX = outerRad + innerRad * Math.cos(i);
            eX = outerRad + outerRad * Math.cos(i);
            dc.drawLine(sX, sY, eX, eY);
		}
    }

    // Handle the update event
    function onUpdate(dc) {
        var width;
        var height;
        var screenWidth = dc.getWidth();
        var clockTime = System.getClockTime();
        var minuteHandAngle;
        var hourHandAngle;
        var targetDc = dc;


        width = targetDc.getWidth();
        height = targetDc.getHeight();

        // Fill the entire background with Black.
        targetDc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
        targetDc.fillRectangle(0, 0, targetDc.getWidth(), targetDc.getHeight());


        // Draw the tick marks around the edges of the screen
        targetDc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_DK_GRAY);
        drawHashMarks(targetDc);

        targetDc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        var battery = System.getSystemStats().battery;
        if (battery <= 30) {
            if (battery <= 10) {
                targetDc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            }
            targetDc.drawText(width * 0.60 ,(height * 0.15), Graphics.FONT_MEDIUM, "B", Graphics.TEXT_JUSTIFY_CENTER);
        }

        targetDc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        var notifications = System.getDeviceSettings().notificationCount;
        if (notifications > 0) {
            targetDc.drawText(width * 0.40 ,(height * 0.15), Graphics.FONT_MEDIUM, "N", Graphics.TEXT_JUSTIFY_CENTER);
        }

        var info = ActivityMonitor.getInfo();
        targetDc.drawText(width * 0.25,(height * 0.42), Graphics.FONT_MEDIUM, info.steps, Graphics.TEXT_JUSTIFY_CENTER);

        targetDc.drawText(width * 0.75,(height * 0.42), Graphics.FONT_MEDIUM, info.activeMinutesDay.total, Graphics.TEXT_JUSTIFY_CENTER);

        var distance = (info.distance / 100000.0).format("%.2f");
        targetDc.drawText(width / 2,(height * 0.7), Graphics.FONT_TINY, distance, Graphics.TEXT_JUSTIFY_CENTER);

        //Use white to draw the hour and minute hands
        targetDc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        // Draw the hour hand. Convert it to minutes and compute the angle.
        hourHandAngle = (((clockTime.hour % 12) * 60) + clockTime.min);
        hourHandAngle = hourHandAngle / (12 * 60.0);
        hourHandAngle = hourHandAngle * Math.PI * 2;
        drawHandCoordinates(targetDc, screenCenterPoint, hourHandAngle, 60, 0, 4);

        // Draw the minute hand.
        minuteHandAngle = (clockTime.min / 60.0) * Math.PI * 2;
        drawHandCoordinates(targetDc, screenCenterPoint, minuteHandAngle, 100, 0, 4);

        // Draw the arbor in the center of the screen.
        targetDc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        targetDc.fillCircle(width / 2, height / 2, 7);
        targetDc.setColor(Graphics.COLOR_BLACK,Graphics.COLOR_BLACK);
        targetDc.drawCircle(width / 2, height / 2, 7);
    }

    // Draw the date string into the provided buffer at the specified location
//    function drawDateString( dc, x, y ) {
//        var info = Gregorian.info(Time.now(), Time.FORMAT_LONG);
//        var dateStr = Lang.format("$1$ $2$ $3$", [info.day_of_week, info.month, info.day]);
//
//        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
//        dc.drawText(x, y, Graphics.FONT_MEDIUM, dateStr, Graphics.TEXT_JUSTIFY_CENTER);
//    }


    // Compute a bounding box from the passed in points
    function getBoundingBox( points ) {
        var min = [9999,9999];
        var max = [0,0];

        for (var i = 0; i < points.size(); ++i) {
            if(points[i][0] < min[0]) {
                min[0] = points[i][0];
            }

            if(points[i][1] < min[1]) {
                min[1] = points[i][1];
            }

            if(points[i][0] > max[0]) {
                max[0] = points[i][0];
            }

            if(points[i][1] > max[1]) {
                max[1] = points[i][1];
            }
        }

        return [min, max];
    }


    // This method is called when the device re-enters sleep mode.
    // Set the isAwake flag to let onUpdate know it should stop rendering the second hand.
    function onEnterSleep() {
        isAwake = false;
        WatchUi.requestUpdate();
    }

    // This method is called when the device exits sleep mode.
    // Set the isAwake flag to let onUpdate know it should render the second hand.
    function onExitSleep() {
        isAwake = true;
    }
}

class AnalogDelegate extends WatchUi.WatchFaceDelegate {
    // The onPowerBudgetExceeded callback is called by the system if the
    // onPartialUpdate method exceeds the allowed power budget. If this occurs,
    // the system will stop invoking onPartialUpdate each second, so we set the
    // partialUpdatesAllowed flag here to let the rendering methods know they
    // should not be rendering a second hand.
    function onPowerBudgetExceeded(powerInfo) {
        System.println( "Average execution time: " + powerInfo.executionTimeAverage );
        System.println( "Allowed execution time: " + powerInfo.executionTimeLimit );
        partialUpdatesAllowed = false;
    }
}
