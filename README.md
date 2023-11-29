# Horizon

**A fast, simple and lightweight but performant ECS(Entity Component System).**

## Prerequisite

The following are musts:
 - GitHub/Git
 - Roblox + Rojo
 - ECS in general

## Installation

1. Clone or folk the repository (Ensure you have the latest version)
2. Copy the `Horizon` folder to your project
3. Using rojo config files, place Horizon in `ReplicatedStorage`

## Getting Started

There is an example to demonstrate the 'proper' usage of the framework. However, the example does not demonstrate the best coding practices. You should only use the example to get acquainted with Horizon.

**Note: Horizon on the server and client NEVER naturally in sync. This means that Entities on the server are not necessarily entities on the client. In other words, it is 'FilteringEnabled'.**

## API

```lua
-- Header -> assumed to be present for all API code snippets

local HorizonModel = game:GetService("ReplicatedStorage"):WaitForChild("Horizon")

local Horizon = require(HorizonModel)
local Entity = require(HorizonModel.Entity)
local Component = require(HorizonModel.Component)
local System = require(HorizonModel.System)
```

### World

World can only be created once!
```lua
local _World = Horizon.new() 
    --> Horizon keeps the world as reference
     -- therefore it's not obligatory to reference
```

### Entity

Entity are building blocks. They accept an instance as argument and all other arguments are considered as `Components`. It is good practice to set a model as instance.

Once created, the entity should be fed directly to Horizon. This allows the entity to be assigned an unique ID. `:AddEntity` can be called on world or directly on Horizon. It takes the entity as argument and returns the entity. This behaviour allows the chaining of methods. You will discover other methods which returns the entity itself.

#### AddEntity

```lua
local my_Entity = Entity.new(My_Model, ...)

_World:AddEntity(my_Entity) 
Horizon:AddEntity(my_Entity)
```

#### RemoveEntity

Sometimes, you will need to remove an Entity from the world model; perhaps after it has been destroyed. Unlike `:AddEntity`, it takes the ID of the entity.

```lua
Horizon:RemoveEntity(ID)
```

#### FindID 

Some methods will provide the ID of the Entity as parameter but not all will. So, `:FindID` can be called with the Entity to obtain its ID.

```lua
Horizon:FindID(my_Entity)
```

#### GetEntityFromInstance

`:GetEntityFromInstance` takes an instance as argument and returns an array if an entity is linked to the instance. The first element of the array is the ID of the entity, and the second element is the Entity itself.

```lua
local result = Horizon:GetEntityFromInstance(My_Model)
result[1] --> ID
result[2] --> Entity
```

#### Query

There are two types of queries: `:QueryWith` and `:QueryWithout`. Both methods return a complex table which will continue to update. They also both take components as arguments.

QueryObjects will never stop updating its results. This implies that calling `.Get()` on a QueryObject could result in two seperate results. It is for this reason that `:Terminate()` should be called to terminate the updating process.

```lua
local my_Query = Horizon:QueryWith(Health, Transform)
local my_SecondQuery = Horizon:QueryWithout("Particles")

my_Query.Get(false) -> Results the results directly

my_Query.Get(true).iter(function(ID, Entity)
     -> Is ultimately syntax sugar
    ...
end)

for _, result in my_Query.Get() do
     -> Is equivalent to `myQuery.Get(true).iter()` method
    local ID, Entity = result[1], result[2]
end

my_Query:Terminate()
```

### More on Entity

These methods are called directly on a specific entity.

It may be more comprehensive if you read the components section first.

#### hasComponents
It takes in components(names of components or ComponentObject) as arguments. It only returns true if all the components are present.

```lua
my_Entity:hasComponents(...)
my_Entity:hasComponents("Health", Transform) :: boolean
```
#### AddComponent

Note: It takes a ComponentObject as argument; not a string. An only takes ONE ComponentObject at a time. It is not a chained behaviour and does not return.

Most of the times, you will add components on the creation of the entity rather than on runtime. However, there are cases where this feature is required. Unlike `:AddComponent`, `Entity.new` accepts several components at once.

```lua
my_Entity:AddComponent(Particles)
```

#### RemoveComponent

It is complementary to `AddComponent`, and works exactly the same way. 

```lua
my_Entity:RemoveComponent(Particles)
```

#### GetComponent

It is ubiquitous to obtain a specific component from an entity. It only accepts ONE component per time as argument. The component can be a string or a ComponentObject.


```lua
my_Entity:GetComponent("Transform")
my_Entity:GetComponent(Health)
```

#### AddSystem

It adds a system to the entity. It is similar to how `AddComponent` behaves, and it only takes ONE system per time. The system passed should be a SystemObject. This methods allows chainable behaviours.

This section will be more clear after you understand Systems. 

```lua
my_Entity:AddSystem(Generation)
```

#### SetLoop

This is a special function that allows the entity to be update through a loop. There are three loop modes: 
1. `BeforePhysics` equivalent to Stepped
2. `AfterPhysics` equivalent to Heartbeat
3. `BeforeRender` equivalent to RenderStepped -> for client only

The `SetLoop` method takes a loop mode (string) and function as arguments. The function will be ran on each iteration. `SetLoop` allows chainable behaviours. The function receives special parameters:
1. `ID` -> Entity's ID
2. `DeltaTime` -> DeltaTime for modes: 2 and 3, and `Time` for mode: 1
3. `LoopID` -> The unique loop indentifier to the entity; DeltaTime for mode: 1
4. `LoopID` -> nil for modes: 2 and 3, and `LoopID` for mode: 1

[`BeforePhysics`](https://create.roblox.com/docs/reference/engine/classes/RunService#Stepped) receives different parameters as it has time as an additional parameter. 

If the function provided returns `Horizon.Enums.TerminateLoop` equivalent to "END_LOOP_SEQUENCE_WORKFLOW" in string, then the loop is stopped and removed.

Each loop set on an entity has a Loop ID that is unique only to the Entity itself.

```lua
local Condition = true
my_Entity:SetLoop("BeforePhysics", function(ID, DeltaTime, LoopID)
    if not Condition then
        return Horizon.Enums.TerminateLoop
    end

    doSomething()

    Condition = false
end)
```

#### RemoveLoop

The same behaviour as return the `TerminateLoop` enum can be achieved using the `:RemoveLoop` method. This method only takes a LoopID as argument, and has no returns.

```lua
function(ID, DeltaTime, LoopID)
    if not Condition then
        my_Entity:RemoveLoop(LoopID)
        return
    end
end)
```

#### AutoPilot

When an entity is created and added to the world model, it is not automatically garbage collected. This means that if the instance attached to the entity is destroyed; the entity object continues to exist. This behaviour is unwanted in most situations. 

The `:AutoPilot` method ensures that the object is garbage collected if the instance is destroyed. This means that all the components attached to the Entity will be denatured, and the entity will removed from the World model.

This method allows chainable behaviours.

```lua
my_Entity:AutoPilot()
```

```lua
-- Example of a chain pattern
Entity.new(workspace.Plane, ...)
    :AutoPilot()
    :AddSystem(Kinematics)
    :AddSystem(Particles)
```

#### AddMaid

The `AutoPilot` can be achieved using the `AddMaid` method. The method can only be ran once and returns a MaidObject. MaidObjects are complex, so we recommend that you check:
`Horizon > Utils > Maid.lua` to get acquainted with the Maid util.

The method allows chainable maid behaviours.

```lua
local myMaid = my_Entity:AddMaid()
```

```lua
-- Example of a chain pattern through maid
my_Entity:AddMaid()
    :BindTo(Plane, onPlaneAdded, workspace.Seats, ...)
    :Add(Plane_Component, ...)
    :beforeDestroy(function()
        doSomething()
    end)
    :afterDestroy(function()
     doSomething()
    end) --> returns a maid
```

#### Clone

**This method is unsafe. Use with caution!**

The clone method takes an instance as argument and returns a similar entity.

```lua
local my_Entity2 = my_Entity:Clone(new_plane)
    --> the components of my_Entity are also cloned.
```

#### Destroy

This method destroys the entity. If the entity was attached to the World model, calling the `:Destroy` method remove the Entity from the world model and from QueryObjects. Additionally, this also triggers a Maid cleanup if the MaidObject if any has not be cleaned already. -> AutoPilot calls the `:Destroy` method after the instance is destroyed.

```lua
my_Entity:Destroy()
print(my_Entity) -> {}
```

### Components

Components are incredible important in ECS. They can act as entity data storages. It is through components that you can achieve universal component behaviours

Components are cloned when they are attached to entities. This means that they may not have the same data as the original component.
When a component is cloned, the data hashmap is deep cloned. However, EntityObjects, ComponentObjects and SystemObjects are not deep cloned but instead of simply referenced back to the clone.

#### New

The method method takes two arguments:
1. `Name` -> the name of the component
2. `Data` -> should be a table/hashmap

These two arguments are obligatory, and omitting them will result in the system breaking safetly via en error.

```lua
local Health = Component.new("Health", {
    Health = 100,
    MaxHealth = 100,
    RegenPerSecond = 2,
})
```

#### setData

This method is use to set the data of a component. You may think that you can directly modify the of the Component. 

`setData` does not modify the original data table, but instead creates(via cloning the data table) a new table passed as a parameter to the function. Once the new data table is returned back; it becomes readonly. 

```lua
Health.Data.MaxHealth = 120  
    --> this error as data is readonly.
```

```lua
-- Correct method of modifying data
Health:setData(function(PreviousData)
    PreviousData.MaxHealth = 120    
    return PreviousData
end)
```

The above snipple, is correct. However, you will almost never do this! This because Components are meant to be attached to entities. This implies that you should not modify pure component objects. Their correct usage will be demonstrated in the `System` section.

#### getData

This method returns a readonly table of the Component's data.

```lua
local Data = Health:getData()

print(Data.Health) -> 100
```

#### Denature

Components cannot be destroyed. They are instead denatured which means that the data they hold is emptied. This does not affect the original Component, unless if the `:Denature` method is called on the origianl Component. However since Components are cloned, denaturing the original Component object does not denature derived Components.

### System

The last part of an ECS, which really make the magic happen are Systems. There are two types of systems: 'External' and 'Internal'. The systems that were referring to here External, which means that they can be accessed from outside scripts.

External systems cannot exist without a component, similar to how an entity cannot exist without an instance.

#### New

This method creates a new system. Systems are basically functions. However, their syntax are a little weird. The new method takes a component(Component name or ComponentObject) as argument, and returns a truple.

The first return is the System itself, and the second return is a table to which functions can be attached to.

Functions which have been attached to the second return will recieve the following parameters:
1. `self` -> the Entity to which the system is added (`some_entity:AddSystem(first_return)`)
2. `Component` -> The related component: Remember how we said you would almost never use `:setData` on actual components. This is because `:setData` and `:getData` are mostly called on this Component.
3. `Args...` -> Any arguments that has been passed...

```lua
-- Valid code

local Health_System, _HealthFunctions = System.new(Health)

function _HealthFunctions:Regenerate(HealthComponent, Amount)
    HealthComponent:setData(function(previous)
        previous.Health = math.min(previous.MaxHealth, previous.Health + Amount)

        return previous
    end)

    return true --> will be returned to where this is called
end
```


```lua
-- You can think of the _HealthFunction as:
Health_Systems.Functions:Regenerate() ... 
    --> keep in mind that this is invalid code!
```

#### Seal

The second return of creating a system, allows us to bind functions to it. Once the required functions have been attached, they should be sealed. `:Seal` prevents any further functions from being added to the Functions table.

```lua
Health_System:Seal()
     --> notice, we do not call seal on _HealthFunctions
```

#### How do I access a system from an entity?

**This is not a method.** 

Systems are stored in an organised pattern:
`Entity > Systems > ComponentName > Functions...`

Remember that `self` refers to the Entity that the System is attached to, and the component refers to the component attached to the entity.

```lua
function _HealthFunctions:TakeDamage(HealthComponent, Amount)
    doStuff()

    return self.Systems.Health:IsDead()
end

function _HealthFunctions:IsDead(HealthComponent)
    return HealthComponent.getData().Health > 0
end
```

## Fin
