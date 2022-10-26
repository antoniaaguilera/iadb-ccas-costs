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
local support_c 	    = applicants[1]*105/806 //3308635*0.14*105/806
local maintenance       = 7000 //annual maintenance of the system


* --- Learning Gains Parameters --- *
local improved_score_vac = 0.011  //nº of position where teacher's score is improved as a % of total teachers
local learning_effect    = 1/3    //impact of improving teachers as a fraction of the yearly learning in std dev
local loss_income        = 0.025  //% of life loss income due to learning losses
local discount_rate      = 0.03
local wage_growth	  	 = 0.02


* ---------------------------------------------------------------- *
* -------------- CATEGORÍA 1: Costos de la Política -------------- *
* ---------------------------------------------------------------- *

replace implementation  = `infra_algorithm'  if cost_cat == 1
replace yearly_admin    = `process_admin'    if cost_cat == 1
*replace  outreach       = `outreach'        if cost_cat == 1
replace monitoring_dc   = stateofficialwage/monthhrs*time_monitoring/4*schools if cost_cat == 1
replace monitoring_sc   = stateofficialwage/monthhrs*time_monitoring/4*schools if cost_cat == 1
replace maintenance     = `maintenance'      if cost_cat == 1
replace support         = `support_c'        if cost_cat == 1

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

keep  country applicant_type cost_cat cost_type applicants implementation yearly_admin maintenance outreach support* monitoring* application* teachers_eval* transport* supplies* staff* data* contact* learning_gains* learning_gains2* teachers_eval_gob*
order country applicant_type cost_cat cost_type applicants implementation yearly_admin maintenance outreach support* monitoring* application* teachers_eval* transport* supplies* staff* data* contact* learning_gains* learning_gains2* teachers_eval_gob*

gen admin_dc    = .
gen schools_dc  = .
gen families_dc = .

gen admin_sc    = .
gen schools_sc  = .
gen families_sc = .

drop outreach

* Administrador
replace admin_dc = implementation + yearly_admin + maintenance + support + monitoring_dc + teachers_eval_gob_dc if cost_cat == 1 //+ outreach if cost_cat == 1
replace admin_dc = monitoring_dc  if cost_cat == 2

replace admin_sc = implementation + yearly_admin + maintenance + support + monitoring_sc + teachers_eval_gob_sc if cost_cat == 1 //+ outreach if cost_cat == 1
replace admin_sc = monitoring_dc  + staff_sc + supplies_sc + teachers_eval_gob_sc if cost_cat == 2

* Escuelas
replace schools_dc = staff_dc                                          if cost_cat == 1
replace schools_dc = supplies_dc + staff_dc + teachers_eval_gob_dc     if cost_cat == 2

replace schools_sc = staff_sc                                          if cost_cat == 1
replace schools_sc = staff2_sc 										   if cost_cat == 2

* Familias
replace families_dc = application_dc + teachers_eval_dc                if cost_cat == 1
replace families_dc = application_dc + transport_dc + teachers_eval_dc if cost_cat == 2

replace families_sc = application_sc + teachers_eval_sc                if cost_cat == 1
replace families_sc = application_sc + transport_sc + teachers_eval_sc if cost_cat == 2

* Total
gen total_cost_dc = schools_dc + families_dc + admin_dc
gen total_cost_sc = schools_sc + families_sc + admin_sc

format total_cost_dc total_cost_sc %20.01f
sort cost_type cost_cat

replace cost_type = "pa" if cost_type == "per_applicant"
preserve
drop learning_gains*
reshape wide implementation yearly_admin maintenance support monitoring_dc monitoring_sc application_dc application_sc  teachers_eval_dc teachers_eval_sc transport_dc transport_sc supplies_dc supplies_sc staff_dc staff_sc staff2_dc staff2_sc data contact teachers_eval_gob_dc teachers_eval_gob_sc total_cost_dc total_cost_sc admin_dc admin_sc schools_dc schools_sc families_dc families_sc ,i(country cost_cat) j(cost_type) string

reshape long @gross @pa, i(cost_cat) j(cat) string

reshape wide gross pa, i(country cat) j(cost_cat)
drop *3
rename (gross1 gross2 pa1 pa2)(cost_gross savings_gross cost_perapplicant savings_perapplicant)
  
// drop if cat == "admin" | cat =="schools" | cat == "families" | cat == "total_cost"
// inlist(cat, "admin_dc", "schools_dc", "families_dc", "total_cost_dc")|inlist(cat, "admin_sc", "schools_sc", "families_sc", "total_cost_sc")

format cost_gross savings_gross %20.0f
format cost_perapplicant savings_perapplicant %10.3f

export excel "$pathData/output/cost_teachers_ec.xlsx", replace first(var)
restore

* ----------------------------------------------------- *
* ------------------- COSTS SUMMARY ------------------- *
* ----------------------------------------------------- *
* --- resumen de costos
local cost_admin           : di %5.4g admin_dc[1]/1000000
local cost_schools         : di %5.4g schools_dc[1]/1000000
local cost_families        : di %5.4g families_dc[1]/1000000
local cost_admin_perapp    : di %2.1g admin_dc[4]
local cost_schools_perapp  : di %2.1g schools_dc[4]
local cost_families_perapp : di %2.1g families_dc[4]
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

* --- desglose de costos 
local cost_admin_1         : di %6.3f implementation[1]/1000000
*local cost_admin_2         : di %6.3f outreach[1]/1000000
local cost_admin_3         : di %6.3f yearly_admin[1]/1000000
local cost_admin_4         : di %6.3f maintenance[1]/1000000
local cost_admin_5         : di %6.3f support[1]/1000000
local cost_admin_6         : di %6.3f monitoring_dc[1]/1000000
local cost_admin_7         : di %6.3f teachers_eval_gob_dc[1]/1000000

local cost_admin_1_pc      : di %3.2f implementation[4]
*local cost_admin_2_pc      : di %3.2f outreach[4]
local cost_admin_3_pc      : di %3.2f yearly_admin[4]
local cost_admin_4_pc      : di %5.4f maintenance[4]
local cost_admin_5_pc      : di %3.2f support[4]
local cost_admin_6_pc      : di %5.4f monitoring_dc[4]
local cost_admin_7_pc      : di %5.4f teachers_eval_gob_dc[4]

local cost_schools_1       : di %5.4f staff_dc[1]/1000000
local cost_schools_1_pc    : di %3.2f staff_dc[4]

local cost_families_1      : di %5.4f application_dc[1]/1000000
local cost_families_2      : di %5.4f teachers_eval_dc[1]/1000000
local cost_families_1_pc   : di %3.2f application_dc[4]
local cost_families_2_pc   : di %3.2f teachers_eval_dc[4]

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
file write costs_summary2 "\multicolumn{1}{|c|}{} & - Apoyo a los postulantes durante el proceso mediante & &\\"_n
file write costs_summary2 "\multicolumn{1}{|c|}{} & vía remota o mesas de apoyo                      &\\$`cost_admin_5' & \\$`cost_admin_5_pc'  \\"_n
file write costs_summary2 "\multicolumn{1}{|c|}{} & - Monitoreo al nivel centralizado                &\\$`cost_admin_6' & \\$`cost_admin_6_pc'  \\"_n
file write costs_summary2 "\multicolumn{1}{|c|}{} & - Evaluación de docentes para la asignación      &\\$`cost_admin_7' & \\$`cost_admin_7_pc'  \\\hline"_n
file write costs_summary2 "\multicolumn{1}{|c|}{\multirow{2}{*}{Escuelas}} & - Publicación de vacantes e información && \\"_n
file write costs_summary2 "\multicolumn{1}{|c|}{} &relacionada utilizando la plataforma digital &\\$`cost_schools_1' & \\$`cost_schools_1_pc'  \\\hline"_n
file write costs_summary2 "\multicolumn{1}{|c|}{\multirow{2}{*}{Familias}} & Creación de perfil, entrega de antedecentes, búsqueda de  &  & \\"_n
file write costs_summary2 "\multicolumn{1}{|c|}{} &  vacantes y postulación a escuelas utilizando plataforma digital &\\$`cost_families_1' & \\$`cost_families_1_pc' \\"_n
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

* --- resumen de ahorros 
local savings_admin_dc           : di %5.3f admin_dc[2]/1000000
local savings_schools_dc         : di %5.3f schools_dc[2]/1000000
local savings_families_dc        : di %5.2f families_dc[2]/1000000
local savings_admin_perapp_dc    : di %5.3g admin_dc[5]
local savings_schools_perapp_dc  : di %5.3g schools_dc[5]
local savings_families_perapp_dc : di %5.3g families_dc[5]
local savings_total_dc           : di %5.4g `savings_admin_dc'+`savings_schools_dc'+`savings_families_dc'
local savings_total_perapp_dc    : di %3.2g `savings_admin_perapp_dc'+`savings_schools_perapp_dc'+`savings_families_perapp_dc'

local savings_admin_sc           : di %5.3f admin_sc[2]/1000000
local savings_schools_sc         : di %5.3f schools_sc[2]/1000000
local savings_families_sc        : di %5.2f families_sc[2]/1000000
local savings_admin_perapp_sc    : di %5.3g admin_sc[5]
local savings_schools_perapp_sc  : di %5.3g schools_sc[5]
local savings_families_perapp_sc : di %5.3g families_sc[5]
local savings_total_sc           : di %5.4g `savings_admin_sc'+`savings_schools_sc'+`savings_families_sc'
local savings_total_perapp_sc    : di %3.2g `savings_admin_perapp_sc'+`savings_schools_perapp_sc'+`savings_families_perapp_sc'

file open  savings_summary using "$tables/savings_summary.tex", write replace
file write savings_summary "\begin{table}[ht!]" _n
file write savings_summary "\centering"_n
file write savings_summary "\caption{Resumen de ahorros de la implementación de un Sistema de Asignación Centralizada de Docentes, desde un Sistema Descentralizado y desde uno Semi-Centralizado.}"_n
file write savings_summary "\begin{tabular}{|l|cc|cc|} \hline \hline"_n
file write savings_summary "\hline"_n
file write savings_summary "\rowcolor{black!25}& \multicolumn{2}{|c|}{\textbf{Descentralizado}}                                         &\multicolumn{2}{|c|}{\textbf{Semi-Centralizado}} \\ \hline"_n
file write savings_summary "\rowcolor{black!25} \textbf{Grupo} & \textbf{Total (MUSD)}          & \textbf{Por postulante (USD)}         & \textbf{Total (MUSD)}          & \textbf{Por postulante (USD)}         \\ \hline"_n
file write savings_summary "Administrador                      & \\$`savings_admin_dc'          & \\$`savings_admin_perapp_dc'          & \\$`savings_admin_sc'          & \\$`savings_admin_perapp_sc'          \\ \hline"_n
file write savings_summary "Escuela                            & \\$`savings_schools_dc'        & \\$`savings_schools_perapp_dc'        & \\$`savings_schools_sc'        & \\$`savings_schools_perapp_sc'        \\ \hline"_n
file write savings_summary "Docentes                           & \\$`savings_families_dc'       & \\$`savings_families_perapp_dc'       & \\$`savings_families_sc'       & \\$`savings_families_perapp_sc'       \\ \hline"_n
file write savings_summary "\rowcolor{black!25}\textbf{Total}  & \textbf{\\$`savings_total_dc'} & \textbf{\\$`savings_total_perapp_dc'} & \textbf{\\$`savings_total_sc'} & \textbf{\\$`savings_total_perapp_sc'} \\ \hline"_n
file write savings_summary "\end{tabular}"_n
file write savings_summary "\label{tab:savings_summary}"_n
file write savings_summary "\end{table}"_n
file close savings_summary


* --- desglose de ahorros
local savings_admin_1_dc         : di %6.3f monitoring_dc[2]/1000000
local savings_admin_1_pc_dc      : di %5.3f monitoring_dc[5]
local savings_schools_1_dc       : di %6.3f supplies_dc[2]/1000000+staff_dc[2]/1000000
local savings_schools_2_dc       : di %6.3f teachers_eval_gob_dc[2]/1000000
local savings_schools_1_pc_dc    : di %5.3f supplies_dc[5] + staff_dc[5]
local savings_schools_2_pc_dc    : di %5.3f teachers_eval_gob_dc[5]
local savings_families_1_dc      : di %6.3f application_dc[2]/1000000 + transport_dc[2]/1000000
local savings_families_2_dc      : di %6.3f teachers_eval_dc[2]/1000000
local savings_families_1_pc_dc   : di %5.3f application_dc[5] + transport_dc[5]
local savings_families_2_pc_dc   : di %5.3f teachers_eval_dc[5]


local savings_total_dc           : di %5.2f `savings_admin_1_dc' + `savings_schools_1_dc' +  `savings_schools_2_dc' + `savings_families_1_dc' + `savings_families_2_dc'
local savings_total_perapp_dc    : di %5.2f `savings_admin_1_pc_dc'+ `savings_schools_1_pc_dc' +`savings_schools_2_pc_dc' + `savings_families_1_pc_dc' + `savings_families_2_pc_dc'

local savings_admin_1_sc         : di %6.3f (staff_sc[2] + supplies_sc[2])/1000000
local savings_admin_1_pc_sc      : di %5.3f (staff_sc[5] + supplies_sc[5])
local savings_admin_2_sc         : di %6.3f monitoring_sc[2]/1000000
local savings_admin_2_pc_sc      : di %5.3f monitoring_sc[5]
local savings_admin_3_sc         : di %6.3f teachers_eval_gob_sc[2]/1000000
local savings_admin_3_pc_sc      : di %5.3f teachers_eval_gob_sc[5]
local savings_schools_1_sc       : di %6.3f staff2_sc[2]/1000000
local savings_schools_1_pc_sc    : di %5.3f staff2_sc[5]
local savings_families_1_sc      : di %6.3f application_sc[2]/1000000 + transport_sc[2]/1000000
local savings_families_2_sc      : di %6.3f teachers_eval_sc[2]/1000000
local savings_families_1_pc_sc   : di %5.3f application_sc[5] + transport_sc[5]
local savings_families_2_pc_sc   : di %5.3f teachers_eval_sc[5]

local savings_total_sc           : di %5.2f `savings_admin_1_sc'    + `savings_admin_2_sc'    + `savings_admin_3_sc'    + `savings_schools_1_sc'    + `savings_families_1_sc'    + `savings_families_2_sc'
local savings_total_perapp_sc    : di %5.2f `savings_admin_1_pc_sc' + `savings_admin_2_pc_sc' + `savings_admin_3_pc_sc' + `savings_schools_1_pc_sc' + `savings_families_1_pc_sc' + `savings_families_2_pc_sc'

file open  savings_summary2 using "$tables/savings_items.tex", write replace
file write savings_summary2 "\begin{table}[ht!]" _n
file write savings_summary2 "\centering"_n
file write savings_summary2 "\caption{Ahorros de la implementación de un Sistema de Asignación Centralizada de Docentes desde un Sistema Descentralizado y desde un Sistema Semi-Centralizado.}"_n
file write savings_summary2 "\resizebox{17cm}{!}{"_n
file write savings_summary2 "\begin{tabular}{|c|l|c|c|c|c|}"_n
file write savings_summary2 "\hline"_n
file write savings_summary2 "\rowcolor{black!25}                                  & \multicolumn{1}{|c|}{\textbf{AHORROS}} & \multicolumn{2}{|c|}{\textbf{Descentralizado}}                  &\multicolumn{2}{|c|}{\textbf{Semi-Centralizado}}\\"_n
file write savings_summary2 "\rowcolor{black!25}                & \multicolumn{1}{|c|}{Descripción}                  & \multicolumn{1}{|c|}{ Total (MUSD)}           &  \multicolumn{1}{|c|}{Por Postulante (USD)}      & \multicolumn{1}{|c|}{ Total (MUSD)}     &  \multicolumn{1}{|c|}{Por Postulante (USD)}  \\\hline"_n
file write savings_summary2 "\multicolumn{1}{|c|}{\multirow{5}{*}{Administrador}} & - Personal y materiales empleados && && \\"_n
file write savings_summary2 "\multicolumn{1}{|c|}{} & en el proceso de postulación, revisión de antecedentes,   & & & &  \\"_n
file write savings_summary2 "\multicolumn{1}{|c|}{} & asignación y comunicación de los resultados.              & - & -    &\\$`savings_admin_1_sc'     & \\$`savings_admin_1_pc_sc'     \\ "_n
file write savings_summary2 "\multicolumn{1}{|c|}{} & - Monitoreo del proceso                                   & - & -    &\\$`savings_admin_2_sc'     & \\$`savings_admin_2_pc_sc'     \\ "_n
file write savings_summary2 "\multicolumn{1}{|c|}{} & - Evaluación docente para la asignación                   & - & -    &\\$`savings_admin_3_sc'     & \\$`savings_admin_3_pc_sc'     \\ \hline"_n
file write savings_summary2 "\multicolumn{1}{|c|}{\multirow{5}{*}{Escuelas}} & - Personal de la escuela y materiales empleados && && \\"_n
file write savings_summary2 "\multicolumn{1}{|c|}{} & en el proceso de postulación, revisión de antecedentes,  & & & &  \\"_n
file write savings_summary2 "\multicolumn{1}{|c|}{} & asignación y comunicación de los resultados                        &\\$`savings_schools_1_dc' & \\$`savings_schools_1_pc_dc' & -  & -   \\ "_n
file write savings_summary2 "\multicolumn{1}{|c|}{} & - Evaluación docente para la asignación                            &\\$`savings_schools_2_dc' & \\$`savings_schools_2_pc_dc' & -  & -   \\ "_n
file write savings_summary2 "\multicolumn{1}{|c|}{} & - Estimación de vacantes docentes y comunicación al administrador  & -                        & -                            &\\$`savings_schools_1_sc' & \\$`savings_schools_1_pc_sc'  \\ \hline"_n
file write savings_summary2 "\multicolumn{1}{|c|}{\multirow{3}{*}{Familias}} & - Postulación presencial en 3 escuelas   &  & &  & \\"_n
file write savings_summary2 "\multicolumn{1}{|c|}{} &  incluyendo costos de transporte                &\\$`savings_families_1_dc' & \\$`savings_families_1_pc_dc' &\\$`savings_families_1_sc' & \\$`savings_families_1_pc_sc'  \\ "_n
file write savings_summary2 "\multicolumn{1}{|c|}{} & - Evaluación docente para la asignación         &\\$`savings_families_2_dc' & \\$`savings_families_2_pc_dc' &\\$`savings_families_2_sc' & \\$`savings_families_2_pc_sc'  \\ "_n
file write savings_summary2 "\rowcolor{black!25} \multicolumn{2}{|c|}{\textbf{Total}}                 &\\$`savings_total_dc'      & \\$`savings_total_perapp_dc'  &\\$`savings_total_sc'      & \\$`savings_total_perapp_sc'   \\ "_n
file write savings_summary2 "\end{tabular} "_n
file write savings_summary2 "}"_n
file write savings_summary2 "\label{tab:savings_long}"_n
file write savings_summary2 "\end{table} "_n
file close savings_summary2






































