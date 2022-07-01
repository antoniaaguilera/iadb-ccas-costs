* ======================================= *
* 			BENEFITS STUDENTS
* ======================================= *

* ---- PREAMBULO ---- *

global main "/Users/antoniaaguilera/ConsiliumBots Dropbox/antoniaaguilera@consiliumbots.com/projects/iadb-ccas-costs"
global pathData "/Users/antoniaaguilera/ConsiliumBots Dropbox/antoniaaguilera@consiliumbots.com/random_data"
global figures "$main/figures"
global tables "$main/tables"
global git "/Users/antoniaaguilera/GitHub/iadb-ccas-costs"

* ---- Panel matrícula 2011-2021 ---- *

local path2005 = "$pathData/matricula/matricula-por-estudiante/basica-y-media/Matricula-por-estudiante-2005/20140805_matricula_unica_2005_20050430_PUBL.csv"
local path2006 = "$pathData/matricula/matricula-por-estudiante/basica-y-media/Matricula-por-estudiante-2006/20140805_matricula_unica_2006_20060430_PUBL.csv"
local path2007 = "$pathData/matricula/matricula-por-estudiante/basica-y-media/Matricula-por-estudiante-2007/20140805_matricula_unica_2007_20070430_PUBL.csv"
local path2008 = "$pathData/matricula/matricula-por-estudiante/basica-y-media/Matricula-por-estudiante-2008/20140805_matricula_unica_2008_20080430_PUBL.csv"
local path2009 = "$pathData/matricula/matricula-por-estudiante/basica-y-media/Matricula-por-estudiante-2009/20140805_matricula_unica_2009_20090430_PUBL.csv"
local path2010 = "$pathData/matricula/matricula-por-estudiante/basica-y-media/Matricula-por-estudiante-2010/20130904_matricula_unica_2010_20100430_PUBL.csv"
local path2011 = "$pathData/matricula/matricula-por-estudiante/basica-y-media/Matricula-por-estudiante-2011/20140812_matricula_unica_2011_20110430_PUBL.csv"
local path2012 = "$pathData/matricula/matricula-por-estudiante/basica-y-media/Matricula-por-estudiante-2012/20140812_matricula_unica_2012_20120430_PUBL.csv"
local path2013 = "$pathData/matricula/matricula-por-estudiante/basica-y-media/Matricula-por-estudiante-2013/20140808_matricula_unica_2013_20130430_PUBL.csv"
local path2014 = "$pathData/matricula/matricula-por-estudiante/basica-y-media/Matricula-por-estudiante-2014/20140924_matricula_unica_2014_20140430_PUBL.csv"
local path2015 = "$pathData/matricula/matricula-por-estudiante/basica-y-media/Matricula-por-estudiante-2015/20150923_matricula_unica_2015_20150430_PUBL.csv"
local path2016 = "$pathData/matricula/matricula-por-estudiante/basica-y-media/Matricula-por-estudiante-2016/20160926_matricula_unica_2016_20160430_PUBL.csv"
local path2017 = "$pathData/matricula/matricula-por-estudiante/basica-y-media/Matricula-por-estudiante-2017/20170921_matricula_unica_2017_20170430_PUBL.csv"
local path2018 = "$pathData/matricula/matricula-por-estudiante/basica-y-media/Matricula-por-estudiante-2018/20181005_Matrícula_unica_2018_20180430_PUBL.csv"
local path2019 = "$pathData/matricula/matricula-por-estudiante/basica-y-media/Matricula-por-estudiante-2019/20191028_Matrícula_unica_2019_20190430_PUBL.csv"
local path2020 = "$pathData/matricula/matricula-por-estudiante/basica-y-media/Matricula-por-estudiante-2020/20200921_Matrícula_unica_2020_20200430_WEB.csv"
local path2021 = "$pathData/matricula/matricula-por-estudiante/basica-y-media/Matricula-por-estudiante-2021/20210913_Matrícula_unica_2021_20210430_WEB.csv"


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
local path_sae_2019_vacs = "$pathData/SAE/SAE_2019/A1_Oferta_Establecimientos_etapa_regular_2019_Admision_2020.csv"
local path_sae_2020_vacs = "$pathData/SAE/SAE_2020/A1_Oferta_Establecimientos_etapa_regular_2020_Admision_2021.csv"
local path_sae_2021_vacs = "$pathData/SAE/SAE_2021/A1_Oferta_Establecimientos_etapa_regular_2021_Admision_2022.csv"

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
use "$main/data/ModelData_SchoolsAll_2021_04_13.dta", clear
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
save "$main/data/for_benefit_estimation.dta", replace

* -------------------------- *
* ------- estimación ------- *
* -------------------------- *
use "$main/data/for_benefit_estimation.dta", clear
sort rbd year

* --- promedio simple --- *
bys rbd: egen va_mean_simple = mean(va) //promedio simple del VA 2005-2016
*bys cod_com_rbd year: egen va_mean_com = mean(va) //promedio anual del VA de la comuna
* --- copiar va del 2016 hasta el 2021  --- *
forvalues x = 2017/2021 {
  replace va = va[_n-1] if year == `x'
}
keep if year>=2018
sort rbd year
*drop va
gen va_positivo = (va>0)

* --- comparar los cupos de un año con la matrícula del año siguiente --- *
bys rbd: gen cupos_prev = cupos[_n-1]
bys rbd: gen vacs_prev  = vacs[_n-1]

* --- check consistencia --- *
qui tab rbd if vacs>cupos_prev //hay 98 colegios donde pasa
return list
qui tab rbd if matricula>cupos_prev //hay 231 colegios donde pasa
return list
qui tab rbd if matricula>vacs_prev //hay 586 colegios donde pasa
return list

* --- para los casos donde la matrícula es más alta que los cupos/vacantes, voy a suponer que no hay vacantes desiertas --- *
keep if year == 2019 | year == 2020

gen empty_vacs     = 0   if matricula >= cupos_prev
replace empty_vacs = 1   if matricula <  cupos_prev
tab empty_vacs

gen n_empty_vacs = 0                             if empty_vacs == 0
replace n_empty_vacs = (cupos_prev - matricula)  if empty_vacs == 1
sum n_empty_vacs

gen delta_vacs = cupos_prev-matricula
sum delta_vacs

gen prop_empty = n_empty_vacs / cupos_prev
sum prop_empty


* --- estadistica descriptiva --- *

forvalues x = 2019/2020 {
  sum matricula if year == `x'
  local mat_`x'_tot = `r(sum)'
  local N_`x'_tot =  `r(N)'

  sum delta_vacs if year == `x'
  local delta_`x'_sum_tot  : di %4.0fc `r(sum)'
  local delta_`x'_mean_tot : di %4.0fc `r(mean)'

  sum empty_vacs if year == `x'
  local empty_`x'_sum_tot  : di %4.3fc `r(sum)'
  local empty_`x'_mean_tot : di %4.3fc `r(mean)'

  sum n_empty_vacs if year == `x'
  local n_empty_`x'_sum_tot  : di %4.0fc `r(sum)'
  local n_empty_`x'_mean_tot : di %4.0fc `r(mean)'

  sum prop_empty if year == `x'
  local prop_empty_`x'_mean_tot : di %4.3f `r(mean)'

  forval y = 0/1 {
    sum matricula if year == `x' & va_positivo == `y'
    local mat_`x'_`y' = `r(sum)'
    local N_`x'_`y'   = `r(N)'

    sum delta_vacs if year == `x' & va_positivo == `y'
    local delta_`x'_sum_`y'  : di %4.0fc `r(sum)'
    local delta_`x'_mean_`y' : di %4.0fc `r(mean)'

    sum empty_vacs if year == `x' & va_positivo == `y'
    local empty_`x'_sum_`y'  : di %4.3fc `r(sum)'
    local empty_`x'_mean_`y' : di %4.3fc `r(mean)'

    sum n_empty_vacs if year == `x' & va_positivo == `y'
    local n_empty_`x'_sum_`y'  : di %4.0fc `r(sum)'
    local n_empty_`x'_mean_`y' : di %4.0fc `r(mean)'

    sum prop_empty if year == `x' & va_positivo == `y'
    local prop_empty_`x'_mean_`y' : di %4.3f `r(mean)'

  }
}

sum va

file open tabla1 using "$tables/estaddesc_vacantes.tex", write replace
file write tabla1 "\begin{table}" _n
file write tabla1 "\centering"_n
file write tabla1 "\begin{tabular}{lcccccc} \toprule"_n
file write tabla1 "                                    & \multicolumn{3}{c}{PRE-SAE (2019)} & \multicolumn{3}{c}{POST-SAE (2020)} &     \\ \hline"_n
file write tabla1 "                                    &  VA Negativo             & VA Positivo              & Total                    &  VA Negativo             &  VA Positivo             & Total    \\"_n
file write tabla1 "Matrícula                           & `mat_2019_0'             & `mat_2019_1'             & `mat_2019_tot'             & `mat_2020_0'             & `mat_2020_1'             & `mat_2020_tot'             \\"_n
file write tabla1 "Vacantes vacías\footnote{dasdasd}   & `n_empty_2019_sum_0'     & `n_empty_2019_sum_1'     & `n_empty_2019_sum_tot'     & `n_empty_2020_sum_0'     & `n_empty_2020_sum_1'     & `n_empty_2020_sum_tot'     \\"_n
file write tabla1 "Cursos con vacantes vacías          & `empty_2019_sum_0'       & `empty_2019_sum_1'       & `empty_2019_sum_tot'       & `empty_2020_sum_0'       & `empty_2020_sum_1'       & `empty_2020_sum_tot'       \\"_n
file write tabla1 "\% Cursos con vacantes vacías       & `empty_2019_mean_0'      & `empty_2019_mean_1'      & `empty_2019_mean_tot'      & `empty_2020_mean_0'      & `empty_2020_mean_1'      & `empty_2020_mean_tot'      \\"_n
file write tabla1 "\Delta vacantes                     & `delta_2019_sum_0'       & `delta_2019_sum_1'       & `delta_2019_sum_tot'       & `delta_2020_sum_0'       & `delta_2019_sum_1'       & `delta_2020_sum_tot'       \\"_n
file write tabla1 "Vacantes vacías / matrícula         & `prop_empty_2019_mean_0' & `prop_empty_2019_mean_1' & `prop_empty_2019_mean_tot' & `prop_empty_2020_mean_0' & `prop_empty_2020_mean_1' & `prop_empty_2020_mean_tot' \\"_n
file write tabla1 "Observaciones                       & `N_2019_0'               & `N_2019_1'               & `N_2019_tot'               & `N_2020_0'               & `N_2020_1'               & `N_2020_tot'               \\ \bottomrule"_n
file write tabla1 "\end{tabular}"_n
file write tabla1 "\label{}"_n
file write tabla1 "\caption{}"_n
file write tabla1 "\end{table}"_n
file close tabla1


* ------ test de diferencia de medias ------- *

ttest prop_empty, by(va_positivo)
preserve
keep if year ==2019
ttest prop_empty, by(va_positivo)
restore

preserve
keep if year ==2020
ttest prop_empty, by(va_positivo)
restore

* --- pre sae y post sae --- *
tab year
ttest prop_empty, by(year)
return list
local p_total =`r(p)'


preserve
keep if va_positivo == 0
ttest prop_empty, by(year)
local p_va0 =`r(p)'
restore

preserve
keep if va_positivo == 1
ttest prop_empty, by(year)
local p_va1 = `r(p)'
restore

local dif_total = `prop_empty_2020_mean_tot' - `prop_empty_2019_mean_tot'
local dif_0 = `prop_empty_2020_mean_0' - `prop_empty_2019_mean_0'
local dif_1 = `prop_empty_2020_mean_1' - `prop_empty_2019_mean_1'

foreach x in total va1 va0 {
  if `p_`x'' <=0.01 {
    local `star_`x'' = "***"
  }
  else if `p_`x'' <=0.05 & `p_`x''>0.01 {
    local `star_`x'' = "**"
  }
  else if `p_`x'' <=0.1 & `p_`x''>0.05 {
    local `star_`x'' = "*"
  }
}

file open  tabla2 using "$tables/estaddesc_vacantes_dif.tex", write replace
file write tabla2 "\begin{table}" _n
file write tabla2 "\centering"_n
file write tabla2 "\begin{tabular}{lcccccc} \hline \hline"_n
file write tabla2 "                 && PRE-SAE (2019)             && POST-SAE (2020)             && \Delta     \\ \hline "_n
file write tabla2 "                 &&                            &&                             &&             \\ "_n
file write tabla2 "Muestra completa && `prop_empty_2019_mean_tot' && `prop_empty_2020_mean_tot'  &&  `dif_total'`star_tot'  \\    "_n
file write tabla2 "VA\leq0          && `prop_empty_2019_mean_0'   && `prop_empty_2020_mean_0'    &&   `dif_0'`star_va0'     \\"_n
file write tabla2 "VA>0             && `prop_empty_2019_mean_1'   && `prop_empty_2020_mean_1'    &&    `dif_1'`star_va1'   \\ \hline \hline"_n
file write tabla2 "\end{tabular}"_n
file write tabla2 "\label{fig:benefits_dif}"_n
file write tabla2 "\caption{Proporción de vacantes desiertas promedio por período, según el \textit{value added} de las escuelas.}"_n
file write tabla2 "\end{table}"_n
file close tabla2

sum prop_empty
preserve
drop if empty_vacs == 0
keep va_mean_simple prop_empty year
keep if year == 2019
export excel "$main/data/for_benefit_estimation_2019.xlsx", replace
restore

preserve
drop if empty_vacs ==0
keep va_mean_simple prop_empty year
keep if year == 2020
export excel "$main/data/for_benefit_estimation_2020.xlsx", replace
restore

* --- scatter (pasar a matlab)
drop if empty_vacs==0
tw (scatter va_mean_simple prop_empty if year == 2019, mcolor("75 22 199%20"))   ///
   (scatter va_mean_simple prop_empty if year == 2020, mcolor("61 187 171%20"))   , ///
   graphr(fc(white) lcolor(white) ilcolor(white)  lwidth(thick) )  ///
   bgcolor(white) plotr(style(none) fc(white) lcolor(white) lwidth(thick)) ///
    ytitle("Mean Value Added") title("", color(`color1'))    ///
   yline(0, lcolor(black%20) lpattern(dash))  legend(order(1 "Pre-SAE" 2 "Post-SAE")) ///
   xtitle("(vacantes vacías/matrícula)")
gr export "$figures/empty_va_byyear.png", as(png) replace

tw (scatter va_mean_simple prop_empty if year == 2019, mcolor("75 22 199%50"))   , ///
   graphr(fc(white) lcolor(white) ilcolor(white)  lwidth(thick) )  ///
   bgcolor(white) plotr(style(none) fc(white) lcolor(white) lwidth(thick)) ///
    ytitle("Mean Value Added") title("Pre-SAE", color(`color1'))    ///
   yline(0, lcolor(black%20) lpattern(dash))  ///
   xtitle("(vacantes vacías/matrícula)") saving(plot1, replace)

tw (scatter va_mean_simple prop_empty if year == 2020, mcolor("75 22 199%50"))   , ///
  graphr(fc(white) lcolor(white) ilcolor(white)  lwidth(thick) )  ///
  bgcolor(white) plotr(style(none) fc(white) lcolor(white) lwidth(thick)) ///
   ytitle("Mean Value Added") title("Post-SAE", color(`color1'))    ///
  yline(0, lcolor(black%20) lpattern(dash))  ///
  xtitle("(vacantes vacías/matrícula)") saving(plot2, replace)

graph combine plot1.gph plot2.gph, ycommon   cols(1) ///
graphr(fc(white) lcolor(white) ilcolor(white)  lwidth(thick) )
gr display, xsize(7) ysize (10)
gr export "$figures/empty_va_byyear_combine.png", as(png) replace

* --- predecir la probabilidad de tener una vacante vacía dado características --- *
gen sae = (year==2020)
* --- MPL --- *
reg empty_vacs sae
* --- Probit --- *
probit empty_vacs sae if va_positivo == 0
probit empty_vacs sae if va_positivo == 1
margins, atmeans post

* --- Logit --- *
logit empty_vacs sae if va_positivo == 0
logit empty_vacs sae if va_positivo == 1

margins, atmeans post
stop
