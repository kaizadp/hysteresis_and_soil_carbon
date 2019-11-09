# 3-read_picarro_data.R


library(picarro.data)

message("Welcome to 3-read_picarro.data")

prd <- process_directory("data/picarro_data/")

write_csv(prd, "outputs/picarro_raw_data.csv")

message("All done.")
