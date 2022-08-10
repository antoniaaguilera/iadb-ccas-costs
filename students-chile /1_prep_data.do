* =========================================== *
*   PREP DATA FOR COST ESTIMATION
* =========================================== *

* ---- SET PATHS ---- *

global main "/Users/antoniaaguilera/ConsiliumBots Dropbox/antoniaaguilera@consiliumbots.com/projects/iadb-ccas-costs/students"
global pathData "$main/data"


* =========================================== *
*   CALCULATE DISTANCES FOR COST ESTIMATION
* =========================================== *

* --------------------------------- *
* ------------ SCHOOLS ------------ *
* --------------------------------- *
import delimited "$pathData/input/SAE/SAE_2019/A1_Oferta_Establecimientos_etapa_regular_2019_Admision_2020.csv", clear 

gen lat_school = subinstr(lat, ",", ".",.)
gen lon_school = subinstr(lon, ",", ".",.)

keep rbd lat_school lon_school
duplicates drop rbd, force

merge 1:1 rbd using "$pathData/input/SchoolsComunas.dta", keepusing(region comuna)
drop _merge 

tempfile schools
save `schools', replace 

* ---------------------------------- *
* ------------ STUDENTS ------------ *
* ---------------------------------- *
* ---- REGULAR STAGE 
import delimited "$pathData/input/SAE/SAE_2019/B1_Postulantes_etapa_regular_2019_Admision_2020_PUBL.csv", clear 

gen lat_student = subinstr(lat_con_error, ",", ".",.)
gen lon_student = subinstr(lon_con_error, ",", ".",.)

keep mrun lat_student lon_student

tempfile students_reg
save `students_reg', replace 

* ---- COMPLEMENTARY STAGE 
import delimited "$pathData/input/SAE/SAE_2019/B2_Postulantes_etapa_complementaria_2019_Admision_2020_PUBL.csv", clear 

gen lat_student = subinstr(lat_con_error, ",", ".",.)
gen lon_student = subinstr(lon_con_error, ",", ".",.)

keep mrun lat_student lon_student

tempfile students_comp
save `students_comp', replace 

* ------------------------------------------------------------ *
* ---------- APPLICATIONS AND DISTANCE CALCULATIONS ---------- *
* ------------------------------------------------------------ *

* ---- REGULAR STAGE 
import delimited "$pathData/input/SAE/SAE_2019/C1_Postulaciones_etapa_regular_2019_Admision_2020_PUBL.csv", clear 

keep mrun rbd preferencia_postulante

bys mrun: egen n_applications_reg = max(preferencia_postulante)

* ---- merge
merge m:1 mrun using `students_reg'
drop _merge 

merge m:1 rbd using `schools'
keep if _merge == 3 
drop _merge 

* ---- calculate distance
destring lat_* lon_*, replace  
geodist lat_student lon_student lat_school lon_school, g(distance)

sum distance 

keep if region == 13 
* ---- travel time pre-sae
local mean_speed = 19.21
gen travel_time_presae = distance/`mean_speed'

sum travel_time_presae

* ---- mean per student 
bys mrun: egen sum_travel_presae_reg = sum(travel_time_presae)

duplicates drop mrun, force 

tempfile applications_reg
save `applications_reg', replace 

* ---- COMPLEMENTARY STAGE 
import delimited "$pathData/input/SAE/SAE_2019/C2_Postulaciones_etapa_complementaria_2019_Admision_2020_PUBL.csv", clear 

keep mrun rbd preferencia_postulante
bys mrun: egen n_applications_comp = max(preferencia_postulante)

* ---- merge
merge m:1 mrun using `students_comp'
drop _merge 

merge m:1 rbd using `schools'
keep if _merge == 3 
drop _merge 

* ---- calculate distance
destring lat_* lon_*, replace  
geodist lat_student lon_student lat_school lon_school, g(distance)

sum distance 

keep if region == 13 
* ---- travel time pre-sae
local mean_speed = 19.21
gen travel_time_presae = distance/`mean_speed'

sum travel_time_presae

* ---- mean per student 
bys mrun: egen sum_travel_presae_comp = sum(travel_time_presae)

duplicates drop mrun, force 

* --------------------------------------- *
* --------------- MERGE  ---------------- *
* --------------------------------------- *

merge 1:1 mrun using `applications_reg'
drop _merge 

replace sum_travel_presae_reg = 0 if sum_travel_presae_reg ==.
replace sum_travel_presae_comp = 0 if sum_travel_presae_comp ==.

gen total_travel_time = (sum_travel_presae_comp+sum_travel_presae_reg)*2

sum total_travel_time
local travel_time_d = `r(mean)'
di `travel_time_d'

* ========================================================== *
*          ----- CLEAN DATA FOR COST ESTIMATION -----
* ========================================================== *

import excel "$pathData/input/parameters.xlsx", clear first

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
local time_transport_d  = `travel_time_d'   //Time spent in transport, all applicants

* --- Other Parameters --- *
local supplycost        = 0.1    //unit supply cost
local datacost          = 1.25   //unit data cost
local contactcost       = 2.53   //unit contact cost
local supportcost       = 0.12   //user support cost per applicant
}

* --------------------------------------- *
* ------------ RE-WORK DATA  ------------ *
* --------------------------------------- *

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

keep if country=="CHILE" & applicant_type=="students"

export delimited  "$pathData/intermediate/for_extended_analysis.csv", replace 


* ----------------------------------------------------------------- *
* -------------------- PARAMETER CONFIGURATION -------------------- *
* ----------------------------------------------------------------- *

gen time_per_app     = `time_app_st_c'         if cost_cat==1
replace time_per_app = `time_app_st_d'         if cost_cat==2

gen time_transport   = 0				 	   if cost_cat == 1 
replace time_transport = `time_transport_d'	   if cost_cat == 2

gen n_apps           = `apps_students'         if cost_cat==2

gen time_staff       = `time_staff'
replace time_staff 	 = `time_staff_c'  	       if cost_cat == 1
gen time_monitoring  = `time_monitoring_s'     if cost_cat<=2

gen support_cost     = `supportcost'	       if cost_cat==1

gen supplycost       = `supplycost'
gen dataperapp       = `datacost'
gen contactperapp    = `contactcost'


* --- inicializar variables
foreach x in implementation yearly_admin maintenance outreach  support monitoring application transport supplies staff data contact  {
	gen `x' = 0
}

gen travel_time_d = `travel_time_d'

rename cost_cat cost_cat_aux
// gen cost_cat = 1     if cost_cat_str == "Costos Política"
// replace cost_cat = 2 if cost_cat_str == "Ahorros en Desperdicios"
// replace cost_cat = 3 if cost_cat_str == "Beneficios de la Política"

gen cost_cat  = 1 if cost_cat_aux == 1
replace cost_cat = 2 if cost_cat_aux == 2
replace cost_cat = 3 if cost_cat_aux == 3

export delimited  "$pathData/intermediate/for_cost_calculation.csv", replace 



 
* =========================================== *
*   PREP DATA FOR SATISFACTION ANALYSIS
* =========================================== *

use "$pathData/input/clean_surveySAE2021_all.dta", clear

keep nota_proceso tiempoSAE*
gen aux = 1
collapse (sum) pc = aux , by(nota_proceso)
drop if nota_proceso==.
egen tot = sum(pc)
replace pc = round(pc/tot*100, .01)
export delimited "$pathData/intermediate/survey_chile_short.csv", replace 


* ======================================= *
* -------- CLEAN BENEFITS STUDENTS ------ *
* ======================================= *


* ---- Panel matrícula 2011-2021 ---- *
local path2005 = "$pathData/input/matricula/matricula-por-estudiante/basica-y-media/Matricula-por-estudiante-2005/20140805_matricula_unica_2005_20050430_PUBL.csv"
local path2006 = "$pathData/input/matricula/matricula-por-estudiante/basica-y-media/Matricula-por-estudiante-2006/20140805_matricula_unica_2006_20060430_PUBL.csv"
local path2007 = "$pathData/input/matricula/matricula-por-estudiante/basica-y-media/Matricula-por-estudiante-2007/20140805_matricula_unica_2007_20070430_PUBL.csv"
local path2008 = "$pathData/input/matricula/matricula-por-estudiante/basica-y-media/Matricula-por-estudiante-2008/20140805_matricula_unica_2008_20080430_PUBL.csv"
local path2009 = "$pathData/input/matricula/matricula-por-estudiante/basica-y-media/Matricula-por-estudiante-2009/20140805_matricula_unica_2009_20090430_PUBL.csv"
local path2010 = "$pathData/input/matricula/matricula-por-estudiante/basica-y-media/Matricula-por-estudiante-2010/20130904_matricula_unica_2010_20100430_PUBL.csv"
local path2011 = "$pathData/input/matricula/matricula-por-estudiante/basica-y-media/Matricula-por-estudiante-2011/20140812_matricula_unica_2011_20110430_PUBL.csv"
local path2012 = "$pathData/input/matricula/matricula-por-estudiante/basica-y-media/Matricula-por-estudiante-2012/20140812_matricula_unica_2012_20120430_PUBL.csv"
local path2013 = "$pathData/input/matricula/matricula-por-estudiante/basica-y-media/Matricula-por-estudiante-2013/20140808_matricula_unica_2013_20130430_PUBL.csv"
local path2014 = "$pathData/input/matricula/matricula-por-estudiante/basica-y-media/Matricula-por-estudiante-2014/20140924_matricula_unica_2014_20140430_PUBL.csv"
local path2015 = "$pathData/input/matricula/matricula-por-estudiante/basica-y-media/Matricula-por-estudiante-2015/20150923_matricula_unica_2015_20150430_PUBL.csv"
local path2016 = "$pathData/input/matricula/matricula-por-estudiante/basica-y-media/Matricula-por-estudiante-2016/20160926_matricula_unica_2016_20160430_PUBL.csv"
local path2017 = "$pathData/input/matricula/matricula-por-estudiante/basica-y-media/Matricula-por-estudiante-2017/20170921_matricula_unica_2017_20170430_PUBL.csv"
local path2018 = "$pathData/input/matricula/matricula-por-estudiante/basica-y-media/Matricula-por-estudiante-2018/20181005_Matrícula_unica_2018_20180430_PUBL.csv"
local path2019 = "$pathData/input/matricula/matricula-por-estudiante/basica-y-media/Matricula-por-estudiante-2019/20191028_Matrícula_unica_2019_20190430_PUBL.csv"
local path2020 = "$pathData/input/matricula/matricula-por-estudiante/basica-y-media/Matricula-por-estudiante-2020/20200921_Matrícula_unica_2020_20200430_WEB.csv"
local path2021 = "$pathData/input/matricula/matricula-por-estudiante/basica-y-media/Matricula-por-estudiante-2021/20210913_Matrícula_unica_2021_20210430_WEB.csv"


forvalues year=2005/2021 {
  import delimited "`path`year''" , clear
  keep if (cod_depe == 1 | cod_depe == 2 | cod_depe == 3 | cod_depe == 6)
  *conservar sólo la matrícula de los grados de entrada para
  keep if (cod_ense == 10 | cod_ense == 110 | cod_ense == 310 | cod_ense == 410 | cod_ense == 510 | cod_ense == 610 | cod_ense == 710)
  *colapsar
  cap destring mrun, replace
  * matricula_total
  collapse (count) matricula = mrun (firstnm) cod_reg_rbd cod_depe cod_com_rbd, by(rbd cod_ense cod_grado)

  tab cod_grado if cod_ense==10
  gen cod_nivel = -1     if cod_ense == 10 & cod_grado == 4
  replace cod_nivel = 0  if cod_ense == 10 & cod_grado == 5
  replace cod_nivel = 1  if cod_ense == 110 & cod_grado == 1
  replace cod_nivel = 2  if cod_ense == 110 & cod_grado == 2
  replace cod_nivel = 3  if cod_ense == 110 & cod_grado == 3
  replace cod_nivel = 4  if cod_ense == 110 & cod_grado == 4
  replace cod_nivel = 5  if cod_ense == 110 & cod_grado == 5
  replace cod_nivel = 6  if cod_ense == 110 & cod_grado == 6
  replace cod_nivel = 7  if cod_ense == 110 & cod_grado == 7
  replace cod_nivel = 8  if cod_ense == 110 & cod_grado == 8
  replace cod_nivel = 9  if cod_ense >= 310 & cod_grado == 1
  replace cod_nivel = 10 if cod_ense >= 310 & cod_grado == 2
  replace cod_nivel = 11 if cod_ense >= 310 & cod_grado == 3
  replace cod_nivel = 12 if cod_ense >= 310 & cod_grado == 4

  gen mat_prek     = matricula if (cod_nivel == -1 )
  gen mat_k        = matricula if (cod_nivel ==  0 )
  gen mat_primerob = matricula if (cod_nivel ==  1 )
  gen mat_septimo  = matricula if (cod_nivel ==  7 )
  gen mat_primerom = matricula if (cod_nivel ==  9 )

  bys rbd: egen entry = min(cod_nivel)
  bys rbd: egen mat_total_`year' = sum(matricula)

  collapse (sum) matricula_`year' = matricula (firstnm) mat_total_`year' entry cod_ense cod_reg_rbd cod_depe cod_com_rbd, by(rbd cod_nivel)

  tempfile mat_`year'
  save `mat_`year'', replace

}

* --- merge --- *
use `mat_2005', clear
merge 1:1 rbd cod_nivel using `mat_2005', keep(3) nogen
merge 1:1 rbd cod_nivel using `mat_2006', keep(3) nogen
merge 1:1 rbd cod_nivel using `mat_2007', keep(3) nogen
merge 1:1 rbd cod_nivel using `mat_2008', keep(3) nogen
merge 1:1 rbd cod_nivel using `mat_2009', keep(3) nogen
merge 1:1 rbd cod_nivel using `mat_2010', keep(3) nogen
merge 1:1 rbd cod_nivel using `mat_2011', keep(3) nogen
merge 1:1 rbd cod_nivel using `mat_2012', keep(3) nogen
merge 1:1 rbd cod_nivel using `mat_2013', keep(3) nogen
merge 1:1 rbd cod_nivel using `mat_2014', keep(3) nogen
merge 1:1 rbd cod_nivel using `mat_2015', keep(3) nogen
merge 1:1 rbd cod_nivel using `mat_2016', keep(3) nogen
merge 1:1 rbd cod_nivel using `mat_2017', keep(3) nogen
merge 1:1 rbd cod_nivel using `mat_2018', keep(3) nogen
merge 1:1 rbd cod_nivel using `mat_2019', keep(3) nogen
merge 1:1 rbd cod_nivel using `mat_2020', keep(3) nogen
merge 1:1 rbd cod_nivel using `mat_2021', keep(3) nogen


tempfile mat_20052021
save `mat_20052021', replace


* ---- SAE 2019 ---- *
local path_sae_2019_vacs = "$pathData/input/SAE/SAE_2019/A1_Oferta_Establecimientos_etapa_regular_2019_Admision_2020.csv"
local path_sae_2020_vacs = "$pathData/input/SAE/SAE_2020/A1_Oferta_Establecimientos_etapa_regular_2020_Admision_2021.csv"
local path_sae_2021_vacs = "$pathData/input/SAE/SAE_2021/A1_Oferta_Establecimientos_etapa_regular_2021_Admision_2022.csv"

import delimited "`path_sae_2021_vacs'", clear
forvalues year = 2019/2021 {
  import delimited "`path_sae_`year'_vacs'", clear
  //agregar vacantes por niveles
  collapse (sum) vacs_`year' = vacantes  cupos_`year' = cupos_totales (firstnm) cod_jor cod_grado cod_ense con_copago cod_espe , by(rbd cod_nivel)

  tempfile sae_`year'
  save `sae_`year'', replace
}

* - merge sae - *
use `sae_2019', clear
merge 1:1 rbd cod_nivel using `sae_2020', keep(3) nogen
merge 1:1 rbd cod_nivel using `sae_2021', keep(3) nogen

* - merge with matricula - *
merge 1:1 rbd cod_nivel using `mat_20052021', keep(3) nogen

* - quedarme solo el grado inicial de cada rbd - *
keep if cod_nivel == entry

tempfile mat_convacs
save `mat_convacs', replace

duplicates report rbd


* ---- Pegar data Value Added ---- *
use "$main/data/input/ModelData_SchoolsAll_2021_04_13.dta", clear
keep School_RBD va2_ave Year
rename School_RBD rbd
reshape wide va2_ave, i(rbd) j(Year)
rename va2_ave* va2_ave_*

duplicates report rbd
merge 1:1 rbd using `mat_convacs', keep(3) nogen

* --- dejar RM --- *
tab cod_reg_rbd
keep if cod_reg_rbd == 13

* --- dejar fijas vacantes 2019 para pre-2019
forvalues year=2005/2018 {
  gen vacs_`year' = vacs_2019
  gen cupos_`year' = cupos_2019
  *gen cupos2_`year' = cupos_2020 //cupos2
}

* --- reshape --- *
reshape long va2_ave_@ vacs_@ cupos_@ matricula_@ mat_total_@, i(rbd) j(year)
rename va2_ave_ va
rename *_ *

tempfile benefits
save `benefits', replace

* ======================================= *
* --------------- ADD SIMCE ------------- *
* ======================================= *
foreach year in 2006 2008 2010 2012 2014 2015 2016 2017 2018 {
  use  "$pathData/input/simce/students/simce4b`year'_alu_mrun.dta", clear
  gen mean_score = (ptje_lect4b_alu + ptje_mate4b_alu)/2
  collapse (mean) ptje_lect4b_alu ptje_mate4b_alu ave=mean_score, by(rbd)
  gen year = `year'
  tempfile simce4b_`year'
  save `simce4b_`year'', replace
}
use `simce4b_2006', clear
append using  `simce4b_2008'
append using  `simce4b_2010'
append using  `simce4b_2012'
append using  `simce4b_2014'
append using  `simce4b_2015'
append using  `simce4b_2016'
append using  `simce4b_2017'
append using  `simce4b_2018'
gen ave_st = (ave-50)/250

collapse (mean) ave ave_st, by(rbd)

merge 1:m rbd using `benefits'
keep if _merge==3
drop _merge

export delimited "$pathData/intermediate/for_benefit_estimation.csv", replace





 














