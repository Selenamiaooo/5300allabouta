install.packages("gert")
install.packages("credentials")

library(gert)
library(credentials)
credentials::set_github_pat()

gert::git_add("cimmit.R")
gert::git_commit_all
file.exists("code.R") 
gert::git_commit_all("my first commit") # save your record of file edits - called a commit

gert::git_push() # push your commit to GitHub
