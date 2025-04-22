# main3Beka.jl

#### Import Julia packages
using Gridap
using GridapMakie, CairoMakie, FileIO
using Gridap.FESpaces
using Gridap.ReferenceFEs
using Gridap.Arrays
using Gridap.Algebra
using Gridap.Geometry
using Gridap.Fields
using Gridap.CellData
using FillArrays
using Test
using InteractiveUtils
using JSON3
using Dates
using Makie

#### Import Custom functions
include("Julia_functions/indicator_chi.jl")
include("Julia_functions/cost_fun.jl")
include("Julia_functions/gradient_descent.jl")
include("Julia_functions/solvers.jl")
include("Julia_functions/find.jl")
include("Julia_functions/res_plot.jl")
include("Julia_functions/get_domain.jl")
include("Julia_functions/get_price_temp.jl")
include("Julia_functions/post_processing.jl")

#### Read JSON File
width, height, Tini_json, Tfin_json, windows, doors, heating_elem = get_room("Boundary.json")
price_EUR, price_NOK, T_out, hour_lst = get_price_temp("WeatherandEnergy.json")

#### Boundary conditions
f_Γ_w = generate_f_Γ(windows, width, height)
f_Γ_d = generate_f_Γ(doors, width, height)
f_Γ_wall(x) = !(f_Γ_w(x) || f_Γ_d(x))

#### Domain & Discretization
domain = (0, width, 0, height)
partition = (25,25)
model = CartesianDiscreteModel(domain,partition)
update_labels!(1, model, f_Γ_w, "window")
update_labels!(2, model, f_Γ_d, "door")
update_labels!(3, model, f_Γ_wall, "wall")

order = 1
degree = 2*order

Ω = Triangulation(model)
dΩ = Measure(Ω, degree)

Γ_w = BoundaryTriangulation(model, tags="window")
dΓ_w = Measure(Γ_w, degree)

Γ_d = BoundaryTriangulation(model, tags="door")
dΓ_d = Measure(Γ_d, degree)

Γ_wall = BoundaryTriangulation(model, tags="wall")
dΓ_wall = Measure(Γ_wall, degree)

reffe = ReferenceFE(lagrangian,Float64,order)
Testspace = TestFESpace(model,reffe,conformity=:H1)
Trialspace = TransientTrialFESpace(Testspace)
Uspace = FESpace(model, reffe, conformity=:H1)

#### Time parameters
t0 = 0.0    # Start time
tF = 28800   # End time
Δt = 50

#### Room parameters
h_wall(x) = 0.22*0.02           # [W/m^2K]
h_window(x) = 1.2*0.02
h_door(x) = 1.0*0.02

ρ(x)=1.225
c(x)=1020.0
k(x)=5#3.5

h = (h_wall, h_window, h_door)
constants = (c, ρ, k, h)

Tout = get_temp_function(T_out, tF)

Tini(x)= Tini_json
TFin(x)= Tfin_json

TIni=interpolate_everywhere(Tini, Uspace(t0))
Tfin=interpolate_everywhere(TFin, Uspace(tF))

#### Control parameter
q_pos = heating_elements(heating_elem)
Q(x,t)=0#150*q_pos(x)*χ(t,6.0,9.0)
Qt(t)=x->Q(x,t)

#### Solver parameters
L2norm(u)=√(Δt*((∑(∫(u[1][2]⋅u[1][2])*dΩ)+∑(∫(u[end][2]⋅u[end][2])*dΩ))/2 + ∑(∑(∫(u[k][2]⋅u[k][2])*dΩ) for k=2:length(u)-1)))
L2skp(u)=Δt*((∑(∫(u[1][2]⋅u[1][2])*dΩ)+∑(∫(u[end][2]⋅u[end][2])*dΩ))/2 + ∑(∑(∫(u[k][2]⋅u[k][2])*dΩ) for k=2:length(u)-1))

Proj(a,b,z) = min(max(a,z),b)
a=0.0
b=400*(∑(∫(q_pos)*dΩ))
Proj(z) = [(t,FEFunction(Uspace,map(x->Proj(a,b,x), get_free_dof_values(zz)))) for (t,zz) in z]

#### Plotting functions
get_control_int(qs) = [∑(∫(u)*dΩ) for (t,u) in qs] ./ ∑(∫(q_pos)*dΩ)
get_temperature_int(Ts) = [∑(∫(temp)*dΩ) for (t,temp) in Ts] ./ ∑(∫(1)*dΩ)

function result_plot2(; T_int, Q_int, t0, tF, hour_lst, price_NOK, T_out)
    time = LinRange(t0, tF, length(T_int)) ./ 3600
    time2 = LinRange(t0, tF, length(T_int))
    time_price = [price(t) for t in time2]

    fig = CairoMakie.Figure(size=(600, 900), figure_padding=(0, 5, 0, 5))

    # Temperature plot
    ax = CairoMakie.Axis(fig[1, 1], title="Temperature profile",
        xlabel="Time (hours)", ylabel="Temperature (°C)", ytickformat=v -> ["$(round(vi - 273.15, digits=1))" for vi in v])
    lines!(ax, time, T_int, color=:green)

    # Heating plot
    ax = CairoMakie.Axis(fig[2, 1], title="Optimal Heating Schedule",
        xlabel="Time (hours)", ylabel="Heating Output (W)")
    lines!(ax, time, Q_int, color=:red)

    # Price plot
    ax = CairoMakie.Axis(fig[3, 1], title="Energy price over time",
        xlabel="Time (hours)", ylabel="Price (NOK)")
    lines!(ax, time, time_price, color=:blue)

    # Outside temperature plot
    ax = CairoMakie.Axis(fig[4, 1], title="Outside Temperature over time",
        xlabel="Time (hours)", ylabel="Temperature (°C)", ytickformat=v -> ["$(round(vi - 273.15, digits=1))" for vi in v])
    lines!(ax, hour_lst .-10, T_out, color=:orange)

    return fig
end

function plot_costs2(costs)
    fig = CairoMakie.Figure(size=(600, 300))
    ax = CairoMakie.Axis(fig[1, 1], xlabel="Iteration", ylabel="Cost", yscale=log10)
    lines!(ax, 1:length(costs), costs, color=:purple)
    return fig
end

#### Run Gradient Descent
price = get_price_function(price_NOK, tF, 1)
γ = 1.225*1020*3

(Ts3, qs3, Ws3, costs3) = GradientDescent(
    solveSE=SEsolver,
    solveAE=AEsolver,
    spaces=(Trialspace, Testspace, Uspace),
    dΩ=dΩ,
    dΓ=(dΓ_w, dΓ_d, dΓ_wall),
    Q=Qt,
    J=E,
    ∇f=∇e,
    P=Proj,
    s_min=s_min,
    sminargs=nothing,
    saveall=false,
    tol=1e-5,
    iter_max=5,
    armijoparas=(ρ=0.5, α_0=10, α_min=1e-4, σ=0.0),
    Δt=Δt,
    t0=t0,
    tF=tF,
    Tout=Tout,
    constants=constants,
    Tfin=Tfin,
    q_pos=q_pos
)



 # # Opprett en mappe for midlertidige filer hvis den ikke eksisterer
 if !isdir("tmp")
     mkdir("tmp")
 end

"""
 #Initialtilstanden og resten av tidsløsningene
 uh0 = solution[1][2]  # Første element er (t0, T0), vi henter T0
 uh  = solution[2:end]  # De resterende løsningene
"""

uh0 = Ts3[1][2]
uh  = Ts3[2:end]


 uh = Ts3
 # Lagre resultater i Paraview-format (VTK)
 createpvd("results") do pvd
     # Første løsning (t=0)
     # pvd[0] = createvtk(Ω, "tmp/results_0.vtu", cellfields=["u" => uh0])

     # Lagrer løsninger for hver tidssteg
     count = 0
     for (tn, uhn) in uh
         if count%5 == 0
             pvd[tn] = createvtk(Ω, "tmp/results_$tn.vtu", cellfields=["u" => uhn])
         end
         count+=1
     end
 end

#### Generate and save plots
c1_real = plot_costs2(costs3)
CairoMakie.save("./static/images/price_real_convergence_beka.png", c1_real)

Q_int = get_control_int(qs3)
T_int = get_temperature_int(Ts3)
c2_real = result_plot2(;T_int, Q_int, t0, tF, hour_lst, price_NOK, T_out)
CairoMakie.save("./static/images/price_real_result_beka.png", c2_real)

#### Calculate final metrics
# Initialize global variable
global real_price = 0.0

for (t, QQ) in qs3
    global real_price  # Explicitly declare we're using the global variable
    real_price += Δt * price(t) * ∑(∫(QQ) * dΩ) * (1/1000/3600)
end

temp_difference = ∑(∫(last(Ts3)[2] - Tfin) * dΩ)
println("Total energy cost: ", real_price)
println("Average temperature difference: ", temp_difference/(width*height))