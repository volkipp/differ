package differ;

import differ.math.*;
import differ.shapes.*;
import differ.data.*;
import differ.sat.*;

class Collision {

        /** Test a single shape against another shape.
            When no collision is found between them, this function returns null.
            Returns a `ShapeCollision` if a collision is found. */
    public static inline function shapeWithShape( shape1:Shape, shape2:Shape, ?into:ShapeCollision ) : ShapeCollision {

        return shape1.test(shape2, into);

    } //test

        /** Test a single shape against multiple other shapes.
            When no collision is found, this function returns an empty array, this function will never return null.
            Returns a list of `ShapeCollision` information for each collision found. */
    public static function shapeWithShapes( shape1:Shape, shapes:Array<Shape> ) : Array<ShapeCollision> {

        var results = [];

            //:todo: pair wise
        for(other_shape in shapes) {

            var result = shapeWithShape(shape1, other_shape, null);
            if(result != null) {
                results.push(result);
            }

        } //for all shapes passed in

        return results;

    } //testShapes

        /** Test a line between two points against a list of shapes.
            When no collision is found, this function returns null.
            Returns a `RayCollision` if a collision is found. */
    public static inline function rayWithShape( ray:Ray, shape:Shape, ?into:RayCollision ) : RayCollision {

        return shape.testRay(ray, into);

    } //rayShape

        /** Test a ray between two points against a list of shapes.
            When no collision is found, this function returns an empty array, this function will never return null.
            Returns a list of `RayCollision` information for each collision found. */
    public static function rayWithShapes( ray:Ray, shapes:Array<Shape> ) : Array<RayCollision> {

        var results = [];

        for(shape in shapes) {
            var result = rayWithShape(ray, shape, null);
            if(result != null) {
                results.push(result);
            }
        }

        return results;

    } //rayShapes

        /** Test a ray against another ray.
            When no collision is found, this function returns null.
            Returns a `RayIntersection` if a collision is found. */
    public static inline function rayWithRay( ray1:Ray, ray2:Ray, ?into:RayIntersection ) : RayIntersection {

        return SAT2D.testRayVsRay(ray1, ray2, into);

    } //rayRay

        /** Test a ray against a list of other rays.
            When no collision is found, this function returns an empty array, this function will never return null.
            Returns a list of `RayIntersection` information for each collision found. */
    public static function rayWithRays( ray:Ray, rays:Array<Ray> ) : Array<RayIntersection> {

        var results = [];

        for(other in rays) {
            var result = rayWithRay(ray, other, null);
            if(result != null) {
                results.push(result);
            }
        }

        return results;

    } //rayRays

        /** Test if a given point lands inside the given polygon.
            Returns true if it does, false otherwise. */
    public static function pointInPoly( x:Float, y:Float, poly:Polygon ) : Bool {

        var sides:Int = poly.transformedVertices.length; //amount of sides the polygon has
        var verts = poly.transformedVertices;

        var i:Int = 0;
        var j:Int = sides - 2;
        // var j:Int = sides - 1;
        var oddNodes:Bool = false;

        while(i < sides) {

            if( (verts[i+1] < y && verts[j+1] >= y) ||
                (verts[j+1] < y && verts[i+1] >= y))
            {
                if( verts[i] +
                    (y - verts[i+1]) /
                    (verts[j+1] - verts[i+1]) *
                    (verts[j] - verts[i]) < x)
                {
                    oddNodes = !oddNodes;
                }

            }

            j = i;
            i += 2;
        } //for each side

        return oddNodes;

    } //pointInPoly


} //Collision
