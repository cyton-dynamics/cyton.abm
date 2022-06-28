
export addTimer, Cell, Stimulus, stimulate, age, CellEvent, Division, Death, addObserver, CellType, cellType, GenericCell

#---------------------- Cell events ---------------------
"""
CellEvent

Top level type for modelling cellular events. 
`Death` and `Division` are handled internally but users should add additional
events to model additional behaviour.
"""
abstract type CellEvent <: CytonEvent end

"""
Division

A timer (or something else) has triggered cell division
"""
struct Division <: CellEvent end

"""
Death

A timer (or something else) has triggered a cell death event
"""
struct Death <: CellEvent end
#----------------------------------------------------------


#--------------------- Cell data types --------------------
"""
CellType

This is a type (in the software sense) that a cell can carry to distinguish different
categories of cell, e.g. WildType, Knockout, etc
"""
abstract type CellType end

"""
GenericCell

A basic cell type, which is used if no more specific type is provided by the modeller.
This can be used when all cells in the model are the same.
"""
struct GenericCell <: CellType end

"""
AbstractCell{T <: CellType}

The base cell type for objects that carry individual cell state
"""
abstract type AbstractCell{T <: CellType} <: CytonAgent end

"""
Cell{T} <: AbstractCell{T}

The main user facing Cell data type. It encapsulates another 
type, `T`, which can model concepts such as phenotype or genotype
"""
mutable struct Cell{T} <: AbstractCell{T} 
  "The time the cell is created."
  birth::Time
  "The generation number of this cell."
  generation::Int64
  "Timers determing the fate of this cell"
  timers::Vector{FateTimer}
  "Observers watching for cell events"
  observers::Dict{CytonEvent, Vector{Function}}
  "An arbitrary type "
  cellType::T
end

"""
Cell(birth::Time)::Cell{GenericCell}

Constructor for a generic cell.
"""
function Cell(birth::Time)::Cell{GenericCell}
  return Cell(birth, 0, FateTimer[], Dict{CytonEvent, Vector{Function}}(), GenericCell())
end

"""
Cell(birth::Time, cellType::T) where T <: CellType

Constructor for a cell of type `T`
"""
function Cell(birth::Time, cellType::T) where T <: CellType
  return Cell(birth, 0, FateTimer[], Dict{CytonEvent, Vector{Function}}(), cellType)
end

"""
Cell(birth::Time, divisionCount::Int64)::Cell{GenericCell}

Constructor for a daughter cell (i.e. a cell with a division count)
"""
function Cell(birth::Time, divisionCount::Int64)
  return Cell(birth, divisionCount, FateTimer[], Dict{CytonEvent, Vector{Function}}(), GenericCell())
end

"""
cellType(::AbstractCell{T}) where T <: CellType

Return the type, `T` of a cell
"""
cellType(::AbstractCell{T}) where T <: CellType = T
#----------------------------------------------------------


#------------------------ Stimuli -------------------------
"""
Stimulus

Top level type for modelling cell stimuli
"""
abstract type Stimulus end

"""
stimulute(::Cell, ::Stimulus, time::Time, Δt::Duration)

This function is called when a stimulus is applied to a cell. This function is
overriden by the modeller to implement their required behaviour.
"""
function stimulate(::Cell, ::Stimulus, time::Time, Δt::Duration)::Nothing end
#----------------------------------------------------------

"""
addTimer

Add a `FateTimer` to a cell.
"""
addTimer(cell::Cell, timer::FateTimer) = push!(cell.timers, timer)

"""
age

Return the age of the cell
"""
age(cell::Cell, time::Time)::Duration = time - cell.birth

"Internal, probably not necassary"
function die(::AbstractCell)::Nothing end

"""
Create a daughter from the mother and reset the mother's state.
This is called internally.
"""
function divide(cell::AbstractCell, time::Time) 
  # Reset the state of the mother
  cell.generation += 1
  cell.birth = time

  new_cell = Cell(time, cell.generation)

  # new and existing cell "inherit" the mother's timers 
  # see the inherit method for more detail
  for i in 1:length(cell.timers)
    timer = cell.timers[i]
    cell.timers[i] = inherit(timer, time)
    addTimer(new_cell, inherit(timer, time))
  end

  return new_cell
end

#----------------- observers --------------------
"""
addObserver

Adds a callback function,
  `observer(event::CytonEvent, cell::Cell, time::Time)`, 
to a cell. This function is called when `Cell` triggers a `CellEvent`.
"""
function addObserver(event::CytonEvent, cell::Cell, observer::Function) 
  observers = cell.observers
  if !haskey(observers, event)
    observers[event] = Function[]
  end
  push!(observers[event], observer)
end

function addObserver(::CytonEvent, ::CytonAgent, ::Function) end

"This is an internal function."
function notifyObservers(event::CellEvent, cell::Cell, time::Time)
  for observer in get(cell.observers, event, Function[])
    observer(event, cell, time)
  end
end
#-----------------------------------------------
