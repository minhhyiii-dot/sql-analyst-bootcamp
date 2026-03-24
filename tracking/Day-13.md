--- DAY 13 UPDATE ---

DAY 13 | COMPLETED | ~1h | Level: 4.6/5
Focus Topic: Index & Performance Basics
Session Notes:
- Learned fundamentals of index design and how query patterns influence index structure.
- Practiced reasoning about composite indexes and the left‑to‑right column order rule.
- Understood equality vs range conditions when designing indexes (equality columns should usually appear first).
- Explored how indexes interact with GROUP BY and filtering conditions in analytical queries.
- Identified that ORDER BY on aggregated values (e.g., SUM, COUNT) still requires sorting even when an index exists.
- Practiced analyzing query logic to avoid unnecessary table scans and redundant query layers.
Minhyi Notes:
- Realized that index design must follow query patterns rather than table structure.
- Understood that some optimizations require changing query structure rather than only adding indexes.
- Started thinking in terms of execution plans and scan costs.
Key Lesson:
"Indexes optimize data access paths, but they cannot eliminate computation steps like aggregation before sorting."
Bootcamp Progress Update:
Current Streak: 13 Days
Bootcamp Progress: Day 13 / 42
Completion: ~31%

query: no record
