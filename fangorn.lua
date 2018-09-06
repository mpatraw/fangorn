
local Ent = {}
Ent.MT = {__index = Ent}

--- Creates a new entity.
-- @return An Ent.
function Ent.new()
    return setmetatable({
        _data = {},
        _dependents = {},
    }, Ent.MT)
end

--- Grow a Branch on an Ent.
-- This also checks and tries to add any dependencies of the added
-- branch and will add this entity to the Branch's array.
-- @param branch The Branch to grow.
-- @param data Optional data to populate, this must exist
--             or the Branch must have a default generator.
function Ent:grow(branch, data)
    assert(not self._data[branch], "cannot grow, ent already has branch " .. branch.name)
    local d = data or (branch and branch.default())
    assert(d, "cannot grow nil")
    for _, r in ipairs(branch.requires) do
        if not self._data[r] then
            self:grow(r)
        end
        self._dependents[r] = self._dependents[r] + 1
    end
    self._data[branch] = d
    self._dependents[branch] = 0
    branch:_add(self)
end

--- Trim a Branch off an Ent.
-- @param branch The Branch to remove.
-- @param purge Optionally will purge any dependencies of
--              the branch that have no other dependents.
function Ent:trim(branch, purge)
    -- Probably can scan data for ents and kill them.
    assert(self:get(branch), "cannot trim, ent does not have branch")
    for b in pairs(self._data) do
        for _, r in ipairs(b.requires) do
            if r == branch then
                self:trim(b)
                break
            end
        end
    end
    for _, r in ipairs(branch.requires) do
        assert(self._dependents[r], "not dependent on " .. r.name)
        assert(self._dependents[r] > 0, "too many depends off on " .. r.name)
        self._dependents[r] = self._dependents[r] - 1
        if self._dependents[r] == 0 and purge then
            self._data[r] = nil
            self._dependents[r] = nil
            r:_remove(self)
        end
    end
    self._data[branch] = nil
    self._dependents[branch] = nil
    branch:_remove(self)
end

--- Kill an ent.
-- This completely removes all Branches from the Ent.
function Ent:kill()
    local n = next(self._data, nil)
    while n do
        self:trim(n, true)
        n = next(self._data, nil)
    end
end

--- Get data associated with a Branch.
-- @param branch The Branch.
function Ent:get(branch)
    return self._data[branch]
end

--- Set data associated with a Branch.
-- @param branch The Branch.
-- @param to What to set it to. Cannot be nil.
function Ent:set(branch, to)
    assert(to, "cannot set to nil")
    self._data[branch] = to
end

--- Gets a list of branches associated with this Ent.
-- @return A list of Branch objects.
function Ent:branches()
    local branches = {}
    for branch in pairs(self._data) do
        table.insert(branches, branch)
    end
    return branches
end

function Ent:dependents(branch)
    return self._dependents[branch]
end

local Branch = {}
Branch.MT = {__index = Branch}

function Branch.new(name, requires, default)
    return setmetatable({
        name = name,
        requires = requires,
        default = default,
        _ents_array = {},
        _ents = {},
        _to_add = {},
        _to_remove = {}
    }, Branch.MT)
end

function Branch:_add(ent)
    assert(ent:get(self), "cannot add, ent does not have branch " .. self.name)
    if self._to_remove[ent] then
        self._to_remove[ent] = nil
    end
    self._to_add[ent] = true
end

function Branch:_remove(ent)
    if self._to_add[ent] then
        self._to_add[ent] = nil
    end
    self._to_remove[ent] = true
end

function Branch:sync()
    for e in pairs(self._to_add) do
        if not self._ents[e] then
            table.insert(self._ents_array, e)
            self._ents[e] = #self._ents_array
        end
    end
    self._to_add = {}
    for e in pairs(self._to_remove) do
        if self._ents[e] then
            local last = self._ents_array[#self._ents_array]
            self._ents[last] = self._ents[e]
            self._ents_array[self._ents[e]] = last
            self._ents[e] = nil
            table.remove(self._ents_array)
        end
    end
    self._to_remove = {}
end

function Branch:ents(nosync)
    if not nosync then
        self:sync()
    end
    return self._ents_array
end

function Branch:iter(nosync)
    if not nosync then
        self:sync()
    end
    local idx = 0
    local function n()
        idx = idx + 1
        if idx > #self._ents_array then
            return
        end
        local e = self._ents_array[idx]
        return e, e and e:get(self)
    end
    return n
end

if type(package.loaded[...]) ~= "userdata" then
    do -- test no default
        local e = Ent.new()
        local b = Branch.new("b", {})
        assert(not pcall(e.grow, e, b))
        assert(#b:ents() == 0)
        assert(#e:branches() == 0)
        assert(not e:get(b))
    end

    do -- test nil default
        local e = Ent.new()
        local b = Branch.new("b", {}, function() return end)
        assert(not pcall(e.grow, e, b))
        assert(#b:ents() == 0)
        assert(#e:branches() == 0)
        assert(not e:get(b))
    end

    do -- test default
        local e = Ent.new()
        local b = Branch.new("b", {}, function() return {} end)
        e:grow(b)
        assert(#b:ents() == 1)
        assert(#e:branches() == 1)
        assert(e:get(b))
    end

    do -- test adding
        local e = Ent.new()
        local b = Branch.new("b", {})
        e:grow(b, {})
        assert(#b:ents() == 1)
        assert(#e:branches() == 1)
        assert(e:get(b))
    end

    do -- test auto defaults
        local e = Ent.new()
        local b = Branch.new("b", {}, function() return {} end)
        local b2 = Branch.new("b2", {b})
        e:grow(b2, {})
        assert(#b:ents() == 1)
        assert(#b2:ents() == 1)
        assert(#e:branches() == 2)
        assert(e:get(b))
        assert(e:get(b2))
    end

    do -- test auto defaults & auto removal
        local e = Ent.new()
        local b = Branch.new("b", {}, function() return {} end)
        local b2 = Branch.new("b2", {b})
        e:grow(b2, {})
        e:trim(b)
        assert(#b:ents() == 0)
        assert(#b2:ents() == 0)
        assert(#e:branches() == 0)
        assert(not e:get(b))
        assert(not e:get(b2))
    end

    do -- test auto defaults & no purge
        local e = Ent.new()
        local b = Branch.new("b", {}, function() return {} end)
        local b2 = Branch.new("b2", {b})
        e:grow(b2, {})
        e:trim(b2)
        assert(#b:ents() == 1)
        assert(#b2:ents() == 0)
        assert(#e:branches() == 1)
        assert(e:get(b))
        assert(not e:get(b2))
    end

    do -- test auto defaults & purge
        local e = Ent.new()
        local b = Branch.new("b", {}, function() return {} end)
        local b2 = Branch.new("b2", {b})
        e:grow(b2, {})
        e:trim(b2, true)
        assert(#b:ents() == 0)
        assert(#b2:ents() == 0)
        assert(#e:branches() == 0)
        assert(not e:get(b))
        assert(not e:get(b2))
    end

    do -- test kill
        local e = Ent.new()
        local b = Branch.new("b", {}, function() return {} end)
        local b2 = Branch.new("b2", {b}, function() return {} end)
        local b3 = Branch.new("b3", {b, b2})
        e:grow(b3, {})
        e:kill()
        assert(#b:ents() == 0)
        assert(#b2:ents() == 0)
        assert(#b3:ents() == 0)
        assert(#e:branches() == 0)
        assert(not e:get(b))
        assert(not e:get(b2))
        assert(not e:get(b3))
    end

    do -- test complex
        local player = Ent.new()
        local goal = Ent.new()
        local position = Branch.new("position", {}, function() return {x = 0, y = 0} end)
        local velocity = Branch.new("velocity", {position}, function() return {x = 0, y = 0} end)

        player:grow(velocity, {x = 1, y = 1})
        goal:grow(position, {x = 5, y = 5})

        assert(#position:ents() == 2)

        while true do
            for e, vel in velocity:iter() do
                local pos = e:get(position)
                pos.x = pos.x + vel.x
                pos.y = pos.y + vel.y
            end

            if player:get(position).x == goal:get(position).x and player:get(position).y == goal:get(position).y then
                goal:kill()
                break
            end
        end

        assert(#position:ents() == 1)
    end

    local ent = Ent.new()
    local position = Branch.new("position", {}, function() return {x = 0, y = 0} end)
    local velocity = Branch.new("velocity", {position}, function() return {x = 0, y = 0} end)
    local physics = Branch.new("physics", {position, velocity}, function() return {} end)

    ent:grow(velocity, {x = 1, y = 1})
    ent:grow(physics)

    for _, pos in position:iter() do
        print(pos.x, pos.y)
    end

    for e, _ in physics:iter() do
        local pos = e:get(position)
        local vel = e:get(velocity)
        pos.x = pos.x + vel.x
        pos.y = pos.y + vel.y
    end

    for _, pos in position:iter() do
        print(pos.x, pos.y)
    end

    print("ent branches #" .. #ent:branches())
    print("ent position dependents " .. ent:dependents(position))
    print("ent velocity dependents " .. ent:dependents(velocity))
    print("ent physics dependents " .. ent:dependents(physics))
    print("position ents #" .. #position:ents())
    print("velocity ents #" .. #velocity:ents())
    print("physics ents #" .. #physics:ents())

    print("trimmed!")
    ent:trim(velocity)

    for _, pos in position:iter() do
        print(pos.x, pos.y)
    end

    print("ent branches #" .. #ent:branches())
    print("ent position dependents " .. tostring(ent:dependents(position)))
    print("ent velocity dependents " .. tostring(ent:dependents(velocity)))
    print("ent physics dependents " .. tostring(ent:dependents(physics)))
    print("position ents #" .. #position:ents())
    print("velocity ents #" .. #velocity:ents())
    print("physics ents #" .. #physics:ents())
end

return {
    Ent = Ent,
    Branch = Branch,
    _VERSION = 0.2,
    _DESCRIPTION = "Lua ECS inspired by froggy",
    _AUTHOR = "Michael Patraw <michaelpatraw@gmail.com>",
}
