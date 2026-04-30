WITH daily AS(
    SELECT
    *,
    row_number() over(PARTITION BY dmd.ticker ORDER BY dmd.trade_date DESC) AS rnd
    FROM daily_market_data dmd 
),
monthly AS(
    SELECT
    *,
    row_number() over(PARTITION BY mf.ticker ORDER BY mf.report_month DESC) AS rnm	
    FROM monthly_fundamentals mf 
),
lastest_daily AS(
    SELECT
    *
    FROM daily
    WHERE rnd = 1
),
lastest_monthly AS(
    SELECT
    *
    FROM monthly
    WHERE rnm = 1
),
lastest_20d AS(
    SELECT
    d.ticker,
    SUM(d.foreign_net_buy_bn_vnd) AS foreign_net_buy_20d,
    AVG(d.turnover_pct) AS avg_turnover_20d,
    MAX(CASE WHEN rnd  = 1 THEN d.vol_20d_pct END) AS vol_20d_lasted
    FROM daily d 
    WHERE rnd <= 20
    GROUP BY d.ticker
),
base_data AS(
    SELECT
    cm.ticker,
    cm.company_name,
    cm.business_focus,
    cm.market_cap_group,
    cm.years_listed,
    cm.equity_bn_vnd,
    
    ld.trade_date,
    ld.close_vnd,
    ld.ret_3m_pct,
    ld.ret_6m_pct,
    
    l20.foreign_net_buy_20d,
    l20.avg_turnover_20d,
    l20.vol_20d_lasted,
    
    lm.report_month,
    lm.roe_pct,
    lm.net_income_ttm_bn_vnd,
    lm.pre_sales_bn_vnd,
    lm.backlog_bn_vnd,
    lm.debt_to_equity,
    lm.current_ratio,
    lm.cash_ratio,
    lm.interest_coverage,
    lm.operating_cashflow_bn_vnd,
    COALESCE(lm.legal_issue_flag, 0) AS legal_issue_flag,
    COALESCE(lm.bond_pressure_flag, 0) AS bond_pressure_flag,
    COALESCE(lm.legal_issue_flag, 0) + COALESCE(lm.bond_pressure_flag, 0) AS red_flag
    FROM company_master cm 
    LEFT JOIN lastest_daily ld ON ld.ticker = cm.ticker
    LEFT JOIN lastest_monthly lm ON lm.ticker = cm.ticker
    LEFT JOIN lastest_20d l20 ON l20.ticker = cm.ticker
),
sub_score AS(
    SELECT
    bd.ticker,
    -- growth
    percent_rank() over(PARTITION BY bd.business_focus, bd.market_cap_group ORDER BY bd.ret_3m_pct) * 100 AS ret_3m_score,
    percent_rank() over(PARTITION BY bd.business_focus, bd.market_cap_group ORDER BY bd.ret_6m_pct) * 100 AS ret_6m_score,
    percent_rank() over(PARTITION BY bd.business_focus, bd.market_cap_group ORDER BY bd.roe_pct) * 100 AS roe_score,
    percent_rank() over(PARTITION BY bd.business_focus, bd.market_cap_group ORDER BY bd.net_income_ttm_bn_vnd) * 100 AS net_income_score,
    percent_rank() over(PARTITION BY bd.business_focus, bd.market_cap_group ORDER BY bd.backlog_bn_vnd) * 100 AS backlog_score,
    percent_rank() over(PARTITION BY bd.business_focus, bd.market_cap_group ORDER BY bd.pre_sales_bn_vnd) * 100 AS pre_sales_score,
    percent_rank() over(PARTITION BY bd.business_focus, bd.market_cap_group ORDER BY bd.foreign_net_buy_20d) * 100 AS foreign_net_buy_20d_score,
    -- safe 
    percent_rank() over(PARTITION BY bd.business_focus, bd.market_cap_group ORDER BY bd.debt_to_equity DESC) * 100 AS low_debt_score,
    percent_rank() over(PARTITION BY bd.business_focus, bd.market_cap_group ORDER BY bd.current_ratio) * 100 AS current_ratio_score,
    percent_rank() over(PARTITION BY bd.business_focus, bd.market_cap_group ORDER BY bd.cash_ratio) * 100 AS cash_ratio_score,
    percent_rank() over(PARTITION BY bd.business_focus, bd.market_cap_group ORDER BY bd.interest_coverage) * 100 AS interest_coverage_score,
    percent_rank() over(PARTITION BY bd.business_focus, bd.market_cap_group ORDER BY bd.operating_cashflow_bn_vnd) * 100 AS operating_cashflow_score,
    percent_rank() over(PARTITION BY bd.business_focus, bd.market_cap_group ORDER BY bd.equity_bn_vnd) * 100 AS equity_score,
    percent_rank() over(PARTITION BY bd.business_focus, bd.market_cap_group ORDER BY bd.years_listed) * 100 AS year_listed_score,
    percent_rank() over(PARTITION BY bd.business_focus, bd.market_cap_group ORDER BY bd.avg_turnover_20d) * 100 AS avg_turnover_20d_score,
    -- risk
    percent_rank() over(PARTITION BY bd.business_focus, bd.market_cap_group ORDER BY bd.debt_to_equity) * 100 AS high_debt_risk_score,
    percent_rank() over(PARTITION BY bd.business_focus, bd.market_cap_group ORDER BY bd.current_ratio DESC) * 100 AS low_current_ratio_risk_score,
    percent_rank() over(PARTITION BY bd.business_focus, bd.market_cap_group ORDER BY bd.cash_ratio DESC) * 100 AS low_cash_ratio_risk_score,
    percent_rank() over(PARTITION BY bd.business_focus, bd.market_cap_group ORDER BY bd.interest_coverage DESC) * 100 AS low_interest_coverage_risk_score,
    percent_rank() over(PARTITION BY bd.business_focus, bd.market_cap_group ORDER BY bd.operating_cashflow_bn_vnd DESC) * 100 AS low_ocf_risk_score,
    percent_rank() over(PARTITION BY bd.business_focus, bd.market_cap_group ORDER BY bd.vol_20d_lasted) * 100 AS high_volatility_risk_score
    FROM base_data bd
), 
final_score AS(
    SELECT
    ss.ticker,
    round(
        0.1 * ss.ret_3m_score + 
        0.1 * ss.ret_6m_score + 
        0.15 * ss.roe_score + 
        0.15 * ss.net_income_score + 
        0.25 * ss.backlog_score + 
        0.20 * ss.pre_sales_score + 
        0.05 * ss.foreign_net_buy_20d_score, 0
    ) AS growth_score,
    round(
        0.25 * ss.low_debt_score +
        0.2 * ss.current_ratio_score +
        0.1 * ss.cash_ratio_score +
        0.2 * ss.interest_coverage_score +
        0.15 * ss.operating_cashflow_score +
        0.05 * ss.equity_score +
        0.025 * ss.year_listed_score +
        0.025 * ss.avg_turnover_20d_score, 0
    ) AS safe_score,
    round(
        0.25 * ss.high_debt_risk_score + 
        0.175 * ss.low_current_ratio_risk_score +
        0.125 * ss.low_cash_ratio_risk_score +
        0.2 * ss.low_interest_coverage_risk_score +
        0.2 * ss.low_ocf_risk_score +
        0.05 * ss.high_volatility_risk_score, 0 
    ) AS risk_score
    FROM sub_score ss 
),
segments AS (
    SELECT
    bd.*,
    fs.growth_score,
    fs.safe_score,
    fs.risk_score,
    CASE
    WHEN bd.red_flag >= 1 THEN 'Rủi ro'
    WHEN risk_score > 60 THEN 'Rủi ro'
    WHEN growth_score < 50 AND safe_score < 40 THEN 'Rủi ro'
    WHEN growth_score > 70 AND risk_score < 60 AND safe_score > 50 THEN 'Tăng trưởng'
    WHEN safe_score > 80 AND risk_score < 30 THEN 'An toàn'
    ELSE 'Trung tính'
    END AS segment
    FROM base_data bd
    JOIN final_score fs ON bd.ticker = fs.ticker
)
SELECT
ticker,
company_name,
business_focus,
growth_score,
safe_score,
risk_score,
red_flag,
segment
FROM segments
