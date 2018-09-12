
# Fangorn

Fangorn is a different take on ECSs inspired by a "[component graph system](https://github.com/kvark/froggy)."

Owing to the semantics of RAII, an exact reimplementation would require manual reference counting. In an effort to avoid that bookkeeping, I created this variant which flattens the graph and reduces sharing.

## Installation

All you need is `fangorn.lua` and use it like:

```lua
local fangorn = require("fangorn")
```

## Usage

To track ents, you need a forest.

### API

```lua
-- Creates a new entity.
local ent = fangorn.Ent.new()
```

### Examples

## License

See [LICENSE.md](LICENSE.md).
