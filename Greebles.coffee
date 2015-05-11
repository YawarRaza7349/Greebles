"use strict"

bigStr = 
    """
    "use strict"

    styleScope = (f) ->
        p.pushStyle()
        f()
        p.popStyle()
    
    randomColors = [0xFF00FF00, 0xFF00FFFFF, 0xFFEEEEEE]
    
    class ConsoleWindow
        constructor: (@x, @y, @width, @numLinesChat, @fontSize, @fontColor, speed, string) ->
            @tickLength = 1/speed
            @untilNextTick = @tickLength
            @indexLine = 0
            @indexChar = 0
            @completed = false
            @lines = string.split("\n")
            @lineArrays = (@intoChunks(l) for l in @lines)
        
        update: (dt) ->
            unless @completed
                @untilNextTick -= dt
                if @untilNextTick < 0
                    @typeChar()
                    @untilNextTick = @tickLength
            
        typeChar: ->
            ++@indexChar
            if @indexChar >= @lines[@indexLine].length
                ++@indexLine
                if @indexLine >= @lines.length
                    @completed = true
                @indexChar = 0
        
        draw: ->
            styleScope(=>
                p.textSize(@fontSize)
                p.fill(@fontColor)
                p.text(_(_(@lineArrays[0...@indexLine]).flatten(true)).last(@numLinesChat).join("\n"), @x, @y, @width, @numLinesChat * @fontSize)
                p.textAlign(p.RIGHT)
                p.text(_((@lines[@indexLine].slice(i, @indexChar) for i in [0...@indexChar])).find((sl) => p.textWidth(sl) < @width), @x, @y + @numLinesChat * @fontSize, @width, @fontSize)
            )
        
        intoChunks: (s) ->
            if s.length == 0
                []
            else
                head = _(s.slice(0, i) for i in [s.length...0]).find((h) => p.textWidth(h) < @width)
                [head].concat(@intoChunks(s.slice(head.length)))
    
    class RandomPixels
        constructor: (@x, @y, @w, @h, @tile, @spacing, @fill) ->
            @intensities = (p.random(1) for i in [0...@w * @h])
            @brightenSpeeds = (p.random(-1, 1) for i in [0...@w * @h])
        
        update: (dt) ->
            [@intensities, @brightenSpeeds] = _.zip.apply(_, (
                (ni = i + s * dt
                if ni < 0
                    [0, -s]
                else if ni > 1
                    [1, -s]
                else
                    [ni, s]
                ) for [i, s] in _.zip(@intensities, @brightenSpeeds)
            ))
        
        draw: ->
            styleScope(=>
                for i in [0...@w]
                    for j in [0...@h]
                        (=>
                            intense = @intensities[i + j * @w]
                            p.fill(p.red(@fill) * intense, p.green(@fill) * intense, p.blue(@fill) * intense)
                            p.rect(@x + i * (@tile + @spacing), @y + j * (@tile + @spacing), @tile, @tile)
                        )()
            )
        
        width: ->
            @tile * (@w + @spacing) - @spacing
        
        height: ->
            @tile * (@h + @spacing) - @spacing
    
    randomRandomPixels = ->
        new RandomPixels(0, 0, 10, 10, 10, 1, _.sample(randomColors))
    
    class BarGraph
        constructor: (@llx, @lly, @maxHeight, @spacing, @barWidths, @fill) ->
            @barHeights = (p.random(0, @maxHeight) for x in @barWidths)
            @speeds = (p.random(50, 100) * _.sample([1, -1]) for x in @barWidths)
            @goals = (if s > 0 then p.random(w, @maxHeight) else p.random(0, w) for [w, s] in _.zip(@barWidths, @speeds))
        
        update: (dt) ->
            variable = false
            @barHeights = (h + s * dt for [h, s] in _.zip(@barHeights, @speeds))
            [@speeds, @goals] = _.zip.apply(_, (
                (if (s > 0) and (h > g)
                    [p.random(-100, -50), p.random(0, h)]
                else if (s < 0) and (h < g)
                    [p.random(50, 100), p.random(h, @maxHeight)]
                else
                    [s, g]
                ) for [h, g, s] in _.zip(@barHeights, @goals, @speeds)
            ))
        
        draw: ->
            styleScope(=>
                p.fill(@fill)
                left = @llx
                for [w, h] in _.zip(@barWidths, @barHeights)
                    p.rect(left, @lly - h, w, h)
                    left += w + @spacing
            )
        
        width: ->
            _(@barWidths).reduce((a, b) => a + b) + @spacing * (@barWidths.length - 1)
        
        height: ->
            @maxHeight
    
    randomBarGraph = ->
        new BarGraph(0, 0, 100, 5, (10 for i in [0...10]), _.sample(randomColors))
    
    class RotatingPolygon
        constructor: (@x, @y, @minRadius, @maxRadius, @rotSpd, @sizeSpds, @radii, @angles, @stroke, @fill) ->
        
        update: (dt) ->
            [@radii, @sizeSpds] = _.zip.apply(_, _(_.zip(@radii, @sizeSpds)).map(([r, s]) =>
                nr = p.constrain(r + s * dt, @minRadius, @maxRadius)
                [nr, if (nr >= @maxRadius or nr <= @minRadius) then -s else s]
            ))
            @angles = (a + @rotSpd * dt for a in @angles)
            [@sizeSpds, @radii, @angles] = _.zip.apply(_, _(_.zip(@sizeSpds, @radii, (a % p.TWO_PI for a in @angles))).sortBy(([s, r, a]) => a))
        
        draw: ->
            styleScope(=>
                if @stroke? then p.stroke(@stroke) else p.noStroke()
                if @fill? then p.fill(@fill) else p.noFill()
                p.beginShape()
                _(_.zip(@radii, @angles)).each(([r, a]) =>
                    p.vertex(@x + r * p.cos(a), @y + r * p.sin(a))
                )
                p.endShape(p.CLOSE)
            )
        
        addVertex: (ang, sizeSpd) ->
            angle = ang % p.TWO_PI
            index = (a for a in @angles when a < angle).length
            len = @angles.length
            @radii[index...index] =
                if index == 0
                    [p.map(angle, @angles[len - 1] - p.TWO_PI, @angles[0], @radii[len - 1], @radii[0])]
                else if index == len
                    [p.map(angle, @angles[len - 1], @angles[0] + p.TWO_PI, @radii[len - 1], @radii[0])]
                else
                    [p.map(angle, @angles[index - 1], @angles[index] , @radii[index - 1], @radii[index])]
            @angles[index...index] = [angle]
            @sizeSpds[index...index] = [sizeSpd]
        
        width: ->
            2 * @maxRadius
        
        height: ->
            2 * @maxRadius
    
    randomRotatingPolygon = ->
        [stroke, fill] = _.sample([[null, _.sample(randomColors)], [_.sample(randomColors), null]])
        new RotatingPolygon(0, 0, 25, 100, p.random(-1, 1), (p.random(-20, 20) for i in [0...6]), (p.random(25, 100) for i in [0...6]), (i * p.TWO_PI / 6 for i in [0...6]), stroke, fill)
        
    class RotatingConcentricCircle
        constructor: (@initAngle, @arcAngle, @radius, @thickness, @rate, @fill) ->
        
        update: (dt, cx, cy) ->
            @initAngle += @rate * dt
        
        draw: (cx, cy) ->
            styleScope(=>
                p.fill(@fill)
                p.arc(cx, cy, @radius + @thickness, @radius + @thickness, @initAngle, @initAngle + @arcAngle)
            )
            styleScope(=>
                p.arc(cx, cy, @radius, @radius, @initAngle, @initAngle + @arcAngle)
            )
    
    randomRotatingConcentricCircle = (rad) ->
        new RotatingConcentricCircle(p.random(0, p.TWO_PI), p.random(0, p.TWO_PI), rad, p.random(10, 20), p.random(-1, 1), _.sample(randomColors))
    
    class RotatingConcentricCircles
        constructor: (@x, @y, arcs, @background) ->
            @arcs = _(arcs).sortBy((a) -> -a.radius)
        
        update: (dt) ->
            for a in @arcs
                a.update(dt, @x, @y)
        
        draw: ->
            styleScope(=>
                p.noStroke()
                p.fill(@background)
                for a in @arcs
                    a.draw(@x, @y)
            )
        
        width: ->
            _.max(a.radius for a in @arcs) * 2
        
        height: ->
            _.max(a.radius for a in @arcs) * 2
    
    randomRotatingConcentricCircles = ->
        rad = 20
        arcs = []
        for i in [0...8]
            randArc = randomRotatingConcentricCircle(rad)
            arcs.push(randArc)
            rad += randArc.thickness + 2
        new RotatingConcentricCircles(0, 0, arcs, 0xFF000000)
    
    class InfoPanel
        constructor: (@llx, @lly, @greebles) ->
        
        update: (dt) ->
            for g in @greebles
                g.update(dt)
        
        draw: ->
            styleScope(=>
                currX = @llx
                for g in @greebles
                    styleScope(=>
                        g.translate(currX, @lly - g.height())
                        g.draw()
                    )
                    currX += g.width()
            )
    
    p = undefined
    
    new Processing(document.getElementById("canvas"), (processing) ->
        stuff = [randomRandomPixels, randomBarGraph, randomRotatingPolygon, randomRotatingConcentricCircles]
        myGreebles = undefined
        positions = undefined
        lastMillis = undefined
        chatbox = undefined
        chatbox2 = undefined
        
        p = processing
        
        p.setup = ->
            p.size(800, 600)
            myGreebles = ((_.sample(stuff))() for i in [0...8])
            positions = ([p.random(0, 800), p.random(0, 400)] for i in [0...8])
            chatbox = new ConsoleWindow(625, 400, 150, 15, 12, _.sample(randomColors), 10, bigStr)
            chatbox2 = new ConsoleWindow(25, 400, 550, 15, 12, _.sample(randomColors), 20, bigStr)
            lastMillis = p.millis()
        
        p.draw = ->
            newMillis = p.millis()
            deltaTime = (newMillis - lastMillis) / 1000;
            p.background(0)
            chatbox.update(deltaTime)
            chatbox.draw()
            chatbox2.update(deltaTime)
            chatbox2.draw()
            for [g, [x, y]] in _.zip(myGreebles, positions)
                g.update(deltaTime)
                styleScope(=>
                    p.translate(x, y)
                    g.draw()
                )
            lastMillis = newMillis
        
        p.mouseClicked = ->
            myGreebles = ((_.sample(stuff))() for i in [0...8])
            positions = ([p.random(0, 800), p.random(0, 400)] for i in [0...8])
    )
    """

styleScope = (f) ->
    p.pushStyle()
    f()
    p.popStyle()

randomColors = [0xFF00FF00, 0xFF00FFFFF, 0xFFEEEEEE]

class ConsoleWindow
    constructor: (@x, @y, @width, @numLinesChat, @fontSize, @fontColor, speed, string) ->
        @tickLength = 1/speed
        @untilNextTick = @tickLength
        @indexLine = 0
        @indexChar = 0
        @completed = false
        @lines = string.split("\n")
        @lineArrays = (@intoChunks(l) for l in @lines)
    
    update: (dt) ->
        unless @completed
            @untilNextTick -= dt
            if @untilNextTick < 0
                @typeChar()
                @untilNextTick = @tickLength
        
    typeChar: ->
        ++@indexChar
        if @indexChar >= @lines[@indexLine].length
            ++@indexLine
            if @indexLine >= @lines.length
                @completed = true
            @indexChar = 0
    
    draw: ->
        styleScope(=>
            p.textSize(@fontSize)
            p.fill(@fontColor)
            p.text(_(_(@lineArrays[0...@indexLine]).flatten(true)).last(@numLinesChat).join("\n"), @x, @y, @width, @numLinesChat * @fontSize)
            p.textAlign(p.RIGHT)
            p.text(_((@lines[@indexLine].slice(i, @indexChar) for i in [0...@indexChar])).find((sl) => p.textWidth(sl) < @width), @x, @y + @numLinesChat * @fontSize, @width, @fontSize)
        )
    
    intoChunks: (s) ->
        if s.length == 0
            []
        else
            head = _(s.slice(0, i) for i in [s.length...0]).find((h) => p.textWidth(h) < @width)
            [head].concat(@intoChunks(s.slice(head.length)))

class RandomPixels
    constructor: (@x, @y, @w, @h, @tile, @spacing, @fill) ->
        @intensities = (p.random(1) for i in [0...@w * @h])
        @brightenSpeeds = (p.random(-1, 1) for i in [0...@w * @h])
    
    update: (dt) ->
        [@intensities, @brightenSpeeds] = _.zip.apply(_, (
            (ni = i + s * dt
            if ni < 0
                [0, -s]
            else if ni > 1
                [1, -s]
            else
                [ni, s]
            ) for [i, s] in _.zip(@intensities, @brightenSpeeds)
        ))
    
    draw: ->
        styleScope(=>
            for i in [0...@w]
                for j in [0...@h]
                    (=>
                        intense = @intensities[i + j * @w]
                        p.fill(p.red(@fill) * intense, p.green(@fill) * intense, p.blue(@fill) * intense)
                        p.rect(@x + i * (@tile + @spacing), @y + j * (@tile + @spacing), @tile, @tile)
                    )()
        )
    
    width: ->
        @tile * (@w + @spacing) - @spacing
    
    height: ->
        @tile * (@h + @spacing) - @spacing

randomRandomPixels = ->
    new RandomPixels(0, 0, 10, 10, 10, 1, _.sample(randomColors))

class BarGraph
    constructor: (@llx, @lly, @maxHeight, @spacing, @barWidths, @fill) ->
        @barHeights = (p.random(0, @maxHeight) for x in @barWidths)
        @speeds = (p.random(50, 100) * _.sample([1, -1]) for x in @barWidths)
        @goals = (if s > 0 then p.random(w, @maxHeight) else p.random(0, w) for [w, s] in _.zip(@barWidths, @speeds))
    
    update: (dt) ->
        variable = false
        @barHeights = (h + s * dt for [h, s] in _.zip(@barHeights, @speeds))
        [@speeds, @goals] = _.zip.apply(_, (
            (if (s > 0) and (h > g)
                [p.random(-100, -50), p.random(0, h)]
            else if (s < 0) and (h < g)
                [p.random(50, 100), p.random(h, @maxHeight)]
            else
                [s, g]
            ) for [h, g, s] in _.zip(@barHeights, @goals, @speeds)
        ))
    
    draw: ->
        styleScope(=>
            p.fill(@fill)
            left = @llx
            for [w, h] in _.zip(@barWidths, @barHeights)
                p.rect(left, @lly - h, w, h)
                left += w + @spacing
        )
    
    width: ->
        _(@barWidths).reduce((a, b) => a + b) + @spacing * (@barWidths.length - 1)
    
    height: ->
        @maxHeight

randomBarGraph = ->
    new BarGraph(0, 0, 100, 5, (10 for i in [0...10]), _.sample(randomColors))

class RotatingPolygon
    constructor: (@x, @y, @minRadius, @maxRadius, @rotSpd, @sizeSpds, @radii, @angles, @stroke, @fill) ->
    
    update: (dt) ->
        [@radii, @sizeSpds] = _.zip.apply(_, _(_.zip(@radii, @sizeSpds)).map(([r, s]) =>
            nr = p.constrain(r + s * dt, @minRadius, @maxRadius)
            [nr, if (nr >= @maxRadius or nr <= @minRadius) then -s else s]
        ))
        @angles = (a + @rotSpd * dt for a in @angles)
        [@sizeSpds, @radii, @angles] = _.zip.apply(_, _(_.zip(@sizeSpds, @radii, (a % p.TWO_PI for a in @angles))).sortBy(([s, r, a]) => a))
    
    draw: ->
        styleScope(=>
            if @stroke? then p.stroke(@stroke) else p.noStroke()
            if @fill? then p.fill(@fill) else p.noFill()
            p.beginShape()
            _(_.zip(@radii, @angles)).each(([r, a]) =>
                p.vertex(@x + r * p.cos(a), @y + r * p.sin(a))
            )
            p.endShape(p.CLOSE)
        )
    
    addVertex: (ang, sizeSpd) ->
        angle = ang % p.TWO_PI
        index = (a for a in @angles when a < angle).length
        len = @angles.length
        @radii[index...index] =
            if index == 0
                [p.map(angle, @angles[len - 1] - p.TWO_PI, @angles[0], @radii[len - 1], @radii[0])]
            else if index == len
                [p.map(angle, @angles[len - 1], @angles[0] + p.TWO_PI, @radii[len - 1], @radii[0])]
            else
                [p.map(angle, @angles[index - 1], @angles[index] , @radii[index - 1], @radii[index])]
        @angles[index...index] = [angle]
        @sizeSpds[index...index] = [sizeSpd]
    
    width: ->
        2 * @maxRadius
    
    height: ->
        2 * @maxRadius

randomRotatingPolygon = ->
    [stroke, fill] = _.sample([[null, _.sample(randomColors)], [_.sample(randomColors), null]])
    new RotatingPolygon(0, 0, 25, 100, p.random(-1, 1), (p.random(-20, 20) for i in [0...6]), (p.random(25, 100) for i in [0...6]), (i * p.TWO_PI / 6 for i in [0...6]), stroke, fill)
    
class RotatingConcentricCircle
    constructor: (@initAngle, @arcAngle, @radius, @thickness, @rate, @fill) ->
    
    update: (dt, cx, cy) ->
        @initAngle += @rate * dt
    
    draw: (cx, cy) ->
        styleScope(=>
            p.fill(@fill)
            p.arc(cx, cy, @radius + @thickness, @radius + @thickness, @initAngle, @initAngle + @arcAngle)
        )
        styleScope(=>
            p.arc(cx, cy, @radius, @radius, @initAngle, @initAngle + @arcAngle)
        )

randomRotatingConcentricCircle = (rad) ->
    new RotatingConcentricCircle(p.random(0, p.TWO_PI), p.random(0, p.TWO_PI), rad, p.random(10, 20), p.random(-1, 1), _.sample(randomColors))

class RotatingConcentricCircles
    constructor: (@x, @y, arcs, @background) ->
        @arcs = _(arcs).sortBy((a) -> -a.radius)
    
    update: (dt) ->
        for a in @arcs
            a.update(dt, @x, @y)
    
    draw: ->
        styleScope(=>
            p.noStroke()
            p.fill(@background)
            for a in @arcs
                a.draw(@x, @y)
        )
    
    width: ->
        _.max(a.radius for a in @arcs) * 2
    
    height: ->
        _.max(a.radius for a in @arcs) * 2

randomRotatingConcentricCircles = ->
    rad = 20
    arcs = []
    for i in [0...8]
        randArc = randomRotatingConcentricCircle(rad)
        arcs.push(randArc)
        rad += randArc.thickness + 2
    new RotatingConcentricCircles(0, 0, arcs, 0xFF000000)

class InfoPanel
    constructor: (@llx, @lly, @greebles) ->
    
    update: (dt) ->
        for g in @greebles
            g.update(dt)
    
    draw: ->
        styleScope(=>
            currX = @llx
            for g in @greebles
                styleScope(=>
                    g.translate(currX, @lly - g.height())
                    g.draw()
                )
                currX += g.width()
        )

p = undefined

new Processing(document.getElementById("canvas"), (processing) ->
    stuff = [randomRandomPixels, randomBarGraph, randomRotatingPolygon, randomRotatingConcentricCircles]
    myGreebles = undefined
    positions = undefined
    lastMillis = undefined
    chatbox = undefined
    chatbox2 = undefined
    
    p = processing
    
    p.setup = ->
        p.size(800, 600)
        myGreebles = ((_.sample(stuff))() for i in [0...8])
        positions = ([p.random(0, 800), p.random(0, 400)] for i in [0...8])
        chatbox = new ConsoleWindow(625, 400, 150, 15, 12, _.sample(randomColors), 10, bigStr)
        chatbox2 = new ConsoleWindow(25, 400, 550, 15, 12, _.sample(randomColors), 20, bigStr)
        lastMillis = p.millis()
    
    p.draw = ->
        newMillis = p.millis()
        deltaTime = (newMillis - lastMillis) / 1000;
        p.background(0)
        chatbox.update(deltaTime)
        chatbox.draw()
        chatbox2.update(deltaTime)
        chatbox2.draw()
        for [g, [x, y]] in _.zip(myGreebles, positions)
            g.update(deltaTime)
            styleScope(=>
                p.translate(x, y)
                g.draw()
            )
        lastMillis = newMillis
    
    p.mouseClicked = ->
        myGreebles = ((_.sample(stuff))() for i in [0...8])
        positions = ([p.random(0, 800), p.random(0, 400)] for i in [0...8])
)
