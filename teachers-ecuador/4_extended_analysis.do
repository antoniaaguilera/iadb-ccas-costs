* ======================================= *
* 	     TEACHER ASSIGNMENT COSTS
* ======================================= *

* ---- PATHS ---- *
global main "/Users/antoniaaguilera/ConsiliumBots Dropbox/antoniaaguilera@consiliumbots.com/projects/iadb-ccas-costs/teachers"
global pathData "$main/data"
global graphs "$main/figures"
global tables "$main/tables"
global git "/Users/antoniaaguilera/GitHub/iadb-ccas-costs"
br
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

* --- Labour Market Parameters --- *
local hrs_teachers      = 44
local hrs_parents       = 45

* --- Application Parameters --- *
local pc_app            = 0.14
local apps_students     = 3
local apps_teachers     = 5

* --- Time Parameters --- *
local time_app_te_d		  = 1      //application time teachers decentralized
local time_app_te_c		  = 0.5    //application time teachers centralizedlocal time_monitoring_t = 0.25   //monitoring  time per school in decentralized system
local time_monitoring_t = 0.25   //monitoring  time per school in decentralized system
local time_staff        = 0.5    //15 minutes per student + 15 minutes reviewing application
local time_staff_c      = 1
local time_transport    = 0.5    //Time spent in transport, all applicants

* --- Teacher Evaluation Parameters --- *
local eval_teachers_d   = 2      //teacher evaluation time in a decentralized system
local eval_teachers_c   = 4		 //teacher evaluation time in a centralized system
local n_interviews      = 3      //teacher interviews in a decentralized system
local eval_cost         = 15     //15 usd ecuador

* --- Other Parameters --- *
local supplycost        = 0.1    //unit supply cost
local datacost          = 1.25   //unit data cost
local contactcost       = 2.53   //unit contact cost
local supportcost       = 0.12   //user support cost per applicant


* ---------------------------------------------------------------- *
* -------------- CATEGORÍA 1: Costos de la Política -------------- *
* ---------------------------------------------------------------- *

replace implementation  = `infra_algorithm' if cost_cat==1
replace yearly_admin    = `process_admin'   if cost_cat==1
*replace  outreach       = `outreach'        if cost_cat==1
replace monitoring      = `monitoring_c'    if cost_cat==1
replace maintenance     = `maintenance'     if cost_cat==1
replace support         = `support_c'       if cost_cat==1

*disminución del 5% en el gasto de difusión, por año, los primeros 5 años
*replace outreach = outreach-outreach*0.02*(year-1) if year<=5
*replace outreach = outreach[5] if year>=6

* -------------- *
* -- TEACHERS -- *
* -------------- *

// Opportunity cost of application time
replace application = teacherwage/monthhrs_teacher*time_per_app*applicants if cost_cat==1

// Opportunity cost of evaluation time + cost of test
replace teachers_eval = teacherwage/monthhrs_teacher*time_eval*applicants  if cost_cat==1

//Evaluation cost for the government
replace teachers_eval_gob = evalcost*applicants                           if cost_cat==1

// Opportunity cost of transport time + fare
replace transport = teacherwage/monthhrs_teacher*time_transport*applicants + (busfare*applicants) if cost_cat==1

// Cost of 1 hour per school of updating vacant seats in platform
replace staff = stateofficialwage/monthhrs*time_staff*schools             if cost_cat == 1

* ---------------------------------------------------------------- *
* ------------- CATEGORÍA 2: Ahorros en Desperdicios ------------- *
* ---------------------------------------------------------------- *

* -------------- *
* -- TEACHERS -- *
* -------------- *

// Time spent by families on application process
replace application = (teacherwage)/monthhrs_teacher*time_per_app*n_apps*applicants if cost_cat==2

// Opportunity cost of evaluation time for teachers
replace teachers_eval = teacherwage/monthhrs_teacher*time_eval*n_apps*applicants    if cost_cat==2

//Evaluation cost for the government
replace teachers_eval_gob = evalcost*n_apps*applicants                              if cost_cat==2

// Opportunity cost of transport time + fare
replace transport = teacherwage/monthhrs_teacher*time_transport*n_apps*applicants + (busfare*applicants)*n_apps if cost_cat==2

// Cost of supplies used in the application process
replace supplies = (supplycost*n_apps*applicants)                                   if cost_cat==2

// Cost of staff working during an application process + 15 usd per applicant
replace staff = stateofficialwage/monthhrs*time_staff*n_apps*applicants + stateofficialwage/monthhrs*time_eval*applicants if cost_cat==2

// Cost of monitoring by authorities
replace monitoring = stateofficialwage/monthhrs*time_monitoring*schools             if cost_cat==2

// Cost of 1 hour per school of coordinating with schools
replace staff = stateofficialwage/monthhrs*time_staff*schools                       if cost_cat == 2


* ----------------------------------------------------------------- *
* ------------- CATEGORÍA 3: BENEFICIO DE LA POLÍTICA ------------- *
* ----------------------------------------------------------------- *

*gen beneficios_mock = (year/2+0.5)^2+1 if cost_cat==3
*replace beneficios_mock = 0 if beneficios_mock==.

* ---- LEARNING GAINS ---- *
*replace learning_gains = `improved_score_vac'*enrollment*st_ratio*`learning_effect'*student_exp*gdp_percap ///
*if cost_cat==3 & applicant_type=="teachers"

* ----------------------------------------------------------------- *
* ---------------------- COSTO POR POSTULANTE --------------------- *
* ----------------------------------------------------------------- *
* --- per applicant --- *
foreach vars in implementation yearly_admin application transport supplies staff monitoring data contact learning_gains teachers_eval_gob {
	replace `vars'= 0 if `vars'==.
	replace `vars'=`vars'/applicants if cost_type=="per_applicant"
}

* ----------------------------------------------------------------- *
* ------------------- COSTO TOTAL POR CATEGORÍA ------------------- *
* ----------------------------------------------------------------- *

egen total_cost     = rowtotal(implementation yearly_admin application transport supplies staff monitoring data contact learning_gains teachers_eval_gob)
replace total_cost  = total_cost/1000000 if year==1
replace total_cost = (yearly_admin + application + transport + supplies + staff + monitoring + data + contact + learning_gains + teachers_eval_gob)/1000000 if year>1

format total_cost %20.01g

* ------------------------------------------------------------------ *
* ------------------------ GRÁFICOS POR AÑO ------------------------ *
* ------------------------------------------------------------------ *
grstyle clear

keep if cost_type=="gross" & country == "ECUADOR"

keep total_cost year cost_cat
reshape wide total_cost@, i(year) j(cost_cat)
*gen estimated_benefit = 4061606/1000000

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
import delimited "$pathData/intermediate/for_extended_analysis.csv", clear
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


* ----------------------------------------------------------------- *
* -------------------- PARAMETER CONFIGURATION -------------------- *
* ----------------------------------------------------------------- *

gen 	time_per_app   = `time_app_te_c'         if cost_cat == 1
replace time_per_app = `time_app_te_d'         if cost_cat == 2

gen time_transport   = `time_transport'

gen n_apps           = `apps_teachers'

gen time_eval        = `eval_teachers_c'       if cost_cat == 1
replace time_eval    = `eval_teachers_d'       if cost_cat == 2

gen time_staff       = `time_staff_c'					 if cost_cat == 1
replace time_staff 	 = `time_staff'  	         if cost_cat == 2

gen time_monitoring  = `time_monitoring_t'     if cost_cat <= 2

gen support_cost     = `supportcost'

gen evalcost         = `eval_cost'
gen supplycost       = `supplycost'
gen dataperapp       = `datacost'
gen contactperapp    = `contactcost'


* --- inicializar variables
foreach x in implementation yearly_admin maintenance outreach monitoring application teachers_eval transport supplies staff data contact learning_gains learning_gains2 teachers_eval_gob{
	gen `x'=.
}

* ---------------------------------------------------------------- *
* -------------- CATEGORÍA 1: Costos de la Política -------------- *
* ---------------------------------------------------------------- *

replace implementation  = `infra_algorithm' if cost_cat == 1
replace yearly_admin    = `process_admin'   if cost_cat == 1
replace  outreach       = `outreach'        if cost_cat == 1
replace monitoring      = `monitoring_c'    if cost_cat == 1
replace maintenance     = `maintenance'     if cost_cat == 1
replace support         = `support_c'       if cost_cat == 1

* --------------- *
* --- TEACHER --- *
* --------------- *

// Opportunity cost of application time
replace application = minwage/monthhrs*time_per_app*applicants             if cost_cat == 1

// Cost of 1 hour per school of updating vacant seats in platform
replace staff = stateofficialwage/monthhrs*time_eval*schools               if cost_cat == 1

// Opportunity cost of evaluation time + cost of test
replace teachers_eval = teacherwage/monthhrs_teacher*time_eval*applicants  if cost_cat == 1

// Evaluation cost for the government
replace teachers_eval_gob =  evalcost*applicants                           if cost_cat == 1

// Opportunity cost of transport time + fare
replace transport = teacherwage/monthhrs_teacher*time_transport*applicants + (busfare*applicants) if cost_cat == 1

// Cost of 1 hour per school of updating vacant seats in platform
replace staff = stateofficialwage/monthhrs*time_staff*schools            if cost_cat == 1


* ---------------------------------------------------------------- *
* ------------- CATEGORÍA 2: Ahorros en Desperdicios ------------- *
* ---------------------------------------------------------------- *

* -------------- *
* -- TEACHERS -- *
* -------------- *

// Time spent by families on application process
replace application = (teacherwage)/monthhrs_teacher*time_per_app*n_apps*applicants  if cost_cat == 2

// Opportunity cost of evaluation time for teachers
replace teachers_eval = teacherwage/monthhrs_teacher*time_eval*n_apps*applicants    if cost_cat == 2

//Evaluation cost for the government
replace teachers_eval_gob = evalcost*n_apps*applicants                              if cost_cat == 2

// Opportunity cost of transport time + fare
replace transport = teacherwage/monthhrs_teacher*time_transport*n_apps*applicants + (busfare*applicants)*n_apps if cost_cat == 2

// Cost of supplies used in the application process
replace supplies = (supplycost*n_apps*applicants)                                   if cost_cat == 2

// Cost of staff working during an application process + 15 usd per applicant
replace staff = stateofficialwage/monthhrs*time_staff*n_apps*applicants + stateofficialwage/monthhrs*time_eval*applicants if cost_cat == 2

// Cost of monitoring by authorities
replace monitoring = stateofficialwage/monthhrs*time_monitoring*schools   if cost_cat == 2


* ----------------------------------------------------------------- *
* ------------- CATEGORÍA 3: Beneficio de la Política ------------- *
* ----------------------------------------------------------------- *


* ----------------------------------------------------------------- *
* ------------------- COSTO TOTAL POR CATEGORÍA ------------------- *
* ----------------------------------------------------------------- *
drop outreach
egen total_cost = rowtotal(implementation yearly_admin maintenance monitoring application teachers_eval transport supplies staff teachers_eval_gob)

format total_cost %20.5f

collapse (sum) total_cost applicants, by(cost_cat year)

drop if year==.
sort cost_cat year applicants
bys cost_cat: gen acc_tot = sum(total_cost)
bys cost_cat: gen acc_teach = sum(applicants)
replace acc_tot = acc_tot/1000000
replace total_cost = total_cost/1000000

* ----------------------------------------------------------------- *
* --------------------------- GRAFICOS ---------------------------- *
* ----------------------------------------------------------------- *
sort year cost_cat
drop if cost_cat == 3
keep year cost_cat applicants total_cost
gen id = _n

reshape wide total_cost@ applicants@, i(id) j(cost_cat)

collapse (firstnm) total_cost1 applicants1 total_cost2, by(year)

export excel "$pathData/output/teachers_pop_ec.xlsx", replace first(var)
