local composer = require "composer"

display.setStatusBar(display.HiddenStatusBar)
composer.gotoScene("scenes.game", { params = { levelName = "0001" } })
