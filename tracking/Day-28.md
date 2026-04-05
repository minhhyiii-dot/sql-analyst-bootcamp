# DAY 28 | COMPLETED | Level: 4.6/5
 
**Focus Topic:** Project 4 — RFM Segmentation
 
---
 
## Session Notes
 
- Built a full RFM segmentation pipeline using validated paid order logic instead of relying on `orders.status`.
- Kept strong data integrity by comparing calculated `order_total` vs aggregated `paid_total` and keeping only financially validated orders.
- Structured the query cleanly across multiple layers:
  - Order validation
  - Customer metric calculation
  - RFM scoring
  - Segment mapping
  - Final segment aggregation
- Demonstrated strong control of data grain by keeping the segmentation base at 1 row per customer before final grouping.
- Calculated segment contribution across:
  - Total customers
  - Total orders
  - Total revenue
- Replaced earlier `NTILE(5)` approach with `PERCENT_RANK()`-based scoring after identifying a real stability issue with tied values and forced equal bucket distribution.
- Successfully defended the scoring choice with correct reasoning:
  - `NTILE(5)` can split tied customers across different buckets when ordering is not fully deterministic
  - Equal bucket sizing is not always appropriate for real customer behavior distribution
  - `PERCENT_RANK()` gave more behaviorally consistent scoring for this dataset and this project goal
 
---
 
## Minhyi Notes
 
- Main improvement today was not SQL syntax, but analytical judgment.
- Identified that a scoring method can be technically valid but still produce unstable or misleading business segmentation.
- Correctly argued that in this case, `PERCENT_RANK()` is more suitable than `NTILE(5)` because it avoids forced equal splits and reduces arbitrary score drops caused by tie-heavy data.
- Still need to improve segment definition quality:
  - Some segment rules still overlap conceptually
  - Business meaning of some labels is still broader than it should be
- Business insight quality improved, but prioritization is still not sharp enough:
  - Good observation of segment patterns
  - Still need stronger ranking of which segment matters most and why
 
---
 
## Key Lesson
 
> RFM is not just about assigning scores. It is about choosing a scoring method that matches the business behavior you are trying to represent.
 
---
 
## Performance Evaluation
 
| Dimension            | Score     |
|----------------------|-----------|
| SQL Logic            | 4.9/5     |
| Data Level Control   | 4.8/5     |
| RFM Scoring Method   | 4.7/5     |
| Segmentation Quality | 4.2/5     |
| Business Thinking    | 4.2/5     |
| **Final Score**      | **4.6/5** |
 
---
 
## Progress Update
 
- **SQL Maturity Level:** ~4.3 → 4.4 / 5
- **Current Position:** Strong Analyst SQL / Early Business Analyst Thinking
 
**Critical Weakness:** Technical execution is now strong. The next bottleneck is segment definition precision and business prioritization.
 
---
 
## Session Verdict
 
This was a strong mini project.
 
The SQL structure is analyst-level. The scoring discussion was the most important part of the session because it showed you are starting to question not just whether the query runs, but whether the model itself represents customer behavior correctly.
 
That is a real step forward.
