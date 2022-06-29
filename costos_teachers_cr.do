* =========================================================== *
* 			COSTOS DOCENTES COSTA RICA 
* =========================================================== *

* ---- PREAMBULO ---- * 

	global git "/Users/antoniaaguilera/GitHub/dashboard-iadb-costs-cr"
	global data "$git/data"

import excel "$data/inputs/parameters.xlsx", clear first

* PARÁMETROS RELEVANTES
{
* --- Policy Costs Parameters --- *
local infra_algorithm   = 247860 //perú
local process_admin     = 50000  //ecuador
*local outreach          = 248000 //outreach and information during the assignment process 
local monitoring_c      = 0 //monitoring and user support
local support_c 		= 60340 //3308635*0.14*105/806
*local maintenance       = 7000 //annual maintenance of the system

* --- Labour Market Parameters --- *
local hrs_teachers      = 44
local hrs_parents       = 45

* --- Application Parameters --- *
local pc_app            = 0.14
local apps_students     = 3
local apps_teachers     = 5

* --- Teacher Evaluation Parameters --- *
local eval_teachers_d   = 2      //teacher evaluation time in a decentralized system
local eval_teachers_c   = 4		 //teacher evaluation time in a centralized system  
local n_interviews      = 3      //teacher interviews in a decentralized system
local eval_cost         = 15     //15 usd ecuador

* --- Time Parameters --- *
local time_app_st_d     = 1     //application time students decentralized (hrs)
local time_app_st_c		= 70/60  //application time students centralized (HRS)
local time_app_te_d		= 1      //application time teachers decentralized
local time_app_te_c		= 0.5    //application time teachers centralized
local time_monitoring_s = 0.5    //monitoring  time per school in decentralized system
local time_monitoring_t = 0.25   //monitoring  time per school in decentralized system
local time_staff        = 0.5    //15 minutes per student + 15 minutes reviewing application
local time_staff2       = 0.5    //30 minutes per admitted student 
local time_staff_c      = 1 
local time_transport    = 0.5    //Time spent in transport, all applicants

* --- Learning Gains Parameters --- *
local improved_score_vac= 0.011  //nº of position where teacher's score is improved as a % of total teachers
local learning_effect   = 1/3    //impact of improving teachers as a fraction of the yearly learning in std dev
local loss_income       = 0.025  //% of life loss income due to learning losses 
local discount_rate     = 0.03
local wage_growth		= 0.02

* --- Other Parameters --- *
local supplycost        = 0.1    //unit supply cost
local datacost          = 1.25   //unit data cost 
local contactcost       = 2.53   //unit contact cost 
local supportcost       = 0.12   //user support cost per applicant
}

* REWORK DATA
{
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
gen applicants=enrollment*`pc_app'
gen monthhrs = 4*`hrs_parents'
gen monthhrs_teacher = 4*`hrs_teachers'

//expandir por categoría
expand 3
gen cost_cat=.
bys place_code applicant_type: replace cost_cat=_n
order place_code place_name country applicant_type cost_cat
sort place_code applicant_type cost_cat

label define cost_cat 1 "Costos Política" 2 "Ahorros en Desperdicios" 3 "Beneficios de la Política"
label values cost_cat cost_cat

expand 2
gen cost_type=""
bys place_code applicant_type cost_cat: replace cost_type="gross" if _n==1
bys place_code applicant_type cost_cat: replace cost_type="per_applicant" if _n==2
order place_code place_name country applicant_type cost_cat cost_type
sort place_code applicant_type cost_cat cost_type

keep if place_code=="costarica_country" & applicant_type=="teachers"

tempfile cost_basic
save `cost_basic', replace
}


* -------------------------------------------------------------------------- *
* -------------------- ESTIMATION BY PLACE AND CATEGORY -------------------- *
* -------------------------------------------------------------------------- *


* ----------------------------------------------------------------- *
* -------------------- PARAMETER CONFIGURATION -------------------- *
* ----------------------------------------------------------------- *
{
gen 	time_per_app = `time_app_te_c'         if applicant_type=="teachers" & cost_cat==1
replace time_per_app = `time_app_te_d'         if applicant_type=="teachers" & cost_cat==2

gen time_transport   = `time_transport'

gen n_apps           = `apps_teachers'         if applicant_type=="teachers" 
 
gen time_eval        = `eval_teachers_d'       if applicant_type=="teachers" & cost_cat==2 
replace time_eval    = `eval_teachers_c'       if applicant_type=="teachers" & cost_cat==1 

gen time_staff       = `time_staff'
gen time_monitoring  =  `time_monitoring_t'  if applicant_type=="teachers" & cost_cat==2

*gen support_cost     = `supportcost'	       if applicant_type=="students" & cost_cat==1 

gen evalcost         = `eval_cost'             if applicant_type=="teachers" & cost_cat==1
gen supplycost       = `supplycost'
gen dataperapp       = `datacost'
gen contactperapp    = `contactcost'

}
* --- inicializar variables
foreach x in implementation yearly_admin maintenance outreach monitoring application teachers_eval transport supplies staff data contact learning_gains learning_gains2 teachers_eval_gob{
	gen `x'=.
}

* ---------------------------------------------------------------- *
* -------------- CATEGORÍA 1: Costos de la Política -------------- *
* ---------------------------------------------------------------- *
{
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
replace application = teacherwage/monthhrs_teacher*`time_app_te_c' *applicants ///
if cost_cat==1 & applicant_type=="teachers"

// Opportunity cost of evaluation time + cost of test
replace teachers_eval = teacherwage/monthhrs_teacher*time_eval*applicants  ///
if cost_cat==1 & applicant_type=="teachers"

//Evaluation cost for the government
replace teachers_eval_gob =  `eval_cost'*applicants if cost_cat==1 & applicant_type=="teachers"

// Opportunity cost of transport time + fare
replace transport = teacherwage/monthhrs_teacher*time_transport*applicants + (busfare*applicants) ///
if cost_cat==1 & applicant_type=="teachers"

// Cost of 1 hour per school of updating vacant seats in platform 
replace staff = stateofficialwage/monthhrs*`time_staff_c'*schools if cost_cat == 1 & applicant_type == "teachers"

}
* ---------------------------------------------------------------- *
* ------------- CATEGORÍA 2: Ahorros en Desperdicios ------------- *
* ---------------------------------------------------------------- *
{
* -------------- *
* -- TEACHERS -- *
* -------------- *

// Time spent by families on application process
replace application = (teacherwage)/monthhrs_teacher*`time_app_te_d'*n_apps*applicants  ///
if cost_cat==2 & applicant_type=="teachers"

// Opportunity cost of evaluation time for teachers
replace teachers_eval = teacherwage/monthhrs_teacher*time_eval*n_apps*applicants  ///
if cost_cat==2 & applicant_type=="teachers"

//Evaluation cost for the government
replace teachers_eval_gob =  `eval_cost'*n_apps*applicants if cost_cat==2 & applicant_type=="teachers"

// Opportunity cost of transport time + fare
replace transport = teacherwage/monthhrs_teacher*time_transport*n_apps*applicants + (busfare*applicants)*n_apps ///
if cost_cat==2 & applicant_type=="teachers"

// Cost of supplies used in the application process
replace supplies = (supplycost*n_apps*applicants) ///
if cost_cat==2 & applicant_type=="teachers"

// Cost of staff working during an application process + 15 usd per applicant
replace staff = stateofficialwage/monthhrs*`time_staff'*n_apps*applicants + ///
				stateofficialwage/monthhrs*time_eval*applicants ///
if cost_cat==2 & applicant_type=="teachers"

// Cost of monitoring by authorities
replace monitoring = stateofficialwage/monthhrs*time_monitoring*schools   ///  
if cost_cat==2 & applicant_type=="teachers"

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

* -------------- *
* -- TEACHERS -- *
* -------------- *

* ---- LEARNING GAINS ---- *
*replace learning_gains = `improved_score_vac'*enrollment*st_ratio*`learning_effect'*student_exp*gdp_percap ///
*if cost_cat==3 & applicant_type=="teachers"

*replace learning_gains2 = 

}

* ----------------------------------------------------------------- *
* ---------------------- COSTO POR POSTULANTE --------------------- *
* ----------------------------------------------------------------- *
* --- per applicant --- *
foreach vars in implementation yearly_admin application teachers_eval transport supplies staff monitoring data contact learning_gains teachers_eval_gob{
	replace `vars'=`vars'/applicants if cost_type=="per_applicant"
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
*export delimited "$dashbid/cost_teachers_cr.csv", replace 

}


* --------------------------------------------------------------------- *
* --------------- II. GRÁFICOS POR PAÍS Y PROYECCIONES ---------------- *
* --------------------------------------------------------------------- *

use `cost_basic', clear 
keep if place_code=="costarica_country" & applicant_type=="teachers"
expand 50
bys applicant_type place_code cost_cat cost_type: gen year=_n

foreach x in 519 2059 {
	bys applicant_type place_code cost_cat cost_type: gen y2_`x' = y_`x' if _n == 1
	bys applicant_type place_code cost_cat cost_type: replace y2_`x' = y_`x'+y_`x'[_n-1]*0.01 if _n > 1
	
}

order place_code place_name country applicant_type cost_cat year
sort applicant_type place_code cost_cat cost_type year

* --- project population growth --- *
gen population_proj     = population ///
if year==1

bys applicant_type place_code cost_cat cost_type: replace population_proj = round(population_proj[_n-1]+population_proj[_n-1]*y2_2059, 1) ///
if year>1 & year<=50

replace applicants=population_proj*`pc_app'*0.02
drop population
rename population_proj population

* ----------------------------------------------------------------- *
* -------------------- PARAMETER CONFIGURATION -------------------- *
* ----------------------------------------------------------------- *
{
gen 	time_per_app = `time_app_te_c'         if applicant_type=="teachers" & cost_cat==1
replace time_per_app = `time_app_te_d'         if applicant_type=="teachers" & cost_cat==2

gen time_transport   = `time_transport'

gen n_apps           = `apps_teachers'         if applicant_type=="teachers" 
 
gen time_eval        = `eval_teachers_d'       if applicant_type=="teachers" & cost_cat==2 
replace time_eval    = `eval_teachers_c'       if applicant_type=="teachers" & cost_cat==1 

gen time_staff       = `time_staff'
gen time_monitoring  =  `time_monitoring_t'  if applicant_type=="teachers" & cost_cat==2

*gen support_cost     = `supportcost'	       if applicant_type=="students" & cost_cat==1 

gen evalcost         = `eval_cost'             if applicant_type=="teachers" & cost_cat==1
gen supplycost       = `supplycost'
gen dataperapp       = `datacost'
gen contactperapp    = `contactcost'

}
* --- inicializar variables
foreach x in implementation yearly_admin maintenance outreach monitoring application teachers_eval transport supplies staff data contact learning_gains learning_gains2 teachers_eval_gob{
	gen `x'=.
}

* ---------------------------------------------------------------- *
* -------------- CATEGORÍA 1: Costos de la Política -------------- *
* ---------------------------------------------------------------- *
{

replace implementation  = `infra_algorithm' ///
if cost_cat==1 
replace yearly_admin    = `process_admin' + `monitoring_c'  ///
if cost_cat==1

* -------------- *
* -- TEACHERS -- *
* -------------- *

// Opportunity cost of application time 
replace application = teacherwage/monthhrs_teacher*time_per_app *applicants ///
if cost_cat==1 & applicant_type=="teachers"

// Opportunity cost of evaluation time + cost of test
replace teachers_eval = teacherwage/monthhrs_teacher*time_eval*applicants  ///
if cost_cat==1 & applicant_type=="teachers"

//Evaluation cost for the government
replace teachers_eval_gob =  `eval_cost'*applicants if cost_cat==1 & applicant_type=="teachers"

// Opportunity cost of transport time + fare
replace transport = teacherwage/monthhrs_teacher*time_transport*applicants + (busfare*applicants) ///
if cost_cat==1 & applicant_type=="teachers"

// Cost of 1 hour per school of updating vacant seats in platform 
replace staff = stateofficialwage/monthhrs*`time_staff_c'*schools if cost_cat == 1 & applicant_type == "teachers"

}
 
* ---------------------------------------------------------------- *
* ------------- CATEGORÍA 2: Ahorros en Desperdicios ------------- *
* ---------------------------------------------------------------- *
{
* -------------- *
* -- TEACHERS -- *
* -------------- *

// Time spent by families on application process
replace application = (teacherwage)/monthhrs_teacher*`time_app_te_d'*n_apps*applicants  ///
if cost_cat==2 & applicant_type=="teachers"

// Opportunity cost of evaluation time for teachers
replace teachers_eval = teacherwage/monthhrs_teacher*time_eval*n_apps*applicants if cost_cat==2 & applicant_type=="teachers"

//Evaluation cost for the government
replace teachers_eval_gob =  `eval_cost'*n_apps*applicants if cost_cat==2 & applicant_type=="teachers"

// Opportunity cost of transport time + fare
replace transport = teacherwage/monthhrs_teacher*time_transport*n_apps*applicants + (busfare*applicants)*n_apps ///
if cost_cat==2 & applicant_type=="teachers"

// Cost of supplies used in the application process
replace supplies = (supplycost*n_apps*applicants) ///
if cost_cat==2 & applicant_type=="teachers"

// Cost of staff working during an application process + 15 usd per applicant
replace staff = stateofficialwage/monthhrs*`time_staff'*n_apps*applicants + ///
				stateofficialwage/monthhrs*time_eval*applicants ///
if cost_cat==2 & applicant_type=="teachers"

// Cost of monitoring by authorities
replace monitoring = stateofficialwage/monthhrs*time_monitoring*schools   ///  
if cost_cat==2 & applicant_type=="teachers"

}
gen beneficios_mock = (year/10+0.1)^2+0.5 if cost_cat==3
replace beneficios_mock = 0 if beneficios_mock==.
* ----------------------------------------------------------------- *
* ---------------------- COSTO POR POSTULANTE --------------------- *
* ----------------------------------------------------------------- *
* --- per applicant --- *
foreach vars in implementation yearly_admin application teachers_eval transport supplies staff monitoring teachers_eval_gob{ //data contact lgains1 lgains2 {
	replace `vars'= 0 if `vars'==.
	replace `vars'=`vars'/applicants if cost_type=="per_applicant"
}
* ----------------------------------------------------------------- *
* ------------------- COSTO TOTAL POR CATEGORÍA ------------------- *
* ----------------------------------------------------------------- *

gen total_cost     = 0

replace total_cost = (implementation+yearly_admin+application+teachers_eval+transport+supplies+staff+teachers_eval_gob)/1000000 + beneficios_mock if year==1

replace total_cost = (yearly_admin+application+teachers_eval+transport+supplies+staff+monitoring+teachers_eval_gob)/1000000 + beneficios_mock if year>1
format total_cost %20.01g
* ------------------------------------------------------------------ *
* ------------------------ GRÁFICOS POR AÑO ------------------------ *
* ------------------------------------------------------------------ *
grstyle clear 

keep if cost_type=="gross" & place_code=="costarica_country" & applicant_type=="teachers" 
keep year total_cost cost_cat
export delimited "$data/cost_teachers_proj_cr.csv", replace
 
* --------------------------------------------------------------------- *
* ------------ III. PROYECCIONES DE AHORROS POR POBLACIÓN ------------- *
* --------------------------------------------------------------------- *
import excel "$data/inputs/growthproj_cr.xlsx", clear firstrow 
keep year population_teachers

gen applicants =  population_teachers*0.14*0.02
//2784005 población en 2021
drop if applicants==.
gen country ="COSTA RICA"

tempfile population
save `population', replace 

use `cost_basic', clear 
keep if _n == 1
drop cost_cat cost_type applicants 
merge 1:m country using `population'
expand 3 
bys year: gen cost_cat = 1  if _n == 1
bys year: replace cost_cat = 2  if _n == 2
bys year: replace cost_cat = 3  if _n == 3

label values cost_cat cost_cat


* ----------------------------------------------------------------- *
* -------------------- PARAMETER CONFIGURATION -------------------- *
* ----------------------------------------------------------------- *
{
gen 	time_per_app = `time_app_te_c'         if applicant_type=="teachers" & cost_cat==1
replace time_per_app = `time_app_te_d'         if applicant_type=="teachers" & cost_cat==2

gen time_transport   = `time_transport'

gen n_apps           = `apps_teachers'         if applicant_type=="teachers" 
 
gen time_eval        = `eval_teachers_d'       if applicant_type=="teachers" & cost_cat==2 
replace time_eval    = `eval_teachers_c'       if applicant_type=="teachers" & cost_cat==1 

gen time_staff       = `time_staff'
gen time_monitoring  =  `time_monitoring_t'  if applicant_type=="teachers" & cost_cat==2

*gen support_cost     = `supportcost'	       if applicant_type=="students" & cost_cat==1 

gen evalcost         = `eval_cost'             if applicant_type=="teachers" & cost_cat==1
gen supplycost       = `supplycost'
gen dataperapp       = `datacost'
gen contactperapp    = `contactcost'

}
* --- inicializar variables
foreach x in implementation yearly_admin maintenance outreach monitoring application teachers_eval transport supplies staff data contact learning_gains learning_gains2 teachers_eval_gob{
	gen `x'=.
}

* ---------------------------------------------------------------- *
* -------------- CATEGORÍA 1: Costos de la Política -------------- *
* ---------------------------------------------------------------- *
{

replace implementation  = `infra_algorithm' ///
if cost_cat==1 
replace yearly_admin    = `process_admin' + `monitoring_c'  ///
if cost_cat==1

* -------------- *
* -- TEACHERS -- *
* -------------- *

// Opportunity cost of application time 
replace application = teacherwage/monthhrs_teacher*`time_app_te_c' *applicants ///
if cost_cat==1 & applicant_type=="teachers"

// Opportunity cost of evaluation time + cost of test
replace teachers_eval = teacherwage/monthhrs_teacher*time_eval*applicants  ///
if cost_cat==1 & applicant_type=="teachers"

//Evaluation cost for the government
replace teachers_eval_gob =  `eval_cost'*applicants if cost_cat==1 & applicant_type=="teachers"

// Opportunity cost of transport time + fare
replace transport = teacherwage/monthhrs_teacher*time_transport*applicants + (busfare*applicants) ///
if cost_cat==1 & applicant_type=="teachers"

// Cost of 1 hour per school of updating vacant seats in platform 
replace staff = stateofficialwage/monthhrs*`time_staff_c'*schools if cost_cat == 1 & applicant_type == "teachers"

}
* ---------------------------------------------------------------- *
* ------------- CATEGORÍA 2: Ahorros en Desperdicios ------------- *
* ---------------------------------------------------------------- *
{
* -------------- *
* -- TEACHERS -- *
* -------------- *

// Time spent by families on application process
replace application = (teacherwage)/monthhrs_teacher*`time_app_te_d'*n_apps*applicants  ///
if cost_cat==2 & applicant_type=="teachers"

// Opportunity cost of evaluation time for teachers
replace teachers_eval = teacherwage/monthhrs_teacher*time_eval*n_apps*applicants  ///
if cost_cat==2 & applicant_type=="teachers"

//Evaluation cost for the government
replace teachers_eval_gob =  `eval_cost'*n_apps*applicants if cost_cat==2 & applicant_type=="teachers"

// Opportunity cost of transport time + fare
replace transport = teacherwage/monthhrs_teacher*time_transport*n_apps*applicants + (busfare*applicants)*n_apps ///
if cost_cat==2 & applicant_type=="teachers"

// Cost of supplies used in the application process
replace supplies = (supplycost*n_apps*applicants) ///
if cost_cat==2 & applicant_type=="teachers"

// Cost of staff working during an application process + 15 usd per applicant
replace staff = stateofficialwage/monthhrs*`time_staff'*n_apps*applicants + ///
				stateofficialwage/monthhrs*time_eval*applicants ///
if cost_cat==2 & applicant_type=="teachers"

// Cost of monitoring by authorities
replace monitoring = stateofficialwage/monthhrs*time_monitoring*schools   ///  
if cost_cat==2 & applicant_type=="teachers"

}

* ----------------------------------------------------------------- *
* ------------------- COSTO TOTAL POR CATEGORÍA ------------------- *
* ----------------------------------------------------------------- *

egen total_cost=rowtotal(implementation yearly_admin ///
application transport teachers_eval teachers_eval_gob supplies staff monitoring  )

format total_cost %20.01f

collapse (sum) total_cost applicants, by(cost_cat year)

sort cost_cat year applicants 
bys cost_cat year: gen acc_tot = sum(total_cost)
bys cost_cat year: gen acc_stu = sum(applicants)
replace acc_tot = acc_tot/1000000
replace total_cost = total_cost/1000000
drop if year==.
* ----------------------------------------------------------------- *
* --------------------------- GRAFICOS ---------------------------- *
* ----------------------------------------------------------------- *
export delimited "$data/cost_teachers_pop_cr.csv", replace
stop 

stop 
grstyle clear 

tw (line acc_tot acc_stu if cost_cat==1)(line acc_tot acc_stu if cost_cat==2) , ///
legend(label(1 "Costo") label(2 "Ahorros") row(1)) xtitle("Postulantes") ylab(,angle(0)) ytitle("MUSD") ///
graphr(fc(white) lcolor(white) ilcolor(white)  lwidth(thick) margin(r+15))  ///
bgcolor(white) plotr(style(none) fc(white) lcolor(white) lwidth(thick)) ///
title("Ahorro neto según cantidad de postulantes") subtitle("Asignación Centralizada de Docentes") ///
xline(2400) xlabel(2000 "2,000" 2400 "2,400" 4000 "4,000" 6000 "6,000" 8000 "8,000")

gr display, xsize(8)
gr export "$graphs/teachers_ecuador_applicants.png", as(png) replace 
*y=0.00003\dots x+0.40739\dots 
*y=0.00019\dots x+0.02738\dots 
*\frac{0.38001}{0.00016}
*2375
