


* ======================================= *
*     ESTIMATE BENEFITS STUDENTS
* ======================================= *

* ---- PREAMBULO ---- *

global main "/Users/antoniaaguilera/ConsiliumBots Dropbox/antoniaaguilera@consiliumbots.com/projects/iadb-ccas-costs"
global pathData "/Users/antoniaaguilera/ConsiliumBots Dropbox/antoniaaguilera@consiliumbots.com/random_data"
global figures "$main/figures"
global tables "$main/tables"
global git "/Users/antoniaaguilera/GitHub/iadb-ccas-costs"



* --------------------------- *
* --------- VA a $$ --------- *
* --------------------------- *
import delimited "$main/data/input_data/TeacherSpending_VA.csv", clear
keep va2_ave_by2 spendingperteacher_by2
sort va2_ave_by2
sum va2_ave_by2

reg spendingperteacher_by2 va2_ave_by2
local beta_va = _b[va2_ave_by2]
local cons_va = _b[_cons]

*tempfile pc_va
*save `pc_va', replace

* -------------------------- *
* ------- estimación ------- *
* -------------------------- *
use "$main/data/for_benefit_estimation.dta", clear
sort rbd year
* --- promedio simple --- *
bys rbd: egen va_mean_simple = mean(va) //promedio simple del VA 2005-2016

* --- comparar los cupos de un año con la matrícula del año siguiente --- *
keep if year>=2018
sort rbd year
sort rbd year
bys rbd: gen cupos_prev = cupos[_n-1]
bys rbd: gen vacs_prev  = vacs[_n-1]

* --- para los casos donde la matrícula es más alta que los cupos/vacantes, voy a suponer que no hay vacantes desiertas --- *
keep if year == 2019 | year == 2020 | year == 2021
tab entry
keep if entry<=1

drop cod_depe cod_nivel cod_jor cod_grado cod_ense con_copago cod_espe cod_reg_rbd cod_com_rbd //botar variables innecesarias

* --- reshape
reshape wide vacs@ cupos@ matricula@ mat_total@ va_mean_simple@ cupos_prev@ vacs_prev@ , i(rbd) j(year)

* --- exceso de matrícula sobre cupos declarados el año anterior
forval x=2019/2021 {
  gen empty_vacs`x'     = 0   if matricula`x' >= cupos_prev`x'
  replace empty_vacs`x' = 1   if matricula`x' <  cupos_prev`x'

  gen n_empty_vacs`x' = 0                                     if empty_vacs`x' == 0
  replace n_empty_vacs`x' = (cupos_prev`x' - matricula`x')  if empty_vacs`x' == 1

  * --- proporción de vacantes vacías
  gen prop_empty`x' = n_empty_vacs`x'/cupos_prev`x'
}

preserve
keep va_mean_simple2019 prop_empty*  vac* cupos* matricula*
order va_mean_simple2019 prop_empty* vac* cupos* matricula*
export excel "$main/data/forbenefits1.xlsx", replace first(variables)
restore

* -----------------------------------------------------------------*
* ----------------- paso a beneficios monetarios ----------------- *
* -----------------------------------------------------------------*
cap drop spending2020
* --- generar gasto
gen spending2020 = `cons_va' + `beta_va'*va_mean_simple2020
replace spending2020 = 0 if spending2020<0

* --- cambios en matrícula según VA
gen delta_mat = matricula2020-matricula2019
gen benefit1 = va_mean_simple2020 * delta_mat * spending2020
bys entry: sum benefit1

* -- guardar data para beneficios
preserve
egen net_benefit1 = sum(benefit1)
keep net_benefit1 benefit1 va_mean_simple2020 delta_mat
export excel "$main/data/forbenefits2.xlsx", replace first(variables)

* -- proyección
keep if _n ==1
expand 10
gen year =_n
gen acumm_benefit = sum(net_benefit1)
gen tot_benefit     = net_benefit1 if year == 1
replace tot_benefit = net_benefit1 + acumm_benefit[_n-1] if year == 2
replace tot_benefit = net_benefit1 + acumm_benefit[_n-1] + acumm_benefit[_n-2]   if year == 3
replace tot_benefit = net_benefit1 + acumm_benefit[_n-1] + acumm_benefit[_n-2] + acumm_benefit[_n-3]  if year == 4
replace tot_benefit = net_benefit1 + acumm_benefit[_n-1] + acumm_benefit[_n-2] + acumm_benefit[_n-3] + acumm_benefit[_n-4] if year == 5
replace tot_benefit = net_benefit1 + acumm_benefit[_n-1] + acumm_benefit[_n-2] + acumm_benefit[_n-3] + acumm_benefit[_n-4] + acumm_benefit[_n-5] if year == 6
replace tot_benefit = net_benefit1 + acumm_benefit[_n-1] + acumm_benefit[_n-2] + acumm_benefit[_n-3] + acumm_benefit[_n-4] + acumm_benefit[_n-5] + acumm_benefit[_n-6]  if year == 7
replace tot_benefit = net_benefit1 + acumm_benefit[_n-1] + acumm_benefit[_n-2] + acumm_benefit[_n-3] + acumm_benefit[_n-4] + acumm_benefit[_n-5] + acumm_benefit[_n-6] + acumm_benefit[_n-7] if year == 8
replace tot_benefit = net_benefit1 + acumm_benefit[_n-1] + acumm_benefit[_n-2] + acumm_benefit[_n-3] + acumm_benefit[_n-4] + acumm_benefit[_n-5] + acumm_benefit[_n-6] + acumm_benefit[_n-7] + acumm_benefit[_n-8] if year == 9
replace tot_benefit = net_benefit1 + acumm_benefit[_n-1] + acumm_benefit[_n-2] + acumm_benefit[_n-3] + acumm_benefit[_n-4] + acumm_benefit[_n-5] + acumm_benefit[_n-6] + acumm_benefit[_n-7] + acumm_benefit[_n-8] + acumm_benefit[_n-9] if year == 10

replace tot_benefit = (tot_benefit)/1000
export excel "$main/data/forbenefits3.xlsx", replace  first(variables)
restore

* ------------------------------------------------------------------*
* ------------------- DATA PARA GRAFICOS SIMCE  ------------------- *
* ------------------------------------------------------------------*

preserve
keep ave ave_st prop_empty*  vac* cupos* matricula*
order ave ave_st prop_empty*  vac* cupos* matricula*
export excel "$main/data/forbenefits4.xlsx", replace first(variables)
restore
