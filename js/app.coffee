
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
        @vy = other.vec.vy + sqrt((pow(other.mass,2) * GRAV_CONSTANT) / dist) * 0.1

class Thing
    mass: 0
    is_attached: false
    is_dead: false
    
    constructor: (@vec, @size, @class, @el)->
        #
    
    update: (other_bodies)->
        if @is_attached is not true
            @vec.update(other_bodies)
        
    kill: ->
        @is_dead = true
        @el.parentNode.removeChild(@el) if @el isnt null and @el.parentNode
        
        
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
    hp: 5
    
    update: (other_bodies)->
        @vec.loop_around()
        super other_bodies
    
    kill: ->
        if @size > 1
            addtional =  if Math.random() > 0.5  then 2 else 1
            for i in [1..addtional]
                size = Math.ceil(Math.random() * @size)
                vec = new Vector @vec.x, @vec.y, @vec.vx + Math.random() - 0.5, @vec.vy  + Math.random() - 0.5
                a = new Asteroid vec, size, 'asteroid', el
                el = new_thing_el(a)
                a.el = el
                el.setAttribute('class', el.getAttribute("class")+" size"+size)
                things.push(a)
        super

class Satellite extends Thing
    beam_el: undefined
    payload_state: "scanning"
    range: 80
    recharge_time: 10
    lock_chance: 0.3
    lock_time: 3
    dps: 0.5
    recharging_counter: 0
    lock_counter: 0
    target: null
    
    update: (other_bodies, things)->
        @vec.loop_around()
        @update_payload(things)
        super other_bodies
    
    be: (state)->
        @payload_state = state
        @el.setAttribute("class", "#{@class} #{@payload_state}")
    
    payload_recharging: (things)->
        @recharging_counter += 1
        if @recharging_counter >= @recharge_time
            @be "scanning"
    payload_scanning: (things)->
        if Math.random() < @lock_chance
            @target = @pick_target(things)
            if @target isnt null
                @be "locking"
    payload_locking: (things)->
        @require_range()
        @lock_counter += 1
        if @lock_counter >= @lock_time
            @be "firing"
    payload_firing: (things)->
        @require_range()
        @target.hp -= @dps
        if @target.hp < 1
            @target.kill()
            @be "reset"
    payload_reset: (things)->
        @target = null
        @lock_counter = 0
        @recharging_counter = 0
        @be "recharging"
    
    require_range: ->
        if @target isnt null and (@vec.distance(@target.vec) > @range or @target.is_dead)
            @payload_state = "reset" 
    
    update_payload: (things)->
        this["payload_"+@payload_state](things)
            
    
    pick_target: (things)->
        vec = @vec
        asteroids = _.filter things, (x)-> 
            x.constructor.name is "Asteroid"
        closest = _.sortBy(asteroids, ((x)->vec.distance(x.vec)))[0]
        if vec.distance(closest.vec) <= @range
            return closest
        else
            return null

class Ship extends Thing
    direction_radians: 0
    is_forward: false
    is_backward: false
    is_counter_clockwise: false
    is_clockwise: false
    is_attaching: false
    attached: null
    
    update: (other_bodies)->
        if @is_attaching and @attached  is null
            @attached = closest_attachable(this)
            if @attached  isnt null
                @attached.is_attached = true
                @attached.vec = @vec
        
        if (not @is_attaching) and @attached  isnt null
            @attached.vec = new Vector(@vec.x, @vec.y, @vec.vx, @vec.vy)
            @attached.is_attached = false
            @attached = null
            
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
    
new_beam_el = ->
    el = document.createElementNS('http://www.w3.org/2000/svg', 'line');
    document.getElementById('svg').appendChild(el)
    return el

sat = ->
    x = MAX_X / 2 +  Math.random() * 150 + 20
    y = MAX_Y / 2
    vect = new Vector(x, y, 0, 0)
    vect.orbit earth
    thing = new Satellite vect, 5,  "satellite"
    thing.el = new_thing_el(thing)
    return thing

moon_sat = ->
    x = moon.vec.x + 20 + Math.random() * 10
    vec = new Vector(x, moon.vec.y, moon.vec.vx, moon.vec.vy + 0.6)
    # vec.orbit(moon)
    thing = new Satellite vec, 5,  "satellite"
    thing.el = new_thing_el(thing)
    return thing
    
asteriod = ->
    x = MAX_X
    y = Math.random() * MAX_Y
    yv = Math.random() * 0.25 - 0.15
    xv = Math.random() * 1 - 1.1
    vect = new Vector(x, y, xv, yv )
    thing = new Asteroid vect, 5,  "asteroid"
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

closest_attachable = (thing)->
    attachables = _.sortBy things, (x)->
        thing.vec.distance(x.vec)
    attachables[1]

earth = new Earth document.getElementById('earth')
moon = new Moon document.getElementById('moon')
ship = a_ship()
moon.vec.orbit earth
grav_bodies = [earth, moon]    
things = [earth, moon, sat(), sat(), sat(), sat(), asteriod(), ship, moon_sat(), moon_sat()]

game_running = true
asteroid_rate = 0.1

create_asteriods = ->
    if Math.random() < asteroid_rate / GAME_SPEED
        things.push(asteriod())


game_step = ->
    return if not game_running 
    create_asteriods()
    things = _.filter things, (x)->
        x.is_dead is false
    for thing in things
        thing.update(grav_bodies, things)
    # Graphics    
    for thing in things
        el = thing.el
        el.style.left = thing.vec.x - thing.size / 2
        el.style.top = thing.vec.y - thing.size / 2
        if (thing.target isnt null and thing.target isnt undefined) and (thing.target.is_dead isnt false)
            if thing.beam_el is undefined
                thing.beam_el = new_beam_el()
            thing.beam_el.setAttribute('x1', thing.vec.x)
            thing.beam_el.setAttribute('x2', thing.target.vec.x)
            thing.beam_el.setAttribute('y1', thing.vec.y)
            thing.beam_el.setAttribute('y2', thing.target.vec.y)
        else
            if thing.beam_el isnt undefined
                thing.beam_el.parentNode.removeChild(thing.beam_el)
                thing.beam_el = undefined
    

setInterval(game_step, 1000 / GAME_SPEED)
setInterval((->things.push(moon_sat()) ), 5 * 1000 )


P = {
    text: (t)->
        (-> 
            $('#text').show().html(t)
            # game_running = false
        )
    production: ->
        
    go: (rate)->
        (->
            $('#text').hide()
            asteroid_rate = rate
            game_running = true
        )
        
}

current_phase = 0
phases = [
    [  1500, P.text "there is only one\n<br>\nearth."]
    [  1500, P.text "you must save it"]
    [  1500, P.text "WASD to move.\n<br>\nhold [SPACEBAR] to hold a satellite."]
    [  1500, P.text "reposition satellites \n<br>\n to defend earth "]
    [  5000, P.go 0.1]
    [  5000, P.go 0.2]
    [15000, P.go 0.5]
    [300, P.go 3]
    [15000, P.go 0.1]
    [  1500, P.text "Wave 2/5"]
    [  5000, P.go 2]
    [15000, P.go 3]
    [15000, P.go 1]
    [  1500, P.text "Wave 3/5"]
    [  5000, P.go 2]
    [15000, P.go 3]
    [15000, P.go 1]
    [  1500, P.text "Wave 4/5"]
    [  5000, P.go 2]
    [15000, P.go 6]
    [15000, P.go 1]
    [  1500, P.text "Wave 5/5"]
    [  5000, P.go 2]
    [15000, P.go 9]
    [15000, P.go 1]
    
]

nextPhase  = ->
    [duration, fn] = phases[current_phase]
    fn()
    current_phase += 1
    if phases[current_phase] isnt null
        setTimeout nextPhase, duration

game_step()
nextPhase()

$(document).keyup (evt)->
    switch evt.which
        when 87 then ship.is_forward = false
        when 83 then ship.is_backward = false
        when 65 then ship.is_counter_clockwise = false
        when 68 then ship.is_clockwise = false
        when 32 then ship.is_attaching = false

$(document).keydown (evt)->
    switch evt.which
        when 87 then ship.is_forward = true
        when 83 then ship.is_backward = true
        when 65 then ship.is_counter_clockwise = true
        when 68 then ship.is_clockwise = true
        when 32 then ship.is_attaching = true

        
    