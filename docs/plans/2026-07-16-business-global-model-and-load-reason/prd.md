---
date: 2026-07-16
status: done
distilled_to:
  - SKILL.md
  - references/business-global-model.md
  - references/progressive-rigor.md
  - references/protocols.md
  - references/layout.md
  - references/skeleton-flesh-split.md
  - references/self-hosting-routing.yaml
  - templates/skill/workflows/profile-business-model.md.example
  - templates/skill/workflows/profile-project.md
  - templates/skill/workflows/plan-feature.md
  - templates/skill/workflows/plan-large.md
  - templates/skill/workflows/fix-bug.md
  - templates/skill/workflows/change-managed.md
  - templates/skill/workflows/update-rules.md
  - templates/skill/workflows/maintain-docs.md
  - templates/skill/workflows/subagent-auxiliary.md
  - templates/skill/workflows/subagent-driven.md
  - templates/skill/workflows/task-closure.md
  - templates/skill/routing.yaml
  - templates/skill/conformance.yaml
  - templates/skill/scripts/route-reachability.sh
---

# 业务全局模型与独立加载理由治理

## Context

当前 skill-based-architecture 擅长记录技术规则、工作流、代码事实和高代价坑，但缺少一种轻量方式，帮助 Agent 在进入复杂业务模块前建立稳定的宏观业务认知。

以合并任务为例，Agent 应当在动手前知道 `mergeType` 的业务分类、来源与目标、整体推进流程、核心状态和不变量；它不需要把具体 Controller、Manager、接口字段、Nacos 路径、某次 bug 修复或易变业务细节长期装入上下文。

本轮讨论已经确认以下约束：

1. 只记录长期稳定的宏观业务事实，不建设详细业务说明书。
2. 内容结构是菜单，不是固定章节清单；没有实际内容的章节和目录不创建。
3. 初始优先一个模块一个文件，只有出现独立读取压力时才拆分。
4. 每个文件必须有独立的加载理由；如果多个文件在所有真实任务中永远共同加载，应当合并。
5. 行数只是评估信号，不是拆分或合并的决定条件。
6. 业务知识不得进入 Always Read，只能通过相关模块和任务的路由渐进加载。
7. Agent 先从代码、配置、测试和现有文档中提取宏观模型，再与用户头脑风暴校准业务含义。
8. 日常任务中“业务模型完全不存在”和“已有但局部不清晰”必须走不同处理路径，不能一律重新建模。
9. 用户选择“稍后”时只在当前会话暂时记住，不创建候选文件、空目录、空 index 或占位 route。
10. Plan 与 Fix Bug 都必须以相关业务全局模型为语义基础，再结合 architecture、rules、代码、测试和运行事实辩证判断。
11. 从头脑风暴、Plan 或排障结果写入长期文档时，必须保留影响判断的定义、条件、边界和原因，禁止为了简短而丢失承重语义。
12. Gotcha 不能默认追加到文件末尾；每次写入都必须先搜索、判断根因、合并旧条目并放到正确结构位置。

对现有仓库的只读审计也发现，当前结构检查虽然报告 `0 orphan`、路由无静态质量告警，但仍存在语义上的共同加载与重复内容问题：

- 下游模板把 `project-rules.md` 与 `coding-standards.md` 预先拆开，却在所有任务中共同 Always Read。
- 自托管 `plan-and-distill` 路由从规划开始就共同加载 `plan-feature.md` 与 `update-rules.md`。
- `update-rules` 路由不区分稳定规则、技术坑和 Agent 行为失败，固定共同加载两个证据库。
- 单 skill 路由优化也固定加载 `multi-skill-routing.md`。
- `gotchas.md` 空种子混入大量仅维护时需要的组织升级说明。
- Task Closure 已内置 Rationalizations / Red Flags，但模板仍额外下发独立副本。
- `plan-feature.md`、`update-rules.md`、`subagent-driven.md` 含有明显的条件分支内容，但当前入口会一次加载全部分支。
- 头脑风暴和计划沉淀存在过度简写风险；经过多轮 Agent 转述后，条件、反例和设计原因会逐渐丢失。
- Gotcha 虽然已有 Search Before Record 和 Structural Placement 规则，实际使用仍容易退化为时间顺序追加，形成重复根因、碎片补充和低准确率读取。

这些问题说明现有 orphan、reachability、route-health 和行数检查只能证明“文件存在且可达”，不能证明“该文件在当前任务上有独立加载价值”。

## Problem

需要同时解决四个相关问题。

第一，建立一套可选的“业务全局模型”机制，使产品型项目可以按模块记录稳定的业务分类、整体流程、状态机、边界和不变量，同时拒绝易变细节、固定八分类和空模板膨胀。

第二，把“独立加载理由”纳入结构设计与文档维护，既约束未来业务模型如何拆分，也回头治理当前已经存在的机械拆分、条件内容混装、路由安全毯和重复 protocol block。

第三，让业务全局模型真正进入 Plan 与 Fix Bug 的判断链路。代码只能证明“当前是什么”，不能自行证明“业务上应该如此”；如果所谓 Fix Bug 会改变类型定义、流程方向、状态机或核心不变量，它必须退出普通修复流程，转入 Plan / 设计变更并由用户确认。

第四，治理长期知识写入时的两种退化：记录阶段的语义压缩失真，以及 Gotcha 等积累型文档的无脑追加和结构腐化。长期知识必须经过“保真、整合、激活”三道门，而不是把会话摘要或新发现直接拼到文件末尾。

当前 `update-rules.md` 的 Generalization Rule 还要求记录脱离当前项目后仍成立，这与项目专属的宏观业务事实存在冲突。业务全局模型需要另一种质量判断：它不要求跨项目通用，但必须跨实现稳定——即底层类、接口、存储或框架替换后，业务描述仍然成立。

## Options Considered

### 方案 A：照搬完整产品知识库分类

为每个项目默认创建 product context、business use cases、system use cases、domain model、state machines、sequences、non-functional 和 traceability 等目录。

- 优点：覆盖全面，适合成熟产品文档体系。
- 缺点：默认文件数量过多；同一模块被横向拆散；业务细节容易大量进入；人工追溯表维护成本高；对 CLI、库和小项目明显不适用。
- 结论：拒绝作为通用 SBA 默认机制。

### 方案 B：每个业务模块使用固定完整模板

规定每个模块文件必须包含介绍、参与者、类型、流程、状态机、权限、异常、审计等完整章节。

- 优点：格式统一，首次编写容易照表填写。
- 缺点：会为了模板完整而补充不稳定或无价值内容；不同模块被迫写相同章节；容易退化成业务说明书。
- 结论：拒绝固定章节配额，只保留可选内容菜单。

### 方案 C：可选、渐进、按加载理由生长的业务全局模型

首次出现真实宏观业务知识时创建 `references/business/<module>.md`；只有当一个模块内部出现能够被不同任务独立选择的内容时，才升级为目录和 index。配套增加代码优先、用户校准、路由激活和独立加载理由审计。

- 优点：直接解决已观察到的业务认知缺口；不为非产品项目增加默认负担；与 Progressive Disclosure 和 Activation over Storage 一致。
- 缺点：需要 Agent 做语义判断，不能完全依赖脚本；初期需要通过真实模块验证内容边界。
- 结论：采用。

### 方案 D：立即扩展 routing.yaml，增加 module/context overlay 引擎

让任务路由与模块路由叠加，自动组合 workflow 与业务模块 required reads。

- 优点：长期可以避免 task × module 路由组合爆炸。
- 缺点：当前没有证据证明普通 route + 直接 required read / 小型 index 不够用；会立即扩大解析器、生成器、校验脚本和多工具薄壳协议。
- 结论：暂缓。先用现有路由能力验证真实使用，再决定是否升级路由语法。

### 方案 E：只增加索引或“禁止追加”规则

保留现有记录流程，只要求 Gotcha 不要追加到末尾，或者为业务知识和 Gotcha 默认创建 index。

- 优点：改动小，容易描述和检查文件结构。
- 缺点：无法解决头脑风暴落盘时的语义压缩；索引只能加速已有内容，不能修复重复根因、错误简写和过期结论；默认 index 本身也会成为空资产。
- 结论：拒绝作为完整方案。索引只作为多文件阶段的条件工具，必须与保真、整合、激活门禁配合。

## Chosen Approach

采用“业务全局模型 + Plan/Fix Bug 语义基线 + 持久知识写入门禁 + 独立加载理由审计 + 分阶段历史治理”的组合方案。

### 1. 业务全局模型的定位

业务全局模型是项目专属、实现无关、低变化率的宏观事实层，建议路径为：

```text
references/business/
└── merge-task.md
```

目录不存在时不预创建。第一个模块出现时直接创建模块文件，不强制创建只有几行导航的 `index.md`。

模块文件可以按实际需要包含：

- 模块定位和解决的问题。
- 核心业务概念与参与者。
- 稳定的业务类型体系或决策矩阵。
- 宏观流程推进。
- 业务状态、允许迁移和终态。
- 长期成立的边界、模块关系和不变量。
- 仅在稳定且承重时记录的权限、审计、时间或终止语义。

这是一份内容菜单，不是必填模板。没有状态机的模块不写状态机，没有独立权限语义的模块不写权限章节。

明确排除：

- 类、方法、接口地址、数据库字段和配置 key。
- 页面布局、组件实现和交互细节。
- 某次需求的方案推导或任务拆解。
- 某个 bug、临时兼容逻辑和分支级特殊处理。
- 频繁变化的执行参数、环境映射和边缘业务规则。
- 未经代码证据或用户确认的推测。

质量判断从“跨项目通用”改为“跨实现稳定”：如果替换框架、类名、接口和存储后仍然成立，才适合记录为业务全局模型。

### 2. 触发、采集与局部校准流程

业务全局模型有两个正式触发入口。

**项目初始化入口：**

1. Profile 项目结构、入口、核心枚举、状态和现有文档，只识别可能具有稳定全局语义的模块候选。
2. 向用户说明每个候选为什么值得梳理，不批量创建业务文件。
3. 用户逐项选择“现在梳理 / 稍后 / 不需要”。
4. 只对“现在梳理”的模块执行代码搜索和头脑风暴。
5. “稍后”不落盘；“不需要”也不留下空资产。

**日常任务入口：**

| 当前状态 | Agent 行为 |
|---|---|
| 完全没有对应业务模型，且缺口影响当前判断 | 说明缺少的宏观语义，询问用户是否现在建立；用户选择稍后时不落盘 |
| 已有模型但局部不清晰 | 先搜索相关代码和测试，只向用户询问缺失的宏观语义，然后原地更新已有文件，不重新做完整模块建模 |
| 已有模型但与代码、测试或运行事实冲突 | 列出冲突，询问哪一边代表正确业务意图，再判断是 Bug、设计变更还是文档过期 |
| 已有模型且足够清晰 | 直接作为 Plan / Fix Bug 的业务基线，不打扰用户 |

完整建模的执行顺序为：

1. 确定目标模块和当前问题范围。
2. Agent 搜索代码、配置、测试和现有文档，只提取类型体系、整体生命周期、状态、边界和不变量候选。
3. 删除实现细节和一次性需求内容，输出带证据状态的宏观理解草稿。
4. 与用户头脑风暴，只询问代码无法决定的业务名称、历史定位、目标语义和隐性边界。
5. 区分当前实现、用户确认的业务语义和仍未确认的内容；未确认内容不进入正式模型。
6. 生成准备持久化的最终文本并做语义回读，确认定义、条件、边界和关键原因没有被简写掉。
7. 对创建新模型或改变宏观含义的更新，向用户展示最终含义并获得确认。
8. 写入最小充分模块文件，并在相关任务 route 中声明读取路径；业务模型不进入 Always Read。

正式业务全局模型描述当前已经确认并生效的业务基线。已经批准但尚未实现的新语义先留在 Plan 中；只有代码、测试和行为落地时，才在同一任务中同步更新正式业务模型。若代码行为与业务基线不一致，具体差距和修复方案留在当前 Plan、需求文档或 gotcha 中，避免把暂态混入长期模型。

### 3. 作为 Plan 与 Fix Bug 的业务语义基线

业务全局模型不是仓库级 Always Read，但一旦 route 命中对应业务模块，它是该模块的第一层语义基础：

```text
用户任务
  → 业务全局模型：业务上应该是什么
  → architecture / rules / 契约：技术上准备怎样实现
  → 代码 / 测试 / 运行数据：当前实际上是什么
  → 对比差异
  → Plan、Fix Bug、设计修正或继续澄清
```

Plan 必须明确本次变化属于哪一种：

- 业务模型不变，只补齐缺失实现。
- 业务模型不变，代码违反原设计，属于 Bug。
- 业务模型变化，属于业务设计变更。
- 业务模型不变，但 architecture 不再适合，属于技术重构。
- 业务模型、architecture 与代码互相冲突，需要先澄清。

Fix Bug 在建立红测或修改代码前执行“设计还是缺陷”判断：

| 判断结果 | 后续流程 |
|---|---|
| `IMPLEMENTATION_BUG`：代码违反已确认业务模型 | 继续 Fix Bug，使用业务模型定义预期行为 |
| `DESIGN_CHANGE`：需要改变类型、流程、状态机或核心不变量 | 立即停止普通修复，转入 Plan / 设计变更，并由用户明确确认 |
| `INSUFFICIENT_BUSINESS_CONTEXT`：缺少足够业务依据 | 按第 2 节判断是完整建模还是局部校准；不能猜测修复方向 |
| 明显技术错误：崩溃、500、编译失败等 | 可直接按技术 Bug 处理，不强制建立业务模型 |

正式红线：如果一次所谓 Fix Bug 会改变业务全局模型中的类型定义、流程方向、状态机或核心不变量，它就不再是普通 Bug 修复。转换为 Plan 时复用已经收集的现象、代码行为、业务基线和冲突证据，不重复调查。

### 4. 渐进拆分规则

初始形态：

```text
references/business/merge-task.md
```

只有出现不同任务独立读取的真实压力时，才升级为：

```text
references/business/merge-task/
├── index.md
├── types.md
└── lifecycle.md
```

拆分前必须回答：

1. 哪一种真实请求只需要读取这个候选文件？
2. 哪条 route、workflow 或 index 会单独选择它？
3. 不读取兄弟文件时，它能否独立成立？
4. 拆分是否实际减少无关上下文？

如果几个文件在所有调用点都一起加载、一起修改，并且没有独立生成或所有权契约，则应合并。状态机和流程通常优先放在同一个 `lifecycle.md`，除非出现分别读取的真实任务，不按标题机械拆分。

### 5. 独立加载理由审计

在 `maintain-docs.md` 增加语义审计：

- 每个正式文件必须声明或能够追溯到独立 route/workflow/index 选择理由。
- 每个 `required_reads` 必须说明为什么当前 route 在开始阶段就需要它；条件内容应移出核心读取集。
- 两个文件如果在全部真实调用点共同加载，应优先评估合并。
- 一个长文件如果包含互斥或条件分支，应优先评估按任务分流，而不是按行数机械拆分。
- 独立生成、不同所有权或机械同步契约可以保留文件边界，但不能因此强迫运行时共同加载。
- 短文件只要具有独立选择路径就可以保留；长文件只要始终整体使用也可以不拆。

第一阶段保持判断式检查，不新增静态脚本。脚本无法可靠判断语义独立性，提前机器化会产生错误合并和为过检查而拆文件的问题。

### 6. 持久知识写入门禁与 Gotcha 治理

业务全局模型、architecture、rules、gotchas 和 Plan 结论沉淀都必须经过三道门：

1. **保真**：最终记录是否保留了会影响判断的定义、适用条件、边界/反例和设计原因；一个未参与当前对话的新 Agent 只读记录，能否重建相同的关键判断。
2. **整合**：新内容应当更新已有条目、合并同根因场景、修正过期内容，还是确实新增；禁止默认在文件末尾追加。
3. **激活**：未来哪个 route、workflow 或 index 会准确读到它，读取后会改变什么下一步动作。

记录不强制使用固定四段模板，但不能把“mergeType=4 是版本合并”这类有害简写当成完整知识。若来源讨论还包含目标身份、与其他类型的边界和错误后果，这些承重信息必须保留。

业务全局模型创建或宏观变化时需要用户语义回读；普通技术 gotcha 可以由 Agent 自动整合，但仍必须自行执行保真和整合检查。

每次 Gotcha 写入只允许五种结果：

1. 已有内容完全覆盖，不写。
2. 同一根因的新表现，扩展已有条目。
3. 已有内容不准确，原地修正。
4. 已有内容已失效，删除或明确标记过期。
5. 确实是独立根因，放入正确主题位置后新增。

Gotcha 按稳定根因或业务/技术模块组织，不按发现时间组织。多个现象如果来自同一个根因，应合并成一个条目并列出不同表现，避免“问题 A”“问题 A 的补充”“另一个问题 A”分散在文件各处。

索引是条件机制，不是默认资产：

- 单一 gotchas 文件使用清晰标题和 topic 标签，不创建 index。
- 只有拆成多个独立文件，并且 index 能根据任务信号改变下一步读取文件时，才创建 `gotchas/index.md`。
- 只列文件名、不能指导选择的目录表不构成有效索引。
- 任何整理、合并或拆分都要做前后语义对账，确认条件、反例和原因没有在压缩中丢失或被扩大。

### 7. 历史问题的分阶段治理

先处理高置信、低争议问题：

1. `plan-and-distill` 不再在规划开始时预读完整 `update-rules.md`；规划和计划沉淀使用不同 route 或明确的后置加载。
2. `improve-activation-routing` 只在检测到多 skill 信号时读取 `multi-skill-routing.md`。
3. `revise-skill-doc` 不再固定加载完整 `layout.md`；只有结构、description 或路径变化时加载。
4. 下游 `update-rules` 先判断记录类型，再选择 `gotchas.md`、`behavior-failures.md` 或相关规则文件。
5. `gotchas.md` 空种子只保留条目格式；组织升级教程移动到 `maintain-docs.md`。
6. Task Closure 的 Rationalizations / Red Flags 保持一个真源；删除没有独立运行时路径的通用重复副本，或反向改为唯一引用，禁止两套正文并存。

再处理需要独立设计验证的拆分：

- 从 `plan-feature.md` 抽取仅 Large 计划需要的内容，普通规划不加载。
- 将 `subagent-driven.md` 收敛为模式选择入口，Mode 1 与现有 Mode 2 orchestration 分别按需加载。
- 评估 `update-rules.md` 中“日常记录”“重大 skill 升级门禁”“规则退役维护”是否形成三个真实独立读取场景；只有 load trace 证明后才拆。

`project-rules.md` 与 `coding-standards.md` 的默认合并问题与现有 Safe Progressive Adoption 计划存在交叉。本计划只登记约束：轻量安装不得预先拆出两个永远共同 Always Read 的空文件；具体 assembler 和 tier 迁移由该计划统一落地，避免两个计划同时修改同一安装契约。

## Requirements & Acceptance Criteria

### 业务全局模型

1. 非产品型或没有真实宏观业务知识的项目不会生成 `references/business/`。
2. 第一个业务模块默认只有一个文件，不为了导航预建 `index.md`。
3. 模块文件没有固定章节配额，空章节、占位章节和为完整而补写的细节为失败。
4. 正式模型只包含低变化率、实现无关的宏观事实；代码路径和一次性需求内容被明确排除。
5. Agent 在用户头脑风暴前先完成证据搜索，但代码推断不得伪装成用户确认的业务意图。
6. 每个业务文件拥有明确 route/workflow/index 读取路径，且不会进入 Always Read。
7. 模块文件拆分时，每个子文件都能指出一个不会同时加载全部兄弟文件的真实任务。
8. 若所有调用点共同读取拆出的文件，维护流程要求合并或记录独立所有权例外。
9. 项目初始化只生成候选说明；用户选择“稍后”或“不需要”时不创建文件、目录、index 或 route。
10. 日常任务能区分模型完全缺失、局部不清晰、与代码冲突和已经充分四种状态，并采用不同交互流程。
11. 正式业务模型只描述当前已经确认并生效的业务基线；未实现的目标语义留在 Plan，落地时与代码和测试同步更新。

### Plan 与 Fix Bug

12. 业务模块相关 Plan 在分析代码前或同时读取对应业务模型，并显式区分业务意图、设计约束和当前实现事实。
13. Fix Bug 在业务预期可能存在争议时先完成 `IMPLEMENTATION_BUG / DESIGN_CHANGE / INSUFFICIENT_BUSINESS_CONTEXT` 分类，再定义红测和修改方向。
14. 任何改变类型定义、流程方向、状态机或核心不变量的“修复”都会停止普通 Fix Bug，转入 Plan / 设计变更并获得用户确认。
15. 从 Fix Bug 转入 Plan 时复用已有现象、证据和冲突说明，不要求重新调查同一问题。
16. 明显技术错误不因业务模型机制增加无关头脑风暴或文档负担。

### 持久知识质量

17. 业务模型、architecture、rules、gotchas 和 Plan 沉淀在写入前执行保真、整合、激活三道检查。
18. 业务模型创建或宏观语义改变时，用户能够看到并确认最终准备持久化的含义，而不是只确认会话中的长篇讨论。
19. 新 Agent 只读最终记录能够恢复影响判断的定义、条件、边界/反例和关键原因；不能恢复则视为过度简写。
20. Gotcha 写入必须明确选择“不写、扩展旧条目、修正、退役、独立新增”之一，禁止默认追加。
21. 同一根因的多个表现被整合到同一条目；新增内容按主题放置，不按发现时间堆在文件末尾。
22. `gotchas/index.md` 仅在存在多个独立文件且能依据任务信号改变读取目标时创建；单文件阶段不创建索引。
23. Gotcha 合并、拆分和压缩后完成前后语义对账，承重条件和反例没有丢失、扩大或缩小。

### 现有结构治理

24. 规划任务不在任务开始时加载仅关闭计划时需要的沉淀工作流。
25. 单 skill 路由优化不默认读取多 skill 专题。
26. 日常规则更新不默认共同加载技术坑和 Agent 行为失败两个证据库。
27. Gotchas 的内容文件不再携带只在文档维护阶段需要的完整拆分教程。
28. Task Closure Rationalizations / Red Flags 只有一个正文真源。
29. 对 `plan-feature`、`subagent-driven`、`update-rules` 的每个拆分都有 before/after load matrix；没有独立读取收益的拆分不得实施。

### 验证

30. `bash scripts/check-all.sh` 通过。
31. 自托管路由修改后，`bash scripts/sync-self-shells.sh` 与 `bash scripts/check-self-shells.sh` 通过。
32. 临时下游 skill 采用业务全局模型工作流后，`sync-routing --check`、`smoke-test --phase 8`、`audit-orphans` 和 `route-reachability` 通过。
33. 至少使用“合并任务”作为前向测试场景，验证首次创建、局部校准、业务模型与代码冲突、Fix Bug 转 Plan、按 mergeType 读取和按状态推进读取。
34. 使用一个头脑风暴长结论做保真测试，确认最终记录没有把条件、反例或设计原因压缩掉。
35. 使用至少三个同根因 Gotcha 碎片做整合测试，最终形成一个结构化条目而不是三个末尾追加项。
36. 静态结构检查通过之外，人工完成独立加载理由审计并保存 before/after 路由读取表。

### Implemented load matrix

| Scenario | Before | After | Independent load reason |
|---|---|---|---|
| Self-hosted planning | `SKILL` + plan archive guide + `plan-feature` + `update-rules` | `SKILL` + plan archive guide + `plan-feature` | recording mechanics are closure-only |
| Self-hosted plan distillation | same combined route as planning | `SKILL` + plan archive guide + `update-rules` | persistence is the task, planning procedure is not |
| Ordinary skill/reference revision | `SKILL` + `REFERENCE` + full `layout` + `update-rules` | `SKILL` + `REFERENCE` + `update-rules`; `layout` only for structure/path changes | layout is conditional structural guidance |
| Single-skill activation/routing | `SKILL` + `layout` + `multi-skill-routing` | `SKILL` + `layout`; multi-skill reference only on multi-skill evidence | coexistence/ownership rules do not apply to one skill |
| Downstream rule recording | Always Read + `update-rules` + Gotchas + behavior failures | Always Read + `update-rules`; destination/evidence selected after classification | technical Gotcha and Agent behavior evidence are mutually conditional |
| Simple/Complex Plan workflow | 198-line combined workflow | 85-line core | Large-only angles are not relevant |
| Large Plan workflow | 198-line combined workflow | 85-line core + 56-line `plan-large` | multi-perspective analysis is selected only after Large classification |
| Day-to-day auxiliary delegation | 225-line two-mode workflow | 65-line `subagent-auxiliary` only | ordinary tasks need Mode 1 admission, not orchestration |
| Planned Mode 2 work | 225-line selector + 94-line orchestration | 63-line selector + 94-line orchestration | Mode 2 does not load Mode 1 details |
| Task Closure reinforcement | 90-line canonical workflow + 38 lines of duplicate blocks in distribution | 90-line canonical workflow only | deleted blocks had no independent runtime selector |

The self-hosted route count is now 11 because `long-run` is a cross-cutting modifier and plan vs distillation intentionally have different read sets. This is an explicit exception to the “review over 10” signal, not a reason to recombine them.

Final evidence:

- `bash scripts/check-all.sh` passed after the final sync, including upstream-note, shell, template downstream smoke 66/66, business/persistence scenarios 47/47, orphan, link, budget, and conformance checks.
- A fresh temporary product downstream adopted `profile-business-model.md`, one directly routed `references/business/merge-task.md`, and merge-type/lifecycle triggers without any business index; sync-routing passed, Phase 8 smoke passed 67/67, orphan and route-reachability were both 0, and route-health reported no smells.
- The merge-task fidelity scenario retained source/target identity, type boundary, lifecycle direction, terminal-state invariant, and the Plan red line while excluding implementation names.
- Three Gotcha fragments (reopened tab, missing callback, manual-refresh workaround) reconciled into one `[lifecycle]` root-cause entry with multiple symptoms and one prevention action.
- Growth review was explicit: the 11 self-hosting routes are justified above; `full-migration.md` remains one sequential workflow despite its line signal; pre-existing oversized generator scripts were not expanded by this plan.

## Out of Scope

- 本计划不直接为 chaos 编写完整的合并任务业务模型；它只提供机制和前向验证样本。
- 不引入八分类产品知识库、手工 traceability 总表或固定四件套需求 dossier。
- 不新增 routing module/context overlay 语法。
- 不新增自动判断“两个文件应该合并”的语义脚本。
- 不把业务全局模型加入 Always Read。
- 不在业务模型中记录 Controller、Manager、API、数据库、Nacos、页面和 bug 修复细节。
- 不为“稍后梳理”创建持久候选队列、空文件或占位 route。
- 不把业务全局模型当成详细需求的替代品；局部、易变规则仍由测试、契约、代码和当前需求承载。
- 不把会话总结直接当成长期真源，也不允许它覆盖已确认的正式业务模型。
- 不强制为所有 Gotcha 建 index；单文件可准确检索时使用标题和 topic 标签即可。
- 不一次性重写全部 references/workflows；历史治理按高置信问题和真实 load trace 分阶段进行。
- 不修改或合并现有 `docs/plans/2026-07-15-safe-progressive-adoption/` 计划及根目录 planning-with-files 账本。

## Task Breakdown

### Task 1 — 定义业务全局模型契约

- **Files**: owns new `references/business-global-model.md`; updates `REFERENCE.md`, `references/progressive-rigor.md`, `templates/ANTI-TEMPLATES.md`; forbidden: downstream project business content
- **Consumes**: 本计划确定的宏观稳定性、内容菜单、红线、单文件优先和独立加载理由原则
- **Produces**: 业务全局模型的适用条件、采集流程、目录演进、拆分/合并判断和 route recipe
- **Acceptance**: 文档明确拒绝固定章节、空目录、八分类和实现细节；给出单文件 → 按需目录的演进示例；所有新 reference 有入口链接

### Task 2 — 提供可选业务建模工作流

- **Files**: owns new `templates/skill/workflows/profile-business-model.md.example`; updates `templates/skill/workflows/profile-project.md`, `TEMPLATES-GUIDE.md`, `templates/README.md`; forbidden: default `routing.yaml` 新增强制业务 route
- **Consumes**: Task 1 的采集顺序、内容边界、route recipe，以及初始化/日常任务两类触发状态机
- **Produces**: 初始化候选扫描；完全缺失时的询问；局部不清晰时的最小用户校准；代码冲突时的语义确认；代码优先搜索 → 宏观候选过滤 → 用户头脑风暴 → 语义回读 → 最小文件写入 → 路由激活的可选流程
- **Acceptance**: 非业务项目无需采用；“稍后”不创建任何资产；已有模型局部不清晰时原地更新而不是重新建模；用户未确认、实现细节和未生效目标不得进入正式模型；示例采用后能被 downstream smoke-test 验证

### Task 3 — 接入 Plan 与 Fix Bug 判断链路

- **Files**: owns changes to `templates/skill/workflows/plan-feature.md`, `templates/skill/workflows/fix-bug.md`, `templates/skill/workflows/change-managed.md`, `templates/skill/references/minimal-sufficient-context.md`; updates related routing summaries only through Task 5; shares Task 1 reference read-only
- **Consumes**: Task 1 的业务语义基线；Task 2 的缺失/局部校准流程；现有 bugfix red→green 与计划复杂度门禁
- **Produces**: Plan 的业务模型→architecture→代码对比顺序；Fix Bug 的 `IMPLEMENTATION_BUG / DESIGN_CHANGE / INSUFFICIENT_BUSINESS_CONTEXT` 分类；改变类型、流程、状态机或不变量时转 Plan 的强门禁
- **Acceptance**: 明显技术 Bug 不增加无关业务流程；业务预期有争议时不能先写红测或改代码；转 Plan 时复用已有证据；已批准未实现的语义保留在 Plan，落地时才更新正式模型

### Task 4 — 增加持久知识写入门禁与独立加载理由审计

- **Files**: owns changes to `templates/skill/workflows/update-rules.md`, `templates/skill/workflows/maintain-docs.md`, `templates/skill/references/gotchas.md`, `references/protocols.md`, `references/progressive-rigor.md`, `SKILL.md` existing Progressive Disclosure/Self-maintenance principles; updates `templates/skill/conformance.yaml` only if a mandatory phrase is introduced
- **Consumes**: 业务事实“项目专属但跨实现稳定”的新分类；保真/整合/激活三门；Gotcha 五结果决策；独立加载理由六项审计和“行数仅为信号”约束
- **Produces**: Generalization Rule 的适用边界；业务模型语义回读；记录前根因归并；禁止末尾无脑追加；可选 Gotcha index；split、merge、required_reads 和 index/hub 的统一判断流程
- **Acceptance**: 通用规则/gotcha 仍要求跨项目泛化，业务模型改用跨实现稳定检查；同根因内容合并；整理前后语义对账；短文件不因短被自动合并，长文件不因长被自动拆分；不新增语义判定脚本

### Task 5 — 修复高置信路由过载

- **Files**: owns `references/self-hosting-routing.yaml`, `templates/skill/routing.yaml`; generated targets `AGENTS.md`, `CLAUDE.md`, `CODEX.md`, `GEMINI.md`, `.cursor/rules/workflow.mdc`, `templates/skill/SKILL.md.template`, downstream shell templates as required by sync; forbidden: unrelated route trigger rewrites
- **Consumes**: Task 4 的 required_reads 判定；当前审计确认的 plan/distill、single/multi-skill、rule/gotcha/behavior 三组错误共同加载
- **Produces**: 分阶段或条件化的最小核心读取集
- **Acceptance**: route summary 与 manifest 同步；规划开始不预载完整 `update-rules.md`；单 skill 场景不预载 `multi-skill-routing.md`；规则更新按记录类型选择证据文件；route-health 无新增重叠告警

### Task 6 — 收敛重复内容与条件工作流

- **Files**: owns `templates/skill/workflows/task-closure.md`, `templates/skill/protocol-blocks/rationalizations-table.md`, `templates/skill/protocol-blocks/red-flags-stop.md`, `templates/skill/sync-manifest.yaml`, optional new large-plan workflow, `templates/skill/workflows/subagent-driven.md`, optional new Mode 1 workflow; updates links/conformance/docs that name moved files; shares `plan-feature.md` with Task 3 only through an agreed extraction patch
- **Consumes**: Task 4 的独立加载理由审计和每个候选的 before load trace
- **Produces**: 单一 Rationalizations/Red Flags 真源、Large planning 条件读取、Mode 1/Mode 2 条件读取
- **Acceptance**: 无正文重复；每个新增子文件有独立调用场景；如果 before/after 表不能证明上下文减少，则保留原文件不拆；交叉链接和 vendor sync manifest 无断裂

### Task 7 — 前向测试与全量验证

- **Files**: owns only temporary fixture/test artifacts outside committed product tree unless an existing scenario test requires update; updates `scripts/check-self-scenarios.sh`, `UPSTREAM-CHANGES.md`, `templates/README.md` only for landed behavior and validation contracts
- **Consumes**: Tasks 1–6 的最终文件结构、路由和工作流
- **Produces**: 合并任务样本、完全缺失/局部校准/代码冲突/Fix Bug 转 Plan 场景、头脑风暴保真样本、同根因 Gotcha 整合样本、before/after load matrix、结构验证结果、回归说明和下游升级提示
- **Acceptance**: `scripts/check-all.sh`、self-shell sync/check、临时 downstream sync/smoke/orphan/reachability 全部通过；业务模型样本不会混入实现细节；保真测试能重建原始关键判断；Gotcha 测试不产生末尾碎片；工作树只包含本计划授权的变更；未通过独立加载理由审计的候选不进入最终实现

## Open Questions

当前没有阻塞实施计划的业务决策。实现前只需要用户批准本计划；批准后按 Task 1–7 执行，不自动吸收 Safe Progressive Adoption 计划中的安装器工作，也不提前实现 routing overlay。
