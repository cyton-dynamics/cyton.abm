abstract type FateTimer end

export inherit, FateTimer

"""
  step(::FateTimer, ::Time, ::Duration)::Union{CellEvent, Nothing}

Step the FateTimer forward by one time increment. This should be implemented for each 
concrete `FateTimer`

Optionally return a `CellEvent`
"""
step(timer::FateTimer, ::Time, ::Duration)::Union{CellEvent, Nothing} = error("step method not implemented for $(typeof(timer))")

"""
  inherit(::FateTimer, ::Time)::FateTimer

Called when a cell divides, this allows daughters to inherit timers, create new timers
or something in between.

**Note:** It may be tempting to simple return the parent timer if the cell inherits the timers but be aware the stepper will called for that timer for each cell that references it.
"""
inherit(::FateTimer, ::Time)::FateTimer = error("inherit method not implemented for $(typeof(timer))")

"A simple exponential decay of protein level"
mutable struct PoissonTimer <: FateTimer
  "Current amount of this stuff"
  amount::Float64
  "Decay time constant"
  λ::Float64
end

step(timer::PoissonTimer, _::Time, Δt::Duration) = timer.amount = timer.amount * exp(-Δt/timer.λ)
