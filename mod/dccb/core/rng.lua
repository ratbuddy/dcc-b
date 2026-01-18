-- /mod/dccb/core/rng.lua
-- Deterministic RNG system for DCC-Barony mod
-- Provides named streams derived from a base seed for reproducible randomness
-- Never uses global math.random directly

local rng = {}

-- Stream seed derivation:
-- Each named stream gets its own independent seed computed as:
--   stream_seed = base_seed + stable_hash(stream_name)
-- This ensures:
--   1. Same base seed + stream name always produces same sequence
--   2. Different stream names produce different sequences
--   3. Streams don't interfere with each other

-- Simple stable string-to-integer hash function
-- Uses a basic polynomial rolling hash for determinism across Lua versions
-- @param str string - the string to hash
-- @return number - a positive integer hash value
local function stable_hash(str)
  local hash = 0
  local prime = 31
  for i = 1, #str do
    hash = (hash * prime + string.byte(str, i)) % 2147483647
  end
  return hash
end

-- LCG (Linear Congruential Generator) parameters
-- Using values from Numerical Recipes
-- These provide a full-period generator with good statistical properties
local LCG_A = 1664525
local LCG_C = 1013904223
local LCG_M = 2^32

-- Stream object constructor
-- @param seed number - the seed for this stream
-- @return table - a stream object with next() and next_int() methods
local function create_stream(seed)
  local stream = {}
  stream.state = seed % LCG_M
  
  -- Generate next random float in range [0, 1)
  -- @return number - random float
  function stream:next()
    self.state = (LCG_A * self.state + LCG_C) % LCG_M
    return self.state / LCG_M
  end
  
  -- Generate random integer in range [min, max] (inclusive)
  -- @param min number - minimum value
  -- @param max number - maximum value
  -- @return number - random integer
  function stream:next_int(min, max)
    if min > max then
      error("RNG next_int: min must be <= max")
    end
    local range = max - min + 1
    return min + math.floor(self:next() * range)
  end
  
  return stream
end

-- RNG object constructor
-- @param base_seed number - the base seed for all streams
-- @return table - RNG object with stream() method
function rng.new(base_seed)
  local rng_obj = {}
  rng_obj.base_seed = base_seed or 0
  rng_obj.streams = {}
  
  -- Get or create a named stream
  -- @param name string - the stream name
  -- @return table - a stream object
  function rng_obj:stream(name)
    if not self.streams[name] then
      -- Derive stream seed from base seed + hash of name
      local stream_seed = (self.base_seed + stable_hash(name)) % LCG_M
      self.streams[name] = create_stream(stream_seed)
    end
    return self.streams[name]
  end
  
  return rng_obj
end

-- Debug test helper function
-- Creates an RNG with the given seed and tests region/floor streams
-- Logs the first 3 values from each stream via log.lua
-- NOT auto-run; intended to be called from bootstrap or tests
-- @param seed number - the test seed to use
function rng.debug_test(seed)
  -- Lazy load log to avoid circular dependency issues
  local log = require("mod.dccb.core.log")
  
  log.info("=== RNG Debug Test ===")
  log.info("Base seed:", seed)
  
  local test_rng = rng.new(seed)
  
  -- Test region stream
  log.info("Region stream (first 3 values):")
  local region_stream = test_rng:stream("region")
  for i = 1, 3 do
    log.info("  region[" .. i .. "]:", region_stream:next())
  end
  
  -- Test floor stream
  log.info("Floor stream (first 3 values):")
  local floor_stream = test_rng:stream("floor")
  for i = 1, 3 do
    log.info("  floor[" .. i .. "]:", floor_stream:next())
  end
  
  -- Test next_int
  log.info("Region stream next_int(1, 10):", region_stream:next_int(1, 10))
  log.info("Floor stream next_int(100, 200):", floor_stream:next_int(100, 200))
  
  log.info("=== RNG Debug Test Complete ===")
end

return rng
