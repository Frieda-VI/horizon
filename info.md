# Horizon

Horizon is a simple and easy to use Entity Component System for Roblox.

## General

`local Horizon = ReplicatedStorage:WaitForChild("Horizon")` -> Should be placed in ReplicatedStorage, but it can also support other paths.

World is a DataModel which holds all created entities. It is possible to create multiple worlds, however, it is not encouraged.

`local World = Horizon.new()`

World:
> Entities -> Requires an instance to exist

Entities:
> Components\
> Signals

Components:
> Systems

*Explanation*: Components and Signals can be assigned to entities. It is through Components and Signals that customised behaviours can be achieved.

---

## Usage

A general use.

```lua
-- context: init.server.lua

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Horizon = require(ReplicatedStorage:WaitForChild("Horizon"))
local World = Horizon.new() --> Should be stored!

for _, Component in ComponentFolder:GetChildren() do
    local Systems = require(Component) -- The component module direclty stores the Systems
    Horizon.newComponent(Component.Name, Systems)
end

for _, Module in Modules:GetChildren do
    require(Module).init(World)
end
```
`listing 0.1`


```lua
-- context: ComponentFolder/Player.lua

local Player = {}

Player.Data = {} -- Behaviour to store data

-- fires after binding to an entity
function Player.init(self)
    local player = self.Instance
end 

 -- fires after all signals have been binded to the entity
function Player.OnSignal(self)
    local player = self.Player
    local GiveCoins = self:GetSignal("GiveCoins")

    GiveCoins:Connect(function(Amount) --> Fired when `GiveCoins:Trigger()`
        local previous = player:GetAttribute("Coins") or 0
        player:SetAttribute("Coins", previous + Amount)
    end)
end

 -- fires on HeatBeat
function Player.Loop(self) end

-- fires when entity is destroyed or component is removed
function Player.Destroy(self)
    -- meant for garbage collection purposes
    clearData()
end

return Player
```
`listing 0.2`


```lua
-- context: Entities/Player.lua

-- Having an entity module for storing the components and signals is a common behaviour but this step can be omitted.

-- see listing 1.0 for the other method

local Player = {}

Player.Components = {
    "Player",
    "King"
}

Player.Signals = {
    "GiveCoins"
    "Demote"
}

return Player
```
`listing 0.3`

```lua
-- context: Modules/PlayerModule.lua

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Horizon = require(ReplicatedStorage:WaitForChild("Horizon"))

local PlayerModule = {}
PlayerModule.Entities = {}

local PlayerEntity = require(Entities.Player)

local function onPlayerAdded(Player)
    -- this additional behaviour is necessary if listing 1.4 has been adopted

    local Components = {} 
    for _, component in PlayerEntity.Components do
        local Component = Horizon.GetComponent(component)
        table.insert(Components, Component)
    end

    local entity = PlayerModule.World
        :Spawn(Player, table.unpack(Components))
        :AddSignal(table.unpack(PlayerEntity.Signal))
    -- end of behaviour

    PlayerModule.Entities[Player] = entity --> not required but can be useful in some cases. Should be garbage collected if done (Explained below)!
end

function PlayerModule.init(World)
    PlayerModule.World = World

    Players.PlayerAdded:Connect(onPlayerAdded) 
    Players.PlayerRemoving:Connect(function(Player)
        PlayerModule.Entities[Player] = nil --> Entity don't need direct cleaning but if they are stored; they need to be deallocated once the instance binded to them is destroyed.
    end)
end

return PlayerModule
```
`listing 0.4`

### Spawn method
The spawn method is used to create a new entity. It takes it an instance as first argument. The remaining arguments are all considered as components. This method is exclusive to the World data model.

`local myFlower = World:Spawn(workspace.Rose, ...)`

### Expanding entity via components
Components should only be created once! Systems can be added to components but not removed naturally. Any system added to a  component will replicate to all other entities bearing the component. 

`local pollen = Horizon.newComponent("Pollen", ...)` It takes a name as first argument and the remaining arguments are systems.

#### Systems

There are two ways of creating systems.

```lua
local Nectar = {}

function Nectar.init(self) end
function Nectar.OnSignal(self) end
function Nectar.Loop(self) end
function Nectar.Destroy(self) end

return Nectar
```
`listing 1.1`

```lua
local Nectar = Horizon.newSystem() -> prebaked with listing 1.1
```
`listing 1.2`

What should I use `listing 1.1` and `listing 1.2`?

- It is best to use `listing 1.1` when two or more methods of the systems are modified.
- `listing 1.2` is simpler if only 1 method is modified.

Additionally, `listing 1.3` is also acceptable.

```lua
local Nectar = Horizon.newSystem()

function Nectar.init(self) end
function Nectar.OnSignal(self) end
function Nectar.Loop(self) end
function Nectar.Destroy(self) end

return Nectar
```
`listing 1.3`

#### What does the self parameters represent?
`self` is a reference to the entity. Any changes to `self` will directly affect the entity. It is only recommended to access the instance: `self.Instance` .


#### More on Components
Since Components hold Systems, and they cannot be removed and update dynamically. Systems can be **thought** to be components.

```lua
    -- The complete creation of entity

    local Nectar = Horizon.newSystem()
    
    Nectar.Data = {}
    local Data = Nectar.Data

    function Nectar.init(self) end
    function Nectar.OnSignal(self)
        -- ONLY triggered after the :AddSignal method is called

        local Flower = self.Instance
        local MakeNectar = self:GetSignal("MakeNectar")
        local Harvest = self:GetSignal("Harvest")

        Data.NectarProduced = 0
        local Connection = MakeNectar:Connect(function(Amount)
            Data.NectarProduced += Amount
        end) 
        -- Connections are automatically garbage collected after the Entity is despawn'ed.
    
        local harvest
        harvest = Harvest:Connect(function()
            -- It is a good pratice to disconnect unused connections
            Connection:Disconnect()
            harvest:Disconnect()

            Data.isHarvested = true
        
            task.delay(5, function()
                EndLife:Trigger() --> Could have been triggered in .Destroy
                Flower:Destroy()
            end)
        end)
    end
    function Nectar.Loop(self) end
    function Nectar.Destroy(self)
        Data.NectarProduced = nil
        Data.isHarvested = nil
        Data = nil
    end

    local PollenComponent = Horizon.newComponent("Pollen", Nectar) --> The nectar system is passed directly as argument

    -- Components can be obtained by using the .GetComponent(ComponentName) method
    local Rose: Entity = World
        :Spawn(workspace.Rose, Horizon.GetComponent("Pollen"))
        :AddSignal("MakeNectar", "Harvest", "EndLife") --> The AddSignal method can be chained to entities.

    -- The component is passed directly as argument. NOTE: passing string as component will cause the system to error.
    local Daisy: Entity = World
        :Spawn(workspace.Daisy, PollenComponent)
```
`listing 1.4`

## Removing entity from World

Removing the entity from the World is done using the `:Despawn()` method. However, this does involve some complexity.

```lua
World:QueryWith(Nectar)
    .iter(function(ID, Entity)
    World:Despawn(ID) --> takes in an ID, rather than an instance
end)
```
`listing 2.0`

## Query

There are two query methods: `QueryWith` and `QueryWithout` . Both method accept components as parameters(**not strings**)

```lua
World:QueryWith(Component, Component2, Component3, ...)
```
`listing 3.0`


```lua
World:QueryWithout(Component, Component2, Component3, ...)
```
`listing 3.1

Both `listing 3.0` and `listing 3.1` returns a table. 

### View query results

```lua
-- iteration method
-- See listing 3.3 to see the iteration method can be done without using .iter()

World:QueryWith(Component, Component2, Component3, ...)
    .iter(function(ID, Entity)
        -- This function will be called for every entity with the entity's ID and Entity model
        ...
    end)
```
`listing 3.2`

```lua
-- get method

local results = World:QueryWith(Component, Component2, Component3, ...)
    .get() --> returns a results table

for _, result in results do --> same as .iter()
    local ID, Entity = result[1], result[2]
    ...
end
```
`listing 3.3`

## End

Consider opening a pull request if you stumble on a bug or unexpected behaviour.\

Note: **Maid and Signal are part of Horizon. You should under not use them in customised settings outside of the Horizon environment. This is because, both of these utils were specifically coded to meet the demands of Horizon. They may not function as expect outside of the Horizon environment.**