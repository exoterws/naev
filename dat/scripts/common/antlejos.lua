--[[

   Antlejos Terraforming Common Functions

--]]
local vn = require "vn"
local mt = require 'merge_tables'

local antlejos = {}

antlejos.verner = {
   portrait = "verner.webp",
   image = "verner.webp",
   name = _("Verner"),
   color = nil,
   transition = nil, -- Use default
}

function antlejos.vn_verner( params )
   return vn.Character.new( antlejos.verner.name,
         mt.merge_tables( {
            image=antlejos.verner.image,
            color=antlejos.verner.colour,
         }, params) )
end

-- Function for adding log entries for miscellaneous one-off missions.
function antlejos.log( text )
   shiplog.create( "antlejos", _("Antlejos V"), _("Neutral") )
   shiplog.append( "antlejos", text )
end

antlejos.unidiff_list = {
   "antlejosv_1",
   "antlejosv_2",
   "antlejosv_3",
   "antlejosv_4",
}

function antlejos.unidiff( diffname )
   for _k,d in ipairs(antlejos.unidiff_list) do
      if diff.isApplied(d) then
         diff.remove(d)
      end
   end
   diff.apply( diffname )
end

function antlejos.dateupdate ()
   var.push( "antlejos_date", time.get() )
end
function antlejos.datecheck ()
   local d = var.peek("antlejos_date")
   return d and d==time.get()
end

--[[
   Gets the Pilots United Against Atmosphere Anthropocentrism (PUAAA) faction or creates it if necessary
--]]
function antlejos.puaaa ()
   local f = faction.exists("puaaa")
   if f then
      return f
   end
   return faction.dynAdd( nil, "puaaa", _("PUAAA"), {clear_allies=true, clear_enemies=true} )
end

antlejos.rewards = {
   ant01 = 200e3,
   ant02 = 350e3,
   ant03 = 500e3,
   ant04 = 500e3,
   ant05 = 700e3,
   ant06 = 300e3, -- Repeatable
}

return antlejos

