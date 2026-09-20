---
name: financial-data
description: "财务数据获取与交叉验证规范：企业财务数据研究的数据源优先级和双源交叉验证要求。"
version: 1.0.0
metadata:
  hermes:
    tags: ['investment', 'financial-data', 'verification', '数据', '交叉验证']
    related_skills: ['earnings-review', 'investment-research']
---

# 财务数据获取与交叉验证规范

本规范适用于所有涉及企业财务数据的研究。**每个关键数据必须来自两个独立来源，误差>1%须标记。**

---

## 数据源优先级

### 美股（PDD、腾讯ADR、网易ADR等）

| 优先级 | 来源 | URL | 获取方式 |
|--------|------|-----|---------|
| 1（主） | **macrotrends** | macrotrends.net/stocks/charts/{ticker} | 直接访问，无需注册 |
| 2（副） | **stockanalysis** | stockanalysis.com/stocks/{ticker}/financials | 直接访问，无需注册 |
| 原始一手 | SEC EDGAR | sec.gov/cgi-bin/browse-edgar | 10-K / 10-Q 原文 |

### 港股（腾讯0700、网易9999、美团3690等）

| 优先级 | 来源 | URL | 获取方式 |
|--------|------|-----|---------|
| 1（主） | **aastocks** | aastocks.com/tc/stocks/analysis/company-fundamental | 直接访问 |
| 2（副） | **macrotrends**（ADR代码） | 腾讯用TCEHY，网易用NTES | 直接访问 |
| 原始一手 | HKEX披露易 | hkexnews.hk | 年报PDF |

### A股（三七互娱、吉比特等）

| 优先级 | 来源 | URL | 获取方式 |
|--------|------|-----|---------|
| 1（主） | **东方财富** | eastmoney.com → 搜股票代码 → 财务报表 | 直接访问 |
| 2（副） | **巨潮资讯** | cninfo.com.cn | 原始年报/季报PDF |

### 台股（台积电2330、联发科2454、大立光3008等）

| 优先级 | 来源 | URL | 获取方式 |
|--------|------|-----|---------|
| 1（主） | **FinMind API** | api.finmindtrade.com | `~/share/code/ai-berkshire/tools/twstock_data.py`（零依赖脚本，见下） |
| 2（副） | **Goodinfo台湾股市资讯网** | goodinfo.tw/tw/StockDetail.asp?STOCK_ID={代码} | 直接访问 |
| 原始一手 | 公开资讯观测站（MOPS） | mops.twse.com.tw | 财报原文/月营收公告 |

**FinMind 取数工具**（分析台股时优先调用，输出自带市值验算）：

```bash
python3 ~/share/code/ai-berkshire/tools/twstock_data.py quote 2330        # 最新行情 + PER/PBR/殖利率 + 市值验算
python3 ~/share/code/ai-berkshire/tools/twstock_data.py valuation 2330    # 估值指标 + PER一年区间 + 52周高低
python3 ~/share/code/ai-berkshire/tools/twstock_data.py financials 2330   # 近5年年度核心财务（营收/毛利率/归母净利/EPS/ROE）
python3 ~/share/code/ai-berkshire/tools/twstock_data.py revenue 2330      # 近13个月月营收及同比
python3 ~/share/code/ai-berkshire/tools/twstock_data.py dividend 2330     # 近年股利政策（现金/股票股利、除息日）
python3 ~/share/code/ai-berkshire/tools/twstock_data.py search 台積        # 搜索股票代码（注意台股名称为繁体）
```

台股特别注意：

1. **货币单位是新台币（TWD）**，与港币/人民币/美元混排时必须显式标注，跨市场对比先统一换算
2. **月营收是台股独有优势**：上市柜公司每月10日前强制披露上月营收，是跟踪基本面拐点最快的公开信号，earnings-review/thesis-tracker 类分析应优先利用（`revenue` 子命令）
3. FinMind 损益表为**单季值**，工具已自动加总为年度值；不足4季的年份会标注"仅前N季累计"
4. FinMind 未注册可直接用（有小时级限额）。注册后的 API token **只存本机、严禁提交到 git**，工具按优先级自动读取：①环境变量 `FINMIND_TOKEN`；②本地文件 `local/finmind_token.txt`（`local/` 已被 `.gitignore` 永久排除，把 token 单独一行写入该文件即可）。token 不得出现在报告、skill、commit 中
5. 交叉验证：FinMind 数值与 Goodinfo（或 macrotrends 上的 ADR，如 TSM）对照，误差规则同下；台积电等有 ADR 的公司注意 ADR 与台股原股的汇率/存托比率差异（1 TSM ADR = 5 股 2330）

---

## 执行规范

### 第一步：获取数据

对每个财务指标（收入、净利润、毛利率、经营现金流、资产负债率等），分别从**来源1**和**来源2**取数。

### 第二步：误差计算与标记

```
误差率 = |来源1数值 - 来源2数值| / 来源1数值 × 100%
```

| 误差 | 处理方式 |
|------|---------|
| ≤ 1% | ✅ 一致，取来源1数值，标注两个来源 |
| 1% ~ 5% | ⚠️ 标记"数据存在差异"，注明两个数值，说明可能原因（汇率/会计口径） |
| > 5% | ❌ 标记"数据存在重大差异"，必须查原始财报核实，不得直接使用 |

### 第三步：数据呈现格式

每个关键数据必须按以下格式标注：

```
收入：1,239亿元 ✅
  - macrotrends: 1,241亿元
  - stockanalysis: 1,237亿元
  - 误差: 0.3%
```

差异示例：
```
净利润：245亿元 ⚠️ 数据存在差异
  - macrotrends: 245亿元（GAAP）
  - stockanalysis: 278亿元（Non-GAAP）
  - 误差: 13.5% — 原因：会计口径不同（GAAP vs Non-GAAP）
```

---

## 常见差异原因（不一定是数据错误）

| 原因 | 说明 |
|------|------|
| GAAP vs Non-GAAP | 最常见，尤其是利润类数据 |
| 汇率换算 | 港币/人民币/美元换算时间点不同 |
| 财年定义 | 自然年 vs 财年（如苹果财年10月结束） |
| 合并口径 | 是否含少数股东权益 |
| 数据更新滞后 | 某平台尚未更新最新一期财报 |

---

## 特别规则

1. **未上市公司**（米哈游、莉莉丝等）：只有一手数据来源时，数据前标记 `[估计]`，不执行交叉验证
2. **季度数据 vs 年度数据**：优先使用年度数据做交叉验证，季度数据部分来源可能有滞后
3. **原始财报优先**：若两个来源均与原始财报（10-K/年报PDF）不符，以原始财报为准，标记来源错误

---

## 股价与复权（历史序列必读）

价格有三种口径，混用会让历史股价位置、长期涨幅、历史估值分位全部失真：

| 口径 | 含义 | 用途 |
|------|------|------|
| 不复权 | 实际成交价，除权除息日跳空 | 仅用于"当前时点"快照 |
| 前复权 | 以最新价为基准回调历史价 | 历史股价对比、N年涨幅、历史PE band 一律用它 |
| 后复权 | 以上市首日为基准前推 | 计算历史总回报/年化收益 |

规则：

1. 涉及历史价格的分析统一用**前复权**，且同一分析内**不得混用**复权与不复权来源。
2. 当前市值/当前PE 用**当前实际股价 × 当前总股本**即可，与复权无关——复权只影响历史序列。
3. 跨越拆股/大比例送转的每股指标（历史EPS、历史股价），必须复权还原后再同比。
4. 总回报/年化收益需计入分红（后复权已含），只看价格涨幅会低估。
5. 增发/回购后市值验算以最新总股本为准（`~/share/code/ai-berkshire/tools/financial_rigor.py verify-market-cap` 偏差>5% 会提示核对）。

---

## 数据获取技巧

### 东方财富 API 端点速查

当 web_search/web_extract 不可用时，用 curl 直接调东方财富 API：

**实时行情**：
```bash
curl -s "https://push2.eastmoney.com/api/qt/stock/get?secid=0.002714&fields=f12,f58,f43,f44,f45,f46,f47,f48,f57,f58,f60,f116,f117,f162,f167,f168,f169,f170,f171,f176,f177,f183,f184,f185,f186,f188,f190" | python3 -m json.tool
```
**⚠️ push2 字段映射陷阱（f169/f170/f171 不可靠）**：
| 字段 | 文档中声称 | 实测结果 |
|------|-----------|---------|
| f169 | 市净率 /100 | **实测数值严重偏离，不应使用** |
| f170 | ROE /100 | **实测数值严重偏离，不应使用** |
| f171 | 毛利率 /100 | **实测数值严重偏离，不应使用** |
> **原因**：push2 对这些字段的数值格式不统一（有的直接是元、有的是百分比、有的是整数/100后的值），且不同股票格式不同。**不要用 push2 获取任何百分比/比率数据**。
> **替代方案**：所有财务指标（毛利率、净利率、ROE、负债率等）从 MAINFINADATA 端点获取（见下方）。push2 只用来获取：股价、市值、PE。
> 如果 push2 返回空数据（网络超时/连接被重置），不要反复重试——可能被临时风控，等几分钟再试或用 MAINFINADATA 替代。

**历史财务数据**（主力端点）：
```bash
curl -s "https://datacenter.eastmoney.com/securities/api/data/v1/get?reportName=RPT_F10_FINANCE_MAINFINADATA&columns=SECURITY_CODE,REPORT_DATE,REPORT_TYPE,TOTALOPERATEREVE,MLR,PARENTNETPROFIT,EPSJB,BPS,XSMLL,XSJLL,ROEJQ,ZCFZL&filter=(SECURITY_CODE=%22002714%22)&pageNumber=1&pageSize=15&sortColumns=REPORT_DATE&sortTypes=-1"
```
- `reportName` 必须是 `RPT_F10_FINANCE_MAINFINADATA`（其他名称会返回 9501 错误）
- 字段名必须用 CAPITALS（如 `TOTALOPERATEREVE`），小写字段名也会返回 9501
- 如果某个字段名不存在，整条请求失败 → 先列所有字段再筛选

**公司概况（管理层、简介、历史）**：
```bash
curl -s "https://emweb.securities.eastmoney.com/PC_HSF10/CompanySurvey/CompanySurveyAjax?code=SZ{6位代码}"
```
返回 JSON 含 `jbzl` 对象：gsmc(公司名称), agjc(股票简称), zjl(总经理), frdb(法人代表), dsz(董事长), dm(董秘), gsjj(公司简介), zczb(注册资本), gyrs(雇员人数), bgdz(办公地址)。以及 `fxxg` 对象：ssrq(上市日期), fxfs(发行方式), mgfxj(每股发行价)等。

**前十大股东**：
```bash
curl -s "https://datacenter.eastmoney.com/securities/api/data/v1/get?reportName=RPT_F10_EH_HOLDERS&columns=SECUCODE,HOLDER_NAME,HOLD_NUM,HOLD_NUM_RATIO,HOLDER_RANK,SHARES_TYPE,HOLD_NUM_CHANGE,END_DATE&filter=%28SECUCODE%3D%22{CODE}.SZ%22%29&pageNumber=1&pageSize=10&sortColumns=END_DATE,HOLDER_RANK&sortTypes=-1,1"
```
返回按 `HOLDER_RANK` 排序的前10大股东。注意结果含多期数据，按一期内的排名去重。`HOLD_NUM_CHANGE` 注明增减变化（"不变"/"加仓"/"新进"/数字股数）。
```bash
curl -s "https://datacenter.eastmoney.com/securities/api/data/v1/get?reportName=RPT_F10_FINANCE_MAINFINADATA&columns=ALL&filter=(SECURITY_CODE=%22002714%22)&pageNumber=1&pageSize=5&sortColumns=REPORT_DATE&sortTypes=-1"
```
用 `columns=ALL` 可以查看所有可用字段，然后挑选需要的。

**注意**：
- `datacenter-web.eastmoney.com` 和 `datacenter.eastmoney.com` 是两个不同的端点，前者某些 reportName 不可用
- 部分字段如 FINANCE_EXPENSE、TOTALSHARES、YJZJ、XJJE 等在 MAINFINADATA 表中不存在，需要用其他端点获取或直接跳过
- 资产负债率 ZCFZL **格式不统一**：部分股票返回小数（如 0.5868=58.68%），部分直接返回百分比（如 28.04=28.04%）。取值后先判断范围再换算：若值 ≈ 0.5 左右则为小数需×100，若值 ≈ 50 左右则直接使用
- MLR 字段是**毛利额**（元，非百分比），需除以营收计算毛利率，不是直接可用的毛利率百分比
- ROEJQ 在 MAINFINADATA 中已为百分比形式（如 6.46=6.46%），不需再 /100
- XSJLL（销售净利率）和 XSMLL（销售毛利率）已为百分比形式，直接使用

### 搜索/提取工具链不可用时的降级策略

当 web_search / web_extract 全部不可用时：
1. **优先使用 curl + 东方财富 API**（无需 credits，返回 JSON），专用于 A 股财务数据
2. **其次使用 Bing CN 搜索**：搜索走 `web.search_backend: bing-cn`，国内可达，无需 API key。适合搜索行业新闻、竞争格局、产品信息等非财务数据。
3. **curl 百度新闻**：`curl -s "https://news.baidu.com/ns?word=关键词&tn=news"` 适合快速获取中文新闻标题。
4. 发现某工具连续失败就切换策略

### 数据字段取值注意

- 股价字段通常是整数形式（如 3599 表示 35.99 元），需要 /100
- 财务数据单位为元（如 29893668691.43 表示 298.94 亿元），需要 /1e8
- 百分比字段通常也是整数形式（如 517 表示 5.17%），需要 /100
- 总股本/流通股单位为"股"（如 127045 万 = 12.7 亿股），注意单位

### MAINFINADATA 字段实际含义速查

`RPT_F10_FINANCE_MAINFINADATA` 端点的关键字段及实际含义：

| 字段 | 含义 | 数值形式 | 处理方式 |
|------|------|---------|---------|
| `TOTALOPERATEREVE` | 营业总收入 | 元 | /1e8 转亿元 |
| `PARENTNETPROFIT` | 归母净利润 | 元 | /1e8 转亿元 |
| `KCFJCXSYJLR` | 扣非净利润 | 元 | /1e8 转亿元 |
| `MLR` | **毛利额**（非毛利率） | 元 | 需除以营收得毛利率，不是直接的百分比 |
| `XSMLL` | 销售毛利率 | **已为百分比** | 直接使用（如 72.05 = 72.05%） |
| `XSJLL` | 销售净利率 | **已为百分比** | 直接使用 |
| `ROEJQ` | 净资产收益率(加权) | **已为百分比** | 直接使用（如 6.46 = 6.46%） |
| `EPSJB` | 基本每股收益 | 元/股 | 直接使用 |
| `BPS` | 每股净资产 | 元/股 | 直接使用 |
| `ZCFZL` | 资产负债率 | **格式不统一** | 见下方验证技巧 |
| `NETCASH_OPERATE_PK` | 经营活动现金流净额 | 元 | /1e8 转亿元 |
| `NETCASH_INVEST_PK` | 投资活动现金流净额 | 元 | /1e8 转亿元 |
| `NETCASH_FINANCE_PK` | 筹资活动现金流净额 | 元 | /1e8 转亿元 |
| `MGJYXJJE` | 每股经营现金流 | 元/股 | 直接使用 |
| `TOTAL_SHARE` | 总股本 | 股 | /1e8 转亿股 |
| `A_FREE_SHARE` | 流通A股 | 股 | /1e8 转亿股 |
| `ZZCZZTS` | 总资产周转率(次) | 次数 | 直接使用 |
| `INTSTCOVRATE` | 利息保障倍数 | 倍数 | 直接使用 |

**ZCFZL 格式验证技巧**（取值后先判断范围再换算）：
```python
zcfzl = item.get('ZCFZL', 0)
# 如果值在 0~1 之间，说明是小数形式，需 ×100
# 如果值在 1~100 之间，说明已是百分比
zcfzl_pct = zcfzl * 100 if 0 < zcfzl < 1 else zcfzl
```

**columns=ALL 返回的额外有用字段**：
- `SECURITY_NAME_ABBR` — 股票简称（确认是否目标公司）
- `NOTICE_DATE` — 财报发布日期
- `TOTALOPERATEREVETZ` — 营收同比增长(%)
- `PARENTNETPROFITTZ` — 净利润同比增长(%)
- `DJD_TOI_QOQ` — 营收环比增长率(%)
- `DJD_DPNP_QOQ` — 净利润环比增长率(%)
- `TOTAL_ASSETS_PK` — 总资产（元）
- `TOTAL_EQUITY_PK` — 股东权益/净资产（元）
- `LIABILITY` — 总负债（元）
- `FCFF_FORWARD` — 企业自由现金流（元）

---

## 快速索引

| 场景 | 主要来源 | 备用来源 |
|------|---------|---------|
| PDD / 拼多多 | macrotrends.net/stocks/charts/PDD | stockanalysis.com/stocks/pdd |
| 腾讯 | macrotrends.net/stocks/charts/TCEHY | aastocks（0700.HK） |
| 网易 | macrotrends.net/stocks/charts/NTES | aastocks（9999.HK） |
| 三七互娱 | eastmoney.com（002555） | cninfo.com.cn |
| 吉比特 | eastmoney.com（603444） | cninfo.com.cn |
| Nintendo | macrotrends.net/stocks/charts/NTDOY | stockanalysis.com/stocks/ntdoy |
| Capcom | macrotrends（CCOEY） | stockanalysis（CCOEY） |
| 台积电 | tools/twstock_data.py（2330） | goodinfo.tw / macrotrends（TSM，注意1 ADR=5股） |
| 联发科 | tools/twstock_data.py（2454） | goodinfo.tw |

## IMA 知识库推送格式规范（用户偏好—经多次纠正确认）

推送到 IMA 知识库的文档表格按**第一版格式**，不要为手机体验修改：

1. **3 列固定**：数据类型 | 代表接口 | 数据源（或 数据类型 | 代表接口 | 说明）
2. **接口名保留完整参数签名**，如 `stock_zh_a_hist(symbol, period, start_date, end_date, adjust)`，不压缩不缩写
3. 对比表可以多列，正常保留
4. 文字内容走笔记中转：`save_ima_note.py` → `add_knowledge(media_type=11)`
5. 网页 URL 由用户自决，用 `import_urls` 直接进知识库

**参考文件**：此技能下 `references/akshare.md` 含 AKShare 接口速查
