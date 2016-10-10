# Variable definitions
# mdl.z_Ol[i,j] = z_OpenLoop, open loop prediction of the state, i = state, j = step

# States in path following mode:
# i = 1 -> s
# i = 2 -> ey
# i = 3 -> epsi
# i = 4 -> v

# States in LMPC and system ID mode:
# i = 1 -> xDot
# i = 2 -> yDot
# i = 3 -> psiDot
# i = 4 -> ePsi
# i = 5 -> eY
# i = 6 -> s

function solveMpcProblem(mdl::MpcModel,mpcSol::MpcSol,mpcCoeff::MpcCoeff,mpcParams::MpcParams,trackCoeff::TrackCoeff,lapStatus::LapStatus,posInfo::PosInfo,modelParams::ModelParams,zCurr::Array{Float64},uCurr::Array{Float64})

    # Load Parameters
    sol_status::Symbol
    sol_u::Array{Float64,2}
    sol_z::Array{Float64,2}

    # Update current initial condition, curvature and System ID coefficients
    setvalue(mdl.z0,zCurr)
    setvalue(mdl.uCurr,uCurr[:])
    setvalue(mdl.c_Vx,mpcCoeff.c_Vx)            # System ID coefficients
    setvalue(mdl.c_Vy,mpcCoeff.c_Vy)
    setvalue(mdl.c_Psi,mpcCoeff.c_Psi)
    setvalue(mdl.coeff,trackCoeff.coeffCurvature)       # Track curvature
    setvalue(mdl.coeffTermCost,mpcCoeff.coeffCost)      # Terminal cost
    setvalue(mdl.coeffTermConst,mpcCoeff.coeffConst)    # Terminal constraints

    # Solve Problem and return solution
    sol_status  = solve(mdl.mdl)
    sol_u       = getvalue(mdl.u_Ol)
    sol_z       = getvalue(mdl.z_Ol)

    # export data
    mpcSol.a_x = sol_u[1,1]
    mpcSol.d_f = sol_u[1,2]
    mpcSol.u   = sol_u
    mpcSol.z   = sol_z
    mpcSol.solverStatus = sol_status
    #mpcSol.cost = zeros(6)
    mpcSol.cost = [0,getvalue(mdl.costZTerm),getvalue(mdl.constZTerm),getvalue(mdl.derivCost),getvalue(mdl.controlCost),getvalue(mdl.laneCost)]

    # Print information
    println("--------------- MPC START -----------------------------------------------")
    println("Solved, status = $sol_status")
    println("Predicting until z = $(sol_z[end,6])")
    println("termCost:      $(mpcSol.cost[2])")
    println("termConst:     $(mpcSol.cost[3])")
    println("derivCost:     $(mpcSol.cost[4])")
    println("controlCost:   $(mpcSol.cost[5])")
    println("laneCost:      $(mpcSol.cost[6])")
    println("--------------- MPC END ------------------------------------------------")
    nothing
end

function solveMpcProblem_pathFollow(mdl::MpcModel_pF,mpcSol::MpcSol,mpcParams::MpcParams,trackCoeff::TrackCoeff,posInfo::PosInfo,modelParams::ModelParams,zCurr::Array{Float64},uCurr::Array{Float64})

    # Load Parameters
    coeffCurvature  = trackCoeff.coeffCurvature::Array{Float64,1}

    sol_status::Symbol
    sol_u::Array{Float64,2}
    sol_z::Array{Float64,2}

    # Update current initial condition, curvature and previous input
    setvalue(mdl.z0,zCurr)
    setvalue(mdl.uCurr,uCurr[:])
    setvalue(mdl.coeff,coeffCurvature)

    # Solve Problem and return solution
    sol_status  = solve(mdl.mdl)
    sol_u       = getvalue(mdl.u_Ol)
    sol_z       = getvalue(mdl.z_Ol)

    mpcSol.a_x = sol_u[1,1]
    mpcSol.d_f = sol_u[1,2]
    mpcSol.u   = sol_u
    mpcSol.z   = sol_z
    mpcSol.solverStatus = sol_status
    #mpcSol.cost = zeros(6)
    mpcSol.cost = [getvalue(mdl.costZ),0,0,getvalue(mdl.derivCost),getvalue(mdl.controlCost),0]

    nothing
end

# Cost structure: costZ, costZTerm, constZTerm, derivCost, controlCost, laneCost
