* ======================================= *
* 	     STUDENT ASSIGNMENT COSTS
* ======================================= *

* ---- PATHS ---- *
global main "/Users/antoniaaguilera/ConsiliumBots Dropbox/antoniaaguilera@consiliumbots.com/projects/iadb-ccas-costs/students"
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

bys applicant_type place_code cost_cat cost_type: gen y2_519 = y_519 if _n == 1
bys applicant_type place_code cost_cat cost_type: replace y2_519 = y_519 + y_519[_n-1]*0.01 if _n > 1

sort applicant_type cost_cat cost_type year

* --- project population growth --- *
gen enrollment_proj     = enrollment ///
if year==1

bys applicant_type cost_cat cost_type: replace enrollment_proj = round(enrollment_proj[_n-1]+enrollment_proj[_n-1]*y2_519, 1) ///
if year>1 & year<=10 & applicant_type == "students"

replace applicants=enrollment_proj*`pc_app'
drop enrollment
rename enrollment_proj enrollment

* ----------------------------------------------------------------- *
* -------------------- PARAMETER CONFIGURATION -------------------- *
* ----------------------------------------------------------------- *

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

* --- Labour Market Parameters --- *
local hrs_teachers      = 44
local hrs_parents       = 45

* --- Application Parameters --- *
local pc_app            = 0.14
local apps_students     = 3
local apps_teachers     = 5

* --- Time Parameters --- *
local time_app_st_d     = 20/60   //application time students decentralized (hrs)
local time_app_st_c		= 70/60  //application time students centralized (HRS)
local time_monitoring_s = 0.5    //monitoring  time per school in decentralized system
local time_monitoring_t = 0.25   //monitoring  time per school in decentralized system
local time_staff        = 0.5    //15 minutes per student + 15 minutes reviewing application
local time_staff_c      = 1 
local time_transport	= 1.9886197 

* --- Other Parameters --- *
local supplycost        = 0.1    //unit supply cost
local datacost          = 1.25   //unit data cost
local contactcost       = 2.53   //unit contact cost
local supportcost       = 0.12   //user support cost per applicant
}


*disminución del 5% en el gasto de difusión, por año, los primeros 5 años
replace outreach = outreach-outreach*0.02*(year-1) if year<=5
replace outreach = outreach[5] if year>=6

* ---------------------------------------------------------------- *
* -------------- CATEGORÍA 1: Costos de la Política -------------- *
* ---------------------------------------------------------------- *


replace implementation  = `infra_algorithm' if cost_cat==1
replace yearly_admin    = `process_admin'   if cost_cat==1
replace  outreach       = `outreach'        if cost_cat==1
replace monitoring      = `monitoring_c'    if cost_cat==1
replace maintenance     = `maintenance'     if cost_cat==1
replace support         = `support_c'       if cost_cat==1

* -------------- *
* -- STUDENTS -- *
* -------------- *

// Opportunity cost of application time
replace application = minwage/monthhrs*time_per_app*applicants ///
if cost_cat==1 & applicant_type=="students"

// Cost of 1 hour per school of updating vacant seats in platform
replace staff = stateofficialwage/monthhrs*`time_staff_c'*schools ///
if cost_cat == 1 & applicant_type == "students"


* ---------------------------------------------------------------- *
* ------------- CATEGORÍA 2: Ahorros en Desperdicios ------------- *
* ---------------------------------------------------------------- *

* -------------- *
* -- STUDENTS -- *
* -------------- *

// Time spent by families on application process
replace application = minwage/monthhrs*time_per_app*n_apps*applicants   ///
if cost_cat==2 & applicant_type=="students"

// Opportunity cost of transport cost + fare
replace transport = minwage/monthhrs*time_transport*applicants + (busfare*n_apps*applicants)    ///
if cost_cat==2 & applicant_type=="students"

// Cost of supplies used in the application process
replace supplies = (supplycost*n_apps*applicants) ///
if cost_cat==2 & applicant_type=="students"

// Cost of school staff working during an application process ((application + review) + communication)
replace staff = stateofficialwage/monthhrs*`time_staff'*n_apps*applicants + stateofficialwage/monthhrs*`time_staff'*applicants ///
if cost_cat==2 & applicant_type=="students"

// Cost of monitoring by authorities
replace monitoring = stateofficialwage/monthhrs*`time_monitoring_s'*schools ///
if cost_cat==2 & applicant_type=="students"



* ----------------------------------------------------------------- *
* ------------- CATEGORÍA 3: BENEFICIO DE LA POLÍTICA ------------- *
* ----------------------------------------------------------------- *
{
	/*
* ---- DATA & CONTACT INFORMATION ---- *
replace data    = dataperapp*applicants     ///
if cost_cat==3

replace contact = contactperapp*applicants  ///
if cost_cat==3
*/

}

gen beneficios_mock = (year/2+0.5)^2+1 if cost_cat==3
replace beneficios_mock = 0 if beneficios_mock==.


* ----------------------------------------------------------------- *
* ---------------------- COSTO POR POSTULANTE --------------------- *
* ----------------------------------------------------------------- *
* --- per applicant --- *
foreach vars in implementation yearly_admin application transport supplies staff monitoring { 
	replace `vars'= 0 if `vars'==.
	replace `vars'=`vars'/applicants if cost_type=="per_applicant"
}

* ----------------------------------------------------------------- *
* ------------------- COSTO TOTAL POR CATEGORÍA ------------------- *
* ----------------------------------------------------------------- *

egen total_cost     = rowtotal(implementation yearly_admin maintenance outreach support monitoring staff application transport supplies data contact )
replace total_cost  = total_cost/1000000 + beneficios_mock if year==1
replace total_cost = (yearly_admin+application+transport+supplies+staff+monitoring)/1000000 + beneficios_mock if year>1

format total_cost %20.01g

* ------------------------------------------------------------------ *
* ------------------------ GRÁFICOS POR AÑO ------------------------ *
* ------------------------------------------------------------------ *
grstyle clear

keep if cost_type=="gross" & country == "CHILE" & applicant_type == "students"

keep total_cost year cost_cat
reshape wide total_cost@, i(year) j(cost_cat)
gen estimated_benefit = 4061606/1000000

export excel "$pathData/output/students_proj_cl.xlsx", replace first(var)


* ---------------------------------------------------------------------- *
* ------------------------ EXTENDED ANALYSIS II ------------------------ *
* ---------------------------------------------------------------------- *

clear all
set obs 500 

local pc_app = 0.14
* ---  generate population numbers
gen year = _n
gen population_students = 10000
replace population_students = sum(population_students)

gen country = "CHILE"

tempfile population
save `population', replace

* --- llamar costos 
import delimited "$pathData/intermediate/for_extended_analysis.csv", clear 
keep if _n == 1

merge 1:m country using `population', update
drop _merge 
cap drop applicants
gen applicants = population_students*`pc_app'

expand 3
drop cost_cat
bys year: gen cost_cat = 1  if _n == 1
bys year: replace cost_cat = 2  if _n == 2
bys year: replace cost_cat = 3  if _n == 3


* ----------------------------------------------------------------- *
* -------------------- PARAMETER CONFIGURATION -------------------- *
* ----------------------------------------------------------------- *

gen time_per_app     = `time_app_st_c'         if cost_cat==1
replace time_per_app = `time_app_st_d'         if cost_cat==2

gen time_transport   = `time_transport'

gen n_apps           = `apps_students'         if cost_cat==2
 
gen time_staff       = `time_staff'
gen time_monitoring  = `time_monitoring_s'     if cost_cat==2

gen support_cost     = `supportcost'	       if cost_cat==1 

gen supplycost       = `supplycost'


* --- inicializar variables
foreach x in implementation yearly_admin maintenance outreach  support monitoring application transport supplies staff data contact learning_gains learning_gains2 {
	gen `x'=.
}

* ---------------------------------------------------------------- *
* -------------- CATEGORÍA 1: Costos de la Política -------------- *
* ---------------------------------------------------------------- *

replace implementation  = `infra_algorithm' ///
if cost_cat==1 
replace yearly_admin    = `process_admin'  ///
if cost_cat==1
replace  outreach       = `outreach'       ///
if cost_cat==1
replace monitoring      = `monitoring_c'  ///
if cost_cat==1 
replace maintenance     = `maintenance'   ///
if cost_cat==1
replace support    = `support_c'   ///
if cost_cat==1

* -------------- *
* -- STUDENTS -- *
* -------------- *

// Opportunity cost of application time
replace application = minwage/monthhrs*time_per_app*applicants ///
if cost_cat==1 

// Cost of 1 hour per school of updating vacant seats in platform 
replace staff = stateofficialwage/monthhrs*`time_staff_c'*schools if cost_cat == 1 


* ---------------------------------------------------------------- *
* ------------- CATEGORÍA 2: Ahorros en Desperdicios ------------- *
* ---------------------------------------------------------------- *

* -------------- *
* -- STUDENTS -- *
* -------------- *

// Time spent by families on application process
replace application = minwage/monthhrs*time_per_app*n_apps*applicants   ///
if cost_cat==2

// Opportunity cost of transport cost + fare
replace transport = minwage/monthhrs*time_transport*applicants + (busfare*n_apps*applicants)    ///
if cost_cat==2 

// Cost of supplies used in the application process
replace supplies = (supplycost*n_apps*applicants) ///
if cost_cat==2 

// Cost of school staff working during an application process ((application + review) + communication)
replace staff = stateofficialwage/monthhrs*`time_staff'*n_apps*applicants + stateofficialwage/monthhrs*`time_staff'*applicants ///
if cost_cat==2 

// Cost of monitoring by authorities
replace monitoring = stateofficialwage/monthhrs*time_monitoring*schools ///
if cost_cat==2 


* ----------------------------------------------------------------- *
* ------------- CATEGORÍA 3: Beneficio de la Política ------------- *
* ----------------------------------------------------------------- *


* ----------------------------------------------------------------- *
* ------------------- COSTO TOTAL POR CATEGORÍA ------------------- *
* ----------------------------------------------------------------- *

egen total_cost=rowtotal(implementation yearly_admin ///
application transport supplies staff monitoring support )

format total_cost %20.5f

collapse (sum) total_cost applicants, by(cost_cat year)

drop if year==.
sort cost_cat year applicants 
bys cost_cat: gen acc_tot = sum(total_cost)
bys cost_cat: gen acc_stu = sum(applicants)
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

export excel "$pathData/output/students_pop_cl.xlsx", replace first(var)
