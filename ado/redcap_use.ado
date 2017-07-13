*! Track use of REDCap fields

program redcap_use
    version 14.1
    
    loc FILENAME redcap_vars.txt
    
    syntax [namelist] using/, [EVar(name) events(string) NOTused clear]
    // TODO Is there a better way to address this issue?
    if !mi(`"`events'"') & !strpos(`"`events'"',`"""') {
        loc events = `"`"`events'"'"'
    }
    
    use `namelist' using `using', `clear'
    
    // List vars not yet used
    if !mi("`notused'") {
        preserve
            qui import delim using tmp/`FILENAME', delim("\t") clear
            qui keep if v1=="`using'"
            qui levelsof v2, local(vars_used) clean
        restore
        ds `vars_used', not det
        drop `vars_used'
        exit
    }
    
    tempname redcap_vars
    cap mkdir tmp
    file open `redcap_vars' using tmp/`FILENAME', write text append
    foreach var of varlist _all {
        file write `redcap_vars' `"`using'"' _tab "`var'" _n
    }
    file close `redcap_vars'
    
    if !mi(`"`events'"') {
        if mi(`"`evar'"') loc evar redcap_event
        loc vl: value label `evar'
        tempvar keepme
        gen byte `keepme' = 0
        foreach event of loc events {
            noi di `"`event'"'
            replace `keepme' = 1 if `evar'==`"`event'"':`vl'
        }
        keep if `keepme'
        drop `keepme'
    }
    
end
