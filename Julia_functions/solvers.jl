
# function SEsolver(Qt,Trialspace,Testspace;w=nothing,dΩ,dΓ=nothing,cache=nothing,A=nothing,y_dof=fill(0.0, num_free_dofs(Testspace)))
# 	a_SE_tconst(t, dtT, ϕ) = ∫(c*dtT*ϕ*ρ)dΩ
# 	a_SE_tnonconst(t, T, ϕ) = ∫(k * ∇(T) ⋅ ∇(ϕ))dΩ + ∫(h*T*ϕ)dΓ
# 	l_SE(t, ϕ) = ∫(Qt(t) * ϕ)dΩ + ∫(Tout(t) * ϕ * h)dΓ	
# 	op_SE = TransientLinearFEOperator((a_SE_tnonconst, a_SE_tconst), l_SE, Trialspace, Testspace, constant_forms=(true, true))

# 	T = solve(solver, op_SE, t0, tF, TIni)

# 	return [(t0, TIni), collect((t, FEFunction(Trialspace, copy(get_free_dof_values(TT)))) for (t, TT) in T)...], 0.0, 0.0
# end






function AEsolver(T,Q,Trialspace,Testspace;dΩ,dΓ=nothing,cache=nothing,A=nothing,W_dof=fill(0.0, num_free_dofs(Testspace)))
	a_AE_tconst(t, dtW, ψ) = ∫(c*dtW*ψ*ρ)dΩ
	a_AE_tnonconst(t, W, ψ) = ∫(k * (∇(W) ⋅ ∇(ψ)))dΩ - ∫(h*W*ψ)dΓ
	l_AE(t, ψ) = ∫(0.0*ψ)dΩ
	#l_AE(t, ψ) = γ*∫(((x->T(x,t))-Tfin)*ψ - tr(h*(x->Tout(x,t))*ψ))dΩ	
	op_AE = TransientLinearFEOperator((a_AE_tnonconst, a_AE_tconst), l_AE, Trialspace, Testspace, constant_forms=(true, true))
	# tableau = :SDIRK_2_2
	# solver_rk = RungeKutta(ls, ls, Δt, tableau)
	W_end=interpolate_everywhere(-γ*(T(tF)-Tfin)/c/ρ, Uspace(tF))
	W = solve(ThetaMethod(LUSolver(), Δt, θ), op_AE, t0, tF, W_end)

	W_copy = [collect((t, FEFunction(Trialspace, copy(get_free_dof_values(WW)))) for (t, WW) in W)...]
	W_copy_reversed = reverse(W_copy)
	push!(W_copy_reversed,(tF,W_end))
	return W_copy_reversed, 0.0, 0.0

	# return [collect((tF-t,w) for (t,w) in reverse(collect((t,WW) for (t,WW) in W)))... ; (tF,W_end)], 0.0,0.0
end


function SEsolver(Qt, Trialspace, Testspace; dΩ, dΓ)
    # Materialparametere
    k_wall, h_wall = 5.0, 2.0
    k_window, h_window = 0.8, 5.0
    k_door, h_door = 1.0, 8.0


    dΓ_window, dΓ_door, dΓ_wall = dΓ 

    # Svake ledd
    a_SE_tconst(t, dtT, ϕ) = ∫(c*dtT*ϕ*ρ)dΩ

    a_SE_tnonconst(t, T, ϕ) =
        ∫(k_wall * ∇(T) ⋅ ∇(ϕ))dΩ +
        ∫(h_wall * T * ϕ)dΓ_wall +
        ∫(h_window * T * ϕ)dΓ_window +
        ∫(h_door * T * ϕ)dΓ_door
    
    l_SE(t, ϕ) = ∫(Qt(t) * ϕ)dΩ + ∫(Tout(t) * ϕ * h)dΓ

    l_SE(t, ϕ) =
        ∫(Qt(t) * ϕ)dΩ +
        ∫(Tout(t) * ϕ * h_wall)dΓ_wall +
        ∫(Tout(t) * ϕ * h_window)dΓ_window +
        ∫(Tout(t) * ϕ * h_door)dΓ_door
    

    # Opprett transient operator
    op_SE = TransientLinearFEOperator((a_SE_tnonconst, a_SE_tconst), l_SE, Trialspace, Testspace, constant_forms=(true, true))

    # Løs systemet
    T = solve(solver, op_SE, t0, tF, TIni)

    return [(t0, TIni), collect((t, FEFunction(Trialspace, copy(get_free_dof_values(TT)))) for (t, TT) in T)...], 0.0, 0.0
end

