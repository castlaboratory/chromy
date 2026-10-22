//! R bindings of `chromy-core`. Every function takes plain vectors, uses
//! 0-based indices, and returns plain vectors or lists; the R side owns the
//! data frames, the classes and the random numbers — the uniforms arrive as
//! arguments, so `set.seed()` governs the selection.

use chromy_core::{
    eligible_positions, eqcv, expected_hits, mpps, multiplicity_estimate, pmr, select_from,
    serpentine, nested, EqcvOptions, Head, Key,
};
use extendr_api::prelude::*;

fn head_mode(head: &str) -> extendr_api::Result<Head> {
    match head {
        "all" => Ok(Head::All),
        "residual" => Ok(Head::Residual),
        other => Err(Error::Other(format!("unknown head mode {other}"))),
    }
}

fn err<T>(r: std::result::Result<T, chromy_core::Error>) -> extendr_api::Result<T> {
    r.map_err(|e| Error::Other(e.to_string()))
}

fn as_usizes(v: &[i32]) -> Vec<usize> {
    v.iter().map(|&i| i as usize).collect()
}

fn as_i32s(v: &[usize]) -> Vec<i32> {
    v.iter().map(|&i| i as i32).collect()
}

/// Probability-minimum-replacement selection down a list. `priority` is
/// 0-based; one uniform in [0, 1) per unit. Returns hits and accounting.
/// @noRd
#[extendr]
fn pmr_rs(lambda: &[f64], unif: &[f64], priority: &[i32]) -> extendr_api::Result<List> {
    let s = err(pmr(lambda, unif, &as_usizes(priority)))?;
    Ok(list!(
        hits = s.hits.iter().map(|&h| h as i32).collect::<Vec<i32>>(),
        effective_lambda = s.effective_lambda,
        sample_size = s.sample_size as f64,
        eps_sum = s.eps_sum,
        corrected_unit = s.corrected_unit.map(|u| u as i32).unwrap_or(-1),
        adjusted_crossings = s.adjusted_crossings as i32,
        max_adjustment = s.max_adjustment
    ))
}

/// Serpentine or nested order over a list of keys (numeric or character
/// vectors). Returns the 0-based order.
/// @noRd
#[extendr]
fn frame_order_rs(keys: List, method: &str) -> extendr_api::Result<Vec<i32>> {
    let mut numeric: Vec<Vec<f64>> = Vec::new();
    let mut categorical: Vec<Vec<String>> = Vec::new();
    let mut shape: Vec<(bool, usize)> = Vec::new();
    for (_, key) in keys.iter() {
        if key.is_string() {
            shape.push((false, categorical.len()));
            categorical.push(
                key.as_string_vector()
                    .ok_or_else(|| Error::Other("a key could not be read as character".into()))?,
            );
        } else {
            shape.push((true, numeric.len()));
            numeric.push(
                key.as_real_vector()
                    .ok_or_else(|| Error::Other("a key could not be read as numeric".into()))?,
            );
        }
    }
    let keys: Vec<Key> = shape
        .iter()
        .map(|&(is_num, i)| {
            if is_num {
                Key::Numeric(&numeric[i])
            } else {
                Key::Categorical(&categorical[i])
            }
        })
        .collect();
    let order = match method {
        "serpentine" => err(serpentine(&keys))?,
        "nested" => err(nested(&keys))?,
        other => return Err(Error::Other(format!("unknown method {other}"))),
    };
    Ok(as_i32s(&order))
}

/// Maximal size measure over the column-major matrix `x` with `nrow` rows.
/// @noRd
#[extendr]
fn mpps_rs(x: &[f64], nrow: i32, n_j: &[f64]) -> extendr_api::Result<Vec<f64>> {
    err(mpps(x, nrow as usize, n_j))
}

/// Expected hits proportional to size, certainties resolved by iteration
/// unless `min_replacement`.
/// @noRd
#[extendr]
fn expected_hits_rs(size: &[f64], n: i32, min_replacement: bool) -> extendr_api::Result<Vec<f64>> {
    err(expected_hits(size, n as u64, min_replacement))
}

/// Equal-CV allocation over the column-major matrix `x`.
/// @noRd
#[extendr]
fn eqcv_rs(
    x: &[f64],
    nrow: i32,
    n: i32,
    max_iterations: i32,
    tolerance: f64,
    damping: f64,
) -> extendr_api::Result<List> {
    let a = err(eqcv(
        x,
        nrow as usize,
        n as u64,
        EqcvOptions {
            max_iterations: max_iterations as usize,
            tolerance,
            damping,
        },
    ))?;
    Ok(list!(
        n_j = a.n_j,
        cv = a.cv,
        used = a.used,
        iterations = a.iterations as i32,
        converged = a.converged
    ))
}

/// List positions (0-based) eligible to be the head.
/// @noRd
#[extendr]
fn eligible_rs(lambda: &[f64], order: &[i32], head: &str) -> extendr_api::Result<Vec<i32>> {
    let order = as_usizes(order);
    Ok(as_i32s(&eligible_positions(lambda, &order, head_mode(head)?)))
}

/// The full selection from a drawn head. `order` and `start` are 0-based;
/// the uniforms feed the sequential selection.
/// @noRd
#[extendr]
fn select_from_rs(
    lambda: &[f64],
    order: &[i32],
    start: i32,
    uniforms: &[f64],
    head: &str,
) -> extendr_api::Result<List> {
    let order = as_usizes(order);
    let s = err(select_from(
        lambda,
        &order,
        start as usize,
        uniforms,
        head_mode(head)?,
    ))?;
    let (eps_sum, corrected_unit, adjusted_crossings, max_adjustment) = match &s.accounting {
        Some(a) => (
            a.eps_sum,
            a.corrected_unit.map(|u| u as i32).unwrap_or(-1),
            a.adjusted_crossings as i32,
            a.max_adjustment,
        ),
        None => (0.0, -1, 0, 0.0),
    };
    Ok(list!(
        head = s.head as i32,
        list = as_i32s(&s.list),
        hits = s.hits.iter().map(|&h| h as i32).collect::<Vec<i32>>(),
        effective_lambda = s.effective_lambda,
        randomised = s.accounting.is_some(),
        eps_sum = eps_sum,
        corrected_unit = corrected_unit,
        adjusted_crossings = adjusted_crossings,
        max_adjustment = max_adjustment
    ))
}

/// Multiplicity estimator with successive-difference variance. `y` is
/// column-major with `nrow` rows; `units` and `positions` are 0-based.
/// @noRd
#[extendr]
fn estimate_rs(
    y: &[f64],
    nrow: i32,
    units: &[i32],
    positions: &[i32],
    expected: &[f64],
    hits: &[i32],
) -> extendr_api::Result<List> {
    let hits: Vec<u64> = hits.iter().map(|&h| h as u64).collect();
    let e = err(multiplicity_estimate(
        y,
        nrow as usize,
        &as_usizes(units),
        &as_usizes(positions),
        expected,
        &hits,
    ))?;
    Ok(list!(
        total = e.total,
        random_draws = e.random_draws as i32,
        sd_variance = e.sd_variance
    ))
}

/// The version of the computational engine.
/// @noRd
#[extendr]
fn core_version_rs() -> String {
    "0.1.1".to_string()
}

extendr_module! {
    mod chromy;
    fn pmr_rs;
    fn frame_order_rs;
    fn mpps_rs;
    fn expected_hits_rs;
    fn eqcv_rs;
    fn eligible_rs;
    fn select_from_rs;
    fn estimate_rs;
    fn core_version_rs;
}
