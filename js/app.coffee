
GAME_SPEED = 30
GRAV_CONSTANT = 30 / GAME_SPEED
MAX_X = 860
MAX_Y = 560

sqrt = Math.sqrt
pow = Math.pow

class Vector
    constructor: (@x, @y, @vx, @vy)->
    
    update: (other_bodies) ->
        @grav_attract(thing) for thing in other_bodies
        @x += @vx
        @y += @vy
        
        
    grav_attract: (other)->
        dist = @distance(other.vec)
        pull = (1 / pow(dist, 2)) *  other.mass * GRAV_CONSTANT
        offset_x =  (other.vec.x - @x ) / dist
        offset_y =  (other.vec.y - @y) / dist
        @vx += offset_x * pull
        @vy += offset_y * pull
    
    loop_around: ->
        if @x > MAX_X
            @x = 0 
            @vx /= 1.5
        if @y > MAX_Y
            @y = 0 
            @vy /= 1.5
        if @x < 0
            @x = MAX_X 
            @vx /= 1.5
        if @y < 0
            @y = MAX_Y 
            @vy /= 1.5
        
    distance: (other_vect)->
        sqrt(pow(@x - other_vect.x, 2) + pow(@y - other_vect.y, 2))
        
    orbit: (other)->
        dist = @distance(other.vec)
        @vy = sqrt((pow(other.mass,2) * GRAV_CONSTANT) / dist) * 0.1

class Thing
    mass: 0
    constructor: (@vec, @size, @class, @el)->
        #
    
    update: (other_bodies)->
        @vec.update(other_bodies)
        
    
        
        
class Earth extends Thing
    mass: 100
    constructor: (el)->
        center = new Vector(MAX_X / 2 ,MAX_Y / 2, 0, 0)
        super center, 20, "earth", el
        
    update: ->
        # Do nothing
        # Geocentric universe here!
        
class Moon extends Thing
    mass: 10
    constructor: (el)->
        vect= new Vector(MAX_X / 2 + 240, MAX_Y / 2, 0, -8000000 / (GAME_SPEED /  GRAV_CONSTANT) )
        super vect, 10, "moon", el
    update: (other_bodies)->
        no_moon = (x for x in other_bodies when x.constructor.name isnt "Moon")
        super no_moon
        
class Asteroid extends Thing
    update: (other_bodies)->
        @vec.loop_around()
        super other_bodies

class Satellite extends Thing
    update: (other_bodies)->
        @vec.loop_around()
        super other_bodies

class Ship extends Thing
    direction_radians: 0
    is_forward = false
    is_backward = false
    is_counter_clockwise = false
    is_clockwise = false
    
    update: (other_bodies)->
        @vec.loop_around()
        if @is_forward
            @vec.vy -= 0.2
        if @is_backward
            @vec.vy += 0.1
        if @is_counter_clockwise
            @vec.vx -= 0.1
        if @is_clockwise
            @vec.vx += 0.1
        super other_bodies

new_thing_el = (thing)->
    el = document.createElement('div')
    document.getElementById('viewport').appendChild(el)
    el.setAttribute("class", thing.class)
    return el

sat = ->
    x = MAX_X / 2 +  Math.random() * 200 + 20
    y = MAX_Y / 2
    vect = new Vector(x, y, 0, 0)
    vect.orbit earth
    thing = new Satellite vect, 5,  "satellite"
    thing.el = new_thing_el(thing)
    return thing
    
asteriod = ->
    x = Math.random() * MAX_X
    y = if Math.random() > 0.5 then 0 else MAX_Y
    yv = Math.random() * 0.25 - 0.5
    xv = Math.random() * 2 - 4
    vect = new Vector(x, y, xv, yv )
    thing = new Asteroid vect, 5,  "asteriod"
    thing.el = new_thing_el(thing)
    return thing

a_ship = ->
    x = MAX_X / 2 + 100
    y = MAX_Y / 2
    vec = new Vector(x, y, 0, 0)
    vec.orbit earth
    thing = new Ship vec, 7,  "ship"
    thing.el = new_thing_el(thing)
    return thing


earth = new Earth document.getElementById('earth')
moon = new Moon document.getElementById('moon')
ship = a_ship()
moon.vec.orbit earth
grav_bodies = [earth, moon]    
things = [earth, moon, sat(), sat(), sat(), sat(), sat(), sat(), sat(), sat(), sat(), asteriod(), ship]

game_step = ->
    for thing in things
        thing.update(grav_bodies)
        el = thing.el
        el.style.left = thing.vec.x - thing.size / 2
        el.style.top = thing.vec.y - thing.size / 2
    

setInterval(game_step, 1000 / GAME_SPEED)
setInterval((->things.push(asteriod()) ), 2 * 1000 )




$(document).keyup (evt)->
    switch evt.which
        when 87 then ship.is_forward = false
        when 83 then ship.is_backward = false
        when 65 then ship.is_counter_clockwise = false
        when 68 then ship.is_clockwise = false

$(document).keydown (evt)->
    switch evt.which
        when 87 then ship.is_forward = true
        when 83 then ship.is_backward = true
        when 65 then ship.is_counter_clockwise = true
        when 68 then ship.is_clockwise = true

        
    