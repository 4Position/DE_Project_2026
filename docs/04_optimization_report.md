# Phase 4: Query Optimization Report

## 1. Benchmark methodology

Baseline and optimized timings are taken from the respective `summary.csv` files. The baseline benchmark used 3 runs per query. The optimized benchmark used 5 iterations per query. Both summary files report average execution time. Raw plans are retained in `benchmarks/results/baseline/` and `benchmarks/results/optimized/`.

Improvement (%) = (Before − After) / Before × 100.

## 2. Optimization table

| Query | Before (ms) | Problem found in the plan | Optimization applied | After (ms) | Improvement | Same result? |
|---|---:|---|---|---:|---:|---|
| R01 | 10.502 | Seq Scan on viewing_activity ; Index Scan using titles_pkey on titles | Partial covering index: idx_va_unfinished_profile_title_time | 0.195 | 98.14% | Yes — original SQL unchanged; indexes do not change query semantics |
| R02 | 0.066 | Index Scan using uq_episode_position on episodes | No new index; existing uq_episode_position index is used | 0.117 | -77.27% | Yes — original SQL unchanged; indexes do not change query semantics |
| R03 | 9.091 | Seq Scan on viewing_activity ; Index Scan using titles_pkey on titles | Covering index: idx_va_started_desc_cover | 1.017 | 88.81% | Yes — original SQL unchanged; indexes do not change query semantics |
| R04 | 1.143 | Seq Scan on titles ; Seq Scan on title_genres ; Seq Scan on genres | Composite index: idx_title_genres_genre_title | 0.693 | 39.37% | Yes — original SQL unchanged; indexes do not change query semantics |
| R05 | 2.314 | Seq Scan on titles | GIN trigram index: idx_titles_name_trgm | 0.369 | 84.05% | Yes — original SQL unchanged; indexes do not change query semantics |
| R06 | 0.109 | Index Scan using my_list_pkey on my_list ; Index Scan using titles_pkey on titles | No dedicated new index; existing indexes used by planner | 0.288 | -164.22% | Yes — original SQL unchanged; indexes do not change query semantics |
| R07 | 0.038 | Index Scan using uq_episode_position on episodes | No new index; existing uq_episode_position index is used | 0.037 | 2.63% | Yes — original SQL unchanged; indexes do not change query semantics |
| R08 | 14.810 | Seq Scan on viewing_activity | No dedicated new index; date filtering and aggregation remain | 3.319 | 77.59% | Yes — original SQL unchanged; indexes do not change query semantics |
| R09 | 47.660 | Seq Scan on viewing_activity ; Seq Scan on title_genres ; Seq Scan on genres | Replaced EXTRACT(YEAR) with timestamp range predicate | 26.017 | 45.41% | Yes — EXCEPT ALL comparison in both directions returned 0 rows |
| R10 | 9.764 | Seq Scan on accounts | Expression index: idx_accounts_lower_email | 0.138 | 98.59% | Yes — original SQL unchanged; indexes do not change query semantics |
| R11 | 12.290 | Seq Scan on accounts ; Seq Scan on invoices | Partial covering index: idx_invoices_failed_period_account | 5.805 | 52.77% | Yes — original SQL unchanged; indexes do not change query semantics |
| R12 | 2.684 | Seq Scan on accounts | Replaced EXTRACT(YEAR) with date range predicate | 2.236 | 16.69% | Yes — EXCEPT ALL comparison in both directions returned 0 rows |
| R13 | 32.469 | Index Scan using uq_episode_position on episodes ; Seq Scan on viewing_activity | Replaced NULL-sensitive NOT IN with correlated NOT EXISTS | 18.630 | 42.62% | Corrected — original NOT IN was affected by NULL values |
| R14 | 38.538 | Seq Scan on viewing_activity ; Seq Scan on profiles ; Seq Scan on titles | No dedicated new index; joins and maturity comparison remain | 39.780 | -3.22% | Yes — original SQL unchanged; indexes do not change query semantics |
| R15 | 8.014 | Seq Scan on accounts ; Seq Scan on plans | No dedicated new index; aggregation across active accounts remains | 8.080 | -0.82% | Yes — original SQL unchanged; indexes do not change query semantics |
| R16 | 237.220 | Seq Scan on viewing_activity ; Seq Scan on profiles ; Seq Scan on accounts ; Seq Scan on plans | No dedicated new index; multi-table aggregation remains | 241.419 | -1.77% | Yes — original SQL unchanged; indexes do not change query semantics |
| R17 | 9.951 | Seq Scan on ratings ; Seq Scan on titles | No dedicated new index; aggregation across ratings remains | 10.994 | -10.48% | Yes — original SQL unchanged; indexes do not change query semantics |
| R18 | 46.362 | Seq Scan on viewing_activity | Replaced date cast predicate with timestamp range predicate | 33.706 | 27.30% | Yes — EXCEPT ALL comparison in both directions returned 0 rows |
| R19 | 11,261.825 | Seq Scan on titles ; Seq Scan on viewing_activity | Replaced correlated subqueries with one grouped aggregate and LEFT JOIN; planner used a single Seq Scan and HashAggregate. | 36.677 | 99.67% | Yes — EXCEPT ALL comparison in both directions returned 0 rows |
| R20 | 5.062 | Seq Scan on my_list ; Seq Scan on titles | No dedicated new index; existing indexes used by planner | 4.945 | 2.31% | Yes — original SQL unchanged; indexes do not change query semantics |
| R21 | 2.248 | Seq Scan on accounts | Partial index: idx_accounts_hold_billing_date | 0.668 | 70.28% | Yes — original SQL unchanged; indexes do not change query semantics |
| R22 | 0.294 | Seq Scan on titles | Partial index: idx_titles_leaving_on | 0.134 | 54.42% | Yes — original SQL unchanged; indexes do not change query semantics |
| R23 | 74.135 | Seq Scan on viewing_activity | Covering index: idx_va_started_desc_cover | 18.901 | 74.50% | Yes — original SQL unchanged; indexes do not change query semantics |
| R24 | 3.251 | Seq Scan on profiles | Covering composite index: idx_profiles_account_created | 0.121 | 96.28% | Yes — original SQL unchanged; indexes do not change query semantics |
| R25 | 1.230 | Seq Scan on title_genres ; Index Only Scan using title_genres_pkey on title_genres | Composite index: idx_title_genres_genre_title | 0.956 | 22.28% | Yes — original SQL unchanged; indexes do not change query semantics |
| W01 | 0.815 | Index Scan using uq_episode_position on episodes | No dedicated rewrite or new index | 1.423 | -74.60% | Yes — original SQL unchanged; indexes do not change query semantics |
| W02 | 0.834 | (no scan) | No dedicated rewrite or new index | 1.056 | -26.62% | Yes — original SQL unchanged; indexes do not change query semantics |
| W03 | 0.437 | Seq Scan on plans ; Index Scan using accounts_pkey on accounts | No dedicated rewrite or new index | 0.879 | -101.14% | Yes — original SQL unchanged; indexes do not change query semantics |
| W04 | 189.016 | Seq Scan on accounts ; Seq Scan on plans | No dedicated rewrite or new index | 171.705 | 9.16% | Yes — original SQL unchanged; indexes do not change query semantics |
| W05 | 20.308 | Seq Scan on accounts ; Seq Scan on invoices | No dedicated rewrite or new index | 20.714 | -2.00% | Yes — original SQL unchanged; indexes do not change query semantics |
| **Total** | **12,042.480** | | | **651.019** | **94.59%** | |

The total row is only the sum of the 30 per-query average timings. It is not a directly measured end-to-end workload runtime or a workload-level speedup.

## 3. Before/after EXPLAIN plans for the five biggest improvements

The five queries below are selected by their measured percentage improvement. The following are the actual raw plan files generated by the benchmark.

### R19 — 99.67% improvement

Before: 11,261.825 ms; After: 36.677 ms.

**Baseline EXPLAIN:**

```text
=== R19 run 1 ===
Sort  (cost=5008426.02..5008427.55 rows=610 width=45) (actual time=11310.452..11310.480 rows=610.00 loops=1)
  Sort Key: ((SubPlan 1)) DESC
  Sort Method: quicksort  Memory: 63kB
  Buffers: shared hit=1952039
  ->  Seq Scan on titles t  (cost=0.00..5008397.80 rows=610 width=45) (actual time=19.730..11310.087 rows=610.00 loops=1)
        Filter: is_netflix_original
        Rows Removed by Filter: 2390
        Buffers: shared hit=1952036
        SubPlan 1
          ->  Aggregate  (cost=4105.18..4105.19 rows=1 width=8) (actual time=9.304..9.304 rows=1.00 loops=610)
                Buffers: shared hit=976000
                ->  Seq Scan on viewing_activity v  (cost=0.00..4105.01 rows=67 width=0) (actual time=1.332..9.298 rows=65.25 loops=610)
                      Filter: (title_id = t.title_id)
                      Rows Removed by Filter: 200336
                      Buffers: shared hit=976000
        SubPlan 2
          ->  Aggregate  (cost=4105.18..4105.19 rows=1 width=8) (actual time=9.235..9.235 rows=1.00 loops=610)
                Buffers: shared hit=976000
                ->  Seq Scan on viewing_activity v_1  (cost=0.00..4105.01 rows=67 width=8) (actual time=1.323..9.228 rows=65.25 loops=610)
                      Filter: (title_id = t.title_id)
                      Rows Removed by Filter: 200336
                      Buffers: shared hit=976000
Planning:
  Buffers: shared hit=126
Planning Time: 0.487 ms
Execution Time: 11311.037 ms
=== R19 run 2 ===
Sort  (cost=5008426.02..5008427.55 rows=610 width=45) (actual time=11220.762..11220.799 rows=610.00 loops=1)
  Sort Key: ((SubPlan 1)) DESC
  Sort Method: quicksort  Memory: 63kB
  Buffers: shared hit=1952039
  ->  Seq Scan on titles t  (cost=0.00..5008397.80 rows=610 width=45) (actual time=19.985..11220.427 rows=610.00 loops=1)
        Filter: is_netflix_original
        Rows Removed by Filter: 2390
        Buffers: shared hit=1952036
        SubPlan 1
          ->  Aggregate  (cost=4105.18..4105.19 rows=1 width=8) (actual time=9.207..9.207 rows=1.00 loops=610)
                Buffers: shared hit=976000
                ->  Seq Scan on viewing_activity v  (cost=0.00..4105.01 rows=67 width=0) (actual time=1.324..9.201 rows=65.25 loops=610)
                      Filter: (title_id = t.title_id)
                      Rows Removed by Filter: 200336
                      Buffers: shared hit=976000
        SubPlan 2
          ->  Aggregate  (cost=4105.18..4105.19 rows=1 width=8) (actual time=9.185..9.185 rows=1.00 loops=610)
                Buffers: shared hit=976000
                ->  Seq Scan on viewing_activity v_1  (cost=0.00..4105.01 rows=67 width=8) (actual time=1.347..9.178 rows=65.25 loops=610)
                      Filter: (title_id = t.title_id)
                      Rows Removed by Filter: 200336
                      Buffers: shared hit=976000
Planning:
  Buffers: shared hit=126
Planning Time: 0.513 ms
Execution Time: 11220.890 ms
=== R19 run 3 ===
Sort  (cost=5008426.02..5008427.55 rows=610 width=45) (actual time=11253.420..11253.450 rows=610.00 loops=1)
  Sort Key: ((SubPlan 1)) DESC
  Sort Method: quicksort  Memory: 63kB
  Buffers: shared hit=1952039
  ->  Seq Scan on titles t  (cost=0.00..5008397.80 rows=610 width=45) (actual time=20.813..11253.218 rows=610.00 loops=1)
        Filter: is_netflix_original
        Rows Removed by Filter: 2390
        Buffers: shared hit=1952036
        SubPlan 1
          ->  Aggregate  (cost=4105.18..4105.19 rows=1 width=8) (actual time=9.253..9.253 rows=1.00 loops=610)
                Buffers: shared hit=976000
                ->  Seq Scan on viewing_activity v  (cost=0.00..4105.01 rows=67 width=0) (actual time=1.330..9.247 rows=65.25 loops=610)
                      Filter: (title_id = t.title_id)
                      Rows Removed by Filter: 200336
                      Buffers: shared hit=976000
        SubPlan 2
          ->  Aggregate  (cost=4105.18..4105.19 rows=1 width=8) (actual time=9.193..9.193 rows=1.00 loops=610)
                Buffers: shared hit=976000
                ->  Seq Scan on viewing_activity v_1  (cost=0.00..4105.01 rows=67 width=8) (actual time=1.322..9.185 rows=65.25 loops=610)
                      Filter: (title_id = t.title_id)
                      Rows Removed by Filter: 200336
                      Buffers: shared hit=976000
Planning:
  Buffers: shared hit=126
Planning Time: 0.569 ms
Execution Time: 11253.548 ms
```

**Optimized EXPLAIN:**

```text
=== R19 run 1 ===
Sort  (cost=5276.25..5277.78 rows=610 width=45) (actual time=36.022..36.045 rows=610.00 loops=1)
  Sort Key: (COALESCE((count(*)), '0'::bigint)) DESC
  Sort Method: quicksort  Memory: 63kB
  Buffers: shared hit=1639
  ->  Hash Right Join  (cost=5180.64..5248.03 rows=610 width=45) (actual time=35.418..35.916 rows=610.00 loops=1)
        Hash Cond: (viewing_activity.title_id = t.title_id)
        Buffers: shared hit=1636
        ->  HashAggregate  (cost=5107.02..5136.80 rows=2978 width=20) (actual time=35.100..35.336 rows=3000.00 loops=1)
              Group Key: viewing_activity.title_id
              Batches: 1  Memory Usage: 345kB
              Buffers: shared hit=1600
              ->  Seq Scan on viewing_activity  (cost=0.00..3604.01 rows=200401 width=12) (actual time=0.003..8.949 rows=200401.00 loops=1)
                    Buffers: shared hit=1600
        ->  Hash  (cost=66.00..66.00 rows=610 width=29) (actual time=0.310..0.311 rows=610.00 loops=1)
              Buckets: 1024  Batches: 1  Memory Usage: 45kB
              Buffers: shared hit=36
              ->  Seq Scan on titles t  (cost=0.00..66.00 rows=610 width=29) (actual time=0.010..0.248 rows=610.00 loops=1)
                    Filter: is_netflix_original
                    Rows Removed by Filter: 2390
                    Buffers: shared hit=36
Planning:
  Buffers: shared hit=247
Planning Time: 0.810 ms
Execution Time: 36.131 ms
=== R19 run 2 ===
Sort  (cost=5276.25..5277.78 rows=610 width=45) (actual time=35.886..35.909 rows=610.00 loops=1)
  Sort Key: (COALESCE((count(*)), '0'::bigint)) DESC
  Sort Method: quicksort  Memory: 63kB
  Buffers: shared hit=1639
  ->  Hash Right Join  (cost=5180.64..5248.03 rows=610 width=45) (actual time=35.284..35.781 rows=610.00 loops=1)
        Hash Cond: (viewing_activity.title_id = t.title_id)
        Buffers: shared hit=1636
        ->  HashAggregate  (cost=5107.02..5136.80 rows=2978 width=20) (actual time=34.964..35.199 rows=3000.00 loops=1)
              Group Key: viewing_activity.title_id
              Batches: 1  Memory Usage: 345kB
              Buffers: shared hit=1600
              ->  Seq Scan on viewing_activity  (cost=0.00..3604.01 rows=200401 width=12) (actual time=0.002..8.881 rows=200401.00 loops=1)
                    Buffers: shared hit=1600
        ->  Hash  (cost=66.00..66.00 rows=610 width=29) (actual time=0.312..0.313 rows=610.00 loops=1)
              Buckets: 1024  Batches: 1  Memory Usage: 45kB
              Buffers: shared hit=36
              ->  Seq Scan on titles t  (cost=0.00..66.00 rows=610 width=29) (actual time=0.010..0.249 rows=610.00 loops=1)
                    Filter: is_netflix_original
                    Rows Removed by Filter: 2390
                    Buffers: shared hit=36
Planning:
  Buffers: shared hit=247
Planning Time: 0.774 ms
Execution Time: 35.996 ms
=== R19 run 3 ===
Sort  (cost=5276.25..5277.78 rows=610 width=45) (actual time=37.153..37.175 rows=610.00 loops=1)
  Sort Key: (COALESCE((count(*)), '0'::bigint)) DESC
  Sort Method: quicksort  Memory: 63kB
  Buffers: shared hit=1639
  ->  Hash Right Join  (cost=5180.64..5248.03 rows=610 width=45) (actual time=36.538..37.045 rows=610.00 loops=1)
        Hash Cond: (viewing_activity.title_id = t.title_id)
        Buffers: shared hit=1636
        ->  HashAggregate  (cost=5107.02..5136.80 rows=2978 width=20) (actual time=36.193..36.430 rows=3000.00 loops=1)
              Group Key: viewing_activity.title_id
              Batches: 1  Memory Usage: 345kB
              Buffers: shared hit=1600
              ->  Seq Scan on viewing_activity  (cost=0.00..3604.01 rows=200401 width=12) (actual time=0.003..9.450 rows=200401.00 loops=1)
                    Buffers: shared hit=1600
        ->  Hash  (cost=66.00..66.00 rows=610 width=29) (actual time=0.337..0.338 rows=610.00 loops=1)
              Buckets: 1024  Batches: 1  Memory Usage: 45kB
              Buffers: shared hit=36
              ->  Seq Scan on titles t  (cost=0.00..66.00 rows=610 width=29) (actual time=0.011..0.274 rows=610.00 loops=1)
                    Filter: is_netflix_original
                    Rows Removed by Filter: 2390
                    Buffers: shared hit=36
Planning:
  Buffers: shared hit=247
Planning Time: 0.834 ms
Execution Time: 37.272 ms
=== R19 run 4 ===
Sort  (cost=5276.25..5277.78 rows=610 width=45) (actual time=36.915..36.937 rows=610.00 loops=1)
  Sort Key: (COALESCE((count(*)), '0'::bigint)) DESC
  Sort Method: quicksort  Memory: 63kB
  Buffers: shared hit=1639
  ->  Hash Right Join  (cost=5180.64..5248.03 rows=610 width=45) (actual time=36.297..36.803 rows=610.00 loops=1)
        Hash Cond: (viewing_activity.title_id = t.title_id)
        Buffers: shared hit=1636
        ->  HashAggregate  (cost=5107.02..5136.80 rows=2978 width=20) (actual time=35.948..36.186 rows=3000.00 loops=1)
              Group Key: viewing_activity.title_id
              Batches: 1  Memory Usage: 345kB
              Buffers: shared hit=1600
              ->  Seq Scan on viewing_activity  (cost=0.00..3604.01 rows=200401 width=12) (actual time=0.003..9.295 rows=200401.00 loops=1)
                    Buffers: shared hit=1600
        ->  Hash  (cost=66.00..66.00 rows=610 width=29) (actual time=0.341..0.341 rows=610.00 loops=1)
              Buckets: 1024  Batches: 1  Memory Usage: 45kB
              Buffers: shared hit=36
              ->  Seq Scan on titles t  (cost=0.00..66.00 rows=610 width=29) (actual time=0.013..0.275 rows=610.00 loops=1)
                    Filter: is_netflix_original
                    Rows Removed by Filter: 2390
                    Buffers: shared hit=36
Planning:
  Buffers: shared hit=247
Planning Time: 0.859 ms
Execution Time: 37.035 ms
=== R19 run 5 ===
Sort  (cost=5276.25..5277.78 rows=610 width=45) (actual time=36.835..36.857 rows=610.00 loops=1)
  Sort Key: (COALESCE((count(*)), '0'::bigint)) DESC
  Sort Method: quicksort  Memory: 63kB
  Buffers: shared hit=1639
  ->  Hash Right Join  (cost=5180.64..5248.03 rows=610 width=45) (actual time=36.209..36.719 rows=610.00 loops=1)
        Hash Cond: (viewing_activity.title_id = t.title_id)
        Buffers: shared hit=1636
        ->  HashAggregate  (cost=5107.02..5136.80 rows=2978 width=20) (actual time=35.861..36.102 rows=3000.00 loops=1)
              Group Key: viewing_activity.title_id
              Batches: 1  Memory Usage: 345kB
              Buffers: shared hit=1600
              ->  Seq Scan on viewing_activity  (cost=0.00..3604.01 rows=200401 width=12) (actual time=0.003..9.347 rows=200401.00 loops=1)
                    Buffers: shared hit=1600
        ->  Hash  (cost=66.00..66.00 rows=610 width=29) (actual time=0.339..0.339 rows=610.00 loops=1)
              Buckets: 1024  Batches: 1  Memory Usage: 45kB
              Buffers: shared hit=36
              ->  Seq Scan on titles t  (cost=0.00..66.00 rows=610 width=29) (actual time=0.012..0.276 rows=610.00 loops=1)
                    Filter: is_netflix_original
                    Rows Removed by Filter: 2390
                    Buffers: shared hit=36
Planning:
  Buffers: shared hit=247
Planning Time: 0.849 ms
Execution Time: 36.953 ms
```

### R10 — 98.59% improvement

Before: 9.764 ms; After: 0.138 ms.

**Baseline EXPLAIN:**

```text
=== R10 run 1 ===
Seq Scan on accounts  (cost=0.00..691.00 rows=125 width=15) (actual time=0.572..9.982 rows=1.00 loops=1)
  Filter: (lower((email)::text) = 'arjun.chopra1409@yahoo.com'::text)
  Rows Removed by Filter: 24999
  Buffers: shared hit=316
Planning:
  Buffers: shared hit=97
Planning Time: 0.402 ms
Execution Time: 10.011 ms
=== R10 run 2 ===
Seq Scan on accounts  (cost=0.00..691.00 rows=125 width=15) (actual time=0.559..9.591 rows=1.00 loops=1)
  Filter: (lower((email)::text) = 'arjun.chopra1409@yahoo.com'::text)
  Rows Removed by Filter: 24999
  Buffers: shared hit=316
Planning:
  Buffers: shared hit=97
Planning Time: 0.343 ms
Execution Time: 9.620 ms
=== R10 run 3 ===
Seq Scan on accounts  (cost=0.00..691.00 rows=125 width=15) (actual time=0.567..9.633 rows=1.00 loops=1)
  Filter: (lower((email)::text) = 'arjun.chopra1409@yahoo.com'::text)
  Rows Removed by Filter: 24999
  Buffers: shared hit=316
Planning:
  Buffers: shared hit=97
Planning Time: 0.338 ms
Execution Time: 9.662 ms
```

**Optimized EXPLAIN:**

```text
=== R10 run 1 ===
Index Scan using idx_accounts_lower_email on accounts  (cost=0.41..8.43 rows=1 width=15) (actual time=0.433..0.434 rows=1.00 loops=1)
  Index Cond: (lower((email)::text) = 'arjun.chopra1409@yahoo.com'::text)
  Index Searches: 1
  Buffers: shared hit=1 read=3 dirtied=1
Planning:
  Buffers: shared hit=130 read=5
Planning Time: 1.265 ms
Execution Time: 0.463 ms
=== R10 run 2 ===
Index Scan using idx_accounts_lower_email on accounts  (cost=0.41..8.43 rows=1 width=15) (actual time=0.017..0.017 rows=1.00 loops=1)
  Index Cond: (lower((email)::text) = 'arjun.chopra1409@yahoo.com'::text)
  Index Searches: 1
  Buffers: shared hit=4
Planning:
  Buffers: shared hit=135
Planning Time: 0.484 ms
Execution Time: 0.047 ms
=== R10 run 3 ===
Index Scan using idx_accounts_lower_email on accounts  (cost=0.41..8.43 rows=1 width=15) (actual time=0.028..0.030 rows=1.00 loops=1)
  Index Cond: (lower((email)::text) = 'arjun.chopra1409@yahoo.com'::text)
  Index Searches: 1
  Buffers: shared hit=4
Planning:
  Buffers: shared hit=135
Planning Time: 0.639 ms
Execution Time: 0.077 ms
=== R10 run 4 ===
Index Scan using idx_accounts_lower_email on accounts  (cost=0.41..8.43 rows=1 width=15) (actual time=0.018..0.018 rows=1.00 loops=1)
  Index Cond: (lower((email)::text) = 'arjun.chopra1409@yahoo.com'::text)
  Index Searches: 1
  Buffers: shared hit=4
Planning:
  Buffers: shared hit=135
Planning Time: 0.483 ms
Execution Time: 0.048 ms
=== R10 run 5 ===
Index Scan using idx_accounts_lower_email on accounts  (cost=0.41..8.43 rows=1 width=15) (actual time=0.022..0.022 rows=1.00 loops=1)
  Index Cond: (lower((email)::text) = 'arjun.chopra1409@yahoo.com'::text)
  Index Searches: 1
  Buffers: shared hit=4
Planning:
  Buffers: shared hit=135
Planning Time: 0.547 ms
Execution Time: 0.057 ms
```

### R01 — 98.14% improvement

Before: 10.502 ms; After: 0.195 ms.

**Baseline EXPLAIN:**

```text
=== R01 run 1 ===
Unique  (cost=4081.86..4082.09 rows=2 width=45) (actual time=10.585..11.574 rows=1.00 loops=1)
  Buffers: shared hit=1618
  ->  Gather Merge  (cost=4081.86..4082.09 rows=2 width=45) (actual time=10.583..11.572 rows=1.00 loops=1)
        Workers Planned: 1
        Workers Launched: 1
        Buffers: shared hit=1618
        ->  Sort  (cost=3081.85..3081.85 rows=1 width=45) (actual time=7.182..7.182 rows=0.50 loops=2)
              Sort Key: v.title_id, v.started_at DESC
              Sort Method: quicksort  Memory: 25kB
              Buffers: shared hit=1618
              Worker 0:  Sort Method: quicksort  Memory: 25kB
              ->  Nested Loop  (cost=0.28..3081.84 rows=1 width=45) (actual time=5.379..7.162 rows=0.50 loops=2)
                    Buffers: shared hit=1603
                    ->  Parallel Seq Scan on viewing_activity v  (cost=0.00..3073.54 rows=1 width=20) (actual time=5.373..7.156 rows=0.50 loops=2)
                          Filter: ((NOT completed) AND (profile_id = 7043))
                          Rows Removed by Filter: 100200
                          Buffers: shared hit=1600
                    ->  Index Scan using titles_pkey on titles t  (cost=0.28..8.30 rows=1 width=29) (actual time=0.009..0.009 rows=1.00 loops=1)
                          Index Cond: (title_id = v.title_id)
                          Index Searches: 1
                          Buffers: shared hit=3
Planning:
  Buffers: shared hit=142
Planning Time: 0.669 ms
Execution Time: 11.856 ms
=== R01 run 2 ===
Unique  (cost=4081.86..4082.09 rows=2 width=45) (actual time=8.726..9.839 rows=1.00 loops=1)
  Buffers: shared hit=1618
  ->  Gather Merge  (cost=4081.86..4082.09 rows=2 width=45) (actual time=8.723..9.835 rows=1.00 loops=1)
        Workers Planned: 1
        Workers Launched: 1
        Buffers: shared hit=1618
        ->  Sort  (cost=3081.85..3081.85 rows=1 width=45) (actual time=7.122..7.131 rows=0.50 loops=2)
              Sort Key: v.title_id, v.started_at DESC
              Sort Method: quicksort  Memory: 25kB
              Buffers: shared hit=1618
              Worker 0:  Sort Method: quicksort  Memory: 25kB
              ->  Nested Loop  (cost=0.28..3081.84 rows=1 width=45) (actual time=5.154..7.110 rows=0.50 loops=2)
                    Buffers: shared hit=1603
                    ->  Parallel Seq Scan on viewing_activity v  (cost=0.00..3073.54 rows=1 width=20) (actual time=5.150..7.105 rows=0.50 loops=2)
                          Filter: ((NOT completed) AND (profile_id = 7043))
                          Rows Removed by Filter: 100200
                          Buffers: shared hit=1600
                    ->  Index Scan using titles_pkey on titles t  (cost=0.28..8.30 rows=1 width=29) (actual time=0.006..0.006 rows=1.00 loops=1)
                          Index Cond: (title_id = v.title_id)
                          Index Searches: 1
                          Buffers: shared hit=3
Planning:
  Buffers: shared hit=142
Planning Time: 0.506 ms
Execution Time: 9.900 ms
=== R01 run 3 ===
Unique  (cost=4081.86..4082.09 rows=2 width=45) (actual time=8.659..9.690 rows=1.00 loops=1)
  Buffers: shared hit=1619
  ->  Gather Merge  (cost=4081.86..4082.09 rows=2 width=45) (actual time=8.659..9.689 rows=1.00 loops=1)
        Workers Planned: 1
        Workers Launched: 1
        Buffers: shared hit=1619
        ->  Sort  (cost=3081.85..3081.85 rows=1 width=45) (actual time=6.910..6.910 rows=0.50 loops=2)
              Sort Key: v.title_id, v.started_at DESC
              Sort Method: quicksort  Memory: 25kB
              Buffers: shared hit=1619
              Worker 0:  Sort Method: quicksort  Memory: 25kB
              ->  Nested Loop  (cost=0.28..3081.84 rows=1 width=45) (actual time=5.101..6.893 rows=0.50 loops=2)
                    Buffers: shared hit=1604
                    ->  Parallel Seq Scan on viewing_activity v  (cost=0.00..3073.54 rows=1 width=20) (actual time=5.095..6.887 rows=0.50 loops=2)
                          Filter: ((NOT completed) AND (profile_id = 7043))
                          Rows Removed by Filter: 100200
                          Buffers: shared hit=1600
                    ->  Index Scan using titles_pkey on titles t  (cost=0.28..8.30 rows=1 width=29) (actual time=0.010..0.010 rows=1.00 loops=1)
                          Index Cond: (title_id = v.title_id)
                          Index Searches: 1
                          Buffers: shared hit=4
Planning:
  Buffers: shared hit=142
Planning Time: 0.497 ms
Execution Time: 9.751 ms
```

**Optimized EXPLAIN:**

```text
=== R01 run 1 ===
Unique  (cost=0.70..25.06 rows=2 width=45) (actual time=0.423..0.424 rows=1.00 loops=1)
  Buffers: shared hit=3 read=4
  ->  Nested Loop  (cost=0.70..25.05 rows=2 width=45) (actual time=0.422..0.423 rows=1.00 loops=1)
        Buffers: shared hit=3 read=4
        ->  Index Only Scan using idx_va_unfinished_profile_title_time on viewing_activity v  (cost=0.42..8.45 rows=2 width=20) (actual time=0.378..0.378 rows=1.00 loops=1)
              Index Cond: (profile_id = 7043)
              Heap Fetches: 0
              Index Searches: 1
              Buffers: shared hit=1 read=3
        ->  Index Scan using titles_pkey on titles t  (cost=0.28..8.30 rows=1 width=29) (actual time=0.042..0.042 rows=1.00 loops=1)
              Index Cond: (title_id = v.title_id)
              Index Searches: 1
              Buffers: shared hit=2 read=1
Planning:
  Buffers: shared hit=246 read=13 dirtied=6
Planning Time: 2.848 ms
Execution Time: 0.661 ms
=== R01 run 2 ===
Unique  (cost=0.70..25.06 rows=2 width=45) (actual time=0.023..0.024 rows=1.00 loops=1)
  Buffers: shared hit=7
  ->  Nested Loop  (cost=0.70..25.05 rows=2 width=45) (actual time=0.022..0.023 rows=1.00 loops=1)
        Buffers: shared hit=7
        ->  Index Only Scan using idx_va_unfinished_profile_title_time on viewing_activity v  (cost=0.42..8.45 rows=2 width=20) (actual time=0.011..0.012 rows=1.00 loops=1)
              Index Cond: (profile_id = 7043)
              Heap Fetches: 0
              Index Searches: 1
              Buffers: shared hit=4
        ->  Index Scan using titles_pkey on titles t  (cost=0.28..8.30 rows=1 width=29) (actual time=0.008..0.008 rows=1.00 loops=1)
              Index Cond: (title_id = v.title_id)
              Index Searches: 1
              Buffers: shared hit=3
Planning:
  Buffers: shared hit=257
Planning Time: 1.091 ms
Execution Time: 0.080 ms
=== R01 run 3 ===
Unique  (cost=0.70..25.06 rows=2 width=45) (actual time=0.020..0.021 rows=1.00 loops=1)
  Buffers: shared hit=7
  ->  Nested Loop  (cost=0.70..25.05 rows=2 width=45) (actual time=0.019..0.020 rows=1.00 loops=1)
        Buffers: shared hit=7
        ->  Index Only Scan using idx_va_unfinished_profile_title_time on viewing_activity v  (cost=0.42..8.45 rows=2 width=20) (actual time=0.008..0.009 rows=1.00 loops=1)
              Index Cond: (profile_id = 7043)
              Heap Fetches: 0
              Index Searches: 1
              Buffers: shared hit=4
        ->  Index Scan using titles_pkey on titles t  (cost=0.28..8.30 rows=1 width=29) (actual time=0.008..0.008 rows=1.00 loops=1)
              Index Cond: (title_id = v.title_id)
              Index Searches: 1
              Buffers: shared hit=3
Planning:
  Buffers: shared hit=257
Planning Time: 1.011 ms
Execution Time: 0.077 ms
=== R01 run 4 ===
Unique  (cost=0.70..25.06 rows=2 width=45) (actual time=0.021..0.021 rows=1.00 loops=1)
  Buffers: shared hit=7
  ->  Nested Loop  (cost=0.70..25.05 rows=2 width=45) (actual time=0.019..0.019 rows=1.00 loops=1)
        Buffers: shared hit=7
        ->  Index Only Scan using idx_va_unfinished_profile_title_time on viewing_activity v  (cost=0.42..8.45 rows=2 width=20) (actual time=0.009..0.010 rows=1.00 loops=1)
              Index Cond: (profile_id = 7043)
              Heap Fetches: 0
              Index Searches: 1
              Buffers: shared hit=4
        ->  Index Scan using titles_pkey on titles t  (cost=0.28..8.30 rows=1 width=29) (actual time=0.007..0.007 rows=1.00 loops=1)
              Index Cond: (title_id = v.title_id)
              Index Searches: 1
              Buffers: shared hit=3
Planning:
  Buffers: shared hit=257
Planning Time: 1.014 ms
Execution Time: 0.075 ms
=== R01 run 5 ===
Unique  (cost=0.70..25.06 rows=2 width=45) (actual time=0.022..0.023 rows=1.00 loops=1)
  Buffers: shared hit=7
  ->  Nested Loop  (cost=0.70..25.05 rows=2 width=45) (actual time=0.020..0.021 rows=1.00 loops=1)
        Buffers: shared hit=7
        ->  Index Only Scan using idx_va_unfinished_profile_title_time on viewing_activity v  (cost=0.42..8.45 rows=2 width=20) (actual time=0.010..0.010 rows=1.00 loops=1)
              Index Cond: (profile_id = 7043)
              Heap Fetches: 0
              Index Searches: 1
              Buffers: shared hit=4
        ->  Index Scan using titles_pkey on titles t  (cost=0.28..8.30 rows=1 width=29) (actual time=0.009..0.009 rows=1.00 loops=1)
              Index Cond: (title_id = v.title_id)
              Index Searches: 1
              Buffers: shared hit=3
Planning:
  Buffers: shared hit=257
Planning Time: 1.090 ms
Execution Time: 0.080 ms
```

### R24 — 96.28% improvement

Before: 3.251 ms; After: 0.121 ms.

**Baseline EXPLAIN:**

```text
=== R24 run 1 ===
Sort  (cost=1545.52..1545.53 rows=3 width=22) (actual time=3.184..3.185 rows=4.00 loops=1)
  Sort Key: created_at
  Sort Method: quicksort  Memory: 25kB
  Buffers: shared hit=611
  ->  Seq Scan on profiles  (cost=0.00..1545.50 rows=3 width=22) (actual time=0.194..3.167 rows=4.00 loops=1)
        Filter: (account_id = 1409)
        Rows Removed by Filter: 74996
        Buffers: shared hit=608
Planning:
  Buffers: shared hit=91
Planning Time: 0.303 ms
Execution Time: 3.220 ms
=== R24 run 2 ===
Sort  (cost=1545.52..1545.53 rows=3 width=22) (actual time=3.257..3.258 rows=4.00 loops=1)
  Sort Key: created_at
  Sort Method: quicksort  Memory: 25kB
  Buffers: shared hit=611
  ->  Seq Scan on profiles  (cost=0.00..1545.50 rows=3 width=22) (actual time=0.207..3.237 rows=4.00 loops=1)
        Filter: (account_id = 1409)
        Rows Removed by Filter: 74996
        Buffers: shared hit=608
Planning:
  Buffers: shared hit=91
Planning Time: 0.303 ms
Execution Time: 3.296 ms
=== R24 run 3 ===
Sort  (cost=1545.52..1545.53 rows=3 width=22) (actual time=3.203..3.204 rows=4.00 loops=1)
  Sort Key: created_at
  Sort Method: quicksort  Memory: 25kB
  Buffers: shared hit=611
  ->  Seq Scan on profiles  (cost=0.00..1545.50 rows=3 width=22) (actual time=0.190..3.186 rows=4.00 loops=1)
        Filter: (account_id = 1409)
        Rows Removed by Filter: 74996
        Buffers: shared hit=608
Planning:
  Buffers: shared hit=91
Planning Time: 0.265 ms
Execution Time: 3.237 ms
```

**Optimized EXPLAIN:**

```text
=== R24 run 1 ===
Index Scan using idx_profiles_account_created on profiles  (cost=0.42..11.97 rows=3 width=22) (actual time=0.315..0.325 rows=4.00 loops=1)
  Index Cond: (account_id = 1409)
  Index Searches: 1
  Buffers: shared hit=3 read=2
Planning:
  Buffers: shared hit=124 dirtied=1
Planning Time: 0.406 ms
Execution Time: 0.361 ms
=== R24 run 2 ===
Index Scan using idx_profiles_account_created on profiles  (cost=0.42..11.97 rows=3 width=22) (actual time=0.015..0.020 rows=4.00 loops=1)
  Index Cond: (account_id = 1409)
  Index Searches: 1
  Buffers: shared hit=5
Planning:
  Buffers: shared hit=124
Planning Time: 0.356 ms
Execution Time: 0.054 ms
=== R24 run 3 ===
Index Scan using idx_profiles_account_created on profiles  (cost=0.42..11.97 rows=3 width=22) (actual time=0.015..0.020 rows=4.00 loops=1)
  Index Cond: (account_id = 1409)
  Index Searches: 1
  Buffers: shared hit=5
Planning:
  Buffers: shared hit=124
Planning Time: 0.379 ms
Execution Time: 0.056 ms
=== R24 run 4 ===
Index Scan using idx_profiles_account_created on profiles  (cost=0.42..11.97 rows=3 width=22) (actual time=0.015..0.021 rows=4.00 loops=1)
  Index Cond: (account_id = 1409)
  Index Searches: 1
  Buffers: shared hit=5
Planning:
  Buffers: shared hit=124
Planning Time: 0.360 ms
Execution Time: 0.058 ms
=== R24 run 5 ===
Index Scan using idx_profiles_account_created on profiles  (cost=0.42..11.97 rows=3 width=22) (actual time=0.021..0.029 rows=4.00 loops=1)
  Index Cond: (account_id = 1409)
  Index Searches: 1
  Buffers: shared hit=5
Planning:
  Buffers: shared hit=124
Planning Time: 0.399 ms
Execution Time: 0.076 ms
```

### R03 — 88.81% improvement

Before: 9.091 ms; After: 1.017 ms.

**Baseline EXPLAIN:**

```text
=== R03 run 1 ===
Limit  (cost=4571.52..4571.54 rows=10 width=37) (actual time=8.639..9.095 rows=10.00 loops=1)
  Buffers: shared hit=1686
  ->  Sort  (cost=4571.52..4572.42 rows=363 width=37) (actual time=8.638..9.093 rows=10.00 loops=1)
        Sort Key: (count(DISTINCT v.profile_id)) DESC
        Sort Method: top-N heapsort  Memory: 25kB
        Buffers: shared hit=1686
        ->  GroupAggregate  (cost=4376.82..4563.67 rows=363 width=37) (actual time=8.035..9.056 rows=238.00 loops=1)
              Group Key: t.title_id
              Buffers: shared hit=1683
              ->  Merge Join  (cost=4376.82..4558.23 rows=363 width=33) (actual time=8.026..8.986 rows=373.00 loops=1)
                    Merge Cond: (v.title_id = t.title_id)
                    Buffers: shared hit=1683
                    ->  Gather Merge  (cost=4376.54..4417.91 rows=363 width=8) (actual time=7.990..8.481 rows=373.00 loops=1)
                          Workers Planned: 1
                          Workers Launched: 1
                          Buffers: shared hit=1637
                          ->  Sort  (cost=3376.53..3377.06 rows=214 width=8) (actual time=6.344..6.351 rows=186.50 loops=2)
                                Sort Key: v.title_id, v.profile_id
                                Sort Method: quicksort  Memory: 29kB
                                Buffers: shared hit=1637
                                Worker 0:  Sort Method: quicksort  Memory: 28kB
                                ->  Parallel Seq Scan on viewing_activity v  (cost=0.00..3368.24 rows=214 width=8) (actual time=6.268..6.291 rows=186.50 loops=2)
                                      Filter: ((started_at >= '2026-06-30 00:00:00+05:30'::timestamp with time zone) AND (started_at < '2026-07-01 00:00:00+05:30'::timestamp with time zone))
                                      Rows Removed by Filter: 100014
                                      Buffers: shared hit=1600
                    ->  Index Scan using titles_pkey on titles t  (cost=0.28..128.28 rows=3000 width=29) (actual time=0.028..0.321 rows=2965.00 loops=1)
                          Index Searches: 1
                          Buffers: shared hit=46
Planning:
  Buffers: shared hit=146
Planning Time: 0.581 ms
Execution Time: 9.156 ms
=== R03 run 2 ===
Limit  (cost=4571.52..4571.54 rows=10 width=37) (actual time=8.668..9.064 rows=10.00 loops=1)
  Buffers: shared hit=1686
  ->  Sort  (cost=4571.52..4572.42 rows=363 width=37) (actual time=8.667..9.063 rows=10.00 loops=1)
        Sort Key: (count(DISTINCT v.profile_id)) DESC
        Sort Method: top-N heapsort  Memory: 25kB
        Buffers: shared hit=1686
        ->  GroupAggregate  (cost=4376.82..4563.67 rows=363 width=37) (actual time=8.065..9.024 rows=238.00 loops=1)
              Group Key: t.title_id
              Buffers: shared hit=1683
              ->  Merge Join  (cost=4376.82..4558.23 rows=363 width=33) (actual time=8.058..8.951 rows=373.00 loops=1)
                    Merge Cond: (v.title_id = t.title_id)
                    Buffers: shared hit=1683
                    ->  Gather Merge  (cost=4376.54..4417.91 rows=363 width=8) (actual time=8.028..8.458 rows=373.00 loops=1)
                          Workers Planned: 1
                          Workers Launched: 1
                          Buffers: shared hit=1637
                          ->  Sort  (cost=3376.53..3377.06 rows=214 width=8) (actual time=6.412..6.419 rows=186.50 loops=2)
                                Sort Key: v.title_id, v.profile_id
                                Sort Method: quicksort  Memory: 28kB
                                Buffers: shared hit=1637
                                Worker 0:  Sort Method: quicksort  Memory: 29kB
                                ->  Parallel Seq Scan on viewing_activity v  (cost=0.00..3368.24 rows=214 width=8) (actual time=6.337..6.360 rows=186.50 loops=2)
                                      Filter: ((started_at >= '2026-06-30 00:00:00+05:30'::timestamp with time zone) AND (started_at < '2026-07-01 00:00:00+05:30'::timestamp with time zone))
                                      Rows Removed by Filter: 100014
                                      Buffers: shared hit=1600
                    ->  Index Scan using titles_pkey on titles t  (cost=0.28..128.28 rows=3000 width=29) (actual time=0.024..0.311 rows=2965.00 loops=1)
                          Index Searches: 1
                          Buffers: shared hit=46
Planning:
  Buffers: shared hit=146
Planning Time: 0.576 ms
Execution Time: 9.124 ms
=== R03 run 3 ===
Limit  (cost=4571.52..4571.54 rows=10 width=37) (actual time=8.549..8.941 rows=10.00 loops=1)
  Buffers: shared hit=1686
  ->  Sort  (cost=4571.52..4572.42 rows=363 width=37) (actual time=8.549..8.939 rows=10.00 loops=1)
        Sort Key: (count(DISTINCT v.profile_id)) DESC
        Sort Method: top-N heapsort  Memory: 25kB
        Buffers: shared hit=1686
        ->  GroupAggregate  (cost=4376.82..4563.67 rows=363 width=37) (actual time=7.960..8.902 rows=238.00 loops=1)
              Group Key: t.title_id
              Buffers: shared hit=1683
              ->  Merge Join  (cost=4376.82..4558.23 rows=363 width=33) (actual time=7.951..8.834 rows=373.00 loops=1)
                    Merge Cond: (v.title_id = t.title_id)
                    Buffers: shared hit=1683
                    ->  Gather Merge  (cost=4376.54..4417.91 rows=363 width=8) (actual time=7.923..8.347 rows=373.00 loops=1)
                          Workers Planned: 1
                          Workers Launched: 1
                          Buffers: shared hit=1637
                          ->  Sort  (cost=3376.53..3377.06 rows=214 width=8) (actual time=6.276..6.283 rows=186.50 loops=2)
                                Sort Key: v.title_id, v.profile_id
                                Sort Method: quicksort  Memory: 28kB
                                Buffers: shared hit=1637
                                Worker 0:  Sort Method: quicksort  Memory: 29kB
                                ->  Parallel Seq Scan on viewing_activity v  (cost=0.00..3368.24 rows=214 width=8) (actual time=6.204..6.226 rows=186.50 loops=2)
                                      Filter: ((started_at >= '2026-06-30 00:00:00+05:30'::timestamp with time zone) AND (started_at < '2026-07-01 00:00:00+05:30'::timestamp with time zone))
                                      Rows Removed by Filter: 100014
                                      Buffers: shared hit=1600
                    ->  Index Scan using titles_pkey on titles t  (cost=0.28..128.28 rows=3000 width=29) (actual time=0.023..0.303 rows=2965.00 loops=1)
                          Index Searches: 1
                          Buffers: shared hit=46
Planning:
  Buffers: shared hit=146
Planning Time: 0.536 ms
Execution Time: 8.994 ms
```

**Optimized EXPLAIN:**

```text
=== R03 run 1 ===
Limit  (cost=161.12..161.14 rows=10 width=37) (actual time=1.084..1.086 rows=10.00 loops=1)
  Buffers: shared hit=47 read=2
  ->  Sort  (cost=161.12..162.10 rows=393 width=37) (actual time=1.083..1.084 rows=10.00 loops=1)
        Sort Key: (count(DISTINCT v.profile_id)) DESC
        Sort Method: top-N heapsort  Memory: 25kB
        Buffers: shared hit=47 read=2
        ->  GroupAggregate  (cost=145.75..152.62 rows=393 width=37) (actual time=0.972..1.050 rows=238.00 loops=1)
              Group Key: t.title_id
              Buffers: shared hit=44 read=2
              ->  Sort  (cost=145.75..146.73 rows=393 width=33) (actual time=0.965..0.979 rows=373.00 loops=1)
                    Sort Key: t.title_id, v.profile_id
                    Sort Method: quicksort  Memory: 44kB
                    Buffers: shared hit=44 read=2
                    ->  Hash Join  (cost=103.92..128.81 rows=393 width=33) (actual time=0.577..0.880 rows=373.00 loops=1)
                          Hash Cond: (v.title_id = t.title_id)
                          Buffers: shared hit=41 read=2
                          ->  Index Only Scan using idx_va_started_desc_cover on viewing_activity v  (cost=0.42..24.28 rows=393 width=8) (actual time=0.011..0.258 rows=373.00 loops=1)
                                Index Cond: ((started_at >= '2026-06-30 00:00:00+05:30'::timestamp with time zone) AND (started_at < '2026-07-01 00:00:00+05:30'::timestamp with time zone))
                                Heap Fetches: 80
                                Index Searches: 1
                                Buffers: shared hit=5 read=2
                          ->  Hash  (cost=66.00..66.00 rows=3000 width=29) (actual time=0.556..0.556 rows=3000.00 loops=1)
                                Buckets: 4096  Batches: 1  Memory Usage: 213kB
                                Buffers: shared hit=36
                                ->  Seq Scan on titles t  (cost=0.00..66.00 rows=3000 width=29) (actual time=0.007..0.263 rows=3000.00 loops=1)
                                      Buffers: shared hit=36
Planning:
  Buffers: shared hit=283 read=3
Planning Time: 1.408 ms
Execution Time: 1.133 ms
=== R03 run 2 ===
Limit  (cost=161.12..161.14 rows=10 width=37) (actual time=0.930..0.932 rows=10.00 loops=1)
  Buffers: shared hit=49
  ->  Sort  (cost=161.12..162.10 rows=393 width=37) (actual time=0.930..0.930 rows=10.00 loops=1)
        Sort Key: (count(DISTINCT v.profile_id)) DESC
        Sort Method: top-N heapsort  Memory: 25kB
        Buffers: shared hit=49
        ->  GroupAggregate  (cost=145.75..152.62 rows=393 width=37) (actual time=0.818..0.895 rows=238.00 loops=1)
              Group Key: t.title_id
              Buffers: shared hit=46
              ->  Sort  (cost=145.75..146.73 rows=393 width=33) (actual time=0.812..0.825 rows=373.00 loops=1)
                    Sort Key: t.title_id, v.profile_id
                    Sort Method: quicksort  Memory: 44kB
                    Buffers: shared hit=46
                    ->  Hash Join  (cost=103.92..128.81 rows=393 width=33) (actual time=0.633..0.726 rows=373.00 loops=1)
                          Hash Cond: (v.title_id = t.title_id)
                          Buffers: shared hit=43
                          ->  Index Only Scan using idx_va_started_desc_cover on viewing_activity v  (cost=0.42..24.28 rows=393 width=8) (actual time=0.011..0.051 rows=373.00 loops=1)
                                Index Cond: ((started_at >= '2026-06-30 00:00:00+05:30'::timestamp with time zone) AND (started_at < '2026-07-01 00:00:00+05:30'::timestamp with time zone))
                                Heap Fetches: 80
                                Index Searches: 1
                                Buffers: shared hit=7
                          ->  Hash  (cost=66.00..66.00 rows=3000 width=29) (actual time=0.610..0.611 rows=3000.00 loops=1)
                                Buckets: 4096  Batches: 1  Memory Usage: 213kB
                                Buffers: shared hit=36
                                ->  Seq Scan on titles t  (cost=0.00..66.00 rows=3000 width=29) (actual time=0.008..0.303 rows=3000.00 loops=1)
                                      Buffers: shared hit=36
Planning:
  Buffers: shared hit=286
Planning Time: 1.035 ms
Execution Time: 0.986 ms
=== R03 run 3 ===
Limit  (cost=161.12..161.14 rows=10 width=37) (actual time=0.906..0.909 rows=10.00 loops=1)
  Buffers: shared hit=49
  ->  Sort  (cost=161.12..162.10 rows=393 width=37) (actual time=0.905..0.907 rows=10.00 loops=1)
        Sort Key: (count(DISTINCT v.profile_id)) DESC
        Sort Method: top-N heapsort  Memory: 25kB
        Buffers: shared hit=49
        ->  GroupAggregate  (cost=145.75..152.62 rows=393 width=37) (actual time=0.785..0.865 rows=238.00 loops=1)
              Group Key: t.title_id
              Buffers: shared hit=46
              ->  Sort  (cost=145.75..146.73 rows=393 width=33) (actual time=0.776..0.791 rows=373.00 loops=1)
                    Sort Key: t.title_id, v.profile_id
                    Sort Method: quicksort  Memory: 44kB
                    Buffers: shared hit=46
                    ->  Hash Join  (cost=103.92..128.81 rows=393 width=33) (actual time=0.594..0.686 rows=373.00 loops=1)
                          Hash Cond: (v.title_id = t.title_id)
                          Buffers: shared hit=43
                          ->  Index Only Scan using idx_va_started_desc_cover on viewing_activity v  (cost=0.42..24.28 rows=393 width=8) (actual time=0.011..0.049 rows=373.00 loops=1)
                                Index Cond: ((started_at >= '2026-06-30 00:00:00+05:30'::timestamp with time zone) AND (started_at < '2026-07-01 00:00:00+05:30'::timestamp with time zone))
                                Heap Fetches: 80
                                Index Searches: 1
                                Buffers: shared hit=7
                          ->  Hash  (cost=66.00..66.00 rows=3000 width=29) (actual time=0.571..0.571 rows=3000.00 loops=1)
                                Buckets: 4096  Batches: 1  Memory Usage: 213kB
                                Buffers: shared hit=36
                                ->  Seq Scan on titles t  (cost=0.00..66.00 rows=3000 width=29) (actual time=0.007..0.278 rows=3000.00 loops=1)
                                      Buffers: shared hit=36
Planning:
  Buffers: shared hit=286
Planning Time: 1.014 ms
Execution Time: 0.966 ms
=== R03 run 4 ===
Limit  (cost=161.12..161.14 rows=10 width=37) (actual time=0.862..0.864 rows=10.00 loops=1)
  Buffers: shared hit=49
  ->  Sort  (cost=161.12..162.10 rows=393 width=37) (actual time=0.861..0.862 rows=10.00 loops=1)
        Sort Key: (count(DISTINCT v.profile_id)) DESC
        Sort Method: top-N heapsort  Memory: 25kB
        Buffers: shared hit=49
        ->  GroupAggregate  (cost=145.75..152.62 rows=393 width=37) (actual time=0.750..0.828 rows=238.00 loops=1)
              Group Key: t.title_id
              Buffers: shared hit=46
              ->  Sort  (cost=145.75..146.73 rows=393 width=33) (actual time=0.743..0.757 rows=373.00 loops=1)
                    Sort Key: t.title_id, v.profile_id
                    Sort Method: quicksort  Memory: 44kB
                    Buffers: shared hit=46
                    ->  Hash Join  (cost=103.92..128.81 rows=393 width=33) (actual time=0.562..0.651 rows=373.00 loops=1)
                          Hash Cond: (v.title_id = t.title_id)
                          Buffers: shared hit=43
                          ->  Index Only Scan using idx_va_started_desc_cover on viewing_activity v  (cost=0.42..24.28 rows=393 width=8) (actual time=0.010..0.047 rows=373.00 loops=1)
                                Index Cond: ((started_at >= '2026-06-30 00:00:00+05:30'::timestamp with time zone) AND (started_at < '2026-07-01 00:00:00+05:30'::timestamp with time zone))
                                Heap Fetches: 80
                                Index Searches: 1
                                Buffers: shared hit=7
                          ->  Hash  (cost=66.00..66.00 rows=3000 width=29) (actual time=0.541..0.541 rows=3000.00 loops=1)
                                Buckets: 4096  Batches: 1  Memory Usage: 213kB
                                Buffers: shared hit=36
                                ->  Seq Scan on titles t  (cost=0.00..66.00 rows=3000 width=29) (actual time=0.007..0.252 rows=3000.00 loops=1)
                                      Buffers: shared hit=36
Planning:
  Buffers: shared hit=286
Planning Time: 0.909 ms
Execution Time: 0.911 ms
=== R03 run 5 ===
Limit  (cost=161.12..161.14 rows=10 width=37) (actual time=1.026..1.029 rows=10.00 loops=1)
  Buffers: shared hit=49
  ->  Sort  (cost=161.12..162.10 rows=393 width=37) (actual time=1.025..1.026 rows=10.00 loops=1)
        Sort Key: (count(DISTINCT v.profile_id)) DESC
        Sort Method: top-N heapsort  Memory: 25kB
        Buffers: shared hit=49
        ->  GroupAggregate  (cost=145.75..152.62 rows=393 width=37) (actual time=0.912..0.990 rows=238.00 loops=1)
              Group Key: t.title_id
              Buffers: shared hit=46
              ->  Sort  (cost=145.75..146.73 rows=393 width=33) (actual time=0.904..0.919 rows=373.00 loops=1)
                    Sort Key: t.title_id, v.profile_id
                    Sort Method: quicksort  Memory: 44kB
                    Buffers: shared hit=46
                    ->  Hash Join  (cost=103.92..128.81 rows=393 width=33) (actual time=0.716..0.814 rows=373.00 loops=1)
                          Hash Cond: (v.title_id = t.title_id)
                          Buffers: shared hit=43
                          ->  Index Only Scan using idx_va_started_desc_cover on viewing_activity v  (cost=0.42..24.28 rows=393 width=8) (actual time=0.010..0.050 rows=373.00 loops=1)
                                Index Cond: ((started_at >= '2026-06-30 00:00:00+05:30'::timestamp with time zone) AND (started_at < '2026-07-01 00:00:00+05:30'::timestamp with time zone))
                                Heap Fetches: 80
                                Index Searches: 1
                                Buffers: shared hit=7
                          ->  Hash  (cost=66.00..66.00 rows=3000 width=29) (actual time=0.693..0.693 rows=3000.00 loops=1)
                                Buckets: 4096  Batches: 1  Memory Usage: 213kB
                                Buffers: shared hit=36
                                ->  Seq Scan on titles t  (cost=0.00..66.00 rows=3000 width=29) (actual time=0.008..0.330 rows=3000.00 loops=1)
                                      Buffers: shared hit=36
Planning:
  Buffers: shared hit=286
Planning Time: 1.078 ms
Execution Time: 1.089 ms
```

## 4. Result correctness and the NULL-related query

R09, R12, R18 and R19 were compared against their original forms using EXCEPT ALL in both directions. Each comparison returned zero rows, establishing result equivalence on the seed dataset.

R13 originally used NOT IN (SELECT episode_id FROM viewing_activity). The subquery can return NULL. Under SQL three-valued logic, a NULL in the NOT IN result can cause the predicate to evaluate to UNKNOWN, excluding otherwise-unwatched episodes. The corrected query uses correlated NOT EXISTS, matching each episode_id explicitly. This is an intentional correctness fix, so its output is not expected to match the incorrect original output.

For queries whose SQL was unchanged, the indexes affect access paths rather than the logical result. The report distinguishes these from the four rewritten queries explicitly checked above.

## 5. Write overhead

| Query | Before (ms) | After (ms) | Change |
|---|---:|---:|---:|
| W01 | 0.815 | 1.423 | 74.60% slower |
| W02 | 0.834 | 1.056 | 26.62% slower |
| W03 | 0.437 | 0.879 | 101.14% slower |
| W04 | 189.016 | 171.705 | 9.16% faster |
| W05 | 20.308 | 20.714 | 2.00% slower |

Write operations may become slower because PostgreSQL must maintain additional indexes during inserts, updates and deletes. The absolute time changes should be considered alongside the read improvements and the workload's read/write balance.

## 6. Index storage comparison

Sizes below were measured using pg_relation_size on the seed database.

| Index | Table | Index size | Table size |
|---|---|---:|---:|
| idx_va_unfinished_profile_title_time | viewing_activity | 3912 kB | 13 MB |
| idx_titles_name_trgm | titles | 256 kB | 288 kB |
| idx_accounts_lower_email | accounts | 1224 kB | 3032 kB |
| idx_invoices_failed_period_account | invoices | 208 kB | 7824 kB |
| idx_va_title_started | viewing_activity | 6192 kB | 13 MB |
| idx_accounts_hold_billing_date | accounts | 32 kB | 3032 kB |
| idx_titles_leaving_on | titles | 16 kB | 288 kB |
| idx_va_started_desc_cover | viewing_activity | 8768 kB | 13 MB |
| idx_profiles_account_created | profiles | 3584 kB | 4864 kB |
| idx_title_genres_genre_title | title_genres | 152 kB | 216 kB |
| **Total index storage** | | **Approximately 24 MB** | |

## 7. Queries with limited or negative improvement

The benchmark shows that not every query became faster. R02, R06, R14, R15, R16 and R17 became slower in the measured run. Some are already very fast on the seed dataset; others perform joins or aggregations that still need to process a substantial part of their input. R16 and R17 are examples where aggregation work remains. Small timing differences should be interpreted cautiously because the seed dataset is relatively small and execution plans are affected by caching and measurement variation.

The write-query measurements also show the trade-off of maintaining additional indexes. Index selection should balance read performance, write cost and disk storage.

## 8. Index justification

| Index | Purpose |
|---|---|
| idx_va_unfinished_profile_title_time | Supports R01's profile filter, unfinished-row predicate and title/time ordering |
| idx_titles_name_trgm | Supports R05 substring ILIKE search |
| idx_accounts_lower_email | Supports R10 lower(email) lookup |
| idx_invoices_failed_period_account | Supports R11 failed-invoice period/account lookup |
| idx_va_title_started | Supports R19 per-title viewing aggregation |
| idx_accounts_hold_billing_date | Supports R21 ON_HOLD billing-date lookup |
| idx_titles_leaving_on | Supports R22 leaving-date lookup |
| idx_va_started_desc_cover | Supports R03 date filtering and R23 newest-first covered retrieval |
| idx_profiles_account_created | Supports R24 account filtering and created_at ordering |
| idx_title_genres_genre_title | Supports R04/R25 genre-to-title joins |

## 9. Conclusion

Phase 4 applied targeted indexes and semantics-aware query rewrites. The largest measured improvement came from eliminating repeated correlated scans in R19. The report also records cases where read performance did not improve and the write/storage costs introduced by indexing. Phase 5 will evaluate these optimizations on the larger dataset.
