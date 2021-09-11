require 'ai.core.core'
local fmt = require "format"

-- We’ll consider the Za'lek prefer to turn a bad (i.e. battle) situation into
-- a profitable one by getting money and selling fuel if possible if the player
-- hasn’t been too hostile in the past.

-- Settings
mem.armour_run    = 75 -- Za'lek armour is pretty crap. They know this, and will dip when their shields go down.
mem.aggressive    = true
mem.whiteknight   = true

local drones = {
   ["Za'lek Heavy Drone"] = true,
   ["Za'lek Bomber Drone"] = true,
   ["Za'lek Light Drone"] = true,
   ["Za'lek Scout Drone"] = true,
}

local bribe_no_list = {
   _([["Keep your cash, you troglodyte."]]),
   _([["Don't make me laugh. Eat laser beam!"]]),
   _([["My drones aren't interested in your ill-gotten gains and neither am I!"]]),
   _([["Ahaha! Nice one! Oh, you're actually serious? Ahahahaha!"]]),
   _([["While I admire the spirit of it, testing my patience is suicide, NOT science."]])
}

local taunt_list_offensive = {
   _("Move drones in to engage. Cook this clown!"),
   _("Say hello to my little friends!"),
   _("Ooh, more victi- ah, volunteers for our experiments!"),
   _("We need a test subject to test our attack on; you'll do nicely!"),
   _("Ready for a physics lesson, punk?"),
   _("After we wax you, we can return to our experiments!")
}
local taunt_list_defensive = {
   _("We're being attacked! Prepare defence protocols!"),
   _("You just made a big mistake!"),
   _("Our technology will fix your attitude!"),
   _("You wanna do this? Have it your way.")
}

function create()
   local p = ai.pilot()
   local ps = p:ship()

   -- See if a drone
   mem.isdrone = drones[ ai.pilot():ship():nameRaw() ]
   if mem.isdrone then
      local msg = _([["Access denied"]])
      mem.refuel_no = msg
      mem.bribe_no = msg
      mem.armour_run = 0 -- Drones don't run
      -- Drones can get indirectly bribed as part of fleets
      mem.bribe = math.sqrt( p:stats().mass ) * (500 * rnd.rnd() + 1750)
      create_post()
      return
   end

   -- Not too many credits.
   ai.setcredits( rnd.rnd( ps:price()/200, ps:price()/50) )

   mem.loiter = 2 -- This is the amount of waypoints the pilot will pass through before leaving the system

   -- Set how far they attack
   mem.enemyclose = 3000 + 1000 * ps:size()
   mem.formation = "circle"

   -- Finish up creation
   create_post()
end

function hail ()
   local p = ai.pilot()

   -- Remove randomness from future calls
   if not mem.hailsetup then
      mem.refuel_base = rnd.rnd( 2000, 4000 )
      mem.bribe_base = math.sqrt( p:stats().mass ) * (500 * rnd.rnd() + 1750)
      mem.bribe_rng = rnd.rnd()
      mem.hailsetup = true
   end

   -- Clean up
   mem.refuel        = 0
   mem.refuel_msg    = nil
   mem.bribe         = 0
   mem.bribe_prompt  = nil
   mem.bribe_prompt_nearby = nil
   mem.bribe_paid    = nil
   mem.bribe_no      = nil

   -- Deal with refueling
   local standing = p:faction():playerStanding()
   mem.refuel = mem.refuel_base
   if standing < -10 then
      mem.refuel_no = _([["I do not have fuel to spare."]])
   else
      mem.refuel = mem.refuel * 0.6
   end
   -- Most likely no chance to refuel
   mem.refuel_msg = string.format( _([["I will agree to refuel your ship for %s."]]), fmt.credits(mem.refuel) )

   -- See if can be bribed
   mem.bribe = mem.bribe_base
   if (mem.natural or mem.allowbribe) and (standing > 0 or
         (standing > -20 and mem.bribe_rng > 0.8) or
         (standing > -50 and mem.bribe_rng > 0.6) or
         (rnd.rnd() > 0.4)) then
      mem.bribe_prompt = string.format(_([["We will agree to end the battle for %s."]]), fmt.credits(mem.bribe) )
      mem.bribe_paid = _([["Temporarily stopping fire."]])
   else
      mem.bribe_no = bribe_no_list[ rnd.rnd(1,#bribe_no_list) ]
   end
end

function taunt ( target, offense )
   -- Only 50% of actually taunting.
   if rnd.rnd(0,1) == 0 and not mem.isdrone then
      return
   end

   local taunts
   if offense then
      taunts = taunt_list_offensive
   else
      taunts = taunt_list_defensive
   end

   ai.pilot():comm(target, taunts[ rnd.rnd(1,#taunts) ])
end


