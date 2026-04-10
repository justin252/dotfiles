# TypeScript & React Guidelines

Sources:
- https://www.typescriptlang.org/docs/
- https://react.dev
- https://google.github.io/styleguide/tsguide.html
- https://typescript-eslint.io/rules/

Auto-consult when writing or reviewing TypeScript or React/JSX code.

## TypeScript

- `strict: true` in tsconfig. Non-negotiable. Enables `noImplicitAny`, `strictNullChecks`, etc.
- Explicit return types on all exported functions/hooks. Prevents `any` creep, forces intent.
- No `any` without `// TODO(type): <reason>`. Use `unknown` + type guard instead.
- Prefer `interface` for public APIs (object shapes). Use `type` for unions, intersections, mapped types.
- Avoid type assertions (`as Foo`). Use type guards (`instanceof`, `in`, discriminated unions) instead.
- No `enum`. Use `const` objects with `as const` + `keyof typeof`:
  ```ts
  const Status = { Active: 'active', Inactive: 'inactive' } as const;
  type Status = (typeof Status)[keyof typeof Status];
  ```
- `readonly` on object/array props where mutation isn't intended.
- Prefer `const` over `let`. Never `var`.
- Destructure early; avoid deeply chained property access.
- Generic constraints over `any`: `<T extends Record<string, unknown>>` not `<T>`.

## React

- Function components only. No class components.
- Custom hooks must start with `use`. Validate/throw on bad inputs in dev.
- **Exhaustive deps** in `useEffect`/`useCallback`/`useMemo`. Missing deps = stale closure bug.
- No conditional hooks. Hooks must be called unconditionally and in the same order every render.
- Keys must be stable, unique, and derived from data – not array index, not `Math.random()`.
- No spread in JSX props (`<Foo {...props} />`). Makes deps and contract implicit; breaks type safety.
- Colocate state as close to its consumers as possible. Lift only when siblings need it.
- `useCallback`/`useMemo` only for referential stability (passing to child with `memo`, dep of another hook). Not for perf speculation.
- Cleanup all effects that register listeners, timers, or subscriptions:
  ```ts
  useEffect(() => {
    const sub = subscribe(handler);
    return () => sub.unsubscribe();
  }, [handler]);
  ```
- Next.js / RSC: default to Server Components. Add `'use client'` only when browser APIs or hooks are needed.

## Common Agent Mistakes

| Wrong | Right |
|---|---|
| `key={index}` | `key={item.id}` |
| `useEffect(() => { fetch(...) }, [])` with deps missing | include all values read inside effect |
| `const x = value as SomeType` | use type guard or `satisfies` |
| `const [val, setVal] = useState()` (untyped) | `useState<Type>(initial)` |
| `export const fn = () => { ... }` (no return type) | `export const fn = (): ReturnType => { ... }` |
| `useCallback(fn, [])` with stale deps | include all fn's deps |
| `enum Direction { Up, Down }` | `const Direction = { Up: 'up', Down: 'down' } as const` |

## Tooling Baseline

Suggest these when setting up a new TS/React project:
- `typescript-eslint` with `strict` preset
- `eslint-plugin-react-hooks` (enforces exhaustive deps + rules of hooks)
- `prettier` for formatting (don't bikeshed style in reviews)
- `tsconfig.json`: `"strict": true, "noUncheckedIndexedAccess": true, "exactOptionalPropertyTypes": true`
