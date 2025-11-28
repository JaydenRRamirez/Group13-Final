# Rigid Body Docs (tell me if you need other functions described here)

## rigidBody.newRigidBody(verts, texture, translation, rotation, scale, type, colliderType, colliderParams, extraParams, mass, gravity)

Creates the wrapper for g3d `newModel` that works with the physics engine.

Arguments

* `verts, texture, translation, rotation, scale`
  * all work exactly the same as they do for g3d's newModel function. The parameters after it are what the rigid body object requires to know how the object functions. Most of the other parameters will default to some base values if they're set to `nil`
* `type` (string)
  * can be set to "static" or "dynamic". Static will allow it to be unmoving and have infinite mass so other simulated objects can bounce off of it. dynamic will be under the effects of gravity and can collide with static objects. neither object type processes collisions with other objects of it's same type yet.
* `colliderType` (string)
  * Determines what is treated as your rigid body's collider. `colliderParams` is what gives specifics about the collider in question. collider type can be "sphere", "capsule", or "verts".
* `colliderParams` (dictionary)
  * Gives the parameters for the collider in the form of a dictionary where you assign values at the necessary keys. The bullet points below specify what the string for `colliderType` can be set to and what it will look for in the dictionary if that's the case. A vector is a lua table `{}` with three values for x, y, and z
    * "sphere":
      * `radius` (number)
      * `center` (Vector)
    * "capsule":
      * `radius` (number)
      * `centerA` (Vector)
      * `centerB` (Vector)
    * "verts":
      * Doesn't look for anything in the dictionary
* `extraParams` (dictionary)
  * Specifies extra details for object simulation. Will gain more possible keys if more factors are added.
  * `elasticity` (number) - determines bouncyness, 0 is perfectly inelastic and 1 retains all energy
* `mass` (number) - defaults to 1
* `gravity` (Vector) - can be set to any individual vector. Defaults to world gravity as defined in the rigidBody.lua file.

## rigidBody.applyLinearImpulse(impulseX, impulseY, impulseZ)

* Give the body an impulse force in the form of the three separate numbers of a vector. Only effects dynamic bodies.

## rigidBody:checkCollision(otherBody)

* `otherBody` is another rigid body object. Works the same as g3d collision functions and returns values in the same way. Doesn't process actual interaction, only checks if they overlap and reports the data.

## rigidBody:resolveCollision(otherBody)

* Same argument as `checkCollision`. Calling rigid body must be dynamic and `otherBody` must be static for right now. Will both check the collision and resolve the collision.

## rigidBody:draw()

* Standard g3d method to draw the rigidBody.

## rigidBody:update(dt)

* Processes the forces on the object, applies gravity and drag as well as moving the object through it's trajectory if it's dynamic. Does nothing if it's static. `dt` is standard change in time between frames that you can get in the `love.update(dt)` function.
