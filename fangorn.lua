local forest = {}
forest.mt = {__index = forest}

function forest.new()
  return setmetatable({
    ents = {},
    branches = {},
    _nextbit = 0,
    _ent_set = {},
    _dead = {},
    _ent_masks = {},
  }, forest.mt)
end

function forest:definebranch(name, requires, default)
  assert(self._nextbit <= 31)
  assert(not self.branches[name])
  local mask = bit.lshift(1, self._nextbit)
  for _, r in ipairs(requires) do
    local b = self.branches[r]
    mask = bit.bor(mask, b.mask)
  end
  self.branches[name] = {
    name = name,
    bit = self._nextbit,
    mask = mask,
    requires = requires or {},
    default = default,
  }
  self._nextbit = self._nextbit + 1
end

function forest:clearents()
  self.ents = {}
  self._ent_masks = {}
  self._ent_set = {}
  self._dead = {}
end

function forest:clearbranches()
  self.branches = {}
  self._nextbit = 0
end

function forest:growent()
  local e = {}
  table.insert(self.ents, e)
  self._ent_set[e] = #self.ents
  self._ent_masks[e] = 0
  return e
end

function forest:killent(ent)
  self._dead[ent] = true
end

function forest:growbranch(ent, name, data)
  local branch = self.branches[name]
  local d = data or (branch and branch.default())
  assert(d, "cannot grow nil")
  for _, r in ipairs(branch.requires) do
    local b = self.branches[r]
    if not ent[b.name] then
      self:growbranch(ent, b.name)
    end
  end
  self._ent_masks[ent] = bit.bor(self._ent_masks[ent], bit.lshift(1, branch.bit))
  ent[branch.name] = ent[branch.name] or d
end

function forest:prune(ent)
  local continue = true
  while continue do
    continue = false
    for bname in pairs(ent) do
      if not self:hasfullbranch(ent, bname) then
        self:trimbranch(ent, bname)
        continue = true
      end
    end
  end
end

function forest:trimbranch(ent, name, prune)
  ent[name] = nil
  local b = self.branches[name]
  self._ent_masks[ent] = bit.band(self._ent_masks[ent], bit.bnot(bit.lshift(1, b.bit)))
  if prune then
    self:prune(ent)
  end
end

function forest:hasfullbranch(ent, name)
  return bit.band(self._ent_masks[ent], self.branches[name].mask) == self.branches[name].mask
end

function forest:isdead(ent)
  return not self._ent_set[ent] or self._dead[ent]
end

function forest:burn(ent)
  self._dead[ent] = nil
  local repl = self.ents[#self.ents]
  self._ent_set[repl] = self._ent_set[ent]
  self.ents[self._ent_set[ent]] = repl
  self._ent_set[ent] = nil
  self._ent_masks[ent] = nil
  self.ents[#self.ents] = nil
end

function forest:iter(branch)
  local idx = #self.ents
  local function n()
    while true do
      if idx < 1 then
        break
      end
      local e = self.ents[idx]
      if self._dead[e] then
        self:burn(e)
        idx = idx - 1
      else
        idx = idx - 1
        if not branch or (branch and self:hasfullbranch(e, branch)) then
          return e
        end
      end
    end
  end
  return n
end

function forest:each(branch, func)
  for idx=#self.ents, 1, -1 do
    local e = self.ents[idx]
    if self._dead[e] then
      self:burn(e)
      idx = idx - 1
    else
      idx = idx - 1
      if not branch or (branch and self:hasfullbranch(e, branch)) then
        func(e)
      end
    end
  end
end

if type(package.loaded[...]) ~= "userdata" then
  local f = forest.new()
  f:definebranch("pos", {}, function() return {x = 0, y = 0} end)
  f:definebranch("vel", {"pos"}, function() return {x = 0, y = 0} end)

  do -- test masks
    local e = f:growent()
    f:growbranch(e, "vel")
    assert(f:hasfullbranch(e, "vel"))
    assert(f:hasfullbranch(e, "pos"))
    assert(e.pos and e.vel)
  end

  do -- test removal
    local e = f:growent()
    f:growbranch(e, "vel")
    f:trimbranch(e, "vel")
    assert(not f:hasfullbranch(e, "vel"))
    assert(f:hasfullbranch(e, "pos"))
    assert(e.pos)
  end

  do -- test prune removal
    local e = f:growent()
    f:growbranch(e, "vel")
    f:trimbranch(e, "pos", true)
    assert(not f:hasfullbranch(e, "vel"))
    assert(not f:hasfullbranch(e, "pos"))
    assert(not e.pos and not e.vel)
  end

  do -- test additions
    assert(#f.ents == 3)
    local count = 0
    for e in f:iter("vel") do
      count = count + 1
    end
    assert(count == 1)
  end

  do -- test clear
    f:clearents()
    assert(#f.ents == 0)
  end
end

return {
  forest = forest,
  _VERSION = 1.0,
  _DESCRIPTION = "Lua ECS inspired by froggy",
  _AUTHOR = "Michael Patraw <michaelpatraw@gmail.com>",
}
