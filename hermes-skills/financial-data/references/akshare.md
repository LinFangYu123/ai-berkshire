# AKShare 接口速查

安装：`pip install akshare --upgrade` | 国内：`-i https://pypi.tuna.tsinghua.edu.cn/simple`

## 已验证的核心接口（本项目使用经验）

### 指数
| 数据 | 接口 |
|------|------|
| 四大指数（上证/深证/沪深300等） | `ak.stock_zh_index_spot_sina()` |
| 美股三大指数 | `ak.index_us_stock_sina(".INX"/".IXIC"/".DJI")` |
| 港股指数 | `ak.stock_hk_index_spot_sina()` |
| 上证红利/上国红利/恒生 | `ak.stock_zh_index_spot_sina()` |
| 中证系列（含end_date参数） | `ak.index_stock_cons_csindex(代码)` |
| 全球56指数 | `ak.index_global_spot_em()` |

### 板块与新闻
| 数据 | 接口 |
|------|------|
| 板块涨跌幅+主力净流入 | `ak.board_change_em()` |
| 财经快讯 | `ak.info_global_em()` |

### A股
| 数据 | 接口 |
|------|------|
| 全部实时行情 | `ak.stock_zh_a_spot_em()` |
| 历史行情 | `ak.stock_zh_a_hist(代码, 周期, 起止日, 复权)` |
| 个股信息 | `ak.stock_individual_info_em(代码)` |

### 其他数据
- **期货**：六大交易所（CFFEX/SHFE/INE/CZCE/DCE/GFEX），基差用 `futures_spot_price(日期)`
- **期权**：金融+商品期权，风险指标含希腊字母，隐含波动率
- **宏观**：杠杆率 `macro_cnbs()`，CPI/PPI/GDP/PMI/LPR/M2，多国宏观系列

## 数据源偏好

新浪源（`*_sina()`）速度快但字段少；东方财富源（`*_em()`）字段全但稍慢。展期收益率需收盘后运行。各期货交易所会员持仓公布方式不同。

详见 AKShare 官方文档：https://akshare.akfamily.xyz/
