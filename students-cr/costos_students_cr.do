* =========================================================== *
* 			COSTOS ESTUDIANTES COSTA RICA 
* =========================================================== *

* ---- PREAMBULO ---- * 

	global git "/Users/antoniaaguilera/GitHub/dashboard-iadb-costs-cr"
	global data "$git/data"

import excel "$data/inputs/parameters.xlsx", clear first

* PARÁMETROS RELEVANTES
{
* --- Policy Costs Parameters --- *
local infra_algorithm   = 186000 //cost of tech infraestructure and algorithm creation
local process_admin     = 50000  //administration of the yearly assignment process
local outreach          = 248000 //outreach and information during the assignment process 
local monitoring_c      = 0 //monitoring and user support
local support_c 		= 60340 //3308635*0.14*105/806
local maintenance       = 7000 //annual maintenance of the system

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
local eval_cost         = 15     //15 usd

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
schools minwage busfare teacherwage stateofficialwage student_exp gdp_percap st_ratio teny_519 y_519 teny_2059 y_2059

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

keep if country=="COSTA RICA" & applicant_type=="students"

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
gen time_per_app     = `time_app_st_c'         if applicant_type=="students" & cost_cat==1
replace time_per_app = `time_app_st_d'         if applicant_type=="students" & cost_cat==2

gen time_transport   = `time_transport'

gen n_apps           = `apps_students'         if applicant_type=="students" & cost_cat==2
 
gen time_eval        = `eval_teachers_d'       if applicant_type=="teachers" & cost_cat==2 

gen time_staff       = `time_staff'
gen time_monitoring  = `time_monitoring_s'     if applicant_type=="students" & cost_cat==2

gen support_cost     = `supportcost'	       if applicant_type=="students" & cost_cat==1 

gen supplycost       = `supplycost'
gen dataperapp       = `datacost'
gen contactperapp    = `contactcost'

}
* --- inicializar variables
foreach x in implementation yearly_admin maintenance outreach  support monitoring application teachers_eval transport supplies staff data contact learning_gains learning_gains2 {
	gen `x'=.
}

* ---------------------------------------------------------------- *
* -------------- CATEGORÍA 1: Costos de la Política -------------- *
* ---------------------------------------------------------------- *
{
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
if cost_cat==1 & applicant_type=="students"

// Cost of 1 hour per school of updating vacant seats in platform 
replace staff = stateofficialwage/monthhrs*`time_staff_c'*schools if cost_cat == 1 & applicant_type == "students"

//government spending in user support during application process
*replace support = support_cost*applicants ///
*if cost_cat==1 & applicant_type=="students"

}
* ---------------------------------------------------------------- *
* ------------- CATEGORÍA 2: Ahorros en Desperdicios ------------- *
* ---------------------------------------------------------------- *
{
* -------------- *
* -- STUDENTS -- *
* -------------- *

// Time spent by families on application process
replace application = minwage/monthhrs*time_per_app*n_apps*applicants   ///
if cost_cat==2 & applicant_type=="students"

// Opportunity cost of transport cost + fare
replace transport = minwage/monthhrs*time_transport*n_apps*applicants + (busfare*n_apps*applicants)    ///
if cost_cat==2 & applicant_type=="students"

// Cost of supplies used in the application process
replace supplies = (supplycost*n_apps*applicants) ///
if cost_cat==2 & applicant_type=="students"

// Cost of school staff working during an application process ((application + review) + communication)
replace staff = stateofficialwage/monthhrs*`time_staff'*n_apps*applicants + stateofficialwage/monthhrs*`time_staff2'*applicants ///
if cost_cat==2 & applicant_type=="students"

// Cost of monitoring by authorities
replace monitoring = stateofficialwage/monthhrs*time_monitoring*schools ///
if cost_cat==2 & applicant_type=="students"
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

}

* ----------------------------------------------------------------- *
* ---------------------- COSTO POR POSTULANTE --------------------- *
* ----------------------------------------------------------------- *
* --- per applicant --- *
foreach vars in implementation yearly_admin application teachers_eval transport supplies staff monitoring data contact learning_gains {
	replace `vars'=`vars'/applicants if cost_type=="per_applicant"
}

* ----------------------------------------------------------------- *
* ------------------- COSTO TOTAL POR CATEGORÍA ------------------- *
* ----------------------------------------------------------------- *
{
egen total_cost=rowtotal(implementation yearly_admin ///
application teachers_eval transport supplies staff monitoring support ///
data contact learning_gains)

format total_cost %20.01f

sort place_code applicant_type cost_type cost_cat 
rename cost_cat cost_cat2
gen cost_cat=cost_cat2
order place_code place_name country cost_cat
*export excel "/Users/antoniaaguilera/Dropbox/CB/BID-Cost Effective/Cost_Estimation/output data/cost_estimation.xlsx", replace first(var)
  
}
* ----------------- *
* -- BY CATEGORY -- *
* ----------------- *
{
keep  place_code country applicant_type cost_cat cost_type total_cost

reshape wide total_cost, i(place_code applicant_type cost_type) j(cost_cat)

gen net_impact=total_cost2+total_cost3-total_cost1
format net_impact %20.01f
format net_impact %20.01f
}

* --------------------------------------------------------------------- *
* --------------- II. GRÁFICOS POR PAÍS Y PROYECCIONES ---------------- *
* --------------------------------------------------------------------- *

use `cost_basic', clear 
keep if country=="COSTA RICA" & applicant_type=="students"
expand 50
bys applicant_type place_code cost_cat cost_type: gen year=_n

foreach x in 519 2059 {
	bys applicant_type place_code cost_cat cost_type: gen y2_`x' = y_`x' if _n == 1
	bys applicant_type place_code cost_cat cost_type: replace y2_`x' = y_`x'+y_`x'[_n-1]*0.01 if _n > 1
	
}

order place_code place_name country applicant_type cost_cat year
sort applicant_type place_code cost_cat cost_type year

* --- project population growth --- *
gen enrollment_proj     = enrollment ///
if year==1

bys applicant_type place_code cost_cat cost_type: replace enrollment_proj = round(enrollment_proj[_n-1]+enrollment_proj[_n-1]*y2_519, 1) ///
if year>1 & year<=50 & applicant_type == "students"

replace applicants=enrollment_proj*0.14
drop enrollment 
rename enrollment_proj enrollment

* ----------------------------------------------------------------- *
* -------------------- PARAMETER CONFIGURATION -------------------- *
* ----------------------------------------------------------------- *

gen time_per_app     = `time_app_st_c'   if applicant_type=="students" & cost_cat==1
replace time_per_app = `time_app_te_c'   if applicant_type=="teachers" & cost_cat==1
replace time_per_app = `time_app_st_d'   if applicant_type=="students" & cost_cat==2
replace time_per_app = `time_app_te_d'   if applicant_type=="teachers" & cost_cat==2

gen time_transport   = `time_transport'

gen n_apps           = `apps_students'   if applicant_type=="students" 
replace n_apps       = `apps_teachers'   if applicant_type=="teachers" 
 
gen time_eval        = `eval_teachers_d' if applicant_type=="teachers" & cost_cat==2 
replace time_eval    = `eval_teachers_c' if applicant_type=="teachers" & cost_cat==1 

gen supplycost       = `supplycost'
gen dataperapp       = `datacost'
gen contactperapp    = `contactcost'

gen life_income = (minwage*12)*((1-(1+`wage_growth')^40*(1+`discount_rate')^-40)/(`discount_rate'-`wage_growth'))
gen life_income10 = (minwage*12)*((1-(1+`wage_growth')^10*(1+`discount_rate')^-10)/(`discount_rate'-`wage_growth'))

*disminución del 5% en el gasto de difusión, por año, los primeros 5 años
gen outreach = `outreach'
replace outreach = outreach-outreach*0.02*(year-1) if year<=5
replace outreach = outreach[5] if year>=6
* --- inicializar variables
foreach x in implementation yearly_admin application teachers_eval transport supplies staff monitoring data contact{
	gen `x'=0
}

* ---------------------------------------------------------------- *
* -------------- CATEGORÍA 1: Costos de la Política -------------- *
* ---------------------------------------------------------------- *
{
replace implementation  = `infra_algorithm' ///
if cost_cat==1 
replace yearly_admin    = `process_admin' + outreach + `monitoring_c' + `maintenance' + `support_c' ///
if cost_cat==1


* -------------- *
* -- STUDENTS -- *
* -------------- *

// Opportunity cost of application time
replace application = minwage/monthhrs*time_per_app*applicants ///
if cost_cat==1 & applicant_type=="students"

// Cost of 1 hour per school of updating vacant seats in platform 
replace staff = stateofficialwage/monthhrs*`time_staff_c'*schools if cost_cat == 1 & applicant_type == "students"

}
* ---------------------------------------------------------------- *
* ------------- CATEGORÍA 2: Ahorros en Desperdicios ------------- *
* ---------------------------------------------------------------- *
{
* -------------- *
* -- STUDENTS -- *
* -------------- *

// Time spent by families on application process
replace application = minwage/monthhrs*time_per_app*n_apps*applicants   ///
if cost_cat==2 & applicant_type=="students"

// Opportunity cost of transport cost + fare
replace transport = minwage/monthhrs*time_transport*n_apps*applicants + (busfare*n_apps*applicants)    ///
if cost_cat==2 & applicant_type=="students"

// Cost of supplies used in the application process
replace supplies = (supplycost*n_apps*applicants) ///
if cost_cat==2 & applicant_type=="students"

// Cost of school staff working during an application process ((application + review) + communication)
replace staff = stateofficialwage/monthhrs*`time_staff'*n_apps*applicants + stateofficialwage/monthhrs*`time_staff2'*applicants ///
if cost_cat==2 & applicant_type=="students"

// Cost of monitoring by authorities
replace monitoring = stateofficialwage/monthhrs*`time_monitoring_s'*schools ///
if cost_cat==2 & applicant_type=="students"


}
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
foreach vars in implementation yearly_admin application teachers_eval transport supplies staff monitoring { //data contact lgains1 lgains2 {
	replace `vars'= 0 if `vars'==.
	replace `vars'=`vars'/applicants if cost_type=="per_applicant"
}

* ----------------------------------------------------------------- *
* ------------------- COSTO TOTAL POR CATEGORÍA ------------------- *
* ----------------------------------------------------------------- *

gen total_cost     = 0

replace total_cost = (implementation+yearly_admin+application+transport+supplies+staff)/1000000+ beneficios_mock if year==1

replace total_cost = (yearly_admin+application+transport+supplies+staff+monitoring)/1000000 + beneficios_mock if year>1

format total_cost %20.01g


* ------------------------------------------------------------------ *
* ------------------------ GRÁFICOS POR AÑO ------------------------ *
* ------------------------------------------------------------------ *
grstyle clear 

keep if cost_type=="gross" & place_code=="costarica_country" & applicant_type=="students" 
keep year cost_cat total_cost
export delimited "$data/cost_students_proj_cr.csv", replace 
 

* --------------------------------------------------------------------- *
* ------------ III. PROYECCIONES DE AHORROS POR POBLACIÓN ------------- *
* --------------------------------------------------------------------- *
import excel "$data/inputs/growthproj_cr.xlsx", clear firstrow
keep year population_students
gen applicants = population_students*0.14

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
replace transport = minwage/monthhrs*time_transport*n_apps*applicants + (busfare*n_apps*applicants)    ///
if cost_cat==2 

// Cost of supplies used in the application process
replace supplies = (supplycost*n_apps*applicants) ///
if cost_cat==2 

// Cost of school staff working during an application process ((application + review) + communication)
replace staff = stateofficialwage/monthhrs*`time_staff'*n_apps*applicants + stateofficialwage/monthhrs*`time_staff2'*applicants ///
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

format total_cost %20.01f

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
drop if applicants>200000
export delimited "$git/data/cost_students_pop_cr.csv", replace
stop
*grstyle clear 

*tw (connect acc_tot acc_stu if cost_cat==1)(connect acc_tot acc_stu if cost_cat==2) ///
*(area ), ///
*legend(label(1 "Costo") label(2 "Ahorros") row(1)) xtitle("Postulantes") ylab(,angle(0)) ytitle("MUSD") ///
*graphr(fc(white) lcolor(white) ilcolor(white)  lwidth(thick) margin(r+15))  ///
*bgcolor(white) plotr(style(none) fc(white) lcolor(white) lwidth(thick)) ///
*title("Ahorro neto según cantidad de postulantes") subtitle("Asignación Centralizada de Estudiantes") ///
*xlabel(3951 "3,951" 39876 "39,876" 100000 "100,000" 200000 "200,000" 300000 "300,000" 400000 "400,000" 500000 "500,000") ///
*xline(39876, lcolor(black%50))  xline(3951, lcolor(green%50)) text(16.2 3951 "Magallanes", size(3)) note("")
**yline(0.624073, lcolor(orange%70)) text(0.624073 535000 "$624,073")
*
*gr display, xsize(8)
*gr export "$graphs/students_cr_applicants.png", as(png) replace 

