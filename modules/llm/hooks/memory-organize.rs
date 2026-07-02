//! Keep project-root .memory/ lean and index-shaped.
//!
//! Runs as a PostToolUse hook on Write|Edit, and can also run without a file
//! path from turn-level hooks. Memory bloat lowers an agent's efficiency, so
//! every entry must be a small, topic-scoped unit and the directory must expose
//! a minimal INDEX.md. The agent then loads only the index plus the single
//! entry it needs, instead of the whole memory store.
//!
//! Contract (shared by Claude and Codex):
//! - stdin : JSON tool event (both schemas are handled).
//! - exit 0: ok -- index regenerated, or the path is not a memory entry.
//! - exit 2: rejected -- stderr explains the fix and is fed back to the agent.
//!
//! INDEX.md is written with a plain filesystem write (not the Write tool), so
//! it never re-triggers this hook.

use std::collections::BTreeMap;
use std::fs;
use std::io::{self, Read};
use std::path::{Path, PathBuf};
use std::process::exit;

const MARKER: &str = ".memory";
const INDEX: &str = "INDEX.md";
const MAX_ENTRY_LINES: usize = 120;
const AUTO_BEGIN: &str = "<!-- AUTO:memory-index (managed by hook; do not edit below) -->";
const AUTO_END: &str = "<!-- /AUTO:memory-index -->";

fn main() {
    let mut input = String::new();
    if io::stdin().read_to_string(&mut input).is_err() {
        exit(0);
    }

    // Extract the written path. The key location/name differs across harnesses
    // (Claude/Codex `tool_input.file_path`, Cursor top-level `file_path`, Gemini
    // `absolute_path`/`path`); json_string scans the whole payload by key.
    let path = match json_string(&input, "file_path")
        .or_else(|| json_string(&input, "path"))
        .or_else(|| json_string(&input, "absolute_path"))
    {
        Some(p) => p,
        None => {
            if let Some(root) = cwd_memory_root() {
                validate_memory_root(&root);
                write_index(&root);
            }
            exit(0);
        }
    };
    if !path.ends_with(".md") {
        exit(0);
    }

    let abs = absolute(&path);
    let root = match memory_root(&abs) {
        Some(r) => r,
        None => exit(0), // write is outside any .memory/
    };
    if abs.file_name().and_then(|s| s.to_str()) == Some(INDEX) {
        exit(0); // index is auto-managed
    }

    validate_memory_entry(&abs, &root, path.as_str());
    write_index(&root);
    exit(0);
}

fn validate_memory_entry(abs: &Path, root: &Path, fallback: &str) {
    let text = match fs::read_to_string(abs) {
        Ok(t) => t,
        Err(_) => return, // nothing to validate (e.g. deletion)
    };

    let rel = relative_path(abs, root).unwrap_or_else(|| fallback.to_string());
    validate_entry_text(&rel, &text);
}

fn validate_entry_text(rel: &str, text: &str) {
    match parse_entry(text) {
        None => reject(&format!(
            "{rel}: missing frontmatter. Each .memory entry needs `topic` and \
             `description` to be indexable."
        )),
        Some((fm, body)) => {
            let missing: Vec<&str> = ["topic", "description"]
                .into_iter()
                .filter(|k| field(&fm, k).is_none())
                .collect();
            if !missing.is_empty() {
                reject(&format!(
                    "{rel}: frontmatter missing {}. Add them so the entry is \
                     grouped under its topic in INDEX.md.",
                    missing.join(", ")
                ));
            }
            if body.lines().count() > MAX_ENTRY_LINES {
                reject(&format!(
                    "{rel}: entry exceeds {MAX_ENTRY_LINES} lines. Split it into \
                     smaller topic-scoped entries to keep memory lean."
                ));
            }
        }
    }
}

fn validate_memory_root(root: &Path) {
    let mut files = Vec::new();
    collect_md(root, &mut files);
    for file in files {
        if file.file_name().and_then(|s| s.to_str()) == Some(INDEX) {
            continue;
        }
        validate_memory_entry(&file, root, "");
    }
}

fn reject(msg: &str) -> ! {
    eprintln!("{msg}");
    exit(2);
}

fn absolute(path: &str) -> PathBuf {
    let p = PathBuf::from(path);
    if p.is_absolute() {
        p
    } else {
        std::env::current_dir().map(|d| d.join(&p)).unwrap_or(p)
    }
}

fn cwd_memory_root() -> Option<PathBuf> {
    memory_root_from_cwd(std::env::current_dir().ok()?)
}

fn memory_root_from_cwd(mut dir: PathBuf) -> Option<PathBuf> {
    loop {
        let root = dir.join(MARKER);
        if root.is_dir() {
            return Some(root);
        }
        if !dir.pop() {
            return None;
        }
    }
}

/// Path up to and including the nearest `.memory` component.
fn memory_root(abs: &Path) -> Option<PathBuf> {
    let mut acc = PathBuf::new();
    for comp in abs.components() {
        acc.push(comp.as_os_str());
        if comp.as_os_str().to_str() == Some(MARKER) {
            return Some(acc);
        }
    }
    None
}

fn relative_path(abs: &Path, root: &Path) -> Option<String> {
    abs.strip_prefix(root)
        .ok()
        .and_then(|p| p.to_str())
        .map(ToString::to_string)
}

/// Read a top-level `key: value` from a frontmatter block.
fn field(block: &str, key: &str) -> Option<String> {
    let prefix = format!("{key}:");
    for line in block.lines() {
        if let Some(rest) = line.strip_prefix(&prefix) {
            let value = rest.trim().trim_matches('"').trim().to_string();
            if !value.is_empty() {
                return Some(value);
            }
        }
    }
    None
}

/// Split a `---`-delimited frontmatter header from the body.
fn parse_entry(text: &str) -> Option<(String, String)> {
    let rest = text.strip_prefix("---\n")?;
    let idx = rest.find("\n---")?;
    let fm = rest[..idx].to_string();
    let after = &rest[idx + "\n---".len()..];
    let body = after.strip_prefix('\n').unwrap_or(after).to_string();
    Some((fm, body))
}

/// Minimal extractor for a JSON string value by key. The input is
/// machine-generated tool-event JSON, so a targeted scan is sufficient and
/// avoids pulling in a JSON crate (keeps the hook std-only).
fn json_string(src: &str, key: &str) -> Option<String> {
    let needle = format!("\"{key}\"");
    let bytes = src.as_bytes();
    let mut i = src.find(&needle)? + needle.len();
    while i < bytes.len() && bytes[i].is_ascii_whitespace() {
        i += 1;
    }
    if i >= bytes.len() || bytes[i] != b':' {
        return None;
    }
    i += 1;
    while i < bytes.len() && bytes[i].is_ascii_whitespace() {
        i += 1;
    }
    if i >= bytes.len() || bytes[i] != b'"' {
        return None;
    }
    i += 1;
    let mut out: Vec<u8> = Vec::new();
    while i < bytes.len() {
        match bytes[i] {
            b'\\' => {
                i += 1;
                if i >= bytes.len() {
                    break;
                }
                match bytes[i] {
                    b'n' => out.push(b'\n'),
                    b't' => out.push(b'\t'),
                    b'r' => out.push(b'\r'),
                    other => out.push(other), // \" \\ \/ ...
                }
            }
            b'"' => return Some(String::from_utf8_lossy(&out).into_owned()),
            c => out.push(c),
        }
        i += 1;
    }
    None
}

/// Render a compact, topic-grouped index of every entry under `root`.
fn build_index(root: &Path) -> String {
    let mut files = Vec::new();
    collect_md(root, &mut files);

    let mut groups: BTreeMap<String, Vec<(String, String, String)>> = BTreeMap::new();
    for file in files {
        if file.file_name().and_then(|s| s.to_str()) == Some(INDEX) {
            continue;
        }
        let text = match fs::read_to_string(&file) {
            Ok(t) => t,
            Err(_) => continue,
        };
        let fm = match parse_entry(&text) {
            Some((fm, _)) => fm,
            None => continue,
        };
        let topic = field(&fm, "topic").unwrap_or_else(|| "uncategorized".to_string());
        let title = field(&fm, "title")
            .or_else(|| field(&fm, "name"))
            .unwrap_or_else(|| stem(&file));
        let desc = field(&fm, "description").unwrap_or_default();
        let rel = file
            .strip_prefix(root)
            .ok()
            .and_then(|p| p.to_str())
            .unwrap_or_default()
            .to_string();
        groups.entry(topic).or_default().push((title, desc, rel));
    }

    let mut lines = vec![AUTO_BEGIN.to_string(), String::new()];
    for (topic, mut entries) in groups {
        entries.sort();
        lines.push(format!("## {topic}"));
        for (title, desc, rel) in entries {
            let tail = if desc.is_empty() {
                String::new()
            } else {
                format!(" — {desc}")
            };
            lines.push(format!("- **{title}**{tail}  `{rel}`"));
        }
        lines.push(String::new());
    }
    lines.push(AUTO_END.to_string());
    lines.join("\n")
}

fn stem(path: &Path) -> String {
    path.file_stem()
        .and_then(|s| s.to_str())
        .unwrap_or("entry")
        .to_string()
}

/// Recursively collect `*.md` paths under `dir`.
fn collect_md(dir: &Path, out: &mut Vec<PathBuf>) {
    let entries = match fs::read_dir(dir) {
        Ok(e) => e,
        Err(_) => return,
    };
    for entry in entries.flatten() {
        let path = entry.path();
        if path.is_dir() {
            collect_md(&path, out);
        } else if path.extension().and_then(|s| s.to_str()) == Some("md") {
            out.push(path);
        }
    }
}

/// Regenerate INDEX.md, preserving any manual header above the AUTO block.
fn write_index(root: &Path) {
    let index_path = root.join(INDEX);
    let body = build_index(root);

    let contents = match fs::read_to_string(&index_path) {
        Ok(cur) if cur.contains(AUTO_BEGIN) => {
            let head = cur.split(AUTO_BEGIN).next().unwrap_or("");
            let tail = if cur.contains(AUTO_END) {
                cur.rsplit(AUTO_END).next().unwrap_or("")
            } else {
                ""
            };
            format!("{head}{body}{tail}")
        }
        Ok(cur) => format!("{}\n\n{body}\n", cur.trim_end()),
        Err(_) => format!("# Memory Index\n\n{body}\n"),
    };
    let _ = fs::write(&index_path, contents);
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::time::{SystemTime, UNIX_EPOCH};

    fn temp_dir(name: &str) -> PathBuf {
        let stamp = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_nanos();
        std::env::temp_dir().join(format!(
            "memory-organize-{name}-{}-{stamp}",
            std::process::id()
        ))
    }

    #[test]
    fn memory_root_from_cwd_finds_parent_memory_dir() {
        let dir = temp_dir("parent");
        let memory = dir.join(MARKER);
        let child = dir.join("sub").join("dir");
        fs::create_dir_all(&memory).unwrap();
        fs::create_dir_all(&child).unwrap();

        assert_eq!(memory_root_from_cwd(child), Some(memory));

        let _ = fs::remove_dir_all(dir);
    }

    #[test]
    fn build_index_groups_entries_by_topic() {
        let dir = temp_dir("index");
        let memory = dir.join(MARKER);
        fs::create_dir_all(&memory).unwrap();
        fs::write(
            memory.join("entry.md"),
            "---\ntopic: diagnostics\ndescription: indexed entry.\n---\n\nbody\n",
        )
        .unwrap();

        let index = build_index(&memory);

        assert!(index.contains("## diagnostics"));
        assert!(index.contains("- **entry** — indexed entry.  `entry.md`"));

        let _ = fs::remove_dir_all(dir);
    }
}
