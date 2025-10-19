install.packages("gert")
install.packages("credentials")

library(gert)
library(credentials)
credentials::set_github_pat()

gert::git_add("cimmit.R")
gert::git_commit_all
file.exists("code.R") 
