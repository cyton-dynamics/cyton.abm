module Cyton

using Agents
import Base.length

export modelTime, modelTimeStep, step, createPopulation, cellCount, CytonModel, cohortCount, Time, Duration

include("BaseTypes.jl")
include("probability/DistributionParms.jl")
include("cells/FateTimers.jl")
include("cells/Cells.jl")
include("utils/void_space.jl")


#------------------------- A Cyton model ------------------------
"""
CytonModel

The population of cells and environmental agents with convenince constructors. Ordinarily, this will be 
constructed by the framework.
"""
mutable struct CytonModel
  model::AgentBasedModel
  cells::Dict{Cell,Int64}
  environmentAgents::Vector{EnvironmentalAgent}
  startingCnt::Int
  eventCallbacks::Vector{Function} 
end
function CytonModel(model::AgentBasedModel, cells::Dict{Cell{T},Int64}, environment::Vector{EnvironmentalAgent}, callbacks::Vector{Function}) where T<: CellType
  CytonModel(model, cells, environment, length(cells), callbacks)
end

"""
addCell(::Cell,::CytonModel) 

Funciton to add new cells to the model. Will add the agent implementation to the 
ABM framework and add the cell to the model's cell array.
"""
function addCell(new_cell::Cell,model::CytonModel)
  new_id=model.model.maxid[]+1
  new_agent = AgentImpl(new_id, new_cell)
  add_agent_pos!(new_agent, model.model)
  model.cells[new_cell]=new_id
  return nothing
end

"""
remove_cell(::Cell,::CytonModel,::AgentImpl) 

Funciton to kill cells in the model. 

"""
function removeCell(cell::Cell,model::CytonModel,agent_id::Int64)
  die(cell)
  kill_agent!(agent_id, model.model)
  delete!(model.cells,cell)
  return nothing
end


Base.length(population::CytonModel) = length(population.cells)
#----------------------------------------------------------------

include("stepping.jl")

"""
cellCount(model::CellPopulation)::Int

Return the number of cells in the population
"""
cellCount(model::CytonModel)::Int = length(model.model.agents)

"""
cohortCount(model::CellPopulation)::Int

Return the current cohort count, cell count normalised by generation number.
"""
function cohortCount(model::CytonModel)::Int
  cohort = 0.0
  for (cell,id) in model.cells
    cohort += 2.0^-cell.generation
  end
  return cohort/model.startingCnt
end

"""
createPopulation(nCells::Int, 
  cellFactory::Function; 
  eventCallbacks::Vector{Function}=Function[])::CellPopulation

  Create a population of cells:
 nCells: size of starting populations
 cellFactory: A function that returns constructs a new cell
 environmentFactory: A function that returns a Vector of environment agents
 eventCallbacks: Function that are called when events occurs
 
 `Division` and `Death` are two predefined events
"""
function createPopulation(nCells::Int, 
  cellFactory::Function,
  environmentAgents::Vector{EnvironmentalAgent}=EnvironmentalAgent[],
  eventCallbacks::Vector{Function}=Function[])

  space = VoidSpace()
  scheduler = Schedulers.fastest
  properties = Dict(:step_cnt => 0, :Δt => 0.1)
  model = AgentBasedModel(AgentImpl, space; properties, scheduler)

  cells = map(1:nCells) do id
    cell = cellFactory(0.0)
    agent = AgentImpl(id, cell)
    add_agent_pos!(agent, model)
    cell=>id
  end
  cells=Dict(cells)
  id = length(cells)
  for e in environmentAgents
    id += 1
    agent = AgentImpl(id, e)
    add_agent_pos!(agent,model)
  end

 
  return CytonModel(model, cells, environmentAgents ,eventCallbacks)
end


"""
interact(::EnvironmentalAgent, ::Cell, ::TIme, ::Duration)

Model the interaction between the cell and the environment.
"""
function interact(::EnvironmentalAgent, ::Cell, ::Time, ::Duration) end


end

