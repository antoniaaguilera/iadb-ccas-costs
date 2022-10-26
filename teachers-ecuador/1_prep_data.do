* =========================================== *
*   PREP DATA FOR COST ESTIMATION
* =========================================== *

* ---- SET PATHS ---- *

global main "/Users/antoniaaguilera/ConsiliumBots Dropbox/antoniaaguilera@consiliumbots.com/projects/iadb-ccas-costs/teachers"
global pathData "$main/data"

* ========================================================== *
*          ----- CLEAN DATA FOR DISTANCE -----
* ========================================================== *
* --- prepare data --- *
import delimited "$pathData/input/Institutions.csv", clear 
keep institution_id institution_name institution_lat institution_long

tempfile institution
save `institution', replace //3345 institutions

use "$pathData/input/Programs.dta", clear
merge m:1 institution_id using `institution'
keep program_id institution_id institution_lat institution_long

tempfile program
save `program', replace 

use "$pathData/input/Base para estimaciones.dta", clear
keep teacher_id application_id teacher_lat teacher_long

tempfile applicants
save `applicants', replace 

import delimited "$pathData/input/Application.csv", clear
keep institution_id teacher_id program_id application_id
// applications per applicant 
bys teacher_id: egen applications = count(program_id)
sum applications

merge m:1 teacher_id using `applicants'
keep if _m ==3 
drop _merge 

tempfile application
save `application', replace 

* --- merge data --- *
use `program', clear 
merge 1:m institution_id program_id using `application'
keep if _m == 3
drop _merge 

* ----------------------------------------------------------- *
* ---------- DISTANCE AND TRAVEL TIME CALCULATIONS ---------- *
* ----------------------------------------------------------- *
// public transport speed in Ecuador: 18 km/h according to: https://www.nacion.com/el-mundo/interes-humano/ecuador-tendra-un-metro-que-duplicara-velocidad-de-transporte-publico-en-quito/LFOLDDDGYVERVK3I6WDNU7WYCE/story/

// distance 
geodist teacher_lat teacher_long institution_lat institution_long, g(distance)

// travel time 
local speed = 18 // km/h
gen travel_time = distance/18 
sum travel_time
local travel_time_sc = `r(mean)'

// total travel time per teacher 
bys teacher_id: egen sum_travel_time = sum(travel_time)
sum sum_travel_time
local travel_time_dc = `r(mean)'
 
* ========================================================== *
*          ----- CLEAN DATA FOR COST ESTIMATION -----
* ========================================================== *

import excel "$pathData/input/parameters.xlsx", clear first

* --------------------------------------- *
* ----------- SET PARAMETERS  ----------- *
* --------------------------------------- *

* --- Policy Costs Parameters --- *
local infra_algorithm   = 247860 //perú
local process_admin     = 50000  //ecuador
local outreach          = 248000 //outreach and information during the assignment process
local monitoring_c      = 0 //monitoring and user support
local support_c 		    = 60340 //3308635*0.14*105/806
local maintenance       = 7000 //annual maintenance of the system

* --- Labour Market Parameters --- *
local hrs_teachers      = 44
local hrs_parents       = 45

* --- Application Parameters --- *
local pc_app            = 0.14
local apps_teachers     = 5
local schools			= 0.25 //25% of schools receive applicants (estimate based on 3345 institutions with applications in the QSM7 process of a total of 13144 schools in the country)

* --- Teacher Evaluation Parameters --- *
local eval_teachers_d   = 2      //teacher evaluation time in a decentralized system
local eval_teachers_c   = 4		 //teacher evaluation time in a centralized system
local n_interviews      = 3      //teacher interviews in a decentralized system
local eval_cost         = 15     //15 usd ecuador

* --- Time Parameters --- *
local time_app_te_d	  	= 1      //application time teachers decentralized
local time_app_te_c	  	= 0.5    //application time teachers centralized
local time_monitoring_t = 0.25   //monitoring  time per school in decentralized system
local time_staff        = 0.5    //15 minutes per student + 15 minutes reviewing application
local time_staff_c      = 1
local time_transport_dc  = `travel_time_dc'    //Time spent in transport, all applicants
local time_transport_sc  = `travel_time_sc'    //Time spent in transport, all applicants

* --- Learning Gains Parameters --- *
local improved_score_vac = 0.011  //nº of position where teacher's score is improved as a % of total teachers
local learning_effect    = 1/3    //impact of improving teachers as a fraction of the yearly learning in std dev
local loss_income        = 0.025  //% of life loss income due to learning losses
local discount_rate      = 0.03
local wage_growth	 	     = 0.02

* --- Other Parameters --- *
local supplycost        = 0.1    //unit supply cost
local datacost          = 1.25   //unit data cost
local contactcost       = 2.53   //unit contact cost
local supportcost       = 0.12   //user support cost per applicant


* --------------------------------------- *
* ------------ RE-WORK DATA  ------------ *
* --------------------------------------- *

keep place_code place_name country enrollment_students enrollment_teachers xchange_rate ///
schools minwage busfare teacherwage stateofficialwage student_exp gdp_percap st_ratio teny_519 y_519 teny_2059 y_2059 population

drop if place_code==""

foreach vars in minwage busfare teacherwage stateofficialwage {
	gen `vars'_local = `vars'
	replace `vars' = `vars'*xchange_rate
}

reshape long enrollment_@ , i(place_code) j(applicant_type) s

rename enrollment_ enrollment

// postulantes y otros parámetros
gen applicants         = enrollment*`pc_app'
replace schools 	   = schools+`schools'
gen monthhrs           = 4*`hrs_parents'
gen monthhrs_teacher   = 4*`hrs_teachers'

//expandir por categoría
expand 3
gen cost_cat=.
bys place_code applicant_type: replace cost_cat=_n
order place_code place_name country applicant_type cost_cat
sort place_code applicant_type cost_cat

expand 2
gen cost_type=""
bys place_code applicant_type cost_cat: replace cost_type="gross" if _n==1
bys place_code applicant_type cost_cat: replace cost_type="per_applicant" if _n==2
order place_code place_name country applicant_type cost_cat cost_type
sort place_code applicant_type cost_cat cost_type

keep if place_code=="ecuador_country" & applicant_type=="teachers"

* ----------------------------------------------------------------- *
* -------------------- PARAMETER CONFIGURATION -------------------- *
* ----------------------------------------------------------------- *

gen 	time_per_app   = `time_app_te_c'       if cost_cat == 1
replace time_per_app = `time_app_te_d'         if cost_cat == 2

gen time_transport_dc   = `time_transport_dc'
gen time_transport_sc   = `time_transport_sc'


gen n_apps           = `apps_teachers'

gen time_eval        = `eval_teachers_c'       if cost_cat == 1
replace time_eval    = `eval_teachers_d'       if cost_cat == 2

gen time_staff       = `time_staff_c'		   if cost_cat == 1
replace time_staff 	 = `time_staff'  	       if cost_cat == 2

gen time_monitoring  = `time_monitoring_t'     if cost_cat <= 2

gen support_cost     = `supportcost'

gen evalcost         = `eval_cost'
gen supplycost       = `supplycost'
gen dataperapp       = `datacost'
gen contactperapp    = `contactcost'


* --- cost variables
foreach x in implementation yearly_admin maintenance outreach support data contact learning_gains learning_gains2 {
	gen `x'=.
}

* --- savings variables
foreach x in application teachers_eval teachers_eval_gob transport supplies staff staff2 monitoring {
	gen `x'_dc = .
	gen `x'_sc = .
}
export delimited  "$pathData/intermediate/for_cost_calculation.csv", replace





