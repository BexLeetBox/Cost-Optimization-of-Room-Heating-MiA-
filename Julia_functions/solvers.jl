
function SEsolver(Q,Trialspace,Testspace;w=nothing,dΩ,dΓ=nothing,cache=nothing,A=nothing,y_dof=fill(0.0, num_free_dofs(Testspace)), solver)
	a_SE_tconst(t, dtT, ϕ) = ∫(ρ*c*dtT*ϕ)dΩ
	a_SE_tnonconst(t, T, ϕ) = ∫(-k * ∇(T) ⋅ ∇(ϕ) - tr(h*T*ϕ))dΩ
	l_SE(t, ϕ) = ∫((x->Q(x,t))*ϕ - tr(h*(x->Tout(x,t))*ϕ))dΩ	
	op_SE = TransientLinearFEOperator((a_SE_tconst, a_SE_tnonconst), l_SE, Trialspace, Testspace, constant_forms=(true, false))
	# tableau = :SDIRK_2_2
	# solver_rk = RungeKutta(ls, ls, Δt, tableau)

	y_dof = solve(solver, op_SE, t0, tF, TIni)
	return y_dof, 0.0,0.0
end






function AEsolver(T,Q,Trialspace,Testspace;dΩ,dΓ=nothing,cache=nothing,A=nothing,p_dof=fill(0.0, num_free_dofs(Testspace)), solver)
	a_AE_tconst(t, dtW, ψ) = ∫(ρ*c*dtW*ψ)dΩ
	a_AE_tnonconst(t, W, ψ) = ∫(+k * ∇(W) ⋅ ∇(ψ) + tr(h*W*ψ))dΩ
	l_AE(t, ψ) = γ*∫(((x->T(x,t))-Tfin)*ψ - tr(h*(x->Tout(x,t))*ψ))dΩ	
	op_AE = TransientLinearFEOperator((a_AE_tconst, a_AE_tnonconst), l_AE, Trialspace, Testspace, constant_forms=(true, false))
	# tableau = :SDIRK_2_2
	# solver_rk = RungeKutta(ls, ls, Δt, tableau)

	y_dof = solve(solver, op_AE, t0, tF, TIni)
	return y_dof, 0.0,0.0
end