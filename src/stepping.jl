using Agents

export modelTime, modelTimeStep, step




"""
modelTime(model::CellPopulation)::Time

Returns the current model time
"""
modelTime(model::CytonModel)::Time = model.model.properties[:step_cnt] * modelTimeStep(model)

"""
  modelTimeStep(model::CellPopulation)::Duration
  
Returns the current model time step.
"""
modelTimeStep(model::CytonModel)::Duration = model.model.properties[:Δt]

"""
step(model::CellPopulation, stimulus::T) where T<:Stimulus

Step the population forward in time by one time step, with a single stimulus. This
is called in the modeller's simulation loop.
"""
step(model::CytonModel, stimulus::T) where T<:Stimulus = step(model, [stimulus])


"""
step(model::CellPopulation, stimuli::Vector{T}=Vector{Stimulus}()) where T<:Stimulus

Step the population forward in time by one time step, with optional stimuli
"""
function step(model::CytonModel, stimuli::Vector{T}=Vector{Stimulus}()) where T<:Stimulus 
  step!(model.model, (a, _) -> step(a, model, stimuli), stepModel)

  Δt   = modelTimeStep(model)
  time = modelTime(model)
  for (cell,id) in model.cells
    for environment in model.environmentAgents
      interact(environment, cell, time, Δt)
    end
  end
end


"""
step(agent::AgentImpl, model::CellPopulation, stimuli::Vector{T}) where T<:Stimulus

Step a cell forward in time by one time step.
"""
function step(agent::AgentImpl, model::CytonModel, stimuli::Vector{T}) where T<:Stimulus
  Δt   = modelTimeStep(model)
  time = modelTime(model)
  doStep(agent.agent, time, Δt, model, stimuli)
end

stepModel(model::AgentBasedModel) = model.properties[:step_cnt] += 1

function doStep(environment::EnvironmentalAgent, time::Time, Δt::Duration, model::CytonModel, stimuli::Vector{T}) where T<:Stimulus
  
  for stimulus in stimuli
    stimulate(environment, stimulus, time, Δt)
  end
  
  events = step(environment, time, Δt, model)
  if !(events===nothing)
    for e in events
      notifyObservers(e, environment, time)
    end
  end
end
  
function doStep(cell::Cell, time::Time, Δt::Duration, model::CytonModel, stimuli::Vector{T}) where T<:Stimulus
  
  agent_id=model.cells[cell]

  for stimulus in stimuli
    stimulate(cell, stimulus, time, Δt)
  end

  events = [step(timer, time, Δt) for timer in cell.timers]
  events = filter(x -> x ≠ nothing, events)
  
  if any(typeof.(events) .== Death)
    removeCell(cell,model,agent_id)
  end
  
  if any(typeof.(events) .== Division)
    new_cell = divide(cell, time)
    if new_cell ≠ nothing
      addCell(new_cell,model)
      for e in events
        notifyObservers(e, new_cell, time)
      end
    end
  end

  for e in events
    # Cell observers
    notifyObservers(e, cell, time)
    # Population observers
    for cb in model.eventCallbacks
      cb(e, time)
    end
  end

end
