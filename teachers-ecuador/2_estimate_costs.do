* ======================================= *
* 	     TEACHER ASSIGNMENT COSTS
* ======================================= *

* ---- PATHS ---- *

global main "/Users/antoniaaguilera/ConsiliumBots Dropbox/antoniaaguilera@consiliumbots.com/projects/iadb-ccas-costs/teachers"
global pathData "$main/data"
global graphs   "$main/figures"
global tables   "$main/tables"
global git      "/Users/antoniaaguilera/GitHub/iadb-ccas-costs"

* -------------------------------------------------------------------------- *
* -------------------- ESTIMATION BY PLACE AND CATEGORY -------------------- *
* -------------------------------------------------------------------------- *
clear all

* --------------------------------------- *
* ----------- SET PARAMETERS  ----------- *
* --------------------------------------- *

import delimited "$pathData/intermediate/for_cost_calculation.csv", clear
* --- Policy Costs Parameters --- *
local infra_algorithm   = 247860 //perú
local process_admin     = 50000  //ecuador
*local outreach          = 248000 //outreach and information during the assignment process
local monitoring_c      = 0 //monitoring and user support
local support_c 	    	= applicants[1]*105/806 //3308635*0.14*105/806
local maintenance       = 7000 //annual maintenance of the system


* --- Learning Gains Parameters --- *
local improved_score_vac = 0.011  //nº of position where teacher's score is improved as a % of total teachers
local learning_effect    = 1/3    //impact of improving teachers as a fraction of the yearly learning in std dev
local loss_income        = 0.025  //% of life loss income due to learning losses
local discount_rate      = 0.03
local wage_growth	     	 = 0.02


* ---------------------------------------------------------------- *
* -------------- CATEGORÍA 1: Costos de la Política -------------- *
* ---------------------------------------------------------------- *

replace implementation  = `infra_algorithm' if cost_cat == 1
replace yearly_admin    = `process_admin'   if cost_cat == 1
*replace  outreach       = `outreach'        if cost_cat == 1
replace monitoring      = stateofficialwage/monthhrs*time_monitoring/4*schools if cost_cat == 1
replace maintenance     = `maintenance'     if cost_cat == 1
replace support         = `support_c'       if cost_cat == 1

* -------------- *
* -- TEACHERS -- *
* -------------- *

// Opportunity cost of application time
replace application = teacherwage/monthhrs_teacher*time_per_app*applicants if cost_cat == 1

// Opportunity cost of evaluation time + cost of test
replace teachers_eval = teacherwage/monthhrs_teacher*time_eval*applicants  if cost_cat == 1

// Cost of supplies used in the application process
*replace supplies = (supplycost*n_apps*applicants) if cost_cat == 1

//Evaluation cost for the government
replace teachers_eval_gob = evalcost*applicants if cost_cat == 1

// Opportunity cost of transport time + fare
replace transport = teacherwage/monthhrs_teacher*time_transport*applicants + (busfare*applicants) if cost_cat == 1

// Cost of 1 hour per school of updating vacant seats in platform
replace staff = stateofficialwage/monthhrs*time_staff*schools if cost_cat == 1

// Cost of monitoring by authorities
*replace monitoring = stateofficialwage/monthhrs*time_monitoring*schools if cost_cat == 1


* ---------------------------------------------------------------- *
* ------------- CATEGORÍA 2: Ahorros en Desperdicios ------------- *
* ---------------------------------------------------------------- *

* -------------- *
* -- TEACHERS -- *
* -------------- *

// Time spent by families on application process
replace application = (teacherwage)/monthhrs_teacher*time_per_app*n_apps*applicants  if cost_cat == 2

// Opportunity cost of evaluation time for teachers
replace teachers_eval = teacherwage/monthhrs_teacher*time_eval*n_apps*applicants     if cost_cat == 2

//Evaluation cost for the government
replace teachers_eval_gob = evalcost*n_apps*applicants if cost_cat == 2

// Opportunity cost of transport time + fare
replace transport = teacherwage/monthhrs_teacher*time_transport*n_apps*applicants + (busfare*applicants)*n_apps if cost_cat == 2

// Cost of supplies used in the application process
replace supplies = (supplycost*n_apps*applicants) if cost_cat == 2

// Cost of staff working during an application process
replace staff = stateofficialwage/monthhrs*time_staff*n_apps*applicants + stateofficialwage/monthhrs*time_eval*applicants if cost_cat == 2

// Cost of monitoring by authorities
replace monitoring = stateofficialwage/monthhrs*time_monitoring*schools  if cost_cat == 2

// Cost of 1 hour per school of coordinating with schools
*replace staff = stateofficialwage/monthhrs*time_staff*schools if cost_cat == 2


* ----------------------------------------------------------------- *
* ------------- CATEGORÍA 3: Beneficio de la Política ------------- *
* ----------------------------------------------------------------- *

* ---- DATA & CONTACT INFORMATION ---- *
*replace data    = dataperapp*applicants     ///
*if cost_cat==3

*replace contact = contactperapp*applicants  ///
*if cost_cat==3

* ---- LEARNING GAINS ---- *
replace learning_gains = `improved_score_vac'*enrollment*st_ratio*`learning_effect'*student_exp*gdp_percap if cost_cat == 3

* ----------------------------------------------------------------- *
* ---------------------- COSTO POR POSTULANTE --------------------- *
* ----------------------------------------------------------------- *
* --- per applicant --- *
foreach vars in implementation yearly_admin maintenance outreach support monitoring application teachers_eval transport supplies staff data contact learning_gains learning_gains2 teachers_eval_gob {
	replace `vars'=`vars'/applicants if cost_type=="per_applicant"
	replace `vars'= 0 if `vars'==.
}

* ----------------------------------------------------------------- *
* ------------------- COSTO TOTAL POR CATEGORÍA ------------------- *
* ----------------------------------------------------------------- *

keep country applicant_type cost_cat cost_type applicants implementation yearly_admin maintenance outreach support monitoring application teachers_eval transport supplies staff data contact learning_gains learning_gains2 teachers_eval_gob
order country applicant_type cost_cat cost_type applicants implementation yearly_admin maintenance outreach support monitoring application teachers_eval transport supplies staff data contact learning_gains learning_gains2 teachers_eval_gob

gen admin = .
gen schools = .
gen families = .

drop outreach

* State: revisar esto!!!
replace admin = implementation + yearly_admin + maintenance + support + monitoring + teachers_eval_gob if cost_cat == 1 //+ outreach if cost_cat == 1
replace admin = monitoring  if cost_cat == 2

* Escuelas
replace schools = staff                                    if cost_cat == 1
replace schools = supplies + staff + teachers_eval_gob     if cost_cat == 2

* Familias
replace families = application + teachers_eval             if cost_cat == 1
replace families = application + transport + teachers_eval if cost_cat == 2

* Total
gen total_cost = schools + families + admin

format total_cost %20.01f
sort cost_type cost_cat

preserve
drop learning_gains*
reshape wide implementation yearly_admin maintenance support monitoring application teachers_eval transport supplies staff data contact teachers_eval_gob total_cost admin schools families ,i(country cost_cat) j(cost_type) string

reshape long @gross @per_applicant, i(cost_cat) j(cat) string

reshape wide gross per_applicant, i(country cat) j(cost_cat)
drop *3
rename (gross1 gross2 per_applicant1 per_applicant2)(cost_gross savings_gross cost_perapplicant savings_perapplicant)

drop if cat == "admin" | cat =="schools" | cat == "families" | cat == "total_cost"

format cost_gross savings_gross %20.0f
format cost_perapplicant savings_perapplicant %10.3f

export excel "$pathData/output/cost_teachers_ec.xlsx", replace first(var)
restore

* ----------------------------------------------------- *
* ------------------- COSTS SUMMARY ------------------- *
* ----------------------------------------------------- *

local cost_admin           : di %5.4g admin[1]/1000000
local cost_schools         : di %5.4g schools[1]/1000000
local cost_families        : di %5.4g families[1]/1000000
local cost_admin_perapp    : di %2.1g admin[4]
local cost_schools_perapp  : di %2.1g schools[4]
local cost_families_perapp : di %2.1g families[4]
local cost_total           : di %5.4g `cost_admin'+`cost_schools'+`cost_families'
local cost_total_perapp    : di %3.2g `cost_admin_perapp'+`cost_schools_perapp'+`cost_families_perapp'


file open  costs_summary using "$tables/costs_summary.tex", write replace
file write costs_summary "\begin{table}[ht!]" _n
file write costs_summary "\centering"_n
file write costs_summary "\caption{Resumen de costos de la implementación de un Sistema de Asignación Centralizada de Docentes.}"_n
file write costs_summary "\begin{tabular}{|l|cc|} \hline \hline"_n
file write costs_summary "\hline"_n
file write costs_summary "\rowcolor{black!25}\multicolumn{3}{|c|}{\textbf{Costos}}\\\hline"_n
file write costs_summary "\rowcolor{black!25} \textbf{Grupo} & \textbf{Total (MUSD)} & \textbf{Por postulante (USD)} \\\hline"_n
file write costs_summary "Administrador & \\$`cost_admin'    & \\$`cost_admin_perapp' \\"_n
file write costs_summary "Escuela       & \\$`cost_schools'  & \\$`cost_schools_perapp' \\"_n
file write costs_summary "Familias      & \\$`cost_families' & \\$`cost_families_perapp'\\\hline"_n
file write costs_summary "\rowcolor{black!25}\textbf{Total}  & \textbf{\\$`cost_total'} & \textbf{\\$`cost_total_perapp'} \\\hline"_n
file write costs_summary "\end{tabular}"_n
file write costs_summary "\label{tab:costs_summary}"_n
file write costs_summary "\end{table}"_n
file close costs_summary

local cost_admin_1         : di %6.3f implementation[1]/1000000
*local cost_admin_2         : di %6.3f outreach[1]/1000000
local cost_admin_3         : di %6.3f yearly_admin[1]/1000000
local cost_admin_4         : di %6.3f maintenance[1]/1000000
local cost_admin_5         : di %6.3f support[1]/1000000
local cost_admin_6         : di %6.3f monitoring[1]/1000000
local cost_admin_7         : di %6.3f teachers_eval_gob[1]/1000000

local cost_admin_1_pc      : di %3.2f implementation[4]
*local cost_admin_2_pc      : di %3.2f outreach[4]
local cost_admin_3_pc      : di %3.2f yearly_admin[4]
local cost_admin_4_pc      : di %5.4f maintenance[4]
local cost_admin_5_pc      : di %3.2f support[4]
local cost_admin_6_pc      : di %5.4f monitoring[4]
local cost_admin_7_pc      : di %5.4f teachers_eval_gob[4]

local cost_schools_1       : di %5.4f staff[1]/1000000
local cost_schools_1_pc    : di %3.2f staff[4]

local cost_families_1      : di %5.4f application[1]/1000000
local cost_families_2      : di %5.4f teachers_eval[1]/1000000
local cost_families_1_pc   : di %3.2f application[4]
local cost_families_2_pc   : di %3.2f teachers_eval[4]

local cost_total : di %5.4g `cost_admin_1'+`cost_admin_3'+`cost_admin_4'+`cost_admin_5'+`cost_admin_6'+`cost_admin_7'+`cost_schools_1'+`cost_families_1'+`cost_families_2'
local cost_total_perapp : di %3.2g `cost_admin_1_pc'+`cost_admin_3_pc'+`cost_admin_4_pc'+`cost_admin_5_pc'+`cost_admin_6_pc'+`cost_admin_7_pc'+`cost_schools_1_pc'+`cost_families_1_pc'+`cost_families_2_pc'


file open  costs_summary2 using "$tables/costs_items.tex", write replace
file write costs_summary2 "\begin{table}[ht!]" _n
file write costs_summary2 "\centering"_n
file write costs_summary2 "\caption{Costos de la implementación de un Sistema de Asignación Centralizada de Docentes.}"_n
file write costs_summary2 "\resizebox{17cm}{!}{"_n
file write costs_summary2 "\begin{tabular}{|c|l|c|c|}"_n
file write costs_summary2 "\hline"_n
file write costs_summary2 "\rowcolor{black!25} & \multicolumn{1}{|c|}{\textbf{COSTOS}} & Total & Por postulante\\"_n
file write costs_summary2 "\rowcolor{black!25} & \multicolumn{1}{|c|}{Descripción}  & (MUSD) & (USD) \\\hline"_n
file write costs_summary2 "\multicolumn{1}{|c|}{\multirow{8}{*}{Administrador}} & - Equipo de algoritmo y construcción de & &\\"_n
file write costs_summary2 "\multicolumn{1}{|c|}{} & infraestructura tecnológica                      &\\$`cost_admin_1' & \\$`cost_admin_1_pc'  \\"_n
file write costs_summary2 "\multicolumn{1}{|c|}{} & - Administración anual del proceso               &\\$`cost_admin_3' & \\$`cost_admin_3_pc'  \\"_n
file write costs_summary2 "\multicolumn{1}{|c|}{} & - Mantención anual del proceso                   &\\$`cost_admin_4' & \\$`cost_admin_4_pc'  \\"_n
file write costs_summary2 "\multicolumn{1}{|c|}{} & - Apoyo a las familias durante el proceso mediante & &\\"_n
file write costs_summary2 "\multicolumn{1}{|c|}{} & vía remota o mesas de apoyo                      &\\$`cost_admin_5' & \\$`cost_admin_5_pc'  \\"_n
file write costs_summary2 "\multicolumn{1}{|c|}{} & - Monitoreo al nivel centralizado                &\\$`cost_admin_6' & \\$`cost_admin_6_pc'  \\\hline"_n
file write costs_summary2 "\multicolumn{1}{|c|}{} & - Evaluación de docentes para la asignación      &\\$`cost_admin_7' & \\$`cost_admin_7_pc'  \\\hline"_n
file write costs_summary2 "\multicolumn{1}{|c|}{\multirow{2}{*}{Escuelas}} & - Publicación de vacantes e información && \\"_n
file write costs_summary2 "\multicolumn{1}{|c|}{} &relacionada utilizando la plataforma digital &\\$`cost_schools_1' & \\$`cost_schools_pc'  \\\hline"_n
file write costs_summary2 "\multicolumn{1}{|c|}{\multirow{2}{*}{Familias}} & Creación de perfil, entrega de antedecentes, búsqueda de  &  & \\"_n
file write costs_summary2 "\multicolumn{1}{|c|}{} &  vacantes y postulación a escuelas utilizando plataforma digital &\\$`cost_families_1' & \\$`cost_families_1_pc' \\\hline"_n
file write costs_summary2 "\multicolumn{1}{|c|}{} & - Evaluación de docentes para la asignación &\\$`cost_families_2' & \\$`cost_families_2_pc' \\\hline"_n
file write costs_summary2 "\rowcolor{black!25}  \multicolumn{2}{|c|}{\textbf{Total}} & \\$`cost_total' & \\$`cost_total_perapp' \\\hline"_n
file write costs_summary2 "\end{tabular} "_n
file write costs_summary2 "}"_n
file write costs_summary2 "\label{tab:costs_long}"_n
file write costs_summary2 "\end{table} "_n
file close costs_summary2


* ----------------------------------------------------- *
* ------------------ SAVINGS SUMMARY ------------------ *
* ----------------------------------------------------- *

local savings_admin           : di %5.3f admin[2]/1000000
local savings_schools         : di %5.3f schools[2]/1000000
local savings_families        : di %5.2f families[2]/1000000
local savings_admin_perapp    : di %5.3g admin[5]
local savings_schools_perapp  : di %5.3g schools[5]
local savings_families_perapp : di %5.3g families[5]
local savings_total : di %5.4g `savings_admin'+`savings_schools'+`savings_families'
local savings_total_perapp : di %3.2g `savings_admin_perapp'+`savings_schools_perapp'+`savings_families_perapp'

file open  savings_summary using "$tables/savings_summary.tex", write replace
file write savings_summary "\begin{table}[ht!]" _n
file write savings_summary "\centering"_n
file write savings_summary "\caption{Resumen de ahorros de la implementación de un Sistema de Asignación Centralizada de Docentes.}"_n
file write savings_summary "\begin{tabular}{|l|cc|} \hline \hline"_n
file write savings_summary "\hline"_n
file write savings_summary "\rowcolor{black!25}\multicolumn{3}{|c|}{\textbf{Ahorros}}\\\hline"_n
file write savings_summary "\rowcolor{black!25} \textbf{Grupo} & \textbf{Total (MUSD)} & \textbf{Por postulante (USD)} \\\hline"_n
file write savings_summary "Administrador & \\$`savings_admin'     & \\$`savings_admin_perapp' \\\hline"_n
file write savings_summary "Escuela       & \\$`savings_schools'   & \\$`savings_schools_perapp' \\\hline"_n
file write savings_summary "Familias      & \\$`savings_families'  & \\$`savings_families_perapp'\\\hline"_n
file write savings_summary "\rowcolor{black!25}\textbf{Total} &  \textbf{\\$`savings_total'} & \textbf{\\$`savings_total_perapp'} \\\hline"_n
file write savings_summary "\end{tabular}"_n
file write savings_summary "\label{tab:savings_summary}"_n
file write savings_summary "\end{table}"_n
file close savings_summary


local savings_admin_1         : di %6.3f monitoring[2]/1000000
local savings_admin_1_pc      : di %5.3f monitoring[5]
local savings_schools_1       : di %5.3f supplies[2]/1000000+staff[2]/1000000
local savings_schools_2       : di %5.3f teachers_eval_gob[2]/1000000
local savings_schools_1_pc    : di %5.3f supplies[5] + staff[5]
local savings_schools_2_pc    : di %5.3f teachers_eval_gob[5]
local savings_families_1      : di %5.3f application[2]/1000000 + transport[2]/1000000
local savings_families_2      : di %5.3f teachers_eval[2]/1000000
local savings_families_1_pc   : di %5.3f application[5] + transport[5]
local savings_families_2_pc   : di %5.3f teachers_eval[5]

local savings_total : di %5.2f `savings_admin_1'+ `savings_schools_1' +  `savings_schools_2' + `savings_families_1' + `savings_families_2'
local savings_total_perapp : di %5.2f `savings_admin_1_pc'+ `savings_schools_1_pc' +`savings_schools_2_pc' + `savings_families_1_pc' + `savings_families_2_pc'

file open  savings_summary2 using "$tables/savings_items.tex", write replace
file write savings_summary2 "\begin{table}[ht!]" _n
file write savings_summary2 "\centering"_n
file write savings_summary2 "\caption{Ahorros de la implementación de un Sistema de Asignación Centralizada de Docentes.}"_n
file write savings_summary2 "\resizebox{17cm}{!}{"_n
file write savings_summary2 "\begin{tabular}{|c|l|c|c|}"_n
file write savings_summary2 "\hline"_n
file write savings_summary2 "\rowcolor{black!25} & \multicolumn{1}{|c|}{\textbf{AHORROS}} & Total & Por postulante\\"_n
file write savings_summary2 "\rowcolor{black!25} & \multicolumn{1}{|c|}{Descripción}  & (MUSD) & (USD) \\\hline"_n
file write savings_summary2 "\multicolumn{1}{|c|}{\multirow{2}{*}{Administrador}} & - Monitoreo del proceso a nivel de cada & &\\"_n
file write savings_summary2 "\multicolumn{1}{|c|}{} & escuela realizado por funcionarios públicos    &\\$`savings_admin_1' & \\$`savings_admin_1_pc'  \\\hline"_n
file write savings_summary2 "\multicolumn{1}{|c|}{\multirow{3}{*}{Escuelas}} & - Personal de la escuela y materiales empleados && \\"_n
file write savings_summary2 "\multicolumn{1}{|c|}{} & en el proceso de postulación, revisión de antecedentes,  & &  \\"_n
file write savings_summary2 "\multicolumn{1}{|c|}{} & asignación y comunicación de los resultados &\\$`savings_schools_1' & \\$`savings_schools_1_pc'  \\\hline"_n
file write savings_summary2 "\multicolumn{1}{|c|}{} & - Evaluación docente para la asignación &\\$`savings_schools_2' & \\$`savings_schools_2_pc'  \\\hline"_n
file write savings_summary2 "\multicolumn{1}{|c|}{\multirow{2}{*}{Familias}} & - Postulación presencial en 3 escuelas   &  & \\"_n
file write savings_summary2 "\multicolumn{1}{|c|}{} &  incluyendo costos de transporte &\\$`savings_families_1' & \\$`savings_families_1_pc' \\\hline"_n
file write savings_summary2 "\multicolumn{1}{|c|}{} & - Evaluación docente para la asignación &\\$`savings_families_2' & \\$`savings_families_2_pc' \\\hline"_n
file write savings_summary2 "\rowcolor{black!25} \multicolumn{2}{|c|}{\textbf{Total}} & \\$`savings_total' & \\$`savings_total_perapp' \\\hline"_n
file write savings_summary2 "\end{tabular} "_n
file write savings_summary2 "}"_n
file write savings_summary2 "\label{tab:savings_long}"_n
file write savings_summary2 "\end{table} "_n
file close savings_summary2
