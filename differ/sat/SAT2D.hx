package differ.sat;

import differ.math.*;
import differ.shapes.*;
import differ.data.*;
import differ.math.Util.*;

/** Implementation details for the 2D SAT collision queries.
    Used by the various shapes, and Collision API, mostly internally.  */
class SAT2D {

        /** Internal api - test a circle against a polygon */
    public static function testCircleVsPolygon( circle:Circle, polygon:Polygon, ?into:ShapeCollision, flip:Bool=false ) : ShapeCollision {

        into = into == null ? new ShapeCollision() : into.reset();

        var verts = polygon.transformedVertices;

        var circleX = circle.x;
        var circleY = circle.y;

        var testDistance : Float = 0x3FFFFFFF;
        var distance = 0.0, closestX = 0.0, closestY = 0.0;
        var count :Int = verts.length;
        var i :Int = 0;
        while(i < count) {

            distance = vec_lengthsq(circleX - verts[i], circleY - verts[i+1]);

            if(distance < testDistance) {
                testDistance = distance;
                closestX = verts[i];
                closestY = verts[i+1];
            }

            i += 2;
        } //for

        var normalAxisX = closestX - circleX;
        var normalAxisY = closestY - circleY;
        var normAxisLen = vec_length(normalAxisX, normalAxisY);
            normalAxisX = vec_normalize(normAxisLen, normalAxisX);
            normalAxisY = vec_normalize(normAxisLen, normalAxisY);

            //project all its points, 0 outside the loop
        var test = 0.0;
        var min1 = vec_dot(normalAxisX, normalAxisY, verts[0], verts[1]);
        var max1 = min1;

        var j :Int = 2;
        while(j < count) {
            test = vec_dot(normalAxisX, normalAxisY, verts[j], verts[j+1]);
            if(test < min1) min1 = test;
            if(test > max1) max1 = test;
            j += 2;
        } //each vert

            // project the circle
        var max2 = circle.transformedRadius;
        var min2 = -circle.transformedRadius;
        var offset = vec_dot(normalAxisX, normalAxisY, -circleX, -circleY);
            
        min1 += offset;
        max1 += offset;

        var test1 = min1 - max2;
        var test2 = min2 - max1;

            //if either test is greater than 0, there is a gap, we can give up now.
        if(test1 > 0 || test2 > 0) return null;

            // circle distance check
        var distMin = -(max2 - min1);
        if(flip) distMin *= -1;

        into.overlap = distMin;
        into.unitVectorX = normalAxisX;
        into.unitVectorY = normalAxisY;
        var closest = Math.abs(distMin);

            // find the normal axis for each point and project
        i = 0;
        while(i < count) {

            normalAxisX = findNormalAxisX(verts, i); // TODO: Come back to this.
            normalAxisY = findNormalAxisY(verts, i);
            var aLen = vec_length(normalAxisX, normalAxisY);
            normalAxisX = vec_normalize(aLen, normalAxisX);
            normalAxisY = vec_normalize(aLen, normalAxisY);

                // project the polygon(again? yes, circles vs. polygon require more testing...)
            min1 = vec_dot(normalAxisX, normalAxisY, verts[0], verts[1]);
            max1 = min1; //set max and min

            //project all the other points(see, cirlces v. polygons use lots of this...)
            j = 2;
            while(j < count) {
                test = vec_dot(normalAxisX, normalAxisY, verts[j], verts[j+1]);
                if(test < min1) min1 = test;
                if(test > max1) max1 = test;
                j += 2;
            }

            // project the circle(again)
            max2 = circle.transformedRadius; //max is radius
            min2 = -circle.transformedRadius; //min is negative radius

            //offset points
            offset = vec_dot(normalAxisX, normalAxisY, -circleX, -circleY);
            min1 += offset;
            max1 += offset;

            // do the test, again
            test1 = min1 - max2;
            test2 = min2 - max1;

                //failed.. quit now
            if(test1 > 0 || test2 > 0) {
                return null;
            }

            distMin = -(max2 - min1);
            if(flip) distMin *= -1;

            if(Math.abs(distMin) < closest) {
                into.unitVectorX = normalAxisX;
                into.unitVectorY = normalAxisY;
                into.overlap = distMin;
                closest = Math.abs(distMin);
            }

            i += 2;
        } //for

        //if you made it here, there is a collision!!!!!

        into.shape1 = if(flip) polygon else circle;
        into.shape2 = if(flip) circle else polygon;
        into.separationX = into.unitVectorX * into.overlap;
        into.separationY = into.unitVectorY * into.overlap;

        if(!flip) {
            into.unitVectorX = -into.unitVectorX;
            into.unitVectorY = -into.unitVectorY;
        }

        return into;

    } //testCircleVsPolygon

        /** Internal api - test a circle against a circle */
    public static function testCircleVsCircle( circleA:Circle, circleB:Circle, ?into:ShapeCollision, flip:Bool = false ) : ShapeCollision {
        //

        var circle1 = flip ? circleB : circleA;
        var circle2 = flip ? circleA : circleB;

            //add both radii together to get the colliding distance
        var totalRadius = circle1.transformedRadius + circle2.transformedRadius;
            //find the distance between the two circles using Pythagorean theorem. No square roots for optimization
        var distancesq = vec_lengthsq(circle1.x - circle2.x, circle1.y - circle2.y);

            //if your distance is less than the totalRadius square(because distance is squared)
        if(distancesq < totalRadius * totalRadius) {

            into = (into == null) ? new ShapeCollision() : into.reset();
                //find the difference. Square roots are needed here.
            var difference = totalRadius - Math.sqrt(distancesq);

                into.shape1 = circle1;
                into.shape2 = circle2;

                var unitVecX = circle1.x - circle2.x;
                var unitVecY = circle1.y - circle2.y;
                var unitVecLen = vec_length(unitVecX, unitVecY);

                unitVecX = vec_normalize(unitVecLen, unitVecX);
                unitVecY = vec_normalize(unitVecLen, unitVecY);

                into.unitVectorX = unitVecX;
                into.unitVectorY = unitVecY;

                    //find the movement needed to separate the circles
                into.separationX = into.unitVectorX * difference;
                into.separationY = into.unitVectorY * difference;

                    //the magnitude of the overlap
                into.overlap = vec_length(into.separationX, into.separationY);

            return into;

        } //if distancesq < r^2

        return null;

    } //testCircleVsCircle

        /** Internal api - test a polygon against another polygon */
    static var tmp1:ShapeCollision = new ShapeCollision();
    static var tmp2:ShapeCollision = new ShapeCollision();

    public static function testPolygonVsPolygon( polygon1:Polygon, polygon2:Polygon, ?into:ShapeCollision, flip:Bool=false ) : ShapeCollision {

        into = (into == null) ? new ShapeCollision() : into.reset();
        
        if(checkPolygons(polygon1, polygon2, tmp1, flip) == null) {
            return null;
        }

        if(checkPolygons(polygon2, polygon1, tmp2, !flip) == null) {
            return null;
        }

        var result = null, other = null;
        if(Math.abs(tmp1.overlap) < Math.abs(tmp2.overlap)) {
            result = tmp1;
            other = tmp2;
        } else {
            result = tmp2;
            other = tmp1;
        }

        result.otherOverlap = other.overlap;
        result.otherSeparationX = other.separationX;
        result.otherSeparationY = other.separationY;
        result.otherUnitVectorX = other.unitVectorX;
        result.otherUnitVectorY = other.unitVectorY;

        into.copy_from(result);
        result = other = null;

        return into;

    } //testPolygonVsPolygon

        /** Internal api - test a ray against a circle */
    public static function testRayVsCircle( ray:Ray, circle:Circle, ?into:RayCollision ) : RayCollision {

        var deltaX = ray.end.x - ray.start.x;
        var deltaY = ray.end.y - ray.start.y;
        var ray2circleX = ray.start.x - circle.position.x;
        var ray2circleY = ray.start.y - circle.position.y;

        var a = vec_lengthsq(deltaX, deltaY);
        var b = 2 * vec_dot(deltaX, deltaY, ray2circleX, ray2circleY);
        var c = vec_dot(ray2circleX, ray2circleY, ray2circleX, ray2circleY) - (circle.radius * circle.radius);
        var d = b * b - 4 * a * c;

        if (d >= 0) {

            d = Math.sqrt(d);

            var t1 = (-b - d) / (2 * a);
            var t2 = (-b + d) / (2 * a);

            if (ray.infinite || (t1 <= 1.0 && t1 >= 0.0)) {
                
                into = (into == null) ? new RayCollision() : into.reset();
                    
                    into.shape = circle;
                    into.ray = ray;
                    into.start = t1;
                    into.end = t2;

                return into;

            } //

        } //d >= 0

        return null;

    } //testRayVsCircle

        /** Internal api - test a ray against a polygon */
    public static function testRayVsPolygon( ray:Ray, polygon:Polygon, ?into:RayCollision ) : RayCollision {

        var min_u = Math.POSITIVE_INFINITY;
        var max_u = 0.0;

        var startX = ray.start.x;
        var startY = ray.start.y;
        var deltaX = ray.end.x - startX;
        var deltaY = ray.end.y - startY;

        var verts = polygon.transformedVertices;
        var v1x = verts[verts.length - 2];
        var v1y = verts[verts.length - 1];
        var v2x = verts[0];
        var v2y = verts[1];

        var ud = (v2y-v1y) * deltaX - (v2x-v1x) * deltaY;
        var ua = rayU(ud, startX, startY, v1x, v1y, v2x - v1x, v2y - v1y);
        var ub = rayU(ud, startX, startY, v1x, v1y, deltaX, deltaY);

        if (ud != 0.0 && ub >= 0.0 && ub <= 1.0) {
            if (ua < min_u) min_u = ua;
            if (ua > max_u) max_u = ua;
        }

        var i :Int = 2;
        var count = verts.length;
        while (i < count) {

            v1x = verts[i - 2];
            v1y = verts[i - 1];
            v2x = verts[i];
            v2y = verts[i + 1];

            ud = (v2y-v1y) * deltaX - (v2x-v1x) * deltaY;
            ua = rayU(ud, startX, startY, v1x, v1y, v2x - v1x, v2y - v1y);
            ub = rayU(ud, startX, startY, v1x, v1y, deltaX, deltaY);

            if (ud != 0.0 && ub >= 0.0 && ub <= 1.0) {
                if (ua < min_u) min_u = ua;
                if (ua > max_u) max_u = ua;
            }
            i += 2;
        } //each vert

        if(ray.infinite || (min_u <= 1.0 && min_u >= 0.0) ) {
            into = (into == null) ? new RayCollision() : into.reset();
                into.shape = polygon;
                into.ray = ray;
                into.start = min_u; 
                into.end = max_u;
            return into;
        }

        return null;

    } //testRayVsPolygon

        /** Internal api - test a ray against another ray */
    public static function testRayVsRay( ray1:Ray, ray2:Ray, ?into:RayIntersection ) : RayIntersection {

        var delta1X = ray1.end.x - ray1.start.x;
        var delta1Y = ray1.end.y - ray1.start.y;
        var delta2X = ray2.end.x - ray2.start.x;
        var delta2Y = ray2.end.y - ray2.start.y;
        var diffX = ray1.start.x - ray2.start.x;
        var diffY = ray1.start.y - ray2.start.y;
        var ud = delta2Y * delta1X - delta2X * delta1Y;

        if(ud == 0.0) return null;

        var u1 = (delta2X * diffY - delta2Y * diffX) / ud;
        var u2 = (delta1X * diffY - delta1Y * diffX) / ud;

        if ((ray1.infinite || (u1 > 0.0 && u1 <= 1.0)) && (ray2.infinite || (u2 > 0.0 && u2 <= 1.0))) {
            into = (into == null) ? new RayIntersection() : into.reset();
                into.ray1 = ray1;
                into.ray2 = ray2;
                into.u1 = u1;
                into.u2 = u2;
            return into;
        }

        return null;

    } //testRayVsRay

//Internal implementation detail helpers

        /** Internal api - implementation details for testPolygonVsPolygon */
    static function checkPolygons( polygon1:Polygon, polygon2:Polygon, into:ShapeCollision, flip:Bool=false ) : ShapeCollision {

        into.reset();

        var offset = 0.0, test1 = 0.0, test2 = 0.0, testNum = 0.0;
        var min1 = 0.0, max1 = 0.0, min2 = 0.0, max2 = 0.0;
        var closest : Float = 0x3FFFFFFF;

        var axisX = 0.0;
        var axisY = 0.0;
        var verts1 = polygon1.transformedVertices;
        var verts2 = polygon2.transformedVertices;

            // loop to begin projection
        var count :Int = verts1.length;
        var i :Int = 0;
        while (i < count) {

            axisX = findNormalAxisX(verts1, i);
            axisY = findNormalAxisY(verts1, i);
            var aLen = vec_length(axisX, axisY);
            axisX = vec_normalize(aLen, axisX);
            axisY = vec_normalize(aLen, axisY);

                // project polygon1
            min1 = vec_dot(axisX, axisY, verts1[0], verts1[1]);
            max1 = min1;

            var j :Int = 2;
            while(j < count) {
                testNum = vec_dot(axisX, axisY, verts1[j], verts1[j+1]);
                if(testNum < min1) min1 = testNum;
                if(testNum > max1) max1 = testNum;
                j += 2;
            }

                // project polygon2
            min2 = vec_dot(axisX, axisY, verts2[0], verts2[1]);
            max2 = min2;

            var count2 = verts2.length;
            j = 2;
            while(j < count2) {
                testNum = vec_dot(axisX, axisY, verts2[j], verts2[j+1]);
                if(testNum < min2) min2 = testNum;
                if(testNum > max2) max2 = testNum;
                j += 2;
            }

            test1 = min1 - max2;
            test2 = min2 - max1;

            if(test1 > 0 || test2 > 0) return null;

            var distMin = -(max2 - min1);
            if(flip) distMin *= -1;

            if(Math.abs(distMin) < closest) {
                into.unitVectorX = axisX;
                into.unitVectorY = axisY;
                into.overlap = distMin;
                closest = Math.abs(distMin);
            }
            i += 2;
        }

        into.shape1 = if(flip) polygon2 else polygon1;
        into.shape2 = if(flip) polygon1 else polygon2;
        into.separationX = -into.unitVectorX * into.overlap;
        into.separationY = -into.unitVectorY * into.overlap;

        if(flip) {
            into.unitVectorX = -into.unitVectorX;
            into.unitVectorY = -into.unitVectorY;
        }

        return into;

    } //checkPolygons


//Internal helpers

        /** Internal helper for ray overlaps */
    static inline function rayU(udelta:Float, aX:Float, aY:Float, bX:Float, bY:Float, dX:Float, dY:Float) : Float {
        return (dX * (aY - bY) - dY * (aX - bX)) / udelta;
    } //rayU

    static inline function findNormalAxisX(verts:haxe.ds.Vector<Float>, index:Int) : Float {
        var v2 = (index >= verts.length - 3) ? verts[1] : verts[index + 3];
        return -(v2 - verts[index+1]);
    }

    static inline function findNormalAxisY(verts:haxe.ds.Vector<Float>, index:Int) : Float {
        var v2 = (index >= verts.length - 3) ? verts[0] : verts[index + 2];
        return (v2 - verts[index]);
    }

} //SAT2D
