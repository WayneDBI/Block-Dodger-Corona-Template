------------------------------------------------------------------------------------------------------------------------------------
-- RED BIT ESCAPE Corona SDK Template
------------------------------------------------------------------------------------------------------------------------------------
-- Developed by Deep Blue Apps.com [www.deepbueapps.com]
------------------------------------------------------------------------------------------------------------------------------------
-- Abstract: Avoid the blue enemies. Stay alive as long as possible
------------------------------------------------------------------------------------------------------------------------------------
-- Release Version 1.0
-- Code developed for CORONA SDK STABLE RELEASE 2014.2189
-- 12th March 2014
------------------------------------------------------------------------------------------------------------------------------------
-- main.lua
------------------------------------------------------------------------------------------------------------------------------------

display.setStatusBar( display.HiddenStatusBar )

-- require controller module
local composer 						= require "composer"
local physics 						= require( "physics" )
local myGlobalData 					= require( "globalData" )
local loadsave 						= require( "loadsave" ) -- Require our external Load/Save module

scaleFactor = 0.5

myGlobalData._w 					= display.contentWidth  		-- Get the devices Width
myGlobalData._h 					= display.contentHeight 		-- Get the devices Height

myGlobalData.imagePath				= "_Assets/Images/"
myGlobalData.audioPath				= "_Assets/Audio/"

myGlobalData.levelReset				= false							-- We use this flag to help reset the level..
myGlobalData.levelFailed			= false							-- We use this flag to indicate the user has failed a level..

myGlobalData.endGame				= false							-- is the game at an end?

myGlobalData.iPhone5				= false							-- Which device	

myGlobalData.volumeSFX				= 0.7							-- Define the SFX Volume
myGlobalData.volumeMusic			= 0.5							-- Define the Music Volume
myGlobalData.resetVolumeSFX			= myGlobalData.volumeSFX		-- Define the SFX Volume Reset Value
myGlobalData.resetVolumeMusic		= myGlobalData.volumeMusic		-- Define the Music Volume Reset Value
myGlobalData.soundON				= true							-- Is the sound ON or Off?
myGlobalData.musicON				= true							-- Is the sound ON or Off?

myGlobalData.factorX				= 0.4166	--2.400
myGlobalData.factorY				= 0.46875	--2.133


-- Enable debug by setting to [true] to see FPS and Memory usage.
local doDebug 						= false						-- show the Memory and FPS box?

_G.saveDataTable		= {}							-- Define the Save/Load base Table to hold our data

composer.purgeOnSceneChange = true

-- Load in the saved data to our game table
-- check the files exists before !
if loadsave.fileExists("dba_rbe_template_data.json", system.DocumentsDirectory) then
	saveDataTable = loadsave.loadTable("dba_rbe_template_data.json")
else
	saveDataTable.highScore 			= 0
	-- Save the NEW json file, for referencing later..
	loadsave.saveTable(saveDataTable, "dba_rbe_template_data.json")
end

--Now load in the Data
saveDataTable = loadsave.loadTable("dba_rbe_template_data.json")

myGlobalData.highScore				= saveDataTable.highScore		-- Saved HighScore value
myGlobalData.gameScore				= 0								-- Set the Starting value of the score to ZERO ( 0 )
myGlobalData.resetScore				= 0								-- Used when a user RESETS a level, so we keep the correct score.

if system.getInfo("model") == "iPad" or system.getInfo("model") == "iPad Simulator" then
	myGlobalData.iPhone5	= false
	myGlobalData.iPad		= true
elseif display.pixelHeight > 960 then
	myGlobalData.iPhone5	= true
	myGlobalData.iPad		= false
end

-- Debug Data
if (doDebug) then
	local fps = require("fps")
	local performance = fps.PerformanceOutput.new();
	performance.group.x, performance.group.y = (display.contentWidth/2)-40,  380;
	performance.alpha = 0.3; -- So it doesn't get in the way of the rest of the scene
end



function startGame()
	composer.gotoScene( "screenReset")	--This is our start screen
end


--Start Game after a short delay.
timer.performWithDelay(5, startGame )

