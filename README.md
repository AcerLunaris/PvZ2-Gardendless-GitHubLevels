# PvZ2-Gardendless-GitHubLevels

[English](#english) | [中文](#中文)

---

## English

Levels in this repository are fetched by the **GitHub Level Window** in *PvZ2: Gardendless*.

### Repository Structure

**The root directory should only contain folders named after level authors.**

Each author must place their levels (files or subfolders) **inside a folder named after themselves**. Do **not** put level files directly in the root directory.
```
.
├── AuthorA/
│ ├── level1.json
│ └── level2.json
├── AuthorB/
│ ├── level1.json
│ └── SubFolder/
│ └── level3.json
└── ...
```
### Uploading Levels

You can upload your levels via **Pull Request**.

### Making Changes Visible to Players

If you want players to notice changes to a level, **add a different suffix to the level's filename** than before.

For example, if a level was previously named `level0.json`, rename it to something like `level0_v2.json` when you update it. This ensures the game recognizes it as a new version and players can see the change.

---

## How to Contribute

1. Fork this repository.
2. Add, modify or remove level JSON files.
3. Pull Request / Submit a Pull Request.
4. <font color="red">Think twice before changing the name of your folders, or the game will forget all the levels in the folder!!</font>

---

## Level Format

Levels are JSON files. Refer to existing examples for the format.

---

### When Updates Happen

Level updates are synced automatically **every 30 minuites**. To see the latest levels, please **restart the game** after those times and open the **GitHub Level Window**. If the window was already opened before the sync, restarting the game is required to refresh the data.

---

## 中文

本仓库中的关卡会被 *PvZ2: Gardendless* 中的 **GitHub 关卡窗口** 获取。

### 仓库结构

**根目录只应包含以关卡作者名字命名的文件夹。**

每位作者必须把关卡（文件或子文件夹）**放进以自己名字命名的文件夹里**。**不要**把关卡文件直接放在根目录。
```
.
├── 作者A/
│ ├── level1.json
│ └── level2.json
├── 作者B/
│ ├── level1.json
│ └── 子文件夹/
│ └── level3.json
└── ...
```
### 上传关卡

你可以通过 **Pull Request** 上传关卡。

### 让玩家看到关卡变化

如果你希望玩家发现关卡的改变，可以**给关卡文件名加上与以往不同的后缀**。

例如，如果某个关卡原本叫 `level0.json`，更新时把它改成 `level0_v2.json`。这样游戏会把它识别为新版本，玩家就能看到变化。

---

## 如何提交

1. Fork 本仓库；
2. 添加/修改/删除关卡 JSON 文件；
3. 提交 Pull Request；
4. <font color="red">在更改文件夹名字前请郑重考虑，否则游戏将会遗忘文件夹内所有的关卡。</font>

---

## 关卡格式

关卡为 JSON 文件，具体格式参考现有示例。

---

### 更新时机

关卡的更新是定时的，**每半小时**会自动同步一次。因此，请在这些时间点**之后**重启游戏，并打开 **GitHub 关卡窗口**，才能看到最新的关卡内容。如果在同步之前已经打开了窗口，需要重启游戏才能刷新数据。