# TypeScript/JavaScript コーディングスタイル

> このファイルは [common/coding-style.md](../common/coding-style.md) を TypeScript/JavaScript 固有の内容で拡張したものです。

## イミュータビリティ (不変性)

イミュータブルな更新にはスプレッド演算子を使用してください：

```typescript
// 間違い: 変更 (Mutation)
function updateUser(user, name) {
  user.name = name  // 変更！
  return user
}

// 正しい: イミュータビリティ
function updateUser(user, name) {
  return {
    ...user,
    name
  }
}
```

## エラー処理

async/await と try-catch を使用してください：

```typescript
try {
  const result = await riskyOperation()
  return result
} catch (error) {
  console.error('Operation failed:', error)
  throw new Error('詳細なユーザーフレンドリーなメッセージ')
}
```

## 入力バリデーション

スキーマベースのバリデーションには Zod を使用してください：

```typescript
import { z } from 'zod'

const schema = z.object({
  email: z.string().email(),
  age: z.number().int().min(0).max(150)
})

const validated = schema.parse(input)
```

## Console.log

- 本番コードに `console.log` ステートメントを含めないでください。
- 代わりに適切なロギングライブラリを使用してください。
- 自動検出についてはフックを参照してください。
