//! loop-ctl — a domain-agnostic self-regulating controller for improvement loops.
//!
//! The metric is a black box: you supply an `evaluator` command that prints a
//! single number (higher is better). loop-ctl turns a stream of attempts into
//! disciplined progress:
//!   - ratchet:  accept a change only if the score beats the best + noise_margin
//!   - stall:    count consecutive non-improvements on the current axis
//!   - pivot:    when an axis stalls, switch to the highest-yield other axis
//!   - explore:  when every axis stalls, reopen one from a fresh angle
//!   - stop:     only on budget exhaustion or global convergence — never on a
//!               single stalled axis (so the loop pivots instead of giving up)
//!
//! State lives in ./.improve/ (config.json, ledger.jsonl, state.json,
//! directive.json, and an `active` sentinel read by the Stop-hook backstop).
//!
//! Subcommands:
//!   loop-ctl init
//!   loop-ctl next
//!   loop-ctl record --axis <A> --score <N> [--hypothesis "..."]
//!   loop-ctl status
//!   loop-ctl stop

use serde::{Deserialize, Serialize};
use std::collections::BTreeMap;
use std::fs;
use std::path::Path;
use std::process::exit;

const DIR: &str = ".improve";

#[derive(Deserialize)]
struct Config {
    #[serde(default)]
    objective: String,
    #[serde(default)]
    evaluator: String,
    axes: Vec<String>,
    #[serde(default = "d_budget")]
    budget: u64,
    #[serde(default = "d_stall")]
    stall_k: u64,
    #[serde(default)]
    noise_margin: f64,
    #[serde(default = "d_patience")]
    global_patience: u64,
}
fn d_budget() -> u64 {
    50
}
fn d_stall() -> u64 {
    4
}
fn d_patience() -> u64 {
    2
}

#[derive(Serialize, Deserialize)]
struct Entry {
    iter: u64,
    axis: String,
    hypothesis: String,
    score: f64,
    accepted: bool,
}

#[derive(Serialize, Deserialize, Default)]
struct State {
    iter: u64,
    best: Option<f64>,
    current_axis: String,
    regime: String,
    explore_passes: u64,
    tries: BTreeMap<String, u64>,
    improves: BTreeMap<String, u64>,
    stall: BTreeMap<String, u64>,
    exhausted: Vec<String>,
    stopped: bool,
    stop_reason: String,
}

#[derive(Serialize)]
struct Directive {
    action: String,
    regime: String,
    axis: String,
    reason: String,
    iter: u64,
    budget: u64,
    best_score: Option<f64>,
    tabu: Vec<String>,
    instructions: String,
}

fn p(name: &str) -> String {
    format!("{DIR}/{name}")
}

fn die(msg: &str) -> ! {
    eprintln!("loop-ctl: {msg}");
    exit(1);
}

fn load_config() -> Config {
    let s = fs::read_to_string(p("config.json")).unwrap_or_else(|_| {
        die("missing .improve/config.json (run `loop-ctl init` after writing it)")
    });
    serde_json::from_str(&s).unwrap_or_else(|e| die(&format!("invalid config.json: {e}")))
}

fn load_state() -> State {
    fs::read_to_string(p("state.json"))
        .ok()
        .and_then(|s| serde_json::from_str(&s).ok())
        .unwrap_or_default()
}

fn save_state(st: &State) {
    let _ = fs::write(p("state.json"), serde_json::to_string_pretty(st).unwrap());
}

fn set_active(active: bool) {
    if active {
        let _ = fs::write(p("active"), "1\n");
    } else {
        let _ = fs::remove_file(p("active"));
    }
}

fn arg(args: &[String], key: &str) -> Option<String> {
    args.iter()
        .position(|a| a == key)
        .and_then(|i| args.get(i + 1).cloned())
}

fn emit(d: &Directive) {
    let json = serde_json::to_string_pretty(d).unwrap();
    let _ = fs::write(p("directive.json"), &json);
    println!("{json}");
}

/// Improvement rate of an axis; untried axes are maximally attractive.
fn rate(st: &State, axis: &str) -> f64 {
    let tries = *st.tries.get(axis).unwrap_or(&0);
    if tries == 0 {
        f64::INFINITY
    } else {
        *st.improves.get(axis).unwrap_or(&0) as f64 / tries as f64
    }
}

fn instructions(regime: &str, axis: &str, cfg: &Config) -> String {
    format!(
        "Make exactly ONE change along the '{axis}' axis ({regime}). Then run the evaluator (`{}`) and record the numeric score: `loop-ctl record --axis {axis} --score <N> --hypothesis \"<what you changed>\"`. Do NOT claim success unless the recorded score beats the current best. Objective: {}",
        cfg.evaluator, cfg.objective
    )
}

fn cmd_init(cfg: &Config) {
    let _ = fs::create_dir_all(DIR);
    let first = cfg.axes.first().cloned().unwrap_or_default();
    let mut st = State::default();
    st.current_axis = first.clone();
    st.regime = "exploit".into();
    save_state(&st);
    set_active(true);
    emit(&Directive {
        action: "continue".into(),
        regime: "exploit".into(),
        axis: first.clone(),
        reason: "loop start".into(),
        iter: 0,
        budget: cfg.budget,
        best_score: None,
        tabu: vec![],
        instructions: instructions("exploit", &first, cfg),
    });
}

fn stop(st: &mut State, reason: &str) {
    st.stopped = true;
    st.stop_reason = reason.into();
    save_state(st);
    set_active(false);
    emit(&Directive {
        action: "stop".into(),
        regime: "done".into(),
        axis: String::new(),
        reason: reason.into(),
        iter: st.iter,
        budget: 0,
        best_score: st.best,
        tabu: st.exhausted.clone(),
        instructions: format!(
            "STOP ({reason}). Best score: {:?}. Summarize what worked and end the loop.",
            st.best
        ),
    });
}

fn cmd_next(cfg: &Config) {
    let mut st = load_state();

    if st.iter >= cfg.budget {
        return stop(&mut st, "budget exhausted");
    }

    let last = st.current_axis.clone();
    let stalled = *st.stall.get(&last).unwrap_or(&0) >= cfg.stall_k || st.exhausted.contains(&last);

    let regime: &str;
    let axis: String;

    if last.is_empty() {
        regime = "exploit";
        axis = cfg.axes.first().cloned().unwrap_or_default();
    } else if !stalled {
        regime = "exploit";
        axis = last.clone();
    } else {
        let cands: Vec<String> = cfg
            .axes
            .iter()
            .filter(|a| !st.exhausted.contains(*a) && **a != last)
            .cloned()
            .collect();
        if !cands.is_empty() {
            // highest improvement-rate, preferring the earliest axis on ties
            let best = cands.iter().fold(cands[0].clone(), |acc, c| {
                if rate(&st, c) > rate(&st, &acc) {
                    c.clone()
                } else {
                    acc
                }
            });
            regime = "pivot";
            axis = best;
        } else {
            st.explore_passes += 1;
            if st.explore_passes > cfg.global_patience {
                return stop(
                    &mut st,
                    "converged: all axes exhausted across explore passes",
                );
            }
            let reopen = cfg
                .axes
                .iter()
                .min_by_key(|a| *st.tries.get(a.as_str()).unwrap_or(&0))
                .cloned()
                .unwrap_or_default();
            st.exhausted.clear();
            st.stall.insert(reopen.clone(), 0);
            regime = "explore";
            axis = reopen;
        }
    }

    let reason = match regime {
        "pivot" => format!("axis '{last}' stalled; pivoting to a higher-yield axis"),
        "explore" => "all axes stalled; reopening one from a different angle".into(),
        _ => "current axis still yielding".into(),
    };

    st.current_axis = axis.clone();
    st.regime = regime.into();
    set_active(true);
    save_state(&st);

    emit(&Directive {
        action: "continue".into(),
        regime: regime.into(),
        axis: axis.clone(),
        reason,
        iter: st.iter,
        budget: cfg.budget,
        best_score: st.best,
        tabu: st.exhausted.clone(),
        instructions: instructions(regime, &axis, cfg),
    });
}

fn cmd_record(cfg: &Config, args: &[String]) {
    let mut st = load_state();
    let axis = arg(args, "--axis").unwrap_or_else(|| st.current_axis.clone());
    let score: f64 = arg(args, "--score")
        .and_then(|s| s.parse().ok())
        .unwrap_or_else(|| die("record requires --score <number>"));
    let hypothesis = arg(args, "--hypothesis").unwrap_or_default();

    let prev_best = st.best.unwrap_or(f64::NEG_INFINITY);
    let accepted = score > prev_best + cfg.noise_margin;

    let entry = Entry {
        iter: st.iter,
        axis: axis.clone(),
        hypothesis,
        score,
        accepted,
    };
    let mut ledger = fs::read_to_string(p("ledger.jsonl")).unwrap_or_default();
    ledger.push_str(&serde_json::to_string(&entry).unwrap());
    ledger.push('\n');
    let _ = fs::write(p("ledger.jsonl"), ledger);

    *st.tries.entry(axis.clone()).or_insert(0) += 1;
    if accepted {
        st.best = Some(score);
        *st.improves.entry(axis.clone()).or_insert(0) += 1;
        st.stall.insert(axis.clone(), 0);
        st.exhausted.retain(|a| a != &axis);
        st.explore_passes = 0;
    } else {
        let s = st.stall.entry(axis.clone()).or_insert(0);
        *s += 1;
        if *s >= cfg.stall_k && !st.exhausted.contains(&axis) {
            st.exhausted.push(axis.clone());
        }
    }
    st.iter += 1;
    save_state(&st);

    let stall = *st.stall.get(&axis).unwrap_or(&0);
    println!(
        "{}",
        serde_json::to_string_pretty(&serde_json::json!({
            "accepted": accepted,
            "score": score,
            "best": st.best,
            "iter": st.iter,
            "axis": axis,
            "axis_stall": stall,
            "exhausted": st.exhausted,
        }))
        .unwrap()
    );
}

fn cmd_status() {
    let st = load_state();
    let active = Path::new(&p("active")).exists();
    println!(
        "{}",
        serde_json::to_string_pretty(&serde_json::json!({
            "active": active,
            "stopped": st.stopped,
            "stop_reason": st.stop_reason,
            "iter": st.iter,
            "best": st.best,
            "current_axis": st.current_axis,
            "regime": st.regime,
        }))
        .unwrap()
    );
}

fn main() {
    let args: Vec<String> = std::env::args().collect();
    match args.get(1).map(String::as_str).unwrap_or("") {
        "init" => cmd_init(&load_config()),
        "next" => cmd_next(&load_config()),
        "record" => cmd_record(&load_config(), &args),
        "status" => cmd_status(),
        "stop" => stop(&mut load_state(), "manual stop"),
        _ => die(
            "usage: loop-ctl <init|next|record|status|stop> [--axis A --score N --hypothesis H]",
        ),
    }
}
