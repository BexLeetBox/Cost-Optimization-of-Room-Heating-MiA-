
# function SEsolver(Qt,Trialspace,Testspace;w=nothing,dΩ,dΓ=nothing,cache=nothing,A=nothing,y_dof=fill(0.0, num_free_dofs(Testspace)))
# 	a_SE_tconst(t, dtT, ϕ) = ∫(c*dtT*ϕ*ρ)dΩ
# 	a_SE_tnonconst(t, T, ϕ) = ∫(k * ∇(T) ⋅ ∇(ϕ))dΩ + ∫(h*T*ϕ)dΓ
# 	l_SE(t, ϕ) = ∫(Qt(t) * ϕ)dΩ + ∫(Tout(t) * ϕ * h)dΓ	
# 	op_SE = TransientLinearFEOperator((a_SE_tnonconst, a_SE_tconst), l_SE, Trialspace, Testspace, constant_forms=(true, true))

# 	T = solve(solver, op_SE, t0, tF, TIni)

# 	return [(t0, TIni), collect((t, FEFunction(Trialspace, copy(get_free_dof_values(TT)))) for (t, TT) in T)...], 0.0, 0.0
# end




function AEsolver(solver, T,Q,Trialspace,Testspace;dΩ,dΓ=nothing,cache=nothing,A=nothing,W_dof=fill(0.0, num_free_dofs(Testspace)),Tfin=nothing, tF=1.0, constants=nothing)

    c, ρ, k, h = constants

    h_wall, h_window, h_door = h

    dΓ_window, dΓ_door, dΓ_wall = dΓ 

	a_AE_tconst(t, dtW, ψ) = ∫(c*dtW*ψ*ρ)dΩ
	a_AE_tnonconst(t, W, ψ) = ∫(k * (∇(W) ⋅ ∇(ψ)))dΩ + (∫(h_wall*W*ψ)dΓ_wall + ∫(h_window*W*ψ)dΓ_window + ∫(h_door*W*ψ)dΓ_door)

	l_AE(t, ψ) = ∫(0.0*ψ)dΩ

	op_AE = TransientLinearFEOperator((a_AE_tnonconst, a_AE_tconst), l_AE, Trialspace, Testspace, constant_forms=(true, true))

	W_end=interpolate_everywhere(-γ*(T(tF)-Tfin)/c/ρ, Uspace(tF))

	W = solve(solver, op_AE, t0, tF, W_end)
  
	W_copy = [(tF,W_end),collect((tF - t, FEFunction(Trialspace, copy(get_free_dof_values(WW)))) for (t, WW) in W)...]

    W_copy_reversed = reverse(W_copy)

	return W_copy_reversed, 0.0, 0.0
end

function SEsolver(solver, Qt, Trialspace, Testspace; dΩ, dΓ, Tout, constants)

    c, ρ, k, h = constants

    h_wall, h_window, h_door = h

    dΓ_window, dΓ_door, dΓ_wall = dΓ 

    # Svake ledd
    a_SE_tconst(t, dtT, ϕ) = ∫(c*dtT*ϕ*ρ)dΩ

    a_SE_tnonconst(t, T, ϕ) =
        ∫(k * ∇(T) ⋅ ∇(ϕ))dΩ +
        ∫(h_wall * T * ϕ)dΓ_wall +
        ∫(h_window * T * ϕ)dΓ_window +
        ∫(h_door * T * ϕ)dΓ_door

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

