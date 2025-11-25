-- written by groverbuger for g3d
-- september 2021
-- MIT license

local vectors = require(g3d.path .. ".vectors")
local fastSubtract = vectors.subtract
local vectorAdd = vectors.add
local vectorCrossProduct = vectors.crossProduct
local vectorDotProduct = vectors.dotProduct
local vectorNormalize = vectors.normalize
local vectorMagnitude = vectors.magnitude

----------------------------------------------------------------------------------------------------
-- collision detection functions
----------------------------------------------------------------------------------------------------
--
-- none of these functions are required for developing 3D games
-- however these collision functions are very frequently used in 3D games
--
-- be warned! a lot of this code is butt-ugly
-- using a table per vector would create a bazillion tables and lots of used memory
-- so instead all vectors are all represented using three number variables each
-- this approach ends up making the code look terrible, but collision functions need to be efficient

local collisions = {}

-- finds the closest point to the source point on the given line segment
local function closestPointOnLineSegment(
        a_x,a_y,a_z, -- point one of line segment
        b_x,b_y,b_z, -- point two of line segment
        x,y,z        -- source point
    )
    local ab_x, ab_y, ab_z = b_x - a_x, b_y - a_y, b_z - a_z
    local t = vectorDotProduct(x - a_x, y - a_y, z - a_z, ab_x, ab_y, ab_z) / (ab_x^2 + ab_y^2 + ab_z^2)
    t = math.min(1, math.max(0, t))
    return a_x + t*ab_x, a_y + t*ab_y, a_z + t*ab_z
end

-- model - ray intersection
-- based off of triangle - ray collision from excessive's CPML library
-- does a triangle - ray collision for every face in the model to find the shortest collision
--
-- sources:
--     https://github.com/excessive/cpml/blob/master/modules/intersect.lua
--     http://www.lighthouse3d.com/tutorials/maths/ray-triangle-intersection/
local tiny = 2.2204460492503131e-16 -- the smallest possible value for a double, "double epsilon"
local function triangleRay(
        tri_0_x, tri_0_y, tri_0_z,
        tri_1_x, tri_1_y, tri_1_z,
        tri_2_x, tri_2_y, tri_2_z,
        n_x, n_y, n_z,
        src_x, src_y, src_z,
        dir_x, dir_y, dir_z
    )

    -- cache these variables for efficiency
    local e11,e12,e13 = fastSubtract(tri_1_x,tri_1_y,tri_1_z, tri_0_x,tri_0_y,tri_0_z)
    local e21,e22,e23 = fastSubtract(tri_2_x,tri_2_y,tri_2_z, tri_0_x,tri_0_y,tri_0_z)
    local h1,h2,h3 = vectorCrossProduct(dir_x,dir_y,dir_z, e21,e22,e23)
    local a = vectorDotProduct(h1,h2,h3, e11,e12,e13)

    -- if a is too close to 0, ray does not intersect triangle
    if math.abs(a) <= tiny then
        return
    end

    local s1,s2,s3 = fastSubtract(src_x,src_y,src_z, tri_0_x,tri_0_y,tri_0_z)
    local u = vectorDotProduct(s1,s2,s3, h1,h2,h3) / a

    -- ray does not intersect triangle
    if u < 0 or u > 1 then
        return
    end

    local q1,q2,q3 = vectorCrossProduct(s1,s2,s3, e11,e12,e13)
    local v = vectorDotProduct(dir_x,dir_y,dir_z, q1,q2,q3) / a

    -- ray does not intersect triangle
    if v < 0 or u + v > 1 then
        return
    end

    -- at this stage we can compute t to find out where
    -- the intersection point is on the line
    local thisLength = vectorDotProduct(q1,q2,q3, e21,e22,e23) / a

    -- if hit this triangle and it's closer than any other hit triangle
    if thisLength >= tiny and (not finalLength or thisLength < finalLength) then
        --local norm_x, norm_y, norm_z = vectorCrossProduct(e11,e12,e13, e21,e22,e23)

        return thisLength, src_x + dir_x*thisLength, src_y + dir_y*thisLength, src_z + dir_z*thisLength, n_x,n_y,n_z
    end
end

-- detects a collision between a triangle and a sphere
--
-- sources:
--     https://wickedengine.net/2020/04/26/capsule-collision-detection/
local function triangleSphere(
        tri_0_x, tri_0_y, tri_0_z,
        tri_1_x, tri_1_y, tri_1_z,
        tri_2_x, tri_2_y, tri_2_z,
        tri_n_x, tri_n_y, tri_n_z,
        src_x, src_y, src_z, radius
    )

    -- recalculate surface normal of this triangle
    local side1_x, side1_y, side1_z = tri_1_x - tri_0_x, tri_1_y - tri_0_y, tri_1_z - tri_0_z
    local side2_x, side2_y, side2_z = tri_2_x - tri_0_x, tri_2_y - tri_0_y, tri_2_z - tri_0_z
    local n_x, n_y, n_z = vectorNormalize(vectorCrossProduct(side1_x, side1_y, side1_z, side2_x, side2_y, side2_z))

    -- distance from src to a vertex on the triangle
    local dist = vectorDotProduct(src_x - tri_0_x, src_y - tri_0_y, src_z - tri_0_z, n_x, n_y, n_z)

    -- collision not possible, just return
    if dist < -radius or dist > radius then
        return
    end

    -- itx stands for intersection
    local itx_x, itx_y, itx_z = src_x - n_x * dist, src_y - n_y * dist, src_z - n_z * dist

    -- determine whether itx is inside the triangle
    -- project it onto the triangle and return if this is the case
    local c0_x, c0_y, c0_z = vectorCrossProduct(itx_x - tri_0_x, itx_y - tri_0_y, itx_z - tri_0_z, tri_1_x - tri_0_x, tri_1_y - tri_0_y, tri_1_z - tri_0_z)
    local c1_x, c1_y, c1_z = vectorCrossProduct(itx_x - tri_1_x, itx_y - tri_1_y, itx_z - tri_1_z, tri_2_x - tri_1_x, tri_2_y - tri_1_y, tri_2_z - tri_1_z)
    local c2_x, c2_y, c2_z = vectorCrossProduct(itx_x - tri_2_x, itx_y - tri_2_y, itx_z - tri_2_z, tri_0_x - tri_2_x, tri_0_y - tri_2_y, tri_0_z - tri_2_z)
    if  vectorDotProduct(c0_x, c0_y, c0_z, n_x, n_y, n_z) <= 0
    and vectorDotProduct(c1_x, c1_y, c1_z, n_x, n_y, n_z) <= 0
    and vectorDotProduct(c2_x, c2_y, c2_z, n_x, n_y, n_z) <= 0 then
        n_x, n_y, n_z = src_x - itx_x, src_y - itx_y, src_z - itx_z

        -- the sphere is inside the triangle, so the normal is zero
        -- instead, just return the triangle's normal
        if n_x == 0 and n_y == 0 and n_z == 0 then
            return vectorMagnitude(n_x, n_y, n_z), itx_x, itx_y, itx_z, tri_n_x, tri_n_y, tri_n_z
        end

        return vectorMagnitude(n_x, n_y, n_z), itx_x, itx_y, itx_z, n_x, n_y, n_z
    end

    -- itx is outside triangle
    -- find points on all three line segments that are closest to itx
    -- if distance between itx and one of these three closest points is in range, there is an intersection
    local radiussq = radius * radius
    local smallestDist

    local line1_x, line1_y, line1_z = closestPointOnLineSegment(tri_0_x, tri_0_y, tri_0_z, tri_1_x, tri_1_y, tri_1_z, src_x, src_y, src_z)
    local dist = (src_x - line1_x)^2 + (src_y - line1_y)^2 + (src_z - line1_z)^2
    if dist <= radiussq then
        smallestDist = dist
        itx_x, itx_y, itx_z = line1_x, line1_y, line1_z
    end

    local line2_x, line2_y, line2_z = closestPointOnLineSegment(tri_1_x, tri_1_y, tri_1_z, tri_2_x, tri_2_y, tri_2_z, src_x, src_y, src_z)
    local dist = (src_x - line2_x)^2 + (src_y - line2_y)^2 + (src_z - line2_z)^2
    if (smallestDist and dist < smallestDist or not smallestDist) and dist <= radiussq then
        smallestDist = dist
        itx_x, itx_y, itx_z = line2_x, line2_y, line2_z
    end

    local line3_x, line3_y, line3_z = closestPointOnLineSegment(tri_2_x, tri_2_y, tri_2_z, tri_0_x, tri_0_y, tri_0_z, src_x, src_y, src_z)
    local dist = (src_x - line3_x)^2 + (src_y - line3_y)^2 + (src_z - line3_z)^2
    if (smallestDist and dist < smallestDist or not smallestDist) and dist <= radiussq then
        smallestDist = dist
        itx_x, itx_y, itx_z = line3_x, line3_y, line3_z
    end

    if smallestDist then
        n_x, n_y, n_z = src_x - itx_x, src_y - itx_y, src_z - itx_z

        -- the sphere is inside the triangle, so the normal is zero
        -- instead, just return the triangle's normal
        if n_x == 0 and n_y == 0 and n_z == 0 then
            return vectorMagnitude(n_x, n_y, n_z), itx_x, itx_y, itx_z, tri_n_x, tri_n_y, tri_n_z
        end

        return vectorMagnitude(n_x, n_y, n_z), itx_x, itx_y, itx_z, n_x, n_y, n_z
    end
end

-- finds the closest point on the triangle from the source point given
--
-- sources:
--     https://wickedengine.net/2020/04/26/capsule-collision-detection/
local function trianglePoint(
        tri_0_x, tri_0_y, tri_0_z,
        tri_1_x, tri_1_y, tri_1_z,
        tri_2_x, tri_2_y, tri_2_z,
        tri_n_x, tri_n_y, tri_n_z,
        src_x, src_y, src_z
    )

    -- recalculate surface normal of this triangle
    local side1_x, side1_y, side1_z = tri_1_x - tri_0_x, tri_1_y - tri_0_y, tri_1_z - tri_0_z
    local side2_x, side2_y, side2_z = tri_2_x - tri_0_x, tri_2_y - tri_0_y, tri_2_z - tri_0_z
    local n_x, n_y, n_z = vectorNormalize(vectorCrossProduct(side1_x, side1_y, side1_z, side2_x, side2_y, side2_z))

    -- distance from src to a vertex on the triangle
    local dist = vectorDotProduct(src_x - tri_0_x, src_y - tri_0_y, src_z - tri_0_z, n_x, n_y, n_z)

    -- itx stands for intersection
    local itx_x, itx_y, itx_z = src_x - n_x * dist, src_y - n_y * dist, src_z - n_z * dist

    -- determine whether itx is inside the triangle
    -- project it onto the triangle and return if this is the case
    local c0_x, c0_y, c0_z = vectorCrossProduct(itx_x - tri_0_x, itx_y - tri_0_y, itx_z - tri_0_z, tri_1_x - tri_0_x, tri_1_y - tri_0_y, tri_1_z - tri_0_z)
    local c1_x, c1_y, c1_z = vectorCrossProduct(itx_x - tri_1_x, itx_y - tri_1_y, itx_z - tri_1_z, tri_2_x - tri_1_x, tri_2_y - tri_1_y, tri_2_z - tri_1_z)
    local c2_x, c2_y, c2_z = vectorCrossProduct(itx_x - tri_2_x, itx_y - tri_2_y, itx_z - tri_2_z, tri_0_x - tri_2_x, tri_0_y - tri_2_y, tri_0_z - tri_2_z)
    if  vectorDotProduct(c0_x, c0_y, c0_z, n_x, n_y, n_z) <= 0
    and vectorDotProduct(c1_x, c1_y, c1_z, n_x, n_y, n_z) <= 0
    and vectorDotProduct(c2_x, c2_y, c2_z, n_x, n_y, n_z) <= 0 then
        n_x, n_y, n_z = src_x - itx_x, src_y - itx_y, src_z - itx_z

        -- the sphere is inside the triangle, so the normal is zero
        -- instead, just return the triangle's normal
        if n_x == 0 and n_y == 0 and n_z == 0 then
            return vectorMagnitude(n_x, n_y, n_z), itx_x, itx_y, itx_z, tri_n_x, tri_n_y, tri_n_z
        end

        return vectorMagnitude(n_x, n_y, n_z), itx_x, itx_y, itx_z, n_x, n_y, n_z
    end

    -- itx is outside triangle
    -- find points on all three line segments that are closest to itx
    -- if distance between itx and one of these three closest points is in range, there is an intersection
    local line1_x, line1_y, line1_z = closestPointOnLineSegment(tri_0_x, tri_0_y, tri_0_z, tri_1_x, tri_1_y, tri_1_z, src_x, src_y, src_z)
    local dist = (src_x - line1_x)^2 + (src_y - line1_y)^2 + (src_z - line1_z)^2
    local smallestDist = dist
    itx_x, itx_y, itx_z = line1_x, line1_y, line1_z

    local line2_x, line2_y, line2_z = closestPointOnLineSegment(tri_1_x, tri_1_y, tri_1_z, tri_2_x, tri_2_y, tri_2_z, src_x, src_y, src_z)
    local dist = (src_x - line2_x)^2 + (src_y - line2_y)^2 + (src_z - line2_z)^2
    if smallestDist and dist < smallestDist then
        smallestDist = dist
        itx_x, itx_y, itx_z = line2_x, line2_y, line2_z
    end

    local line3_x, line3_y, line3_z = closestPointOnLineSegment(tri_2_x, tri_2_y, tri_2_z, tri_0_x, tri_0_y, tri_0_z, src_x, src_y, src_z)
    local dist = (src_x - line3_x)^2 + (src_y - line3_y)^2 + (src_z - line3_z)^2
    if smallestDist and dist < smallestDist then
        smallestDist = dist
        itx_x, itx_y, itx_z = line3_x, line3_y, line3_z
    end

    if smallestDist then
        n_x, n_y, n_z = src_x - itx_x, src_y - itx_y, src_z - itx_z

        -- the sphere is inside the triangle, so the normal is zero
        -- instead, just return the triangle's normal
        if n_x == 0 and n_y == 0 and n_z == 0 then
            return vectorMagnitude(n_x, n_y, n_z), itx_x, itx_y, itx_z, tri_n_x, tri_n_y, tri_n_z
        end

        return vectorMagnitude(n_x, n_y, n_z), itx_x, itx_y, itx_z, n_x, n_y, n_z
    end
end

-- finds the collision point between a triangle and a capsule
-- capsules are defined with two points and a radius
--
-- sources:
--     https://wickedengine.net/2020/04/26/capsule-collision-detection/
local function triangleCapsule(
        tri_0_x, tri_0_y, tri_0_z,
        tri_1_x, tri_1_y, tri_1_z,
        tri_2_x, tri_2_y, tri_2_z,
        n_x, n_y, n_z,
        tip_x, tip_y, tip_z,
        base_x, base_y, base_z,
        a_x, a_y, a_z,
        b_x, b_y, b_z,
        capn_x, capn_y, capn_z,
        radius
    )

    -- find the normal of this triangle
    -- tbd if necessary, this sometimes fixes weird edgecases
    local side1_x, side1_y, side1_z = tri_1_x - tri_0_x, tri_1_y - tri_0_y, tri_1_z - tri_0_z
    local side2_x, side2_y, side2_z = tri_2_x - tri_0_x, tri_2_y - tri_0_y, tri_2_z - tri_0_z
    local n_x, n_y, n_z = vectorNormalize(vectorCrossProduct(side1_x, side1_y, side1_z, side2_x, side2_y, side2_z))

    local dotOfNormals = math.abs(vectorDotProduct(n_x, n_y, n_z, capn_x, capn_y, capn_z))

    -- default reference point to an arbitrary point on the triangle
    -- for when dotOfNormals is 0, because then the capsule is parallel to the triangle
    local ref_x, ref_y, ref_z = tri_0_x, tri_0_y, tri_0_z

    if dotOfNormals > 0 then
        -- capsule is not parallel to the triangle's plane
        -- find where the capsule's normal vector intersects the triangle's plane
        local t = vectorDotProduct(n_x, n_y, n_z, (tri_0_x - base_x) / dotOfNormals, (tri_0_y - base_y) / dotOfNormals, (tri_0_z - base_z) / dotOfNormals)
        local plane_itx_x, plane_itx_y, plane_itx_z = base_x + capn_x*t, base_y + capn_y*t, base_z + capn_z*t
        local _

        -- then clamp that plane intersect point onto the triangle itself
        -- this is the new reference point
        _, ref_x, ref_y, ref_z = trianglePoint(
            tri_0_x, tri_0_y, tri_0_z,
            tri_1_x, tri_1_y, tri_1_z,
            tri_2_x, tri_2_y, tri_2_z,
            n_x, n_y, n_z,
            plane_itx_x, plane_itx_y, plane_itx_z
        )
    end

    -- find the closest point on the capsule line to the reference point
    local c_x, c_y, c_z = closestPointOnLineSegment(a_x, a_y, a_z, b_x, b_y, b_z, ref_x, ref_y, ref_z)

    -- do a sphere cast from that closest point to the triangle and return the result
    return triangleSphere(
        tri_0_x, tri_0_y, tri_0_z,
        tri_1_x, tri_1_y, tri_1_z,
        tri_2_x, tri_2_y, tri_2_z,
        n_x, n_y, n_z,
        c_x, c_y, c_z, radius
    )
end

----------------------------------------------------------------------------------------------------
-- function appliers
----------------------------------------------------------------------------------------------------
-- these functions apply the collision test functions on the given list of triangles

-- runs a given intersection function on all of the triangles made up of a given vert table
local function findClosest(self, verts, func, ...)
    -- declare the variables that will be returned by the function
    local finalLength, where_x, where_y, where_z, norm_x, norm_y, norm_z

    -- cache references to this model's properties for efficiency
    local translation_x, translation_y, translation_z, scale_x, scale_y, scale_z = 0, 0, 0, 1, 1, 1
    if self then
        if self.translation then
            translation_x = self.translation[1]
            translation_y = self.translation[2]
            translation_z = self.translation[3]
        end
        if self.scale then
            scale_x = self.scale[1]
            scale_y = self.scale[2]
            scale_z = self.scale[3]
        end
    end

    for v=1, #verts, 3 do
        -- apply the function given with the arguments given
        -- also supply the points of the current triangle
        local n_x, n_y, n_z = vectorNormalize(
            verts[v][6]*scale_x,
            verts[v][7]*scale_x,
            verts[v][8]*scale_x
        )

        local length, wx,wy,wz, nx,ny,nz = func(
            verts[v][1]*scale_x + translation_x,
            verts[v][2]*scale_y + translation_y,
            verts[v][3]*scale_z + translation_z,
            verts[v+1][1]*scale_x + translation_x,
            verts[v+1][2]*scale_y + translation_y,
            verts[v+1][3]*scale_z + translation_z,
            verts[v+2][1]*scale_x + translation_x,
            verts[v+2][2]*scale_y + translation_y,
            verts[v+2][3]*scale_z + translation_z,
            n_x,
            n_y,
            n_z,
            ...
        )

        -- if something was hit
        -- and either the finalLength is not yet defined or the new length is closer
        -- then update the collision information
        if length and (not finalLength or length < finalLength) then
            finalLength = length
            where_x = wx
            where_y = wy
            where_z = wz
            norm_x = nx
            norm_y = ny
            norm_z = nz
        end
    end

    -- normalize the normal vector before it is returned
    if finalLength then
        norm_x, norm_y, norm_z = vectorNormalize(norm_x, norm_y, norm_z)
    end

    -- return all the information in a standardized way
    return finalLength, where_x, where_y, where_z, norm_x, norm_y, norm_z
end

-- runs a given intersection function on all of the triangles made up of a given vert table
local function findAny(self, verts, func, ...)
    -- cache references to this model's properties for efficiency
    local translation_x, translation_y, translation_z, scale_x, scale_y, scale_z = 0, 0, 0, 1, 1, 1
    if self then
        if self.translation then
            translation_x = self.translation[1]
            translation_y = self.translation[2]
            translation_z = self.translation[3]
        end
        if self.scale then
            scale_x = self.scale[1]
            scale_y = self.scale[2]
            scale_z = self.scale[3]
        end
    end

    for v=1, #verts, 3 do
        -- apply the function given with the arguments given
        -- also supply the points of the current triangle
        local n_x, n_y, n_z = vectorNormalize(
            verts[v][6]*scale_x,
            verts[v][7]*scale_x,
            verts[v][8]*scale_x
        )

        local length = func(
            verts[v][1]*scale_x + translation_x,
            verts[v][2]*scale_y + translation_y,
            verts[v][3]*scale_z + translation_z,
            verts[v+1][1]*scale_x + translation_x,
            verts[v+1][2]*scale_y + translation_y,
            verts[v+1][3]*scale_z + translation_z,
            verts[v+2][1]*scale_x + translation_x,
            verts[v+2][2]*scale_y + translation_y,
            verts[v+2][3]*scale_z + translation_z,
            n_x,
            n_y,
            n_z,
            ...
        )

        -- if something was hit
        -- and either the finalLength is not yet defined or the new length is closer
        -- then update the collision information
        if length then return true end
    end

    return false
end

----------------------------------------------------------------------------------------------------
-- handle simplex functions
----------------------------------------------------------------------------------------------------

-- trim simplex down to four points if it's above
function trimSimplex(simplex)
    for i=#simplex,5,-1 do
        table.remove(simplex)
    end
end

-- push element in at the front and trim to four points
function pushFrontSimplex(simplex, point_x, point_y, point_z)
    table.insert(simplex, 1, {point_x, point_y, point_z})
    trimSimplex(simplex)
end

-- print simplex for debugging
function printSimplex(simplex)
    print("Simplex:")
    for i=1,#simplex do
        print(string.format("  Point %d: (%.2f, %.2f, %.2f)", i, simplex[i][1], simplex[i][2], simplex[i][3]))
    end
end

function printVerts(verts)
    print("Verts:")
    for i=1,#verts do
        print(string.format("  Vert %d: (%.2f, %.2f, %.2f)", i, verts[i][1], verts[i][2], verts[i][3]))
    end
end

----------------------------------------------------------------------------------------------------
-- Andrew's collision functions     Source: https://winter.dev/
----------------------------------------------------------------------------------------------------
-- My definitions include: 
    -- GJK collision detection which can detect a collision but nothing else
    -- EPA collision detection which works like GJK but also returns penetration depth and contact normal
-- These functions only work between two convex shapes
-- Both of these functions will be extended to be usable with the collisions library
----------------------------------------------------------------------------------------------------

-- Method you call for GJK collision detection between two convex shapes
function GJK(modelA, modelB)
    -- initial direction
    local dir_x, dir_y, dir_z = 1, 0, 0

    -- initial point on the minkowski difference
    local point_x, point_y, point_z = minkowskiDiff(modelA, modelB, dir_x, dir_y, dir_z)

    -- simplex points (max count is 4 since we're in 3D)
    local simplex = {
        {point_x, point_y, point_z}
    }

    -- new direction towards the origin
    dir_x, dir_y, dir_z = -point_x, -point_y, -point_z

    while true do
        -- get a new point on the minkowski difference
        local newPoint_x, newPoint_y, newPoint_z = minkowskiDiff(modelA, modelB, dir_x, dir_y, dir_z)

        -- if the new point isn't past the origin in the direction of dir, no collision
        if vectorDotProduct(newPoint_x, newPoint_y, newPoint_z, dir_x, dir_y, dir_z) <= 0 then
            return false -- no collision
        end

        -- add the new point to the simplex
        pushFrontSimplex(simplex, newPoint_x, newPoint_y, newPoint_z)

        -- check if the simplex contains the origin
        local containsOrigin, dir_x, dir_y, dir_z = nextSimplex(simplex, dir_x, dir_y, dir_z)
        if containsOrigin then
            -- print("GJK: Collision detected")
            -- printSimplex(simplex)
            return true
        end
    end
end

function findFurthestPoint(model, dir_x, dir_y, dir_z)
    local max_x, max_y, max_z
    local maxDist = -math.huge

    local translation_x, translation_y, translation_z, scale_x, scale_y, scale_z = 0, 0, 0, 1, 1, 1
    if model then
        if model.translation then
            translation_x = model.translation[1]
            translation_y = model.translation[2]
            translation_z = model.translation[3]
        end
        if model.scale then
            scale_x = model.scale[1]
            scale_y = model.scale[2]
            scale_z = model.scale[3]
        end
    end

    for v=1, #model.verts do
        x = model.verts[v][1]*scale_x + translation_x
        y = model.verts[v][2]*scale_y + translation_y
        z = model.verts[v][3]*scale_z + translation_z
        local dist = vectorDotProduct(x, y, z, dir_x, dir_y, dir_z)
        if dist > maxDist then
            maxDist = dist
            max_x = x
            max_y = y
            max_z = z
        end
    end

    return max_x, max_y, max_z
end

function minkowskiDiff(modelA, modelB, dir_x, dir_y, dir_z)
    local a_x, a_y, a_z = findFurthestPoint(modelA, dir_x, dir_y, dir_z)
    local b_x, b_y, b_z = findFurthestPoint(modelB, -dir_x, -dir_y, -dir_z)

    return fastSubtract(a_x, a_y, a_z, b_x, b_y, b_z)
end

function nextSimplex(simplex, dir_x, dir_y, dir_z)
    -- handle simplex based on its size
    if #simplex == 2 then
        return handleLine(simplex, dir_x, dir_y, dir_z)
    elseif #simplex == 3 then
        return handleTriangle(simplex, dir_x, dir_y, dir_z)
    elseif #simplex == 4 then
        return handleTetrahedron(simplex, dir_x, dir_y, dir_z)
    end

    -- should not reach here
    return false
end

function sameDirection(a_x, a_y, a_z, b_x, b_y, b_z)
    return vectorDotProduct(a_x, a_y, a_z, b_x, b_y, b_z) > 0
end

function handleLine(simplex, dir_x, dir_y, dir_z)
    local a_x, a_y, a_z = simplex[1][1], simplex[1][2], simplex[1][3]
    local b_x, b_y, b_z = simplex[2][1], simplex[2][2], simplex[2][3]

    local ab_x, ab_y, ab_z = fastSubtract(b_x, b_y, b_z, a_x, a_y, a_z)
    local ao_x, ao_y, ao_z = fastSubtract(0, 0, 0, a_x, a_y, a_z)

    if sameDirection(ab_x, ab_y, ab_z, ao_x, ao_y, ao_z) then
        local cross1_x, cross1_y, cross1_z = vectorCrossProduct(ab_x, ab_y, ab_z, ao_x, ao_y, ao_z)
        dir_x, dir_y, dir_z = vectorCrossProduct(cross1_x, cross1_y, cross1_z, ab_x, ab_y, ab_z)
    else
        simplex = {{a_x, a_y, a_z}}
        dir_x, dir_y, dir_z = ao_x, ao_y, ao_z
    end

    return false, dir_x, dir_y, dir_z
end

function handleTriangle(simplex, dir_x, dir_y, dir_z)
    local a_x, a_y, a_z = simplex[1][1], simplex[1][2], simplex[1][3]
    local b_x, b_y, b_z = simplex[2][1], simplex[2][2], simplex[2][3]
    local c_x, c_y, c_z = simplex[3][1], simplex[3][2], simplex[3][3]

    local ab_x, ab_y, ab_z = fastSubtract(b_x, b_y, b_z, a_x, a_y, a_z)
    local ac_x, ac_y, ac_z = fastSubtract(c_x, c_y, c_z, a_x, a_y, a_z)
    local ao_x, ao_y, ao_z = fastSubtract(0, 0, 0, a_x, a_y, a_z)

    local abc_x, abc_y, abc_z = vectorCrossProduct(ab_x, ab_y, ab_z, ac_x, ac_y, ac_z)

    local crossOut1_x, crossOut1_y, crossOut1_z = vectorCrossProduct(abc_x, abc_y, abc_z, ac_x, ac_y, ac_z)
    if (sameDirection(crossOut1_x, crossOut1_y, crossOut1_z, ao_x, ao_y, ao_z)) then
        if sameDirection(ac_x, ac_y, ac_z, ao_x, ao_y, ao_z) then

            simplex = {{a_x, a_y, a_z}, {c_x, c_y, c_z}}
            local cross1_x, cross1_y, cross1_z = vectorCrossProduct(ac_x, ac_y, ac_z, ao_x, ao_y, ao_z)
            dir_x, dir_y, dir_z = vectorCrossProduct(cross1_x, cross1_y, cross1_z, ac_x, ac_y, ac_z)

        else
            simplex = {{a_x, a_y, a_z}, {b_x, b_y, b_z}}
            return handleLine(simplex, dir_x, dir_y, dir_z)
        end
    else
        local crossOut2_x, crossOut2_y, crossOut2_z = vectorCrossProduct(ab_x, ab_y, ab_z, abc_x, abc_y, abc_z)
        if sameDirection(crossOut2_x, crossOut2_y, crossOut2_z, ao_x, ao_y, ao_z) then
            simplex = {{a_x, a_y, a_z}, {b_x, b_y, b_z}}
            return handleLine(simplex, dir_x, dir_y, dir_z)
        else

            if sameDirection(abc_x, abc_y, abc_z, ao_x, ao_y, ao_z) then
                dir_x, dir_y, dir_z = abc_x, abc_y, abc_z
            else
                simplex = {{a_x, a_y, a_z}, {c_x, c_y, c_z}, {b_x, b_y, b_z}}
                dir_x, dir_y, dir_z = -abc_x, -abc_y, -abc_z
            end

        end
    end

    return false, dir_x, dir_y, dir_z
end

function handleTetrahedron(simplex, dir_x, dir_y, dir_z)
    local a_x, a_y, a_z = simplex[1][1], simplex[1][2], simplex[1][3]
    local b_x, b_y, b_z = simplex[2][1], simplex[2][2], simplex[2][3]
    local c_x, c_y, c_z = simplex[3][1], simplex[3][2], simplex[3][3]
    local d_x, d_y, d_z = simplex[4][1], simplex[4][2], simplex[4][3]

    local ab_x, ab_y, ab_z = fastSubtract(b_x, b_y, b_z, a_x, a_y, a_z)
    local ac_x, ac_y, ac_z = fastSubtract(c_x, c_y, c_z, a_x, a_y, a_z)
    local ad_x, ad_y, ad_z = fastSubtract(d_x, d_y, d_z, a_x, a_y, a_z)
    local ao_x, ao_y, ao_z = fastSubtract(0, 0, 0, a_x, a_y, a_z)

    local abc_x, abc_y, abc_z = vectorCrossProduct(ab_x, ab_y, ab_z, ac_x, ac_y, ac_z)
    local acd_x, acd_y, acd_z = vectorCrossProduct(ac_x, ac_y, ac_z, ad_x, ad_y, ad_z)
    local adb_x, adb_y, adb_z = vectorCrossProduct(ad_x, ad_y, ad_z, ab_x, ab_y, ab_z)

    if sameDirection(abc_x, abc_y, abc_z, ao_x, ao_y, ao_z) then
        simplex = {{a_x, a_y, a_z}, {b_x, b_y, b_z}, {c_x, c_y, c_z}}
        return handleTriangle(simplex, dir_x, dir_y, dir_z)
    end

    if sameDirection(acd_x, acd_y, acd_z, ao_x, ao_y, ao_z) then
        simplex = {{a_x, a_y, a_z}, {c_x, c_y, c_z}, {d_x, d_y, d_z}}
        return handleTriangle(simplex, dir_x, dir_y, dir_z)
    end

    if sameDirection(adb_x, adb_y, adb_z, ao_x, ao_y, ao_z) then
        simplex = {{a_x, a_y, a_z}, {d_x, d_y, d_z}, {b_x, b_y, b_z}}
        return handleTriangle(simplex, dir_x, dir_y, dir_z)
    end

    return true, dir_x, dir_y, dir_z
end

-- Deep copy lua table
function deepCopy(origTable, copies)
    -- Handle non-table types (numbers, strings, booleans, etc.)
    if type(origTable) ~= "table" then
        return origTable
    end

    -- Use a weak map to track tables that have already been copied,
    -- which prevents infinite loops for circular references.
    copies = copies or setmetatable({}, {__mode = "k"}) 

    -- If the table has already been copied, return the existing copy
    if copies[origTable] then
        return copies[origTable]
    end

    -- Create a new table and store a reference to it in the 'copies' map
    local copy = {}
    copies[origTable] = copy

    -- Recursively copy key-value pairs
    for key, value in pairs(origTable) do
        copy[deepCopy(key, copies)] = deepCopy(value, copies)
    end

    -- Recursively copy the metatable, if it exists
    local meta = getmetatable(origTable)
    if meta then
        setmetatable(copy, deepCopy(meta, copies))
    end

    return copy
end

-- Method you call for EPA collision detection between two convex shapes
-- returns contact normal, penetration depth, and a boolean indicating a successful result
function EPA(simplex, vertsA, vertsB)
    local polytope = simplex
    local faces = {
        0, 1, 2,
        0, 3, 1,
        0, 2, 3,
        1, 3, 2
    }

    local normals, minFace = getFaceNormals(polytope, faces)

    local minNorm_x, minNorm_y, minNorm_z
    local minDistance = math.huge

    while minDistance == math.huge do
        minNorm_x, minNorm_y, minNorm_z = normals[minFace], normals[minFace + 1], normals[minFace + 2]
        minDistance = normals[minFace + 3]

        local minkVec_x, minkVec_y, minkVec_z = minkowskiDiff(vertsA, vertsB, minNorm_x, minNorm_y, minNorm_z)
        local sDistance = vectorDotProduct(minkVec_x, minkVec_y, minkVec_z, minNorm_x, minNorm_y, minNorm_z)
        if math.abs(sDistance - minDistance) < 0.001 then
            minDistance = math.huge
            local uniqueEdges = {}
            
            for i = 1, #normals do
                if sameDirection(
                    normals[i], normals[i + 1], normals[i + 2],
                    minkVec_x, minkVec_y, minkVec_z
                ) then
                    local f = i * 3

                    addIfUniqueEdge(uniqueEdges, faces, f, f + 1)
                    addIfUniqueEdge(uniqueEdges, faces, f + 1, f + 2)
                    addIfUniqueEdge(uniqueEdges, faces, f + 2, f)

                    faces[f + 2] = faces[#faces]
                    table.remove(faces)
                    faces[f + 1] = faces[#faces]
                    table.remove(faces)
                    faces[f] = faces[#faces]
                    table.remove(faces)

                    i = i - 1
                end
            end

            local newFaces = {};
            for i = 1, #uniqueEdges, 2 do
                table.insert(newFaces, uniqueEdges[i])
                table.insert(newFaces, uniqueEdges[i + 1])
                table.insert(newFaces, #polytope)
            end

            table.insert(polytope, {minkVec_x, minkVec_y, minkVec_z})

            local newNormals, newMinFace = getFaceNormals(polytope, newFaces)

            local oldMinDistance = math.huge
            for i = 1, #normals do
                if normals[i + 3] < oldMinDistance then
                    oldMinDistance = normals[i + 3]
                    minFace = i
                end
            end

            if newNormals[newMinFace + 3] < oldMinDistance then
                minFace = #normals + newMinFace
            end

            for i = 1, #newFaces do
                table.insert(faces, newFaces[i])
            end
            for i = 1, #newNormals do
                table.insert(normals, newNormals[i])
            end
        end
    end

    return minNorm_x, minNorm_y, minNorm_z, (minDistance + 0.001), true
end 

function getFaceNormals(polytope, faces)
    local normals = {}
    local minFace = 1
    local minDistance = math.huge

    for i = 1, #faces, 3 do
        local a_x, a_y, a_z = polytope[faces[i]][1], polytope[faces[i]][2], polytope[faces[i]][3]
        local b_x, b_y, b_z = polytope[faces[i + 1]][1], polytope[faces[i + 1]][2], polytope[faces[i + 1]][3]
        local c_x, c_y, c_z = polytope[faces[i + 2]][1], polytope[faces[i + 2]][2], polytope[faces[i + 2]][3]

        local bminusa_x, bminusa_y, bminusa_z = fastSubtract(b_x, b_y, b_z, a_x, a_y, a_z)
        local cminusa_x, cminusa_y, cminusa_z = fastSubtract(c_x, c_y, c_z, a_x, a_y, a_z)

        local norm_x, norm_y, norm_z = vectorNormalize(
            vectorCrossProduct(
                bminusa_x, bminusa_y, bminusa_z,
                cminusa_x, cminusa_y, cminusa_z
            )
        )
        local distance = vectorDotProduct(norm_x, norm_y, norm_z, a_x, a_y, a_z)

        if distance < 0 then
            norm_x, norm_y, norm_z = -norm_x, -norm_y, -norm_z
            distance = -distance
        end

        table.insert(normals, norm_x)
        table.insert(normals, norm_y)
        table.insert(normals, norm_z)
        table.insert(normals, distance)

        if distance < minDistance then
            minDistance = distance
            minFace = i / 3
        end
    end

    return normals, minFace
end

function findInTable(table, val1, val2)
    for i = 1, #table, 2 do
        if table[i] == val1 and table[i + 1] == val2 then
            return i
        end
    end
    return nil
end

function addIfUniqueEdge(edges, faces, a, b)
    local reverseIndex = findInTable(edges, faces[b], faces[a])

    if (reverseIndex + 1) ~= #edges then
        table.remove(edges, reverseIndex)
        table.remove(edges, reverseIndex)
    else
        table.insert(edges, faces[a])
        table.insert(edges, faces[b])
    end
end

----------------------------------------------------------------------------------------------------
-- collision functions that apply on lists of vertices
----------------------------------------------------------------------------------------------------

function collisions.rayIntersection(verts, transform, src_x, src_y, src_z, dir_x, dir_y, dir_z)
    return findClosest(transform, verts, triangleRay, src_x, src_y, src_z, dir_x, dir_y, dir_z)
end

function collisions.isPointInside(verts, transform, x, y, z)
    return findAny(transform, verts, triangleRay, x, y, z, 0, 0, 1)
end

function collisions.sphereIntersection(verts, transform, src_x, src_y, src_z, radius)
    return findClosest(transform, verts, triangleSphere, src_x, src_y, src_z, radius)
end

function collisions.closestPoint(verts, transform, src_x, src_y, src_z)
    return findClosest(transform, verts, trianglePoint, src_x, src_y, src_z)
end

function collisions.capsuleIntersection(verts, transform, tip_x, tip_y, tip_z, base_x, base_y, base_z, radius)
    -- the normal vector coming out the tip of the capsule
    local norm_x, norm_y, norm_z = vectorNormalize(tip_x - base_x, tip_y - base_y, tip_z - base_z)

    -- the base and tip, inset by the radius
    -- these two coordinates are the actual extent of the capsule sphere line
    local a_x, a_y, a_z = base_x + norm_x*radius, base_y + norm_y*radius, base_z + norm_z*radius
    local b_x, b_y, b_z = tip_x - norm_x*radius, tip_y - norm_y*radius, tip_z - norm_z*radius

    return findClosest(
        transform,
        verts,
        triangleCapsule,
        tip_x, tip_y, tip_z,
        base_x, base_y, base_z,
        a_x, a_y, a_z,
        b_x, b_y, b_z,
        norm_x, norm_y, norm_z,
        radius
    )
end

function collisions.GJKIntersection(modelA, modelB)
    return GJK(modelA, modelB)
end



return collisions
