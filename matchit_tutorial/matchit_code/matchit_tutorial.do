
* If not yet installed, install "matchit" function as well as accompanying 
* "freqindex" function
// ssc install matchit
// ssc install freqindex

/*
Define directory
*/
global matchit_data "D:\Dropbox\miscellaneous\rf_resourcepage\matchit_tutorial\matchit_data"

/*
Import raw, messy data and save to Stata .dta file
*/
import excel "$matchit_data/matchit_rawdata.xlsx", clear firstrow

gen bridge_id = _n

* In the ensuing "matchit" command, lower/upper case characters register differently
rename state_id matchit_id

replace wrong_state = lower(wrong_state)

save "$matchit_data/matchit_rawdata.dta", replace


/*
Import clean data and save to Stata .dta file
*/
import excel "$matchit_data/matchit_cleandata.xlsx", clear firstrow

duplicates drop

replace correct_state = lower(correct_state)

save "$matchit_data/matchit_cleandata.dta", replace

/*
Employ "matchit" function; the resulting dataset will be used as a bridge to 
the cleaned names found in the "matchit_cleandata.dta" file.

"matchit" works by breaking each string into smaller 2 character substrings and
finding closest match in the other variable. Note that the 2 character substring 
parameter can be adjusted.

Finally, "matchit" also gives a "similscore" variable that allows the user to
gauge the accuracy of the match. Note that, regardless of the similscore value,
all entries should be checked manually to ensure that the matches were successful.
*/
matchit state_id correct_state using "$matchit_data/matchit_rawdata.dta", ///
	idusing(bridge_id) txtusing(wrong_state) sim(ngram, 2)

sort state_id

/*
Some raw data entries matched to more than 1 clean name; for these cases, we take
the raw data entry with the highest similscore.
*/
replace similscore = round(similscore, .0001)

egen max_simil = max(similscore) if similscore != ., by(bridge_id)
recast double max_simil
replace max_simil = round(max_simil, .0001)

keep if max_simil == similscore

/*
"kansas" and "arkansas", because one is nested in the other, register as matches;
the incorrect matches must be dropped.
*/
drop if state_id == 31 & bridge_id < 100

/* 
"dalawase", which should be "delaware", has been so poorly
misspelled that it is mistakenly attributed to "alaska."
*/
drop if state_id == 3 & bridge_id == 55

/* 
"miana", which should be "maine", has been so poorly
misspelled that it is mistakenly attributed to "indiana."
*/
drop if state_id == 27 & bridge_id == 119


/*
Unfortunately, we were unable to match all raw data entries to clean data entries.
The remainder must be manually changed. That said, we were still able to match
~89% of entries; "matchit" has significantly reduced the amount of work
necessary complete this string cleaning exercise!
*/
merge m:1 bridge_id wrong_state using "$matchit_data/matchit_rawdata.dta"

