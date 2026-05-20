---
date: 2026-05-20
status: draft
distilled_to:
---

# Subagent Surface Hints(子 agent 主动提议)

对 meta-skill 的窄幅调优:**保留主 agent inline 作为兜底默认**;在执行流中遇到"主对话看全过程是多余"的具体 sub-step 时,**用反问句**向用户提议把这一步派给 subagent。用户决定 Y / N;沉默 = 继续 inline。

**不是 mode shift。不是默认翻转。subagent 接管的是 sub-step,不是整体任务。**

## 目标

在两条约束下,提升 subagent dispatch 在"机械执行 + 耗时 + 只要结果"场景下的命中率:

1. **简单任务不能搞砸** — ≤ ~5s 开销可接受;30s 任务变成 50s 仪式不可接受
2. **过度拆分比主对话被淹更糟** — 主 agent inline 是兜底,subagent 是 opt-in 调优,不是 opt-out 默认
3. **subagent 只接管 sub-step 不接管主线** — 主对话仍然在做主线决策(理解需求 / 设计方案 / 决定改哪儿 / review 结果 / 跟用户对话);subagent 只做主对话"看了也没用"的耗时执行(跑测试 / 跑构建 / 批量编辑 / 大范围扫描)

前几轮讨论的死胡同(已抛弃):
- mode shift 翻转默认 → 太重,过度拆解
- 触发条件用"任务整体大小"(测试 ≥ 3 cycle / refactor ≥ 5 callsite / 大文件)→ 错误的判定对象;任务大不等于"主对话看了没用"
- "Yes 之后整体接管"→ 错的形态;用户要的是 sub-step 级别派,不是把任务整体丢出去

老 plan `docs/plans/2026-05-20-reflection-first-execution/` 已删,完整推导见此 commit 之前的 git log。

## 设计

### 核心机制:Auxiliary Task Delegation(辅助任务委派)

主 agent 在工作流中决定要做下一步动作时,**问自己一个反问**:

> **"主 agent 看这一步的全过程,是不是多余?"**
> (主对话只看最终结果就够,不需要看过程的每一行)

- 答 **"是,多余"** → 这是 auxiliary sub-step → 用反问句 surface 给用户提议派 subagent
- 答 **"不,有用"** → 主对话本职(讨论代码 / 跟用户来回 / 设计决策),inline 自己做

每次触发是**单个 sub-step**。subagent 完成后立刻把结果回报,主对话拿结果继续下一步。**不是整体任务接管**。

### 为什么用反问句

| 提问方向 | LLM 默认偏向 |
|---|---|
| 正问 "这步该派 subagent 吗?" | 偏 "不派 / 我自己来"(三个截图证明) |
| 反问 "主 agent 看这步全过程是多余的吗?" | 偏 "是,多余 → 派"(因为辩护"不多余"要列出"主对话必须看全过程"的理由,而这些理由通常很弱) |

反问句把"派"的辩护负担从"为什么要派"反转为"为什么不派"。这是个 framing 调整,不是机械 gate,但**直接对应 agent 的实际偏差**。

### 信号入场资格(新信号必过两关)

每个上线信号必须**同时**满足:

1. **反问句通过**:"主 agent 看这一步的全过程是多余的吗?" 答 **是**
2. **场景具体**:机械执行 + 耗时 + 只要结果

只满足第 1 条(反问通过但场景泛)→ 不上,会让 agent "什么都多余"。
只满足第 2 条(场景具体但反问不通)→ 不上,跟"主对话本职"重叠。

这个资格本身是个**过滤器**:之前 plan 写过的"任务整体大小"信号(测试 ≥ 3 cycle / refactor ≥ 5 callsite)都**通不过反问** — "主 agent 看 5 个 callsite 是多余的吗?" 答 "**不一定** — 看了才能决定怎么改",反问失败 → 不是 auxiliary,**不该上**。

### 信号清单 V3.1(5 条,全部反问形式)

1. **"主 agent 看测试跑的全过程是多余的吗?"** — 跑测试(≥ 30s 任何 mvn test / pytest / jest / go test)→ verify subagent
2. **"主 agent 看构建 / 依赖解析全过程是多余的吗?"** — 跑构建(mvn install / gradle build / npm install / npm build)→ build subagent;chaos 项目规则约定 IntelliJ 跑 Maven,该信号在 chaos 触发频次会低,这是规则约束不是信号失败
3. **"主 agent 读完所有 grep / find usage 命中是多余的吗?"** — 大范围搜索(≥ 10 文件命中)→ explore subagent
4. **"主 agent 逐个文件改这堆同型编辑是多余的吗?"** — 批量同型编辑(≥ 5 文件,同型 import 增删 / 同型 rename / 同型加 annotation)→ refactor subagent(可对接 `refactor-fanout.md`)
5. **"主 agent 翻完这段代码找 pattern 是多余的吗?"** — 扫描一片代码(单文件 ≥ 1000 行 或 多文件累计 ≥ 1500 行,找 N 处 callsite / pattern)→ scan subagent

**这 5 个反问在典型场景下答都是"是,多余"**,这是它们入场的资格。

砍掉 / 合并的候选信号(记录原因):

- ~~git 历史 / blame 分析~~ — chaos / chaos_web 实际场景无强证据;为想象场景预备,Phase 5 真出现再加
- ~~大文件 ≥ 1000 行单独成条~~ — 跟大范围 grep 重叠("扫一片代码找东西"本质相同),合并成信号 5

### Surface 给用户的提议

机制要素:**用反问形式 + 具体场景描述**(反问形式是设计核心,不是语气偏好 — 它把"派"的辩护负担从"为什么要派"反转为"为什么不派")。

具体措辞跟 SKILL.md 别处 agent 跟用户对话风格一致即可,Plan 不规范字句模板。

### 决策流程

```text
主 agent inline 跑工作流
   │
   ├── 即将做下一步:问自己 "看全过程多余吗?"
   │       │
   │       ├── 不,主对话本职(讨论 / 决策 / 来回) → inline 做
   │       │
   │       └── 是,多余(机械 + 耗时 + 只看结果)
   │              │
   │              ↓
   │           反问 surface 给用户:"<具体场景>,我看全过程没必要吧?派 subagent?"
   │              │
   │              ├── Yes → 派 subagent 做这一 sub-step → subagent 回报结果
   │              │            → 主对话拿结果继续下一步(回到 inline 默认)
   │              │
   │              └── No / 沉默 → 主对话自己做这一步,继续 inline
   │
   └── 任务完成
```

**关键属性**:
- 信号触发是 **agent 识别**,不是机械测量
- Yes 后的 subagent 接手 **这一个 sub-step**,不是剩余整体
- subagent 完成立刻回主对话,**主对话继续 inline** 做下一步
- 同一任务可能触发多次 surface(跑测试一次、大 grep 一次、批量改一次),**每次独立**;前一次的 Y/N 不影响后一次

### 信号 *不是* 什么

- **不是**任务整体大小信号(测试 ≥ 3 cycle / refactor ≥ 5 callsite / 大文件 / 跨 repo — 全部废弃,反问通不过)
- **不是**文件数 / 时间维度(太糙,跟"主对话价值"不是因果)
- **不是**"主 agent 做任何耗时事情就该派" — 主对话**讨论代码 / 跟用户来回澄清需求 / 设计方案 / 决定改哪儿** 都是它的本职,即便耗时也不该派
- **不是** checkpoint 块(workflow 文件不插判定块,信号识别在 agent 心里)
- **不是** PostToolUse hook(简单任务零开销是硬约束,hook 不上)

#### 本职 vs auxiliary 判据(不数文件,看读完用来做什么)

读完 / 跑完后:

- 主对话**需要把内容作为讨论 / 决策的依据**(用户问起细节要能答,设计选型需要参考,跟用户解释要用到)→ **本职**,自己做
- 主对话**只需要结果做下一步决定**(过程不会被再引用,用户也不会问"刚才怎么跑的")→ **auxiliary**,反问后可派

举例:

| 场景 | 主对话用内容做什么 | 判定 |
|---|---|---|
| 修 NPE 读 3 文件锁定根因 | 用 context 决定怎么改 + 跟你讨论方案 | 本职(主对话需要 context) |
| explore "auth 模块怎么实现" 读 5 文件 | 用这些理解 + 跟你解释 auth | 本职(进入主对话脑子) |
| 找 X 调用链 12 文件,只要清单选改几个 | 主对话只要结果,不读每个 callsite | auxiliary(派出去给清单) |
| 找 X 调用链 12 文件,逐个看 callsite 决定改不改 | 主对话需要每个文件内容 | 本职(自己读) |

**关键**:同一个动作(读 X 文件)可以是本职也可以是 auxiliary,**取决于读完用来做什么**。判据切的是"用途",不是"动作大小"。

## 改动范围

| 文件 | 改什么 | 行数 |
|---|---|---|
| `templates/skill/workflows/subagent-driven.md` | **整体重构为双模式结构**:Mode 1 = Surface(新增,sub-step 级轻量派),Mode 2 = Four Phases(原 "When to Use" + 后续 Phase 1-4 内容改名);Harness Compatibility / Rationalizations / Red Flags / Degraded Mode 共用。文件顶部加"两种模式概述" | +~50 |
| `templates/skill/workflows/fix-bug.md` Step 6 | 一行 cross-ref:"如果要跑测试/构建,反问'看全过程多余吗',多余 → 见 subagent-driven.md § Surface" | +1 |
| `templates/skill/workflows/plan-feature.md` Step 3 | 一行 cross-ref:"如果 inspect 需要大范围 grep / find usage,反问'读完命中多余吗',多余 → 见 § Surface" | +1 |
| `templates/skill/workflows/change-managed.md` | Inspect 结束附近一行:"如果暴露 ≥ 5 callsite 要同型改,见 § Surface 或 `refactor-fanout.md`(开始就规划好了的)" | +1 |
| `templates/skill/conformance.yaml` | **不动**。Surface hints 是调优,不是合约。 |
| `UPSTREAM-CHANGES.md` | 新条目:标题、why(auxiliary sub-step 委派,反问驱动)、下游迁移指南 | +~25 |

**上游净改动 ~85 行**,集中在 `subagent-driven.md`。零新文件,零 conformance 变化,workflow 文件基本不动。

## 实施阶段

### Phase 1 — 写上游,不 commit

1. **重构 `subagent-driven.md`** 为双模式结构:
   - 文件顶部加"两种使用模式"概述(Mode 1: Surface = 轻量 sub-step / Mode 2: Four Phases = 重量整体)
   - 现有 "## When to Use" → 改名 "## Mode 2: Four Phases" + 把它前面挪到新 Mode 1 之后
   - **新增 ## Mode 1: Surface**(含:Mode 1 适用时机 / 信号入场资格 / 5 条反问清单 / 决策流程图 / Codex 信息呈现 isolation 子节)
   - Harness Compatibility / Rationalizations / Red Flags / Degraded Mode 章节标注为两模式共用
2. 在 `fix-bug.md` / `plan-feature.md` / `change-managed.md` 三处加 cross-ref(指向 § Mode 1: Surface)
3. 加 UPSTREAM-CHANGES.md 新条目
4. 跑 `bash scripts/check-all.sh`,11 个子检查必须全绿
5. 把 diff 交给用户 review

### Phase 2 — 用户 review

重点 review:

- **5 条反问句的措辞**是否准确(典型场景下答都是"是,多余"?)
- **本职 vs auxiliary 判据 + 4 个分类例子**是否够清晰(判据是"读完用来做什么",不数文件)
- **信号 #4 跟 `refactor-fanout.md` 分流**写法是否清楚

### Phase 3 — Commit + push 上游

措辞 settled 后单 commit。

### Phase 4 — 下游同步(chaos + chaos_web)

**通用准则:incremental insertion,不是 file replacement**。下游 `subagent-driven.md` 可能有本地化(项目专属 Rationalizations / 本地 Forbidden Zone 默认值 / 项目特定示例),直接覆盖会丢这些。新 § Mode 1: Surface 是新增章节,跟下游已有内容**没语义冲突**,只在合适位置插入。

#### 下游 `subagent-driven.md` 改造步骤

1. 在现有 "## When to Use" 之前插入新 "## Mode 1: Surface (Sub-step Auxiliary Delegation)" 整段
2. 把现有 "## When to Use" 改名为 "## Mode 2: Four Phases (When to invoke this mode)"
3. 文件顶部概述加一句"两种使用模式"
4. **其它章节全部保留**(Phase 1-4 描述 / Rationalizations / Red Flags / Degraded Mode / 项目专属示例,本地化全部不动)

#### 冲突处理

如果下游 `subagent-driven.md` 已经自己加过类似 sub-step 派的机制:

- **不要简单覆盖**
- diff 比较上游新 § Mode 1 vs 下游本地 sub-step 机制
- 取并集 — 上游的信号清单 + 下游的项目专属信号(如果有);Codex 处理跟上游一致
- manual review

#### 项目专属 workflow 加 cross-ref(通用形态规则)

> 任何 inspect-then-edit / explore-then-action 形态的 workflow,在 "explore / inspect 结束、edit 开始之前" 的位置加 cross-ref 指向 § Mode 1: Surface。如果该 workflow 没有清晰的 inspect/edit 分界,在文件顶部加一段总览级 cross-ref。

按这条规则改:

- **chaos**:`implement-feature.md`(inspect-then-edit 形态)
- **chaos_web**:`add-page-or-module.md` / `add-amis-page.md` / `add-hybrid-renderer.md` / `fix-schema-error.md`(都是 explore-then-action)

每个 repo 改完跑 smoke-test;不自动 commit,diff 交给用户 review。

### Phase 5 — 真实使用 1-2 周后,对话回顾

**不建观察日志 / 不写脚本测信号触发次数**(那些都是 "想象需要数据" 的过度设计,跟 cron / external-fact marker 反模式同型)。Phase 5 是个 review checkpoint,不是持续监控。

具体形态:2 周后跟用户聊一次,5 分钟:

- "5 个 surface 信号你印象里触发过哪些?大致几次?"
- "答 Y 多还是 N 多?哪个信号你觉得 mis-targeted?"
- "agent 有没有在不该 surface 的地方 surface(比如读 1 个文件也提议)?"
- "Codex 下答 Yes 后,agent 真的压缩了输出吗?还是还把 mvn 全部贴出来?"
- "有没有想加的新信号场景?"

基于对话直接改 Plan / signal list / Codex 处理,然后 Plan `status: done`,distill load-bearing 内容到 subagent-driven.md 或 rules/。

精确触发次数 / Y/N 比例对 Phase 5 判断**不必要** — 偏差大的能感知,偏差小的本来也没意义改。

Phase 5 输出之一:(a) 清单不动 (b) 改某些信号措辞 (c) 砍掉零触发的信号 (d) 加新信号(有证据支撑)

## 验证清单

Phase 3 commit 前必过:

- [ ] `bash scripts/check-all.sh` 退出码 0
- [ ] `templates/skill/SKILL.md.template` 不动
- [ ] `templates/skill/conformance.yaml` 不动
- [ ] `audit-orphans.sh` 无新孤儿
- [ ] **每个信号都能用反问句"主 agent 看 X 是多余的吗" 形式表达,典型场景答 yes**。念一遍清单测试 — 答"不一定"的信号砍掉
- [ ] **每个信号的场景具体到 "机械 + 耗时 + 只看结果"**,不是"任何耗时事情"
- [ ] 信号清单 ≤ 5 条;超出说明开始为想象场景加保险

## 风险 + 未决问题

### 风险:反问句让 agent "什么都多余"

反问句把默认偏差反过来,**好的副作用**是 agent 会更倾向派 subagent;**坏的副作用**是它可能把不该派的也派 — 比如反问 "主 agent 看读这个 1 个文件是多余的吗?" 答 "是,读完没用",然后连读单文件都 surface。

**Mitigation**:**信号入场资格的"场景具体"那一关是主防线**。反问句必须搭配 "机械 + 耗时 + 只看结果" 三特征的场景描述,不是泛问。再加上 § 信号不是什么 里的"本职 vs auxiliary 判据"(读完内容用作主对话讨论 / 决策依据 → 本职;只用结果做下一步决定 → auxiliary),双重过滤。

**残余风险**:Phase 5 如果发现 agent 把"读 1 个文件"也开始 surface,说明 "场景具体"过滤器失效,要在 § 信号不是什么 加更强约束。

### 风险:用户被反问句引导说 Yes 即便实际想看

反问句的设计意图就是让"派"成为默认,但**用户可能 reflexively 跟着答 Yes**,即便他实际上想看全过程(比如他在学习这个测试在跑啥)。

**Mitigation**:措辞中保留 "全过程" 和 "只看结果" 两个关键词,让用户知道**取消的是"看过程",保留的是"看结果"**。如果他真想看过程,会清楚地答 No。

### 风险:agent 漏识别 sub-step 边界

主 agent 可能"沉默执行" — 没在该反问的地方反问,直接 inline 跑了。比如:开始跑 mvn test 之前没有 surface,跑完才发现"哦该派给 subagent 的"。

**Mitigation**:Phase 1 在 `subagent-driven.md` 顶部把"在每个 sub-step 决定前 do this reverse-question"写成显式 reminder。Phase 5 观察"该 surface 但没 surface"的次数,如果太多,在工作流的关键步骤(测试运行 / 构建 / 大改之前)加更强 reminder。

### 未决问题:Codex 下 dispatch 实际怎么做

CC 干净:`Task` 工具 + `subagent-driven.md` contract。

Codex 没原生 dispatch。三个选项:

a. **手动开新 session** — 用户自己开 fresh Codex,粘 contract,跑完粘结果回。用户介入成本高,实际不会做
b. **当前 context 写 contract 但同 context 跑** — 伪隔离,context 还是污染,无价值
c. **加强版:信息呈现 isolation**

**采用 (c) 加强版**:

Codex 下信号触发后,反问 surface 仍然做(机制跟 CC 一致)。用户回答:

- **Yes** = agent 跑这一 sub-step,但**只贴结论**,不贴全过程:
  - 测试通过 → "通过"(一句话)
  - 测试失败 → "失败:`<错误简短描述>`,缺 mock `<具体>`"(2-3 行)
  - grep 命中 → 命中清单(每条 1 行,不贴文件内容)
  - 批量改 → diff 摘要(`改了 N 个文件,主要变更:<一句话>`;完整 diff 用户要看再说)
- **No** = agent 跑这一 sub-step,**贴全部输出**(传统 inline 行为)

这是 Codex 下能达成的最接近 isolation 的形态 — **信息呈现 isolation,不是 context isolation**:

| | CC (Yes) | Codex (Yes,加强版 c) |
|---|---|---|
| Context isolation | 真隔离 | 不隔离(同 context 跑) |
| 主对话视觉呈现 | 干净(看不到任何 subagent 内部) | 压缩(只贴结论) |
| Token / context 累积 | 低(主 context 不增长) | **跟 No 一样高**(agent 还是读了全部) |
| /compact 风险 | 低 | **跟 No 一样高** |

Codex 下加强版 (c) 的真实好处:**用户回看历史时不被 stack trace 淹**;Yes/No 在 Codex 下有清晰可见差异。Phase 5 监测 agent 是否真自律压缩输出。

### 未决问题:跟 `refactor-fanout.md` 怎么交互

信号 #4(同型编辑 ≥ 5)跟 `refactor-fanout.md` 范围重叠。区分:

- **开始就规划成 fanout refactor** → 直接走 `refactor-fanout.md`
- **执行中才暴露要同型改多处** → 走 § Surface(反问"逐个文件改是多余的吗"),Yes 后挂接到 `refactor-fanout.md` 的 contract 格式

`change-managed.md` cross-ref 已经写明这个分流;`refactor-fanout.md` Phase 1 前言加一行:"如果你从 Surface 信号到这里,正常走 Phase 1-3"。

### 未决问题:agent 拿到 subagent 结果后该不该亲自看代码

subagent 跑完回报 "测试通过 / 失败" 或 "改了 8 个文件 diff 摘要"。**主对话该不该亲自打开 diff / 测试输出?**

如果亲自看 = 信不过 subagent 判断 + 主对话再被污染
如果不看 = 信 subagent,完全依赖摘要

**草稿立场**:**不亲自看,只看 subagent 回报的摘要**。如果回报"卡在 X",主对话基于摘要决策下一步(再派 / 改方向 / 问用户)。这才是"isolation 真正生效"。

Phase 5 如果出现"subagent 说通过但其实没真正测对" 的事故,再考虑加 "主 agent 抽查" 规则;**现在不预先加**(否则又踩"为想象场景加保险"反模式)。

## "Done" 是什么样

- Phase 3 commit 上游
- Phase 4 下游同步 chaos + chaos_web
- 接下来 2 周真实使用中,**至少 1 次反问信号触发**,用户答 Y 或 N,观察后续流程
- subagent 接手 sub-step 完成后**主对话立刻回到 inline 默认**,不残留 orchestrator 状态
- Phase 5 输出"措辞调整"或"维持现状"决定

## "Done" *不是* 什么样

- 任何 workflow 里插了 checkpoint 块
- `conformance.yaml` 新增"必含反问句措辞"硬约束
- 写了脚本测量反问信号触发次数
- **observations / 信号触发日志文件**(用户对话回顾 5 分钟够用,不要为想象需要建脚手架;事件触发的记录也不上,会随时间越来越重 + agent 自律不可靠)
- mode shift 翻转默认到 orchestrator-first
- Yes 之后 subagent **接管剩余整体任务**(而不是只接 sub-step)
- 信号清单超过 5 条(超出说明开始为想象场景加保险)
- "强制用户必答"的 gate 卡住 agent(信号是 pause-and-ask,**沉默 = inline**,就是现有兜底)
