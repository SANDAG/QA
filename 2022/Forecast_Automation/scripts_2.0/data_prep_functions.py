def factorial(n):
    if n == 0:
        return 1
    else:
        return n * factorial(n-1)


print(factorial(3))


# -------------------------- Class: Configuration functions

# t_drive_file_paths

# Download and add to a large dataframe

# Rollup the dataframe - to the MGRA level

# Make adjustments to specific, specified columns that need it - should work at all levels

# mgra_vacancy_additions

# mgra_school_pop_additions

# mgra_age_pop_additions

# mgra_ethn_pop_additions

# mgra_sex_pop_additions

# Roll up to CPA - adjustments will be needed

# Roll up to Jurisdiction - adjustments will be needed

# Roll up to Region - adjustments will be needed

# Potentially doing LUZ and TAZ as well?

# -------------------- Class Manipulation Functions:

# Download the data function

# DF Comparison Function - checking shape and columns and such, returns similar columns

# Check to see if the desired output exists

# Both functions - will house both of the above functions

# Diff Functions --- will use the first two functions

# ---------------------- Class Other Outpus

# Household file path grab

# Number of persons (from households) at MGRA level.

# Combine with the mgra file (will need other files created) - create the diff and output to J drive

# Also do a household comparison check?

# ------------------------ Class QC Checks

# Check to see which aggregate files still need to be created (return a list), comparison with what we have in our config file

# Could also check which diff files also need to be created


# TODO: Update config file to have persons and household datasets


'''
ideas:
- Could have that SQL connection setup in a yml file, have a seperate yml file for more input related things 
- for functions that take in a dataframe (like the Qc ones, I could have a function that checks in the index has been grouped or not, or have it go in as an argument) - The argument will be asking if the index has been set or not


'''
