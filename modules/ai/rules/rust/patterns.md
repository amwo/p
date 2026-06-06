# Rust パターン

> このファイルは [common/patterns.md](../common/patterns.md) を Rust 固有の内容で拡張したものです。
> [Rust Design Patterns](https://rust-unofficial.github.io/patterns/) に基づいています。

## ビルダーパターン (Builder Pattern)

```rust
#[derive(Default)]
pub struct RequestBuilder {
    url: String,
    headers: Vec<(String, String)>,
    timeout: Option<Duration>,
}

impl RequestBuilder {
    pub fn url(mut self, url: impl Into<String>) -> Self {
        self.url = url.into();
        self
    }

    pub fn header(mut self, key: &str, value: &str) -> Self {
        self.headers.push((key.to_owned(), value.to_owned()));
        self
    }

    pub fn timeout(mut self, timeout: Duration) -> Self {
        self.timeout = Some(timeout);
        self
    }

    pub fn build(self) -> Result<Request, BuildError> {
        // バリデーションと構築
    }
}
```

## Newtype パターン

```rust
pub struct UserId(u64);
pub struct Email(String);

impl Email {
    pub fn new(s: &str) -> Result<Self, ValidationError> {
        if s.contains('@') {
            Ok(Self(s.to_owned()))
        } else {
            Err(ValidationError::InvalidEmail)
        }
    }
}
```

## Result 型のエイリアス

```rust
pub type Result<T> = std::result::Result<T, Error>;

pub fn process() -> Result<Data> {
    // ...
}
```

## Extension Traits (拡張トレイト)

```rust
pub trait StrExt {
    fn truncate_to(&self, max_len: usize) -> &str;
}

impl StrExt for str {
    fn truncate_to(&self, max_len: usize) -> &str {
        if self.len() <= max_len {
            self
        } else {
            &self[..max_len]
        }
    }
}
```

## RAII ガード

```rust
pub struct MutexGuard<'a, T> {
    lock: &'a Mutex<T>,
}

impl<T> Drop for MutexGuard<'_, T> {
    fn drop(&mut self) {
        self.lock.unlock();
    }
}
```
