* ======================================= *
* 	     TEACHER ASSIGNMENT COSTS
* ======================================= *

* ---- PATHS ---- *

global main "/Users/antoniaaguilera/ConsiliumBots Dropbox/antoniaaguilera@consiliumbots.com/projects/iadb-ccas-costs/teachers"
global pathData "$main/data"
global graphs "$main/figures"
global tables "$main/tables"
global git "/Users/antoniaaguilera/GitHub/iadb-ccas-costs"

* -------------------------------------------------------------------------- *
* -------------------- ESTIMATION BY PLACE AND CATEGORY -------------------- *
* -------------------------------------------------------------------------- *
clear all 

* --------------------------------------- *
* ----------- SET PARAMETERS  ----------- *
* --------------------------------------- *
{
* --- Policy Costs Parameters --- *
local infra_algorithm   = 186000 //cost of tech infraestructure and algorithm creation
local process_admin     = 50000  //administration of the yearly assignment process
local outreach          = 248000 //outreach and information during the assignment process
local monitoring_c      = 0 //monitoring and user support
local support_c 		    = 60340 //3308635*0.14*105/806
local maintenance       = 7000 //annual maintenance of the system
}

import delimited "$pathData/intermediate/for_cost_calculation.csv", clear 


* ---------------------------------------------------------------- *
* -------------- CATEGORÍA 1: Costos de la Política -------------- *
* ---------------------------------------------------------------- *

replace implementation  = `infra_algorithm' if cost_cat==1 
replace yearly_admin    = `process_admin'   if cost_cat==1
*replace  outreach       = `outreach'        if cost_cat==1
replace monitoring      = `monitoring_c'    if cost_cat==1 
*replace maintenance     = `maintenance'     if cost_cat==1
*replace support    = `support_c'   if cost_cat==1

* -------------- *
* -- TEACHERS -- *
* -------------- *

// Opportunity cost of application time 
replace application = teacherwage/monthhrs_teacher*`time_app_te_c' *applicants if cost_cat==1

// Opportunity cost of evaluation time + cost of test
replace teachers_eval = teacherwage/monthhrs_teacher*time_eval*applicants  if cost_cat==1

//Evaluation cost for the government
replace teachers_eval_gob =  `eval_cost'*applicants if cost_cat==1

// Opportunity cost of transport time + fare
replace transport = teacherwage/monthhrs_teacher*time_transport*applicants + (busfare*applicants) if cost_cat==1

// Cost of 1 hour per school of updating vacant seats in platform 
replace staff = stateofficialwage/monthhrs*`time_staff_c'*schools if cost_cat == 1

* ---------------------------------------------------------------- *
* ------------- CATEGORÍA 2: Ahorros en Desperdicios ------------- *
* ---------------------------------------------------------------- *
{
* -------------- *
* -- TEACHERS -- *
* -------------- *

// Time spent by families on application process
replace application = (teacherwage)/monthhrs_teacher*`time_app_te_d'*n_apps*applicants  if cost_cat==2

// Opportunity cost of evaluation time for teachers
replace teachers_eval = teacherwage/monthhrs_teacher*time_eval*n_apps*applicants  if cost_cat==2

//Evaluation cost for the government
replace teachers_eval_gob =  `eval_cost'*n_apps*applicants if cost_cat==2 

// Opportunity cost of transport time + fare
replace transport = teacherwage/monthhrs_teacher*time_transport*n_apps*applicants + (busfare*applicants)*n_apps if cost_cat==2

// Cost of supplies used in the application process
replace supplies = (supplycost*n_apps*applicants) if cost_cat==2

// Cost of staff working during an application process + 15 usd per applicant
replace staff = stateofficialwage/monthhrs*`time_staff'*n_apps*applicants + ///
				stateofficialwage/monthhrs*time_eval*applicants if cost_cat==2

// Cost of monitoring by authorities
replace monitoring = stateofficialwage/monthhrs*time_monitoring*schools  if cost_cat==2

// Cost of 1 hour per school of coordinating with schools 
replace staff = stateofficialwage/monthhrs*`time_staff_c'*schools if cost_cat == 2

}

* ----------------------------------------------------------------- *
* ------------- CATEGORÍA 3: Beneficio de la Política ------------- *
* ----------------------------------------------------------------- *
{
* ---- DATA & CONTACT INFORMATION ---- *
*replace data    = dataperapp*applicants     ///
*if cost_cat==3

*replace contact = contactperapp*applicants  ///
*if cost_cat==3

* ---- LEARNING GAINS ---- *
replace learning_gains = `improved_score_vac'*enrollment*st_ratio*`learning_effect'*student_exp*gdp_percap if cost_cat==3
}

* ----------------------------------------------------------------- *
* ---------------------- COSTO POR POSTULANTE --------------------- *
* ----------------------------------------------------------------- *
* --- per applicant --- *
foreach vars in implementation yearly_admin application teachers_eval transport supplies staff monitoring data contact learning_gains teachers_eval_gob maintenance outreach{
	replace `vars'=`vars'/applicants if cost_type=="per_applicant"
	replace `vars'= 0 if `vars'==.
}

* ----------------------------------------------------------------- *
* ------------------- COSTO TOTAL POR CATEGORÍA ------------------- *
* ----------------------------------------------------------------- *
{
egen total_cost=rowtotal(implementation yearly_admin ///
application teachers_eval transport supplies staff monitoring ///
data contact learning_gains)

format total_cost %20.01f

sort place_code applicant_type cost_type cost_cat 
rename cost_cat cost_cat2
gen cost_cat=cost_cat2
order place_code place_name country cost_cat

keep if place_code=="ecuador_country" & applicant_type=="teachers"

keep place_name place_code cost_cat2 cost_type implementation yearly_admin maintenance staff outreach monitoring application teachers_eval transport supplies data contact learning_gains learning_gains2 teachers_eval_gob total_cost
order place_name place_code cost_cat2 cost_type implementation yearly_admin maintenance staff outreach monitoring application teachers_eval transport supplies data contact learning_gains learning_gains2 teachers_eval_gob total_cost

gen support = 0
gen admin = implementation + outreach + teachers_eval_gob + yearly_admin + maintenance + support + monitoring if cost_cat == 1
replace admin = staff + monitoring if cost_cat == 2

gen schools = staff if cost_cat == 1
replace schools = staff + supplies + teachers_eval_gob if cost_cat == 2

gen teachers = application + teachers_eval + transport if cost_cat == 1
replace teachers = application + teachers_eval + transport if cost_cat == 2

cap drop total_cost
gen total_cost = schools + admin + teachers 
 
export excel "$main/output_data/cost_teachers_ec.xlsx", replace first(var)

}

