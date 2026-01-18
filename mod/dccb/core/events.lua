-- /mod/dccb/core/events.lua
-- Central event bus for DCC-Barony mod
-- This is the ONLY path for cross-system communication
-- Provides decoupled publish/subscribe system for all modules
-- All cross-system communication MUST go through this event bus

local log = require("mod.dccb.core.log")

local Events = {}

-- Private: registry of event handlers
-- Structure: { [event_name] = { handler_fn, ... }, ... }
local handlers = {}

-- Private: maximum telemetry event buffer size
local MAX_TELEMETRY_EVENTS = 100

-- Private: cached State module reference (loaded lazily)
local State = nil
local state_load_attempted = false

-- Subscribe to an event
-- Handlers are called in registration order
-- @param event_name string - the event to listen for
-- @param handler_fn function - callback to invoke when event is emitted
function Events.on(event_name, handler_fn)
  if type(event_name) ~= "string" then
    log.error("Events.on: event_name must be a string, got:", type(event_name))
    return
  end
  
  if type(handler_fn) ~= "function" then
    log.error("Events.on: handler_fn must be a function, got:", type(handler_fn))
    return
  end
  
  if not handlers[event_name] then
    handlers[event_name] = {}
  end
  
  table.insert(handlers[event_name], handler_fn)
  log.debug("Events.on: registered handler for", event_name, "(count:", #handlers[event_name], ")")
end

-- Unsubscribe from an event
-- Removes the specific handler function from the event
-- @param event_name string - the event to stop listening for
-- @param handler_fn function - the specific handler to remove
function Events.off(event_name, handler_fn)
  if type(event_name) ~= "string" then
    log.error("Events.off: event_name must be a string, got:", type(event_name))
    return
  end
  
  if type(handler_fn) ~= "function" then
    log.error("Events.off: handler_fn must be a function, got:", type(handler_fn))
    return
  end
  
  local event_handlers = handlers[event_name]
  if not event_handlers then
    log.debug("Events.off: no handlers registered for", event_name)
    return
  end
  
  -- Find and remove the handler
  for i = #event_handlers, 1, -1 do
    if event_handlers[i] == handler_fn then
      table.remove(event_handlers, i)
      log.debug("Events.off: removed handler for", event_name, "(remaining:", #event_handlers, ")")
      return
    end
  end
  
  log.debug("Events.off: handler not found for", event_name)
end

-- Emit an event to all registered handlers
-- Normalizes payload, calls handlers in order, catches and logs errors
-- @param event_name string - the event being emitted
-- @param payload table - event data (will be normalized)
function Events.emit(event_name, payload)
  if type(event_name) ~= "string" then
    log.error("Events.emit: event_name must be a string, got:", type(event_name))
    return
  end
  
  -- Normalize payload
  payload = payload or {}
  if type(payload) ~= "table" then
    log.debug("Events.emit: payload should be a table, got:", type(payload), "- wrapping it")
    payload = { value = payload }
  end
  
  -- Add timestamp if missing
  if not payload.ts then
    payload.ts = os.time()
  end
  
  -- Add event_id if missing
  if not payload.event_id then
    payload.event_id = event_name
  end
  
  log.debug("Events.emit:", event_name)
  
  -- Record to telemetry if State is available
  -- Lazy load State module on first use
  if not state_load_attempted then
    local ok, loaded_state = pcall(require, "mod.dccb.core.state")
    if ok then
      State = loaded_state
    end
    state_load_attempted = true
  end
  
  if State and State.get then
    local state_ok, state = pcall(State.get)
    if state_ok and state and state.telemetry and state.telemetry.events then
      -- Add event to telemetry buffer
      table.insert(state.telemetry.events, {
        event_name = event_name,
        payload = payload,
        ts = payload.ts
      })
      
      -- Keep buffer bounded - remove oldest if exceeds max
      while #state.telemetry.events > MAX_TELEMETRY_EVENTS do
        table.remove(state.telemetry.events, 1)
      end
    end
  end
  
  -- Call all handlers in registration order
  local event_handlers = handlers[event_name]
  if not event_handlers or #event_handlers == 0 then
    log.debug("Events.emit: no handlers for", event_name)
    return
  end
  
  for i, handler in ipairs(event_handlers) do
    -- Call handler in protected mode to catch errors
    local success, err = pcall(handler, payload)
    if not success then
      log.error("Events.emit: handler", i, "for", event_name, "failed:", tostring(err))
      -- Continue to next handler - don't break the chain
    end
  end
end

-- Phase-1 event constants (convenience exports)
Events.RUN_START = "RUN_START"
Events.FLOOR_START = "FLOOR_START"
Events.FLOOR_END = "FLOOR_END"
Events.SPAWN_REQUEST = "SPAWN_REQUEST"
Events.SPAWN_FINALIZED = "SPAWN_FINALIZED"
Events.REWARD_OPEN = "REWARD_OPEN"
Events.CONTESTANT_DIED = "CONTESTANT_DIED"
Events.PLAYER_DIED = "PLAYER_DIED"

return Events
