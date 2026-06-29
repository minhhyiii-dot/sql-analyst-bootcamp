## Day 35 — Partial

**Time spent:** Not recorded  
**Main topic:** Re-entry 1 — Data Grain & JOIN Safety Refresh  
**Level:** 3.8/5  

### Session Summary

Today was a re-entry warm-up after a long pause from the SQL bootcamp.

The session focused on rebuilding core analyst muscle memory instead of starting the heavy Project 5 immediately.

### What I Practiced

- Identifying JOIN explosion
- Understanding one-to-many table relationships
- Reviewing data grain
- Choosing the correct validation layer before customer-level aggregation
- Separating order-level validation from customer-level revenue logic

### Key Concepts Reviewed

`orders → order_items` is one-to-many.  
`orders → payments` is also one-to-many.

Joining both before aggregation can create row multiplication:

```text
2 order_items × 2 payments = 4 joined rows
