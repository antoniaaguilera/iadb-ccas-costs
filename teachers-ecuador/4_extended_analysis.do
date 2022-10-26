* ======================================= *
* 	     TEACHER ASSIGNMENT COSTS
* ======================================= *

* ---- PATHS ---- *
global main "/Users/antoniaaguilera/ConsiliumBots Dropbox/antoniaaguilera@consiliumbots.com/projects/iadb-ccas-costs/teachers"
global pathData "$main/data"
global graphs "$main/figures"
global tables "$main/tables"
global git "/Users/antoniaaguilera/GitHub/iadb-ccas-costs"

* --------------------------------------------------------------------- *
* ------------------------ EXTENDED ANALYSIS I ------------------------ *
* --------------------------------------------------------------------- *

import delimited "$pathData/intermediate/for_cost_calculation.csv", clear


local pc_app = 0.14

expand 10
bys applicant_type place_code cost_cat cost_type: gen year=_n
bys applicant_type place_code cost_cat cost_type: gen y2_2059 = y_2059 if _n == 1
bys applicant_type place_code cost_cat cost_type: replace y2_2059 = y_2059 + y_2059[_n-1]*0.01 if _n > 1

sort applicant_type cost_cat cost_type year

* --- project population growth --- *
gen enrollment_proj     = enrollment ///
if year==1

bys applicant_type cost_cat cost_type: replace enrollment_proj = round(enrollment_proj[_n-1]+enrollment_proj[_n-1]*y2_2059, 1) ///
if year>1 & year<=10

replace applicants=enrollment_proj*`pc_app'
drop enrollment
rename enrollment_proj enrollment

* ----------------------------------------------------------------- *
* -------------------- PARAMETER CONFIGURATION -------------------- *
* ----------------------------------------------------------------- *

* --------------------------------------- *
* ----------- SET PARAMETERS  ----------- *
* --------------------------------------- *

* --- Policy Costs Parameters --- *
local infra_algorithm   = 247860 //perú
local process_admin     = 50000  //ecuador
*local outreach          = 248000 //outreach and information during the assignment process
local monitoring_c      = 0 //monitoring and user support
local support_c 	    	= applicants[1]*105/806 //3308635*0.14*105/806
local maintenance       = 7000 //annual maintenance of the system

* ---------------------------------------------------------------- *
* -------------- CATEGORÍA 1: Costos de la Política -------------- *
* ---------------------------------------------------------------- *

replace implementation  = `infra_algorithm' if cost_cat==1
replace yearly_admin    = `process_admin'   if cost_cat==1
*replace  outreach       = `outreach'        if cost_cat==1
replace monitoring_dc   = `monitoring_c'    if cost_cat==1
replace monitoring_sc   = `monitoring_c'    if cost_cat==1
replace maintenance     = `maintenance'     if cost_cat==1
replace support         = `support_c'       if cost_cat==1

*disminución del 5% en el gasto de difusión, por año, los primeros 5 años
*replace outreach = outreach-outreach*0.02*(year-1) if year<=5
*replace outreach = outreach[5] if year>=6

* ------------------ *
* -- CENTRALIZADO -- *
* ------------------ *

// Opportunity cost of application time
replace application_dc = teacherwage/monthhrs_teacher*time_per_app*applicants if cost_cat == 1
replace application_sc = teacherwage/monthhrs_teacher*time_per_app*applicants if cost_cat == 1

// Opportunity cost of evaluation time + cost of test
replace teachers_eval_dc = teacherwage/monthhrs_teacher*time_eval*applicants  if cost_cat == 1
replace teachers_eval_sc = teacherwage/monthhrs_teacher*time_eval*applicants  if cost_cat == 1

// Cost of supplies used in the application process
*replace supplies = (supplycost*n_apps*applicants) if cost_cat == 1

//Evaluation cost for the government
replace teachers_eval_gob_dc = evalcost*applicants if cost_cat == 1
replace teachers_eval_gob_sc = evalcost*applicants if cost_cat == 1

// Opportunity cost of transport time (evaluation) + fare
replace transport_dc = teacherwage/monthhrs_teacher*time_transport_sc*applicants + (busfare*applicants) if cost_cat == 1
replace transport_sc = teacherwage/monthhrs_teacher*time_transport_sc*applicants + (busfare*applicants) if cost_cat == 1

// Cost of 1 hour per school of updating vacant seats in platform
replace staff_dc = stateofficialwage/monthhrs*time_staff*schools if cost_cat == 1
replace staff_sc = stateofficialwage/monthhrs*time_staff*schools if cost_cat == 1

// Cost of monitoring by authorities
*replace monitoring_dc = stateofficialwage/monthhrs*time_monitoring*schools if cost_cat == 1
*replace monitoring_sc = stateofficialwage/monthhrs*time_monitoring*schools if cost_cat == 1

* ---------------------------------------------------------------- *
* ------------- CATEGORÍA 2: Ahorros en Desperdicios ------------- *
* ---------------------------------------------------------------- *

* ------------------------- *
* -- SEMI - CENTRALIZADO -- *
* ------------------------- *
// Time spent by families on application process
replace application_sc = (teacherwage)/monthhrs_teacher*2*time_per_app*applicants  if cost_cat == 2

// Opportunity cost of evaluation time for teachers
replace teachers_eval_sc = teacherwage/monthhrs_teacher*time_eval*applicants     if cost_cat == 2

//Evaluation cost for the government
replace teachers_eval_gob_sc = evalcost*applicants if cost_cat == 2

// Opportunity cost of transport time (application) + transport time (evaluation) + fare
replace transport_sc = teacherwage/monthhrs_teacher*time_transport_sc*applicants*2 + (busfare*applicants)*2 if cost_cat == 2

// Cost of supplies used in the application process
replace supplies_sc = (supplycost*applicants) if cost_cat == 2

// Cost of staff working during an application process
replace staff_sc = stateofficialwage/monthhrs*time_staff*applicants + stateofficialwage/monthhrs*time_eval*applicants if cost_cat == 2

// Cost of monitoring by authorities
replace monitoring_sc = 3*stateofficialwage/monthhrs*time_monitoring*schools  if cost_cat == 2

// Cost of staff working during an application process
replace staff_sc = stateofficialwage/monthhrs*time_staff*applicants + stateofficialwage/monthhrs*time_eval*applicants if cost_cat == 2

// Cost of school staff working during an application process
replace staff2_sc = stateofficialwage/monthhrs*time_staff*schools if cost_cat == 2

* ------------------------- *
* ---- DESCENTRALIZADO ---- *
* ------------------------- *

// Time spent by families on application process
replace application_dc = (teacherwage)/monthhrs_teacher*time_per_app*n_apps*applicants  if cost_cat == 2

// Opportunity cost of evaluation time for teachers
replace teachers_eval_dc = teacherwage/monthhrs_teacher*time_eval*n_apps*applicants     if cost_cat == 2

//Evaluation cost for the government
replace teachers_eval_gob_dc = evalcost*n_apps*applicants if cost_cat == 2

// Opportunity cost of transport time (application) + transport time (evaluation) + fare
replace transport_dc = teacherwage/monthhrs_teacher*time_transport_dc*applicants + teacherwage/monthhrs_teacher*time_transport_sc*applicants + (busfare*applicants)*(n_apps + 1) if cost_cat == 2

// Cost of supplies used in the application process
replace supplies_dc = (supplycost*n_apps*applicants) if cost_cat == 2

// Cost of staff working during an application process
replace staff_dc = stateofficialwage/monthhrs*time_staff*n_apps*applicants + stateofficialwage/monthhrs*time_eval*applicants if cost_cat == 2

// Cost of monitoring by authorities
replace monitoring_dc = stateofficialwage/monthhrs*time_monitoring*schools  if cost_cat == 2

* ----------------------------------------------------------------- *
* ------------- CATEGORÍA 3: BENEFICIO DE LA POLÍTICA ------------- *
* ----------------------------------------------------------------- *

// gen beneficios_mock = ((year/3+0.5)^1.3+1)*1000000 if cost_cat==3
// replace beneficios_mock = 0 if beneficios_mock==.
gen beneficios_mock = 0 
* ---- LEARNING GAINS ---- *
*replace learning_gains = `improved_score_vac'*enrollment*st_ratio*`learning_effect'*student_exp*gdp_percap ///
*if cost_cat==3 & applicant_type=="teachers"

* ----------------------------------------------------------------- *
* ---------------------- COSTO POR POSTULANTE --------------------- *
* ----------------------------------------------------------------- *
* --- per applicant --- *
foreach x in implementation yearly_admin maintenance outreach support data contact learning_gains learning_gains2 {
	replace `x' =`x'/applicants if cost_type == "per_applicant"
	replace `x' = 0 			if `x' 		 == .
}

* --- savings variables
foreach x in application teachers_eval teachers_eval_gob transport supplies staff staff2 monitoring {
	replace `x'_dc =`x'_dc/applicants if cost_type == "per_applicant"
	replace `x'_dc = 0  		      if `x'_dc    == .
	
	replace `x'_sc =`x'_sc/applicants if cost_type == "per_applicant"
	replace `x'_sc = 0 			      if `x'_sc    == .
}

* ----------------------------------------------------------------- *
* ------------------- COSTO TOTAL POR CATEGORÍA ------------------- *
* ----------------------------------------------------------------- *
keep  year country applicant_type cost_cat cost_type applicants implementation yearly_admin maintenance outreach support* monitoring* application* teachers_eval* transport* supplies* staff* data* contact* learning_gains* learning_gains2* teachers_eval_gob* beneficios_mock
order year country applicant_type cost_cat cost_type applicants implementation yearly_admin maintenance outreach support* monitoring* application* teachers_eval* transport* supplies* staff* data* contact* learning_gains* learning_gains2* teachers_eval_gob* beneficios_mock
 
gen total_cost_dc      = implementation + yearly_admin + maintenance + outreach + support + monitoring_dc + application_dc + teachers_eval_dc + transport_dc + supplies_dc + staff_dc + staff2_dc + data + contact + learning_gains + learning_gains2 + teachers_eval_gob_dc + beneficios_mock if year==1
replace total_cost_dc  = yearly_admin + maintenance + outreach + support + monitoring_dc + application_dc + teachers_eval_dc + transport_dc + supplies_dc + staff_dc + staff2_dc + data + contact + learning_gains + learning_gains2+ teachers_eval_gob_dc + beneficios_mock                   if year>1
replace total_cost_dc   = total_cost_dc/1000000

gen total_cost_sc      = implementation + yearly_admin + maintenance + outreach + support + monitoring_sc + application_sc + teachers_eval_sc + transport_sc + supplies_sc + staff_sc + staff2_sc + data + contact + learning_gains + learning_gains2 + teachers_eval_gob_sc + beneficios_mock if year==1
replace total_cost_sc  = yearly_admin + maintenance + outreach + support + monitoring_sc + application_sc + teachers_eval_sc + transport_sc + supplies_sc + staff_sc + staff2_sc + data + contact + learning_gains + learning_gains2+ teachers_eval_gob_sc + beneficios_mock                   if year>1
replace total_cost_sc   = total_cost_sc/1000000

format total_cost_sc total_cost_sc %10.3f


* ------------------------------------------------------------------ *
* ------------------------ GRÁFICOS POR AÑO ------------------------ *
* ------------------------------------------------------------------ *

keep if cost_type=="gross" & country == "ECUADOR"

keep total_cost_dc total_cost_sc year cost_cat
reshape wide total_cost_dc@ total_cost_sc@, i(year) j(cost_cat)

order year *_dc* *_sc*
export excel "$pathData/output/teachers_proj_ec.xlsx", replace first(var)


* ---------------------------------------------------------------------- *
* ------------------------ EXTENDED ANALYSIS II ------------------------ *
* ---------------------------------------------------------------------- *

clear all
set obs 500

local pc_app = 0.14
* ---  generate population numbers
gen year = _n
gen population_teachers = 500
replace population_teachers = sum(population_teachers)

gen country = "ECUADOR"

tempfile population
save `population', replace

* --- llamar costos
import delimited "$pathData/intermediate/for_cost_calculation.csv", clear
keep if _n == 1

merge 1:m country using `population', update
drop _merge
cap drop applicants
gen applicants = population_teachers*`pc_app'

expand 3
drop cost_cat
bys year: gen cost_cat = 1      if _n == 1
bys year: replace cost_cat = 2  if _n == 2
bys year: replace cost_cat = 3  if _n == 3

* --- Policy Costs Parameters --- *
local infra_algorithm   = 247860 //perú
local process_admin     = 50000  //ecuador
*local outreach          = 248000 //outreach and information during the assignment process
local monitoring_c      = 0 //monitoring and user support
local support_c 	    	= applicants[1]*105/806 //3308635*0.14*105/806
local maintenance       = 7000 //annual maintenance of the system

* ---------------------------------------------------------------- *
* -------------- CATEGORÍA 1: Costos de la Política -------------- *
* ---------------------------------------------------------------- *

replace implementation  = `infra_algorithm' if cost_cat==1
replace yearly_admin    = `process_admin'   if cost_cat==1
*replace  outreach       = `outreach'        if cost_cat==1
replace monitoring_dc   = `monitoring_c'    if cost_cat==1
replace monitoring_sc   = `monitoring_c'    if cost_cat==1
replace maintenance     = `maintenance'     if cost_cat==1
replace support         = `support_c'       if cost_cat==1

*disminución del 5% en el gasto de difusión, por año, los primeros 5 años
*replace outreach = outreach-outreach*0.02*(year-1) if year<=5
*replace outreach = outreach[5] if year>=6

* ------------------ *
* -- CENTRALIZADO -- *
* ------------------ *

// Opportunity cost of application time
replace application_dc = teacherwage/monthhrs_teacher*time_per_app*applicants if cost_cat == 1
replace application_sc = teacherwage/monthhrs_teacher*time_per_app*applicants if cost_cat == 1

// Opportunity cost of evaluation time + cost of test
replace teachers_eval_dc = teacherwage/monthhrs_teacher*time_eval*applicants  if cost_cat == 1
replace teachers_eval_sc = teacherwage/monthhrs_teacher*time_eval*applicants  if cost_cat == 1

// Cost of supplies used in the application process
*replace supplies = (supplycost*n_apps*applicants) if cost_cat == 1

//Evaluation cost for the government
replace teachers_eval_gob_dc = evalcost*applicants if cost_cat == 1
replace teachers_eval_gob_sc = evalcost*applicants if cost_cat == 1

// Opportunity cost of transport time (evaluation) + fare
replace transport_dc = teacherwage/monthhrs_teacher*time_transport_sc*applicants + (busfare*applicants) if cost_cat == 1
replace transport_sc = teacherwage/monthhrs_teacher*time_transport_sc*applicants + (busfare*applicants) if cost_cat == 1

// Cost of 1 hour per school of updating vacant seats in platform
replace staff_dc     = stateofficialwage/monthhrs*time_staff*schools if cost_cat == 1
replace staff_sc     = stateofficialwage/monthhrs*time_staff*schools if cost_cat == 1

// Cost of monitoring by authorities
*replace monitoring_dc = stateofficialwage/monthhrs*time_monitoring*schools if cost_cat == 1
*replace monitoring_sc = stateofficialwage/monthhrs*time_monitoring*schools if cost_cat == 1

* ---------------------------------------------------------------- *
* ------------- CATEGORÍA 2: Ahorros en Desperdicios ------------- *
* ---------------------------------------------------------------- *

* ------------------------- *
* -- SEMI - CENTRALIZADO -- *
* ------------------------- *
// Time spent by families on application process
replace application_sc = (teacherwage)/monthhrs_teacher*2*time_per_app*applicants  if cost_cat == 2

// Opportunity cost of evaluation time for teachers
replace teachers_eval_sc = teacherwage/monthhrs_teacher*time_eval*applicants     if cost_cat == 2

//Evaluation cost for the government
replace teachers_eval_gob_sc = evalcost*applicants if cost_cat == 2

// Opportunity cost of transport time (application) + transport time (evaluation) + fare
replace transport_sc = teacherwage/monthhrs_teacher*time_transport_sc*applicants*2 + (busfare*applicants)*2 if cost_cat == 2

// Cost of supplies used in the application process
replace supplies_sc = (supplycost*applicants) if cost_cat == 2

// Cost of staff working during an application process
replace staff_sc = stateofficialwage/monthhrs*time_staff*applicants + stateofficialwage/monthhrs*time_eval*applicants if cost_cat == 2

// Cost of monitoring by authorities
replace monitoring_sc = 3*stateofficialwage/monthhrs*time_monitoring*schools  if cost_cat == 2

// Cost of staff working during an application process
replace staff_sc = stateofficialwage/monthhrs*time_staff*applicants + stateofficialwage/monthhrs*time_eval*applicants if cost_cat == 2

// Cost of school staff working during an application process
replace staff2_sc = stateofficialwage/monthhrs*time_staff*schools if cost_cat == 2

* ------------------------- *
* ---- DESCENTRALIZADO ---- *
* ------------------------- *

// Time spent by families on application process
replace application_dc = (teacherwage)/monthhrs_teacher*time_per_app*n_apps*applicants  if cost_cat == 2

// Opportunity cost of evaluation time for teachers
replace teachers_eval_dc = teacherwage/monthhrs_teacher*time_eval*n_apps*applicants     if cost_cat == 2

//Evaluation cost for the government
replace teachers_eval_gob_dc = evalcost*n_apps*applicants if cost_cat == 2

// Opportunity cost of transport time (application) + transport time (evaluation) + fare
replace transport_dc = teacherwage/monthhrs_teacher*time_transport_dc*applicants + teacherwage/monthhrs_teacher*time_transport_sc*applicants + (busfare*applicants)*(n_apps + 1) if cost_cat == 2

// Cost of supplies used in the application process
replace supplies_dc = (supplycost*n_apps*applicants) if cost_cat == 2

// Cost of staff working during an application process
replace staff_dc = stateofficialwage/monthhrs*time_staff*n_apps*applicants + stateofficialwage/monthhrs*time_eval*applicants if cost_cat == 2

// Cost of monitoring by authorities
replace monitoring_dc = stateofficialwage/monthhrs*time_monitoring*schools  if cost_cat == 2

* ----------------------------------------------------------------- *
* ---------------------- COSTO POR POSTULANTE --------------------- *
* ----------------------------------------------------------------- *
* --- per applicant --- *
foreach x in implementation yearly_admin maintenance outreach support data contact learning_gains learning_gains2 {
	replace `x' =`x'/applicants if cost_type == "per_applicant"
	replace `x' = 0 			if `x' 		 == .
}

* --- savings variables
foreach x in application teachers_eval teachers_eval_gob transport supplies staff staff2 monitoring {
	replace `x'_dc =`x'_dc/applicants if cost_type == "per_applicant"
	replace `x'_dc = 0  		      if `x'_dc    == .
	
	replace `x'_sc =`x'_sc/applicants if cost_type == "per_applicant"
	replace `x'_sc = 0 			      if `x'_sc    == .
}
 
* ----------------------------------------------------------------- *
* ------------------- COSTO TOTAL POR CATEGORÍA ------------------- *
* ----------------------------------------------------------------- *

gen total_cost_dc = implementation + yearly_admin + maintenance + outreach + support + monitoring_dc + application_dc + teachers_eval_dc + transport_dc + supplies_dc + staff_dc + staff2_dc + data + contact + learning_gains + learning_gains2 + teachers_eval_gob_dc 
gen total_cost_sc = implementation + yearly_admin + maintenance + outreach + support + monitoring_sc + application_sc + teachers_eval_sc + transport_sc + supplies_sc + staff_sc + staff2_sc + data + contact + learning_gains + learning_gains2 + teachers_eval_gob_sc 

format total_cost_dc total_cost_sc %20.5f

collapse (sum) total_cost_dc total_cost_sc applicants, by(cost_cat year)

drop if year==.
sort cost_cat year applicants
bys cost_cat: gen acc_tot_dc   = sum(total_cost_dc)
bys cost_cat: gen acc_teach_dc = sum(applicants)
replace acc_tot_dc             = acc_tot_dc/1000000
replace total_cost_dc          = total_cost_dc/1000000

bys cost_cat: gen acc_tot_sc   = sum(total_cost_sc)
bys cost_cat: gen acc_teach_sc = sum(applicants)
replace acc_tot_sc             = acc_tot_sc/1000000
replace total_cost_sc          = total_cost_sc/1000000

* ----------------------------------------------------------------- *
* --------------------------- GRAFICOS ---------------------------- *
* ----------------------------------------------------------------- *
sort year cost_cat
drop if cost_cat == 3
keep year cost_cat applicants total_cost_dc total_cost_sc
gen id = _n

reshape wide total_cost_dc@ total_cost_sc@ applicants@, i(id) j(cost_cat)

collapse (firstnm) total_cost_dc1 total_cost_dc2 total_cost_sc1 total_cost_sc2 applicants1 , by(year)

export excel "$pathData/output/teachers_pop_ec.xlsx", replace first(var)

// agregar una sección en donde se diga explicitamente: dos columnas para un administrador
// desagregación de costos: gráfico de barras explícitos vs implícitos por sistema
// subir a la carpeta
// herramienta para hacer cálculos, podría ser una pestaña extra
