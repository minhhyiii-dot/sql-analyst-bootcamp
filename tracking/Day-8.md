# DAY 8 UPDATE

**DAY 8 | COMPLETED | 57 minutes | Level: 4.5/5**

## Session Notes
- Practiced subquery fundamentals, including filtering using aggregated values from nested queries.
- Successfully differentiated between global average metrics vs segmented averages (e.g., product price vs category average price).
- Demonstrated understanding of correlated subqueries by comparing product price against the average price within its category.
- Explored multi-layer aggregation logic, identifying the difference between:
  • average order value
  • average customer spending
- Learned that correct analyst logic often requires two-stage aggregation:
  aggregate metric → then average that metric
- Practiced building intermediate metric tables using CTE structure to separate calculation layers.

## Minhyi Notes
- Initially attempted to compute comparison using a single GROUP BY + HAVING layer.
- Discovered why nested aggregates like AVG(SUM(...)) are invalid in the same query level.
- Realized that solving business questions often requires building a metric first, then analyzing it in a second query layer.

## Key Lesson
"When comparing aggregated metrics, compute the metric first, then aggregate the result in a separate query layer."

## Query
 no record
