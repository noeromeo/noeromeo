
// PART 1 - TIME SERIES //

use "C:\Users\noero\Documents\HSG\Semester 6\Applications of Econometrics\STATA\Data\part1_timeseries.dta", clear

tsset year, yearly //declare it a time-series data set. The time variable is 'year'.

// i) 
graph set window fontface "Times New Roman"

twoway (tsline children) (tsline unemployed, yaxis(2)), title("FIGURE T1", size(medium)) subtitle("FERTILITY RATE PROXY AND UNEMPLOYMENT OVER TIME") xtitle("SURVEY YEAR") ytitle("AVG. NUMBER OF CHILDREN BELOW FIVE PER WOMAN   ") ytitle("UNEMPLOYMENT RATE            ", axis(2)) legend(lab(1 "children") lab(2 "unemployed")) graphregion(color(white)) // plot the variables children and unemployed over time on the same line graph with 2 y-axes.

reg children unemployed //Regression 1
	outreg2 using "reg1.doc", replace dec(3) label ctitle ("Regression 1")
	
** The coefficient reported for 'unemployed' is 0.0.372. This means that an increase in the mean unemployment rate for a given year is expected to increase the mean number of children per household for women ageed 15-45 by 0.372.

** However, this coefficient is not statistically significant, as the values given for the 95% confidence interval span across 0. Further, the t-statistic (1.72) is very small and the p-value = 0.095 means we fail to reject the null hypothesis at the 5% signficance level.

** Given the estimated coefficient of our simple regression model, unemployment appears to have a positive effect on the number of children. However, looking at the plot, we can suspect a potential negative time trend on the number of young children per household (the fertility rate proxy), which is likely to play into the estimations.

**Alternate simple regressions, testing Lags
reg children unemployed L. unemployed 

reg children unemployed L. unemployed L2. unemployed

*Natural Logs
gen log_children = ln(children) 
gen log_unemployed = ln(unemployed)

reg log_children log_unemployed L. unemployed

reg log_children L. log_unemployed 

*

// ii)
reg children unemployed share_married //Regression 2 
outreg2 using "reg2.doc", replace dec(3) label ctitle ("Regression T2")
** Given the new estimated coefficients, the positive effect of unemployment the proxy for fertility rates is sustained, with the new coefficient of 0.389 being very close to the previous estimation. The share of people currently married also has a positive effect on the number children, specifically, increasing the share of married people by 1 is expected to increase the mean number of children by 0.74.

** The most notable difference between this regression and the model in part i) is that we can confidentally reject null hypotheses for each of the estimated coefficients. In particular, the p-values = 0.00 for each of the coefficients, the estimated ranges for the 95% confidence interval are slim and do not span across 0, and the t-statisticas are higher than before.

** This difference might be because we were facing omitted variable bias in the regression in part i), because the estimation did not include share_married, which clearly has a significant effect on the number of children, as demonstrated by the regression in part ii). Hence, this is likely to explain the change in signficance measures.

*There might however be issues with time trends in both share_married and children
twoway (tsline children) (tsline share_married, yaxis(2)), title("FIGURE T2", size(medium)) subtitle("FERTILITY RATE PROXY AND SHARE MARRIED OVER TIME") xtitle("SURVEY YEAR") ytitle("AVG. NUMBER OF CHILDREN BELOW FIVE PER WOMAN   ") ytitle("SHARE OF ADULT POPULATION MARRIED            ", axis(2)) legend(lab(1 "children") lab(2 "share married")) graphregion(color(white)) 




// iii)

** generating polynomial time trend variables:
gen t = _n // linear time trend
gen t2 = t*t //quadratic time trend


reg share_married t
outreg2 using "reg3timemarried.doc", replace dec(3) label ctitle ("T3.1: share_married")
reg share_married t2
** this shows that there is a negative time trend in the variable share_married, meaning that time negatively affects the share of married people.

reg children t
outreg2 using "reg3timemarried.doc", append dec(3) label ctitle ("T3.1: children")
reg children t2
** similarly, there is a negative time trend on the fertility rate.

** However, it is ambiguous whether there is a common underlying factor that negatively affects both fertility rates and the share of married people. Alternatively, this factor could be only affecting marriage shares, which in turn decreases fertility rates. The inverse "might" also be true.

reg unemployed t //Regression 3 
outreg2 using "reg3timemarried.doc", append dec(3) label ctitle ("T3.1: unemployed")
** This regression estimates a negative, but very small negative effect of time on unemployment rates (coefficient = -0.0000826) which is not statistically significant, given the p-value=0.780, t-statistic = -0.28 and the estimated 95% confidence interval spanning across 0.


reg children unemployed share_married t
outreg2 using "reg3.doc", replace dec(3) label ctitle ("Regression T3") 
** positive, but not stat. sig. time trend
** both share_married and unemployed are stat. sig. at 5%, with positive coeffs.

reg t unemployed share_married //auxiliary regression
outreg2 using "reg3aux.doc", replace dec(3) label ctitle ("Auxilliary Regression T3.2") 

*detrending non-stationary variables
reg share_married t
	predict detr_share_married, resid
	
reg children t 
	predict detr_children, resid
	
*Detrended formulation: 
reg detr_children L. unemployed detr_share_married L. detr_children

*Alternative time trend
reg children unemployed share_married t2
** negative quad. time trend, stat. sig. (inverse U-shaped time trend)
** positive effect of unemployment (stat. sig.)
** share_married no longer stat. sign.


// iv) 
*introducing lags
reg children L. unemployed share_married  L. children t
reg detr_children L. unemployed detr_share_married L. detr_children //same
outreg2 using "reg4.doc", replace dec(3) label ctitle ("Regression T4")

** this is good

** Overall, solid regression.
// testing for unit roots in our regressions

// for the regression from part iii)
reg children unemployed share_married t
	predict resids_iii, resid

reg resids_iii L.resids_iii
** the first-order autocorrelation coefficient = 0.607, which is fairly low and indicates no unit root. The p-value for this estimation of the p-value=0.

//for the regression from part iv) 
reg detr_children L. unemployed detr_share_married L. detr_children 
	predict resids_iv, resid

reg resids_iv L.resids_iv, noconstant
outreg2 using "reg4residuals.doc", replace dec(3) label ctitle ("Regression T4.1: Residuals AR(1)")
** similar to before, the first-order autocorrelation coefficient = -0.184 , which suggests no unit root.

dfuller resids_iv, lag(1) 
*We can reject the null hypothesis of unit root 

*unit root in nonstationary variables
reg children L.children

reg share_married L.share_married
*Variables Exhibits strong unit root!


**Now testing for stationary dynamics
reg detr_children L. unemployed detr_share_married L. detr_children 
	estat dwatson 
	
*Decreasing AC over time
corrgram resids_iv


*Now to quasi-demean variable, to remove serial correlation
reg detr_children detr_share_married L. unemployed L. detr_children 
	predict errors4, resid

*get rho 
reg errors4 L.errors4 
	local rhohat=_b[L.errors4] // store the auto-correlation parameter in a macro
	di `rhohat'
	
*quasi demeaning all regressors	
foreach var in detr_children detr_share_married unemployed {
	gen `var'_tilde = `var' - `rhohat'*L.`var'
} 

* Modified constant
gen cons_tilde = 1 - 0.60142426  

*Run quasi-demeaned regression
reg detr_children_tilde L. unemployed_tilde detr_share_married_tilde L. detr_children_tilde cons_tilde , nocons 
	predict errorsfinal, resid
	
reg errorsfinal L.errorsfinal

*HAC errors 

newey detr_children L. unemployed detr_share_married L. detr_children, lag(1)
outreg2 using "reg4HAC.doc", replace dec(3) label ctitle ("Regression T4: HAC errors")



*Cointegration test, all rejected
egranger detr_children unemployed , lag(1) regress
egranger children unemployed , lag(1) regress


*Final table
reg children unemployed //Reg 1 
outreg2 using "finalreg.doc", replace dec(3) label ctitle ("Regression 1")
reg children unemployed share_married //Reg 2 
outreg2 using "finalreg.doc", append dec(3) label ctitle ("Regression 2")
reg detr_children unemployed detr_share_married  //Reg 3 
outreg2 using "finalreg.doc", append dec(3) label ctitle ("Regression 3")
reg detr_children  detr_share_married L. unemployed L.detr_children //best regression, also works with t as variable. Reg 4
outreg2 using "finalreg.doc", append dec(3) label ctitle ("Regression 4")

*Variations on Regression 4 
reg detr_children  L. unemployed detr_share_married  L.detr_children //best regression, also works with t as variable. Reg 4
outreg2 using "Variations.doc", replace dec(3) label ctitle ("Regression T4")
reg detr_children_tilde L. unemployed_tilde detr_share_married_tilde L. detr_children_tilde cons_tilde , nocons // Reg 4 quasi-demeaned
outreg2 using "Variations.doc", append dec(3) label ctitle ("T4: Quasi-demeaned")
newey detr_children L. unemployed detr_share_married L. detr_children, lag(1) //Reg 4 HAC error
outreg2 using "Variations.doc", append dec(3) label ctitle ("T4: HAC Errors")




// SECTION 2 - PANEL DATA //

// For this section, we downloaded the data from the IPUMS website to add the additional control variable 'share_hispanics'
// We prepared the data as follows:

g children = nchlt5 if sex==2 & age >=15 & age<=45
g share_married = marst==1 | marst==2 if age>=18 & marst<=7
g share_women = sex==2
g share_hispanic = hispan>0 if hispan<=612 //values > 612 were "Do not know" or "N/A (and no response 1985-87)"
g pop = 1

collapse (sum) pop (median) hhincome (mean) children share_* [aw=asecwt], by(statefip year) fast

g lnincome = log(hhincome)
label var lnincome "Log of median household income"
g lnpop = log(pop)
label var lnpop "Log of State Population"

label var children "Mean number of children (aged < 5) per household"
label var lnincome "Log of median household income"
label var share_married "Share of people married (aged > 18)"
label var share_women "Share of Women"
label var share_hispanic "Share of Hispanics"

// Declare the data set as a panel data
xtset statefip year
 ** strongly balanced panel data set, using statefip as the entity variable and year as the time variable
 
 ** QUESTION 5 **

// Scatter Plot children against lnincome 
 
graph set window fontface "Times New Roman"

twoway (scatter children lnincome) (lfit children lnincome, lcolor(red)) if year==2022, xtitle("NATURAL LOG OF MEDIAN HOUSEHOLD INCOME", size(small)) ytitle("AVERAGE NUMBER OF CHILDREN BELOW 5 PER HOUSEHOLD", size(small)) title("FIGURE P.1", color(black)) subtitle("FERTILITY RATES AND INCOME BY USE-STATE IN 2022") legend(lab(1 "State") lab(2 "Fitted values regression line")) graphregion(color(white))

graph export FigureP1, as(jpg) replace

reg children lnincome if year == 2022

// Also plot the relationship between 'share_hispanic' and 'children' in 2022

twoway (scatter children share_hispanic) (lfit children share_hispanic) if year==2022, ytitle("Mean number of children (age<5)", size(small)) xtitle("Share of Hispanics", size(small)) title("Figure P.2", color(black)) subtitle("Number of young children per household and share of Hispanics by US-State in 2022", color(black) size(medsmall)) graphregion(color(white))

graph export FigureP2, as(jpg) replace

// Descriptive Statistics

ssc install asdoc // to export nice descriptives tables to .doc
asdoc tabstat children lnincome share_married share_women lnpop share_hispanic, stat(mean min max) long format label replace

// To see how the mean of 'children' and 'lnincome' change over time:

preserve //so we don't need to re-run the code to reload the data

collapse (mean) children lnincome, by(year)
twoway (line children year) (line lnincome year, yaxis(2)), ytitle("Mean number of children (age<5)", size(small)) ytitle("Mean Natural Log of Median Household Income", size(small) axis(2)) xtitle("Survey Year") title("Figure P.3", color(black)) subtitle(" Mean Number of Children and Mean Income over time", color(black)) graphregion(color(white)) legend(lab(1 "Children(age<5)") lab(2 "Log Income"))

graph export FigureP3, as (jpg) replace

restore

** QUESTION 6 **

// Regression using POLS
reg children lnincome i.year
outreg2 using "Part6.doc", replace dec(3) label ctitle("Pooled OLS on 'number of young children'") drop(i.year) //do not report coefficients for each year

// We added share_hispanic because the following graph shows a negative trend between 'children' and 'share_hispanic':


// Now adding more control variables to the regression, run using POLS
reg children lnincome share_married share_women share_hispanic lnpop i.year 
outreg2 using "Part6new.doc", append dec(3) label ctitle("+ Control Variables") drop(i.year) // do not report coefficients for each year

** QUESTION 7 **

// Fixed Effects Estimator
xtreg children lnincome share_married share_women share_hispanic lnpop i.year, fe
	predict resid_fe, residuals
outreg2 using "Part7.doc", replace dec(3) label ctitle ("Fixed Effects") drop(i.year)

// First Differences Estimator
reg D.(children lnincome share_married share_women share_hispanic lnpop) i.year
	predict resid_fd, residuals
outreg2 using "Part7.doc", append dec(3) label ctitle ("First Differences") drop(i.year)

// Test for serial correlation in the error terms
reg resid_fe L.resid_fe
outreg2 using "Part7errors.doc", replace dec(3) label ctitle ("Fixed Effects - Errors")
reg resid_fd L.resid_fd
outreg2 using "Part7errors.doc", append dec(3) label ctitle ("First Differences - Errors")

// Use clustered standard errors
xtreg children lnincome share_married share_women share_hispanic lnpop i.year, fe vce(cluster statefip)
outreg2 using "Part7.doc", append dec(3) label ctitle("FE with clustered standard errors") drop(i.year)

reg D.(children lnincome share_married share_women share_hispanic lnpop) i.year, vce(cluster statefip)
outreg2 using "Part7.doc", append dec(3) label ctitle("FD with clustered standard errors") drop(i.year)





























