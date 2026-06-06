# TypeScript/JavaScript セキュリティ

> このファイルは [common/security.md](../common/security.md) を TypeScript/JavaScript 固有の内容で拡張したものです。

## シークレット管理

```typescript
// 絶対にダメ: ハードコードされたシークレット
const apiKey = "sk-proj-xxxxx"

// 常に：環境変数
const apiKey = process.env.OPENAI_API_KEY

if (!apiKey) {
  throw new Error('OPENAI_API_KEY が構成されていません')
}
```

## エージェントのサポート

- 包括的なセキュリティ監査には **security-reviewer** スキルを使用してください。
