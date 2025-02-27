flow_velocity=21.7 # cm/s. See MSRE-properties.ods
nt_scale=1e13
ini_temp=922
diri_temp=922

[GlobalParams]
  num_groups = 2
  num_precursor_groups = 6
  use_exp_form = false
  group_fluxes = 'group1 group2'
  temperature = temp
  sss2_input = false
  pre_concs = 'pre1 pre2 pre3 pre4 pre5 pre6'
  account_delayed = true
[]

[Mesh]
  file = '2d_lattice_structured.msh'
  # file = '2d_lattice_structured_jac.msh'
[../]

[Problem]
  coord_type = RZ
[]

[Variables]
  [./temp]
    initial_condition = ${ini_temp}
  [../]
[]

[AuxVariables]
  [./group1]
  [../]
  [./group2]
  [../]
  [./pre1]
    family = MONOMIAL
    order = CONSTANT
    block = 'fuel'
  [../]
  [./pre2]
    family = MONOMIAL
    order = CONSTANT
    block = 'fuel'
  [../]
  [./pre3]
    family = MONOMIAL
    order = CONSTANT
    block = 'fuel'
  [../]
  [./pre4]
    family = MONOMIAL
    order = CONSTANT
    block = 'fuel'
  [../]
  [./pre5]
    family = MONOMIAL
    order = CONSTANT
    block = 'fuel'
  [../]
  [./pre6]
    family = MONOMIAL
    order = CONSTANT
    block = 'fuel'
  [../]
[]

[Kernels]
  # Temperature
  [./temp_time_derivative]
    type = MatINSTemperatureTimeDerivative
    variable = temp
  [../]
  [./temp_source_fuel]
    type = TransientFissionHeatSource
    variable = temp
    nt_scale=${nt_scale}
    block = 'fuel'
  [../]
  # [./temp_source_mod]
  #   type = GammaHeatSource
  #   variable = temp
  #   gamma = .0144 # Cammi .0144
  #   block = 'moder'
  #   average_fission_heat = 'average_fission_heat'
  # [../]
  [./temp_diffusion]
    type = MatDiffusion
    diffusivity = 'k'
    variable = temp
  [../]
  [./temp_advection_fuel]
    type = ConservativeTemperatureAdvection
    velocity = '0 ${flow_velocity} 0'
    variable = temp
    block = 'fuel'
  [../]
[]

[BCs]
  [./temp_diri_cg]
    boundary = 'moder_bottoms fuel_bottoms outer_wall'
    type = FunctionDirichletBC
    function = 'temp_bc_func'
    variable = temp
  [../]
  [./temp_advection_outlet]
    boundary = 'fuel_tops'
    type = TemperatureOutflowBC
    variable = temp
    velocity = '0 ${flow_velocity} 0'
  [../]
[]

[Functions]
  [./temp_bc_func]
    type = ParsedFunction
    value = '${ini_temp} - (${ini_temp} - ${diri_temp}) * tanh(t/1e-2)'
  [../]
[]

[Materials]
  [./fuel]
    type = GenericMoltresMaterial
    property_tables_root = '../../property_file_dir/newt_msre_fuel_'
    interp_type = 'spline'
    block = 'fuel'
    prop_names = 'k cp'
    prop_values = '.0553 1967' # Robertson MSRE technical report @ 922 K
  [../]
  [./rho_fuel]
    type = DerivativeParsedMaterial
    f_name = rho
    function = '2.146e-3 * exp(-1.8 * 1.18e-4 * (temp - 922))'
    args = 'temp'
    derivative_order = 1
    block = 'fuel'
  [../]
  [./moder]
    type = GenericMoltresMaterial
    property_tables_root = '../../property_file_dir/newt_msre_mod_'
    interp_type = 'spline'
    prop_names = 'k cp'
    prop_values = '.312 1760' # Cammi 2011 at 908 K
    block = 'moder'
  [../]
  [./rho_moder]
    type = DerivativeParsedMaterial
    f_name = rho
    function = '1.86e-3 * exp(-1.8 * 1.0e-5 * (temp - 922))'
    args = 'temp'
    derivative_order = 1
    block = 'moder'
  [../]
[]

[Executioner]
  type = Transient
  end_time = 10000

  nl_rel_tol = 1e-6
  nl_abs_tol = 1e-5

  solve_type = 'NEWTON'
  petsc_options = '-snes_converged_reason -ksp_converged_reason -snes_linesearch_monitor'
  petsc_options_iname = '-pc_type -pc_factor_shift_type'
  petsc_options_value = 'lu       NONZERO'
  line_search = 'none'
   # petsc_options_iname = '-snes_type'
  # petsc_options_value = 'test'

  nl_max_its = 30
  l_max_its = 100

  [./TimeStepper]
    type = IterationAdaptiveDT
    cutback_factor = 0.4
    growth_factor = 1.2
    optimal_iterations = 20
    dt = 1e-3
  [../]
[]

[Preconditioning]
  [./SMP]
    type = SMP
    full = true
  [../]
[]

[Postprocessors]
  [./temp_fuel]
    type = ElementAverageValue
    variable = temp
    block = 'fuel'
    outputs = 'exodus console'
  [../]
  [./temp_moder]
    type = ElementAverageValue
    variable = temp
    block = 'moder'
    outputs = 'exodus console'
  [../]
[]

[Outputs]
  perf_graph = true
  print_linear_residuals = true
  exodus = true
[]

[Debug]
  show_var_residual_norms = true
[]

[MultiApps]
  [./pres]
    type = TransientMultiApp
    app_type = MoltresApp
    positions = '0 0 0'
    input_files = 'pres.i'
  [../]
[]

[Transfers]
  [./temp_to_sub]
    type = MultiAppCopyTransfer
    direction = to_multiapp
    multi_app = 'pres'
    source_variable = temp
    variable = temp
  [../]
  [./pre1_from_sub]
    type = MultiAppCopyTransfer
    direction = from_multiapp
    multi_app = 'pres'
    source_variable = pre1
    variable = pre1
  [../]
  [./pre2_from_sub]
    type = MultiAppCopyTransfer
    direction = from_multiapp
    multi_app = 'pres'
    source_variable = pre2
    variable = pre2
  [../]
  [./pre3_from_sub]
    type = MultiAppCopyTransfer
    direction = from_multiapp
    multi_app = 'pres'
    source_variable = pre3
    variable = pre3
  [../]
  [./pre4_from_sub]
    type = MultiAppCopyTransfer
    direction = from_multiapp
    multi_app = 'pres'
    source_variable = pre4
    variable = pre4
  [../]
  [./pre5_from_sub]
    type = MultiAppCopyTransfer
    direction = from_multiapp
    multi_app = 'pres'
    source_variable = pre5
    variable = pre5
  [../]
  [./pre6_from_sub]
    type = MultiAppCopyTransfer
    direction = from_multiapp
    multi_app = 'pres'
    source_variable = pre6
    variable = pre6
  [../]
  [./group1_to_sub]
    type = MultiAppCopyTransfer
    direction = to_multiapp
    multi_app = 'pres'
    source_variable = group1
    variable = group1
  [../]
  [./group2_to_sub]
    type = MultiAppCopyTransfer
    direction = to_multiapp
    multi_app = 'pres'
    source_variable = group2
    variable = group2
  [../]
[]
