# CP2 – Baseline Query Timings

## 1. Benchmark methodology

- Database: PostgreSQL (`netflix_db`, schema `netflix`).
- Workload: 30 supplied queries — 25 READ queries (`R01`–`R25`) and 5 WRITE queries (`W01`–`W05`).
- Each query was executed three times using the project benchmark script with `EXPLAIN (ANALYZE, BUFFERS)`.
- Run timings below are copied from the `Execution Time` line in each raw plan file. Average is the arithmetic mean of the three runs, rounded to three decimal places.
- WRITE queries were benchmarked using the script's transaction/rollback approach so the benchmark did not permanently modify the data.
- These are baseline measurements, before the Phase 4 indexes and query optimizations.

## 2. Timing results

| SQL Query | Type | Run 1 (ms) | Run 2 (ms) | Run 3 (ms) | Average (ms) |
|---|:---:|---:|---:|---:|---:|
| **R01**: "Continue Watching" row: latest unfinished viewing per title for profile 7043 | READ | 11.856 | 9.900 | 9.751 | **10.502** |
| **R02**: Title page: seasons of series 2909 with the number of episodes in each | READ | 0.069 | 0.061 | 0.068 | **0.066** |
| **R03**: "Top 10 in India today" row: most-watched titles on 30 June 2026 | READ | 9.156 | 9.124 | 8.994 | **9.091** |
| **R04**: Genre row for a kids profile: Comedy titles rated U or UA7, newest additions first | READ | 1.132 | 1.132 | 1.164 | **1.143** |
| **R05**: Search: titles whose name contains "love" | READ | 2.256 | 2.293 | 2.393 | **2.314** |
| **R06**: "My List" row for profile 7393 | READ | 0.108 | 0.111 | 0.109 | **0.109** |
| **R07**: Autoplay: next episode of series 2909 after season 1 episode 4 | READ | 0.040 | 0.037 | 0.037 | **0.038** |
| **R08**: Insights: binge sessions in June 2026 (3+ episodes of one series by one profile on one day) | READ | 14.502 | 14.636 | 15.293 | **14.810** |
| **R09**: Content analytics: completion rate per genre (2026) | READ | 47.722 | 47.389 | 47.869 | **47.660** |
| **R10**: Sign-in: find the account by email, ignoring case | READ | 10.011 | 9.620 | 9.662 | **9.764** |
| **R11**: Payments: active accounts whose June 2026 invoice failed (retry list) | READ | 12.145 | 12.397 | 12.327 | **12.290** |
| **R12**: Retention: cancellations per month in 2026 and average tenure (days) | READ | 2.569 | 2.662 | 2.820 | **2.684** |
| **R13**: Content team: episodes of series 2523 that nobody has watched | READ | 32.769 | 32.635 | 32.002 | **32.469** |
| **R14**: Compliance: kids profiles that watched titles above their maturity limit | READ | 37.855 | 38.224 | 39.535 | **38.538** |
| **R15**: Finance: active accounts and monthly recurring revenue per plan | READ | 8.019 | 7.954 | 8.069 | **8.014** |
| **R16**: Account sharing check: accounts with more profiles watching in the same hour than their plan's streams | READ | 236.593 | 238.591 | 236.475 | **237.220** |
| **R17**: Content strategy: share of "LOVE" ratings for Netflix Originals vs licensed titles | READ | 9.739 | 10.060 | 10.055 | **9.951** |
| **R18**: Device analytics: viewing hours per device per month in 2026 | READ | 46.247 | 46.532 | 46.307 | **46.362** |
| **R19**: Originals report: total views and most recent view of every Netflix Original | READ | 11311.037 | 11220.890 | 11253.548 | **11261.825** |
| **R20**: Marketing: 10 titles added to the most My Lists in June 2026 | READ | 4.982 | 4.963 | 5.242 | **5.062** |
| **R21**: Payments: accounts on hold whose billing date has already passed | READ | 2.185 | 2.261 | 2.299 | **2.248** |
| **R22**: "Last chance to watch" row: licensed titles leaving in July 2026 | READ | 0.295 | 0.298 | 0.289 | **0.294** |
| **R23**: Support console: all viewing activity, newest first, page 6,001 (25 per page) | READ | 72.148 | 73.571 | 76.685 | **74.135** |
| **R24**: "Who’s watching?" screen: profiles of account 1409 | READ | 3.220 | 3.296 | 3.237 | **3.251** |
| **R25**: "More like this": titles sharing at least 2 genres with series 2909 | READ | 1.243 | 1.229 | 1.218 | **1.230** |
| **W01**: Player: profile 7043 starts episode S1E5 of series 2909 | WRITE | 0.947 | 0.755 | 0.742 | **0.815** |
| **W02**: "+ My List": profile 7043 adds series 2523 | WRITE | 0.942 | 0.804 | 0.757 | **0.834** |
| **W03**: Account settings: account 1409 downgrades to the STANDARD plan | WRITE | 0.542 | 0.390 | 0.379 | **0.437** |
| **W04**: Monthly billing run: create July 2026 invoices for every active account | WRITE | 219.563 | 175.531 | 171.953 | **189.016** |
| **W05**: Dunning: put active accounts whose latest invoice failed on hold | WRITE | 21.898 | 19.098 | 19.928 | **20.308** |
| **Total (sum of all 30 queries)** | — | **12121.790** | **11986.444** | **12019.207** | **12042.480** |

## 3. Execution-plan scan types and performance observations

The scan types below are taken from `scan_nodes` in `benchmarks/results/baseline/summary.csv`, which is derived from the raw execution plans. Where a plan uses more than one scan type, all reported scan nodes are listed. The explanation is specific to the workload and observed plan; it describes the likely source of the measured cost, not a claim that every sequential scan is inherently inefficient.

### R01 — "Continue Watching" row: latest unfinished viewing per title for profile 7043
- **Type:** READ  
- **Scan type(s):** `Seq Scan on viewing_activity | Index Scan using titles_pkey on titles`  
- **Why this is slow/fast:** A parallel sequential scan filters the 200k-row viewing_activity table by profile and completion status; only a tiny result survives, so many rows are examined.

### R02 — Title page: seasons of series 2909 with the number of episodes in each
- **Type:** READ  
- **Scan type(s):** `Index Scan using uq_episode_position on episodes`  
- **Why this is slow/fast:** A selective lookup uses the unique episode-position index, avoiding a scan of the full episodes table.

### R03 — "Top 10 in India today" row: most-watched titles on 30 June 2026
- **Type:** READ  
- **Scan type(s):** `Seq Scan on viewing_activity | Index Scan using titles_pkey on titles`  
- **Why this is slow/fast:** The plan scans viewing_activity to find the target-day plays, then uses the titles primary-key index for title details; the activity scan dominates.

### R04 — Genre row for a kids profile: Comedy titles rated U or UA7, newest additions first
- **Type:** READ  
- **Scan type(s):** `Seq Scan on titles | Seq Scan on title_genres | Seq Scan on genres`  
- **Why this is slow/fast:** Sequential scans are used on the small titles, title_genres and genres tables; for these small relations, scanning all rows is inexpensive.

### R05 — Search: titles whose name contains "love"
- **Type:** READ  
- **Scan type(s):** `Seq Scan on titles`  
- **Why this is slow/fast:** A sequential scan checks title names for a contains-text match; without a suitable text-search index, the catalogue rows must be inspected.

### R06 — "My List" row for profile 7393
- **Type:** READ  
- **Scan type(s):** `Index Scan using my_list_pkey on my_list | Index Scan using titles_pkey on titles`  
- **Why this is slow/fast:** Primary-key index lookups on my_list and titles locate the profile's saved titles and their details directly.

### R07 — Autoplay: next episode of series 2909 after season 1 episode 4
- **Type:** READ  
- **Scan type(s):** `Index Scan using uq_episode_position on episodes`  
- **Why this is slow/fast:** The unique episode-position index finds the next episode without scanning the complete episodes table.

### R08 — Insights: binge sessions in June 2026 (3+ episodes of one series by one profile on one day)
- **Type:** READ  
- **Scan type(s):** `Seq Scan on viewing_activity`  
- **Why this is slow/fast:** A sequential scan reads viewing_activity to group/filter plays into binge sessions; processing a large activity set drives the cost.

### R09 — Content analytics: completion rate per genre (2026)
- **Type:** READ  
- **Scan type(s):** `Seq Scan on viewing_activity | Seq Scan on title_genres | Seq Scan on genres`  
- **Why this is slow/fast:** Sequential scans of viewing_activity, title_genres and genres feed a multi-table aggregation for completion rates; the large activity relation is the main cost.

### R10 — Sign-in: find the account by email, ignoring case
- **Type:** READ  
- **Scan type(s):** `Seq Scan on accounts`  
- **Why this is slow/fast:** A sequential scan checks accounts for a case-insensitive email match; the current plan does not use an index on the email expression.

### R11 — Payments: active accounts whose June 2026 invoice failed (retry list)
- **Type:** READ  
- **Scan type(s):** `Seq Scan on accounts | Seq Scan on invoices`  
- **Why this is slow/fast:** Sequential scans of accounts and invoices are used to match active accounts with failed June invoices; both relations are read broadly.

### R12 — Retention: cancellations per month in 2026 and average tenure (days)
- **Type:** READ  
- **Scan type(s):** `Seq Scan on accounts`  
- **Why this is slow/fast:** The accounts sequential scan supports filtering and grouping cancellations by month and calculating tenure across the account population.

### R13 — Content team: episodes of series 2523 that nobody has watched
- **Type:** READ  
- **Scan type(s):** `Index Scan using uq_episode_position on episodes | Seq Scan on viewing_activity`  
- **Why this is slow/fast:** The episode-position index locates the series episodes, but a sequential scan of viewing_activity is needed to determine which episodes have no matching views.

### R14 — Compliance: kids profiles that watched titles above their maturity limit
- **Type:** READ  
- **Scan type(s):** `Seq Scan on viewing_activity | Seq Scan on profiles | Seq Scan on titles`  
- **Why this is slow/fast:** Sequential scans of viewing_activity, profiles and titles are combined to evaluate kids-profile viewing against title maturity limits; the broad activity scan is costly.

### R15 — Finance: active accounts and monthly recurring revenue per plan
- **Type:** READ  
- **Scan type(s):** `Seq Scan on accounts | Seq Scan on plans`  
- **Why this is slow/fast:** Sequential scans of accounts and plans support the active-account grouping and revenue calculation by plan; the tables are read broadly.

### R16 — Account sharing check: accounts with more profiles watching in the same hour than their plan's streams
- **Type:** READ  
- **Scan type(s):** `Seq Scan on viewing_activity | Seq Scan on profiles | Seq Scan on accounts | Seq Scan on plans`  
- **Why this is slow/fast:** Sequential scans across viewing_activity, profiles, accounts and plans feed the same-hour profile/stream-count aggregation; joining and grouping a large activity set makes this one of the slower reads.

### R17 — Content strategy: share of "LOVE" ratings for Netflix Originals vs licensed titles
- **Type:** READ  
- **Scan type(s):** `Seq Scan on ratings | Seq Scan on titles`  
- **Why this is slow/fast:** Sequential scans of ratings and titles support joining ratings to title originality and aggregating LOVE shares; the ratings relation is read broadly.

### R18 — Device analytics: viewing hours per device per month in 2026
- **Type:** READ  
- **Scan type(s):** `Seq Scan on viewing_activity`  
- **Why this is slow/fast:** A sequential scan of viewing_activity processes the 2026 records before grouping viewing duration by device and month.

### R19 — Originals report: total views and most recent view of every Netflix Original
- **Type:** READ  
- **Scan type(s):** `Seq Scan on titles | Seq Scan on viewing_activity`  
- **Why this is slow/fast:** Sequential scans of titles and viewing_activity support the Originals report and its view aggregation; the large activity scan and aggregation dominate the exceptionally high runtime.

### R20 — Marketing: 10 titles added to the most My Lists in June 2026
- **Type:** READ  
- **Scan type(s):** `Seq Scan on my_list | Seq Scan on titles`  
- **Why this is slow/fast:** Sequential scans of my_list and titles support the June additions aggregation and title lookup; my_list is read broadly before ranking the top 10.

### R21 — Payments: accounts on hold whose billing date has already passed
- **Type:** READ  
- **Scan type(s):** `Seq Scan on accounts`  
- **Why this is slow/fast:** A sequential scan of accounts checks on-hold status and billing dates; this is inexpensive on the current account table size.

### R22 — "Last chance to watch" row: licensed titles leaving in July 2026
- **Type:** READ  
- **Scan type(s):** `Seq Scan on titles`  
- **Why this is slow/fast:** A sequential scan of titles filters licensed titles by leaving date; the catalogue is small, so this full scan remains inexpensive.

### R23 — Support console: all viewing activity, newest first, page 6,001 (25 per page)
- **Type:** READ  
- **Scan type(s):** `Seq Scan on viewing_activity`  
- **Why this is slow/fast:** A sequential scan reads viewing_activity for a very deep OFFSET page, requiring broad row processing and sorting/ordering rather than a direct keyset lookup.

### R24 — "Who’s watching?" screen: profiles of account 1409
- **Type:** READ  
- **Scan type(s):** `Seq Scan on profiles`  
- **Why this is slow/fast:** A sequential scan of profiles finds the profiles belonging to account 1409; the current profiles table is small enough for this to remain quick.

### R25 — "More like this": titles sharing at least 2 genres with series 2909
- **Type:** READ  
- **Scan type(s):** `Seq Scan on title_genres | Index Only Scan using title_genres_pkey on title_genres`  
- **Why this is slow/fast:** The plan scans title_genres and uses the title_genres primary-key index for the reference title's genre mapping; the small relation keeps the operation fast.

### W01 — Player: profile 7043 starts episode S1E5 of series 2909
- **Type:** WRITE  
- **Scan type(s):** `Index Scan using uq_episode_position on episodes`  
- **Why this is slow/fast:** The unique episode-position index locates the target episode; the write itself is a small, selective operation.

### W02 — "+ My List": profile 7043 adds series 2523
- **Type:** WRITE  
- **Scan type(s):** `(no scan)`  
- **Why this is slow/fast:** The plan reports no scan node: this is a direct insert into my_list, so there is no table scan in the recorded execution plan.

### W03 — Account settings: account 1409 downgrades to the STANDARD plan
- **Type:** WRITE  
- **Scan type(s):** `Seq Scan on plans | Index Scan using accounts_pkey on accounts`  
- **Why this is slow/fast:** A sequential scan finds the STANDARD plan, while the accounts primary-key index locates account 1409 for the update.

### W04 — Monthly billing run: create July 2026 invoices for every active account
- **Type:** WRITE  
- **Scan type(s):** `Seq Scan on accounts | Seq Scan on plans`  
- **Why this is slow/fast:** Sequential scans of accounts and plans support selecting active accounts and their plan prices before inserting July invoices for the account population.

### W05 — Dunning: put active accounts whose latest invoice failed on hold
- **Type:** WRITE  
- **Scan type(s):** `Seq Scan on accounts | Seq Scan on invoices`  
- **Why this is slow/fast:** Sequential scans of accounts and invoices identify active accounts with a failed latest invoice; broad matching across invoices drives the write cost.

## 4. Baseline highlights

- **Slowest query:** R19 at **11,261.825 ms** average. Its plan sequentially scans `titles` and `viewing_activity`; aggregating viewing records for the Originals report is the dominant workload.
- **Next notable read:** R16 at **237.220 ms** average, with sequential scans across viewing_activity, profiles, accounts and plans for the account-sharing aggregation.
- **Deep-pagination query:** R23 averages **74.135 ms** and sequentially scans viewing_activity for page 6,001.
- **Slowest write:** W04 at **189.016 ms** average, scanning accounts and plans to prepare invoices for active accounts.
- Selective indexed lookups such as R02, R06 and R07 are among the fastest operations in this baseline.

## 5. Baseline artifacts

- `benchmarks/results/baseline/summary.csv` — generated summary of averages, medians, minimums, maximums and scan nodes.
- `benchmarks/results/baseline/R01.txt` through `R25.txt`, and `W01.txt` through `W05.txt` — raw `EXPLAIN (ANALYZE, BUFFERS)` plans containing all three runs for each query.

**Note:** Keep the raw plan files and `summary.csv` in the repository. In Phase 4, compare optimized timings against these baseline averages using the same machine and benchmark method.
