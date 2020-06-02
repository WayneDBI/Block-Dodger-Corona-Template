------------------------------------------------------------------------------------------------------------------------------------
-- screenStart.lua
------------------------------------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------
-- Load external modules as required.
---------------------------------------------------------------------------------
---------------------------------------------------------------
-- Require all of the external modules for this level
---------------------------------------------------------------
local ui                 = require("ui")
local widget             = require("widget")
local myGlobalData       = require("globalData")
local loadsave           = require("loadsave")
local composer           = require( "composer" )
local scene              = composer.newScene()

---------------------------------------------------------------
-- Define our SCENE variables and sprite object variables
---------------------------------------------------------------
local changeTheScene     = false
local buttonGroup        = display.newGroup()
local gameAreaGroup      = display.newGroup()

local wallThickness      = 7
local distanceFromEdge   = 10
local maxSquareSize      = myGlobalData._w - distanceFromEdge
local innerWallDistance  = 40
local maxInnerSquareSize = maxSquareSize - innerWallDistance
local inset              = 70

local enemySize          = 30
local enemyMoveSpeed     = 250
local enemySpawnTable    = {}

local playerSize         = 30
local player
local scoreDisplay
local score              = 0
local scoreTimertimer

local timeLimit          = 3
local debounce

local gameOver           = false

local gameOverText
local restartText

-- create table
local stars              = {}
 
-- initial vars
local stars_total        = 60
local stars_field1       = 200
local stars_field2       = 200
local stars_field3       = 600
local star_radius_min    = 1
local star_radius_max    = 2

local checkVelocityTimer
math.randomseed( os.time() )

------------------------------------------------------------------------------------------------------------------------------------
-- Setup the Physics World
------------------------------------------------------------------------------------------------------------------------------------
physics.start()
physics.setScale( 12 )
physics.setGravity( 0, 0 )
physics.setPositionIterations(128)

------------------------------------------------------------------------------------------------------------------------------------
-- un-comment to see the Physics world over the top of the Sprites
------------------------------------------------------------------------------------------------------------------------------------
--physics.setDrawMode( "hybrid" )



---------------------------------------------------------------------------------
-- Scene setup
-- "scene:create()"
---------------------------------------------------------------------------------
function scene:create( event )

    local sceneGroup = self.view

    -- Remove any previous Composer Scenes
    composer.removeScene( "screenReset" )

    -- Initialize the scene here
    -- Example: add display objects to "sceneGroup", add touch listeners, etc.

    display.setDefault( "anchorX", 0.5 )
	display.setDefault( "anchorY", 0.5 )
	
	print("Main Game Scene..Loaded")
	
	local WallFilterData = { categoryBits = 1, maskBits = 6 }
	local PlayerFilterData = { categoryBits = 2, maskBits = 5 }
	local EnemyFilterData = { categoryBits = 4, maskBits = 3 }

	-----------------------------------------------------------------
	-- Add Score
	-----------------------------------------------------------------
	scoreDisplay = display.newText("Score: "..score,0,0, "HelveticaNeue-CondensedBlack", 22)
	scoreDisplay:setFillColor(1,1,1)
	scoreDisplay.x = myGlobalData._w/2
	scoreDisplay.y = 40
	scoreDisplay.alpha = 1
	sceneGroup:insert( scoreDisplay )
	
	-----------------------------------------------------------------
	-- Add the Walls
	-----------------------------------------------------------------
	local function addwall(x ,y, sizeX, sizeY, Colour)
		local wallMaterial = { density=100.0, friction=0.0, bounce=1, filter=WallFilterData }
		local wall = display.newRect( 0,0, sizeX, sizeY )
		wall.x = x; wall.y = y
		if(Colour=="Blue")then
			wall:setFillColor(0.15,0.26,0.62)--blue
			wall.myName = "innerWall"
		else
			wall:setFillColor(0.7,0.2,0.1)--red
			wall.myName = "outerWall"
		end		
		physics.addBody( wall, "static", wallMaterial )
		gameAreaGroup:insert( wall )
		
	end

	--add OUTER Red Walls
	addwall(distanceFromEdge, myGlobalData._h/2, wallThickness, myGlobalData._h - (inset * 2), "Red"  ) --Left
	addwall(maxSquareSize, myGlobalData._h/2, wallThickness, myGlobalData._h - (inset * 2), "Red"  ) --Right
	addwall(myGlobalData._w/2, myGlobalData._h-inset, maxSquareSize-3, wallThickness, "Red"  ) --Bottom
	addwall(myGlobalData._w/2, inset, maxSquareSize-3, wallThickness, "Red"  ) --Top

	--add INNER Blue Walls
	addwall(innerWallDistance-distanceFromEdge, myGlobalData._h/2, wallThickness, myGlobalData._h - (inset * 2)-40, "Blue"  ) --Left
	addwall(maxSquareSize-(innerWallDistance/2), myGlobalData._h/2, wallThickness, myGlobalData._h - (inset * 2)-40, "Blue"  ) --Right
	addwall(myGlobalData._w/2, myGlobalData._h-inset-20, maxInnerSquareSize-3, wallThickness, "Blue"  ) --Bottom
	addwall(myGlobalData._w/2, inset+20, maxInnerSquareSize-3, wallThickness, "Blue"  ) --Top

	-----------------------------------------------------------------
	--Add the player to the screen
	-----------------------------------------------------------------
	player = display.newRect( 0,0, playerSize,playerSize )
	player:setFillColor(0.7,0.2,0.1, 0.4)--red
	player:setStrokeColor(1,1,1, 0.7)--white
	player.strokeWidth = 1
	player.myName = "Player"
	local playerMaterial = { density=100.0, friction=0.1, bounce=0.0, filter=PlayerFilterData }
	player.x = myGlobalData._w/2
	player.y = myGlobalData._h/2
	physics.addBody( player, "dynamic", playerMaterial )
	player.gravityScale = 0.0
	player.isSleepingAllowed = false
	player.isFixedRotation = true
	player.isBullet = true
	player.isSensor = true
	gameAreaGroup:insert(player)
	player:addEventListener( "touch", onTouch )

	-----------------------------------------------------------------
	--Add 4 x enemies to the screen
	-----------------------------------------------------------------
	local function spawnEnemy(params)
		local object = display.newRect( 0,0, enemySize,enemySize )
		object:setFillColor(0.2,0.6,0.8, 0.4)--blue
		object:setStrokeColor(1,1,1, 0.5)--white
		object.strokeWidth = 1
		
		object.objTable = params.objTable
		object.index = #object.objTable + 1
		object.myName = "Enemy"
		
		local enemyMaterial = { density=100.0, friction=0.1, bounce=0.0, filter=EnemyFilterData }
		object.x = params.startX
		object.y = params.startY
		physics.addBody( object, "dynamic", enemyMaterial )
		object.gravityScale = 0.0
		object.isSleepingAllowed = false
		object.linearDamping = 0
		object.isFixedRotation = true
		object.isBullet = true
		gameAreaGroup:insert(object)

		object.objTable[object.index] = object

		return object
	end

	-----------------------------------------------------------------
	--Create 4 Enemies
	-----------------------------------------------------------------
	local spawns = spawnEnemy( { startX = innerWallDistance+(enemySize-distanceFromEdge), startY = myGlobalData._h/2-(maxInnerSquareSize/2)+enemySize, objTable = enemySpawnTable, } ) --Top Left Enemy
	local spawns = spawnEnemy( { startX = maxSquareSize-(innerWallDistance/2)-enemySize, startY = myGlobalData._h/2-(maxInnerSquareSize/2)+enemySize, objTable = enemySpawnTable, } ) --Top Right Enemy
	local spawns = spawnEnemy( { startX = innerWallDistance+(enemySize-distanceFromEdge), startY = myGlobalData._h/2+(maxInnerSquareSize/2)-enemySize, objTable = enemySpawnTable, } ) --Bottom Left Enemy
	local spawns = spawnEnemy( { startX = maxSquareSize-(innerWallDistance/2)-enemySize, startY = myGlobalData._h/2+(maxInnerSquareSize/2)-enemySize, objTable = enemySpawnTable, } ) --Bottom Right Enemy


	-----------------------------------------------------------------
	-- GameOver Text (Hidden until needed)
	-----------------------------------------------------------------
	gameOverText = display.newText("GAME OVER",0,0, "HelveticaNeue-CondensedBlack", 44)
	gameOverText:setFillColor(0.5,1,0.7)
	gameOverText.x = myGlobalData._w/2
	gameOverText.y = -2000 --myGlobalData._h/2
	gameOverText.alpha = 1
	gameAreaGroup:insert( gameOverText )

	
	restartText = display.newText("Restart Game",0,0, "HelveticaNeue-CondensedBlack", 36)
	restartText:setFillColor(0.5,1,0.7)
	restartText.x = myGlobalData._w/2
	restartText.y = -2000 --myGlobalData._h/2
	restartText.alpha = 1
	restartText:addEventListener( "touch", restartTouched )
	gameAreaGroup:insert( restartText )

	-----------------------------------------------------------------
	--insert the game area into the main scene group
	-----------------------------------------------------------------
	sceneGroup:insert( gameAreaGroup )


	-----------------------------------------------------------------
	--Start the Enemies moving
	-----------------------------------------------------------------		
	local function startMove()
		enemySpawnTable[1]:applyForce(500000,500000,enemySpawnTable[1].x,enemySpawnTable[1].y) -- Top Left Enemy
		enemySpawnTable[2]:applyForce(-500000,500000,enemySpawnTable[2].x,enemySpawnTable[2].y) -- Top Right Enemy
		enemySpawnTable[3]:applyForce(500000,-500000,enemySpawnTable[3].x,enemySpawnTable[3].y) -- Bottom Left Enemy
		enemySpawnTable[4]:applyForce(-500000,-500000,enemySpawnTable[4].x,enemySpawnTable[4].y) -- Bottom Right Enemy
	end

	--local startEnemiesMovingTimer = timer.performWithDelay( 1200, startMove)				
	
	-----------------------------------------------------------------
	--Update the score every 1 second
	-----------------------------------------------------------------		
	local function trackTimeUpdate()   -- RunTime enterFrame event handler
		score = score + 1
	end
	
	
	timeLeft = display.newText(timeLimit, 160, 20, "HelveticaNeue-CondensedBlack", 172)
	timeLeft.alpha = 0.8
	timeLeft.x = myGlobalData._w/2
	timeLeft.y = myGlobalData._h/2
	timeLeft:setTextColor(1,1,1)
	sceneGroup:insert( timeLeft )
	timeLeft.isVisible = true

	local function timerDown()
	   timeLimit = timeLimit-1
	   timeLeft.text = timeLimit
	     if(timeLimit==0)then
	     	timeLeft.y = 10000
	        print("Time Out") -- or do your code for time out
	        
	        local startEnemiesMovingTimer = timer.performWithDelay( 50, startMove)				
			scoreTimertimer = timer.performWithDelay( 1000, trackTimeUpdate,10000)				

	     end
	  end

	debounce = timer.performWithDelay(1000,timerDown,timeLimit)

	
	-- create/draw objects
	for i = 1, stars_total do
	        local star = {} 
	        star.object = display.newCircle(math.random(display.contentWidth),math.random(display.contentHeight),math.random(star_radius_min,star_radius_max))
	        stars[ i ] = star       
			sceneGroup:insert( star.object )
	end
 

end



---------------------------------------------------------------------------------
-- Scene setup
-- "scene:show()"
---------------------------------------------------------------------------------
function scene:show( event )

    local sceneGroup = self.view
    local phase = event.phase


    if ( phase == "will" ) then
        -- Called when the scene is still off screen (but is about to come on screen)

    elseif ( phase == "did" ) then

        ---------------------------------------------------------------------------------
        -- Animate all the scene elements into position
        ---------------------------------------------------------------------------------

        -- Called when the scene is now on screen
        -- Insert code here to make the scene come alive
        -- Example: start timers, begin animation, play audio, etc.

    end
end





---------------------------------------------------------------------------------
-- Function "scene:hide()"
---------------------------------------------------------------------------------
function scene:hide( event )

    local sceneGroup = self.view
    local phase = event.phase

    if ( phase == "will" ) then
        -- Called when the scene is on screen (but is about to go off screen)
        -- Insert code here to "pause" the scene
        -- Example: stop timers, stop animation, stop audio, etc.
    elseif ( phase == "did" ) then
        -- Called immediately after scene goes off screen
    end

end


---------------------------------------------------------------------------------
-- Function "scene:destroy()"
---------------------------------------------------------------------------------
function scene:destroy( event )

    local sceneGroup = self.view

    --Runtime:removeEventListener( "enterFrame", handleEnterFrame)

    -- Called prior to the removal of scene's view
    -- Insert code here to clean up the scene
    -- Example: remove display objects, save state, etc.


    display.remove(scoreDisplay)
	scoreDisplay = nil



end


------------------------------------------------------------------------------------------------------------------------------------
-- Update bg stars
------------------------------------------------------------------------------------------------------------------------------------
function udpdatestars(event)
	for i = stars_total,1, -1 do
		if (i < stars_field1) then
				stars[i].object:setFillColor(0.5,0.5,0.5)
				starspeed = 4
		end
		if (i < stars_field2 and i > stars_field1) then
				stars[i].object:setFillColor(0.7,0.7,0.7)
				starspeed = 5
		end
		if (i < stars_field3 and i > stars_field2) then
				stars[i].object:setFillColor(1,1,1)
				starspeed = 16
		end
		stars[i].object.y  = stars[i].object.y + starspeed      
		if (stars[i].object.y > display.contentHeight) then
				stars[i].object.y = stars[i].object.y-display.contentHeight
		end
	end
end





-----------------------------------------------------------------
-- Restart Text (Hidden until needed) - Button event
-----------------------------------------------------------------
function restartTouched( event )
	if event.phase == "began" then

	elseif event.phase == "ended" then
		--gameOver = false
		--print("Go Reset")
		composer.gotoScene( "screenReset",{time=20})	--This is our start screen
	end

	return true
end


---------------------------------------------------------------------------------------------
--Handle the player touch/move/dragging
---------------------------------------------------------------------------------------------
function onTouch( event )
	local t = event.target
	

	if (gameOver==false) then
		local phase = event.phase
		if "began" == phase then
			-- Make target the top-most object
			local parent = t.parent
			parent:insert( t )
			display.getCurrentStage():setFocus( t )

			t.isFocus = true

			-- Store initial position
			t.x0 = event.x - t.x
			t.y0 = event.y - t.y
		elseif t.isFocus then
			if "moved" == phase then
				t.x = event.x - t.x0
				t.y = event.y - t.y0
			elseif "ended" == phase or "cancelled" == phase then
				display.getCurrentStage():setFocus( nil )
				t.isFocus = false
			end
		end

		return true
	end
end



---------------------------------------------------------------------------------------------
-- Stabalise the Enemies movements & prevent sticking to walls
---------------------------------------------------------------------------------------------
local function resetLinearVelocity(event)
  local thisX, thisY = event:getLinearVelocity()

	local vel = enemyMoveSpeed -- this is the arbitrary speed of player motion.
	local p1Rads = math.random(180)

	local velX = math.cos (p1Rads) * vel 
	local velY = math.sin (p1Rads) * vel

	if thisY == 0 then
	  thisY = -event.lastY
	end
	if thisX == 0 then
	  thisX = -event.lastX
	end
  
	event:setLinearVelocity(velX,velY)
	event.lastX, event.lastY = thisX, thisY

end


---------------------------------------------------------------------------------------------
--Game Collision logic system
---------------------------------------------------------------------------------------------
local function onGlobalCollision( event )

	if ( event.phase == "began" and gameOver==false) then
	
		if (player.x < distanceFromEdge) or (player.x > maxSquareSize) 
		or (player.y < inset) or (player.y > myGlobalData._h-inset) 
		
		then 
	
			gameOver = true
		
		end
		
		if (event.object1.myName == "innerWall" and event.object2.myName == "Enemy" ) then
			checkVelocityTimer = timer.performWithDelay(0, resetLinearVelocity(event.object2))
		end
		if (event.object1.myName == "Enemy" and event.object2.myName == "innerWall" ) then
			checkVelocityTimer = timer.performWithDelay(0, resetLinearVelocity(event.object2))
		end

		---------------------------------------------------------------------------------------------
		--Player hit logic
		---------------------------------------------------------------------------------------------
		if (event.object1.myName == "Enemy" and event.object2.myName == "Player" ) then
				gameOver = true
		end
		if (event.object1.myName == "Player" and event.object2.myName == "Enemy" ) then
				gameOver = true
		end
		if (event.object1.myName == "Player" and event.object2.myName == "outerWall" ) then
				--gameOver = true
		end
		if (event.object1.myName == "outerWall" and event.object2.myName == "Player" ) then
				gameOver = true
		end


	end

end


---------------------------------------------------------------
-- Game Update core
---------------------------------------------------------------
function updateTick(event)

	if(gameOver==true) then
	
		player:removeEventListener( "touch", onTouch )		
		display.remove(player)
		player = nil
		

		--Move the player
		for i = 1, #enemySpawnTable do
			enemySpawnTable[i]:setLinearVelocity(0,0)

		end
		
		 --> Cancel the timer
		if(scoreTimertimer) then
			timer.cancel(scoreTimertimer)
			scoreTimertimer = nil
		end
		
		if(debounce) then
			timer.cancel(debounce)
			debounce = nil
		end
		
		timeLeft.isVisible = false
		
		--Show the Game Over & restart message
		gameOverText.y = myGlobalData._h/2
		restartText.y = myGlobalData._h/2+40

		
	--Cancel events	
	Runtime:removeEventListener( "enterFrame", updateTick )
	Runtime:removeEventListener ( "collision", onGlobalCollision )
	Runtime:removeEventListener("enterFrame",udpdatestars)	

		
	end
	
	if(gameOver==false) then
		display.remove(scoreDisplay)
		scoreDisplay = nil
		scoreDisplay = display.newText("Score: "..score,0,0, "HelveticaNeue-CondensedBlack", 36)
		scoreDisplay:setFillColor(1,1,1)
		scoreDisplay.x = myGlobalData._w/2
		scoreDisplay.y = 40
		scoreDisplay.alpha = 1
	end

end

---------------------------------------------------------------------------------
-- Listener setup
---------------------------------------------------------------------------------
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

---------------------------------------------------------------
-- Add a enterFrame event
---------------------------------------------------------------
Runtime:addEventListener( "enterFrame", updateTick )
Runtime:addEventListener ( "collision", onGlobalCollision )
Runtime:addEventListener("enterFrame",udpdatestars)	

---------------------------------------------------------------------------------
-- Return the Scene
---------------------------------------------------------------------------------
return scene
