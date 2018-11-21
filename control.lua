local Event = require('lib/event')
Event.protected_mode = true

require('lib/area')
require('lib/position')

require('lib/player').register_events(true)

--(( Load Scripts ))--
require('scripts/belt-highlight')
--require('scripts/beltbrush')
--require('scripts/beltreverser')
--)) Load Scripts ((--
