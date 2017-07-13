*! Read most recent REDCap export from specified directory

// Reads most recent data file using most recent do-file (not necessarily from
// same export)

program redcap
    version 14.0
    
    syntax [using/], [CSVdir(string asis) Header Renvars(string asis) TRim]
    _parse expand pairs options: renvars
    
    if mi(`"`using'"') loc using .
    if mi(`"`csvdir'"') loc csvdir `"`using'"'
    
    loc REGEXP "_([0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]_[0-9][0-9][0-9][0-9])\.csv$"
    
    loc flist: dir `"`csvdir'"' files "*.csv"
    loc csvfile: word `:list sizeof flist' of `:list sort flist'
    if regexm(`"`csvfile'"',`"`REGEXP'"') loc edate = regexs(1)
    loc edate: di %tcCCYY-NN-DD_HH:MM clock(`"`edate'"',"YMDhm")
    
    loc flist: dir `"`using'"' files "*.do", respectcase
    loc dofile: word `:list sizeof flist' of `:list sort flist'
    
    // Exports through the web in "Stata" format exclude header; exports via
    // API include it
    if !mi("`header'") {
        import delim using `"`csvdir'/`csvfile'"', delim(",") clear ///
            bindquotes(strict)
        
        // Long varnames are shortened with "Stata" format exports, but not
        // when exporting via API; unfortunately, REDCap does not use Stata's
        // scheme for shortening
        forv i = 1/`pairs_n' {
            ren `pairs_`i''
        }
        
        tempfile api_dat
        save `"`api_dat'"'
        
        loc oldpattern "insheet"
        // Substitution needed to handle path names on Windows
        loc newpattern = subinstr(`"use `"`api_dat'"'"',"\","\BS",.) + "\n\n// insheet"
    }
    else {
        loc oldpattern = subinstr(`"`dofile'"',"_STATA_","_DATA_NOHDRS_",1)
        loc oldpattern = subinstr(`"`oldpattern'"',".do",".csv",1)
        loc newpattern `"`csvdir'/`csvfile'"'
    }
    
    tempfile dofile2
    filefilter `"`using'/`dofile'"' `"`dofile2'"', from(`"`oldpattern'"') ///
        to(`"`newpattern'"')
    //Hack to be removed
	tempfile dofile3
	filefilter `"`dofile2'"' `"`dofile3'"', from(`"label values scr_seedsprout scr_seedsprout_"') ///
        to(`""')
	
    run `"`dofile3'"'
    
    // Trim all string vars
    if !mi("`trim'") {
        qui ds, has(type string)
        foreach var of varlist `r(varlist)' {
            qui replace `var' = trim(`var')
        }
    }
    
    loc project_name = substr(`"`csvfile'"',1,strpos(`"`csvfile'"',"_DATA_")-1)
    lab dat `""`project_name'", exported on `edate'"'

end
