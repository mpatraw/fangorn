
# Fangorn

Fangorn is a different take on ECSs inspired by a "[component graph system](https://github.com/kvark/froggy)."

Owing to the semantics of RAII, an exact reimplementation would require manual reference counting. In an effort to avoid that bookkeeping, I created this variant which flattens the graph and reduces sharing.

## Installation

All you need is `fangorn.lua` and use it like:

```lua
local fangorn = require("fangorn")
```

## Usage

Fangorn has two objects: **Ent** and **Branch**. An *Ent** (or entity) is a bag of components. Unlike traditional ECSs, the entity owns its components. When you create an **Ent** it is empty, but you can grow **Branches** of components. These branches may have dependencies on other branches and will ensure that they are present in the **Ent**. **Branches** also maintain a contingent array of entities that have the component.

### API

```lua
-- Creates a new entity.
local ent = fangorn.Ent.new()
```

### Examples

## License

See [LICENSE.md](LICENSE.md).
