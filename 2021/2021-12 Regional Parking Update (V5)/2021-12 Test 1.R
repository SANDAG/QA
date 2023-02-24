#Project ID: 2021-12
#Purpose: Compare updated mgra parking files (v= _05) to previous version (v= _04)
# to confirm that changes are only observed in the following variables:
# [MicroAccessTime], [mparkcost], [dparkcost], [hparkcost]
#Author: Kelsie Telson


##2016
park_05_2016<- read.csv("T://socioec//Current_Projects//XPEF33//abm_csv//new_parking//mgra13_based_input2016_05_np.csv")
park_04_2016<- read.csv("T://socioec//Current_Projects//XPEF33//abm_csv//new_parking//old//mgra13_based_input2016_04_np.csv")


identical(park_04_2016,park_05_2016) #true
all.equal(park_04_2016,park_05_2016) #true

rm("park_04_2016","park_05_2016")

##2018
park_05_2018<- read.csv("T://socioec//Current_Projects//XPEF33//abm_csv//new_parking//mgra13_based_input2018_05_np.csv")
park_04_2018<- read.csv("T://socioec//Current_Projects//XPEF33//abm_csv//new_parking//old//mgra13_based_input2018_04_np.csv")


identical(park_04_2018,park_05_2018) #true
all.equal(park_04_2018,park_05_2018) #true

rm("park_04_2018","park_05_2018")

##2020
park_05_2020<- read.csv("T://socioec//Current_Projects//XPEF33//abm_csv//new_parking//mgra13_based_input2020_05_np.csv")
park_04_2020<- read.csv("T://socioec//Current_Projects//XPEF33//abm_csv//new_parking//old//mgra13_based_input2020_04_np.csv")


identical(park_04_2020,park_05_2020) #true
all.equal(park_04_2020,park_05_2020) #true

rm("park_04_2020","park_05_2020")

##2023
park_05_2023<- read.csv("T://socioec//Current_Projects//XPEF33//abm_csv//new_parking//mgra13_based_input2023_05_np.csv")
park_04_2023<- read.csv("T://socioec//Current_Projects//XPEF33//abm_csv//new_parking//old//mgra13_based_input2023_04_np.csv")


identical(park_04_2023,park_05_2023) #false
all.equal(park_04_2023,park_05_2023) #false
#[1] "Component "MicroAccessTime": Mean relative difference: 0.9445077"

rm("park_04_2023","park_05_2023")

##2025
park_05_2025<- read.csv("T://socioec//Current_Projects//XPEF33//abm_csv//new_parking//mgra13_based_input2025_05_np.csv")
park_04_2025<- read.csv("T://socioec//Current_Projects//XPEF33//abm_csv//new_parking//old//mgra13_based_input2025_04_np.csv")


identical(park_04_2025,park_05_2025) #false
all.equal(park_04_2025,park_05_2025) #false
#[1] "Component "hparkcost": Mean relative difference: 0.1887858"      
#[2] "Component "dparkcost": Mean relative difference: 0.1887858"      
#[3] "Component "mparkcost": Mean relative difference: 0.9631266"      
#[4] "Component "MicroAccessTime": Mean relative difference: 0.9585961"

rm("park_04_2025","park_05_2025")

##2026
park_05_2026<- read.csv("T://socioec//Current_Projects//XPEF33//abm_csv//new_parking//mgra13_based_input2026_05_np.csv")
park_04_2026<- read.csv("T://socioec//Current_Projects//XPEF33//abm_csv//new_parking//old//mgra13_based_input2026_04_np.csv")


identical(park_04_2026,park_05_2026) #false
all.equal(park_04_2026,park_05_2026) #false
#[1] "Component "hparkcost": Mean relative difference: 0.1887858"      
#[2] "Component "dparkcost": Mean relative difference: 0.1887858"      
#[3] "Component "mparkcost": Mean relative difference: 0.9631266"      
#[4] "Component "MicroAccessTime": Mean relative difference: 0.9585961"

rm("park_04_2026","park_05_2026")

##2029
park_05_2029<- read.csv("T://socioec//Current_Projects//XPEF33//abm_csv//new_parking//mgra13_based_input2029_05_np.csv")
park_04_2029<- read.csv("T://socioec//Current_Projects//XPEF33//abm_csv//new_parking//old//mgra13_based_input2029_04_np.csv")


identical(park_04_2029,park_05_2029) #false
all.equal(park_04_2029,park_05_2029) #false
#[1] "Component "hparkcost": Mean relative difference: 0.1887858"      
#[2] "Component "dparkcost": Mean relative difference: 0.1887858"      
#[3] "Component "mparkcost": Mean relative difference: 0.9631266"      
#[4] "Component "MicroAccessTime": Mean relative difference: 0.9585961"

rm("park_04_2029","park_05_2029")

##2030
park_05_2030<- read.csv("T://socioec//Current_Projects//XPEF33//abm_csv//new_parking//mgra13_based_input2030_05_np.csv")
park_04_2030<- read.csv("T://socioec//Current_Projects//XPEF33//abm_csv//new_parking//old//mgra13_based_input2030_04_np.csv")


identical(park_04_2030,park_05_2030) #false
all.equal(park_04_2030,park_05_2030) #false
#[1] "Component "hparkcost": Mean relative difference: 0.1887858"      
#[2] "Component "dparkcost": Mean relative difference: 0.1887858"      
#[3] "Component "mparkcost": Mean relative difference: 0.9631266"      
#[4] "Component "MicroAccessTime": Mean relative difference: 0.9585961"

rm("park_04_2030","park_05_2030")

##2032
park_05_2032<- read.csv("T://socioec//Current_Projects//XPEF33//abm_csv//new_parking//mgra13_based_input2032_05_np.csv")
park_04_2032<- read.csv("T://socioec//Current_Projects//XPEF33//abm_csv//new_parking//old//mgra13_based_input2032_04_np.csv")


identical(park_04_2032,park_05_2032) #false
all.equal(park_04_2032,park_05_2032) #false
#[1] "Component "hparkcost": Mean relative difference: 0.1887858"      
#[2] "Component "dparkcost": Mean relative difference: 0.1887858"      
#[3] "Component "mparkcost": Mean relative difference: 0.9631266"      
#[4] "Component "MicroAccessTime": Mean relative difference: 0.9585961"

rm("park_04_2032","park_05_2032")

##2035
park_05_2035<- read.csv("T://socioec//Current_Projects//XPEF33//abm_csv//new_parking//mgra13_based_input2035_05_np.csv")
park_04_2035<- read.csv("T://socioec//Current_Projects//XPEF33//abm_csv//new_parking//old//mgra13_based_input2035_04_np.csv")


identical(park_04_2035,park_05_2035) #false
all.equal(park_04_2035,park_05_2035) #false
#[1] "Component "hparkcost": Mean relative difference: 0.1887858"      
#[2] "Component "dparkcost": Mean relative difference: 0.1887858"      
#[3] "Component "mparkcost": Mean relative difference: 0.9631266"      
#[4] "Component "MicroAccessTime": Mean relative difference: 0.9585961"

rm("park_04_2035","park_05_2035")

##2040
park_05_2040<- read.csv("T://socioec//Current_Projects//XPEF33//abm_csv//new_parking//mgra13_based_input2040_05_np.csv")
park_04_2040<- read.csv("T://socioec//Current_Projects//XPEF33//abm_csv//new_parking//old//mgra13_based_input2040_04_np.csv")


identical(park_04_2040,park_05_2040) #false
all.equal(park_04_2040,park_05_2040) #false
#[1] "Component "hparkcost": Mean relative difference: 0.1887858"      
#[2] "Component "dparkcost": Mean relative difference: 0.1887858"      
#[3] "Component "mparkcost": Mean relative difference: 0.9631266"      
#[4] "Component "MicroAccessTime": Mean relative difference: 0.9585961"

rm("park_04_2040","park_05_2040")

##2045
park_05_2045<- read.csv("T://socioec//Current_Projects//XPEF33//abm_csv//new_parking//mgra13_based_input2045_05_np.csv")
park_04_2045<- read.csv("T://socioec//Current_Projects//XPEF33//abm_csv//new_parking//old//mgra13_based_input2045_04_np.csv")


identical(park_04_2045,park_05_2045) #false
all.equal(park_04_2045,park_05_2045) #false
#[1] "Component "hparkcost": Mean relative difference: 0.1887858"      
#[2] "Component "dparkcost": Mean relative difference: 0.1887858"      
#[3] "Component "mparkcost": Mean relative difference: 0.9631266"      
#[4] "Component "MicroAccessTime": Mean relative difference: 0.9585961"

rm("park_04_2045","park_05_2045")

##2050
park_05_2050<- read.csv("T://socioec//Current_Projects//XPEF33//abm_csv//new_parking//mgra13_based_input2050_05_np.csv")
park_04_2050<- read.csv("T://socioec//Current_Projects//XPEF33//abm_csv//new_parking//old//mgra13_based_input2050_04_np.csv")


identical(park_04_2050,park_05_2050) #false
all.equal(park_04_2050,park_05_2050) #false
#[1] "Component "hparkcost": Mean relative difference: 0.1887858"      
#[2] "Component "dparkcost": Mean relative difference: 0.1887858"      
#[3] "Component "mparkcost": Mean relative difference: 0.9631266"      
#[4] "Component "MicroAccessTime": Mean relative difference: 0.9585961"

rm("park_04_2050","park_05_2050")
