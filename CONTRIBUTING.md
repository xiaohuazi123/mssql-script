# 为项目`mssql-script`提交`pull request`

首先请核对下本地git config配置的用户名和邮箱与你github上的注册用户和邮箱一致，否则即使`pull request`被接受，贡献者列表中也看不到自己的名字，设置命令：

``` bash
$ git config --global user.email "you@example.com"
$ git config --global user.name "Your Name"
```

- 1.登录github，在本项目页面点击`fork`到自己仓库
- 2.clone 自己的仓库到本地：`git clone https://github.com/xxx/mssql-script.git`
- 3.在 master 分支添加原始仓库为上游分支：`git remote add upstream  https://github.com/xiaohuazi123/mssql-script.git`
- 4.在本地新建开发分支：`git checkout -b dev`
- 5.在开发分支修改代码并提交，如果修复了issue问题，请在提交消息里写上issue编号：`git add .`, `git commit -am 'xx变更说明'` 或 `git commit -am '修复 #issue编号'` 
- 6.切换至 master 分支，同步原始仓库：`git checkout master`， `git pull upstream master`
- 7.切换至 dev 分支，合并本地 master 分支（已经和原始仓库同步），可能需要解冲突：`git checkout dev`, `git rebase master`
- 8.提交本地 dev 分支到自己的远程 fork 仓库：`git push origin dev`
- 9.在github自己的fork仓库页面，点击`Compare & pull request`给原始仓库发 pull request 请求
- 10.等待原作者回复（接受/拒绝）
