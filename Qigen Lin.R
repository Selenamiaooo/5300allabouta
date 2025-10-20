install.packages(c("gert", "credentials"))
library(gert)

library(credentials)

credentials::set_github_pat()

# this will prompt a popup that asks you to enter your GitHub Personal Access Token.

gert::git_pull() # pull most recent changes from GitHub

gert::git_add(dir(all.files = TRUE)) # select any and all new files created or edited to be 'staged'

# 'staged' files are to be saved anew on GitHub 

gert::git_commit_all("my first commit") # save your record of file edits - called a commit

gert::git_push() # push your commit to GitHub

library(gert)
library(credentials)

# 1️⃣ 重新输入你的 GitHub Token（如果已设置过，可跳过）
credentials::set_github_pat()

# 2️⃣ 拉取最新版本
gert::git_pull()

# 3️⃣ 正确添加文件到暂存区（不要用 dir(all.files = TRUE)）
gert::git_add(".")

# 4️⃣ 提交并推送
gert::git_commit("my first commit")
gert::git_push()