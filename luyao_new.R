install.packages(c("gert", "credentials"))
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