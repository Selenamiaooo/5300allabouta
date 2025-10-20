install.packages(c("gert", "credentials"))
library(gert)
library(credentials)


credentials::set_github_pat()
gert::git_pull()
gert::git_add(".")
gert::git_commit("my first commit")
gert::git_push()
