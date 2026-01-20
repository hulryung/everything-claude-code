---
name: frontend-patterns
description: Language-agnostic frontend development patterns, UI architecture, and best practices.
---

# Frontend Development Patterns

Language-agnostic patterns for modern frontend development, UI architecture, and performant user interfaces.

## Component Architecture

### Component Hierarchy
```
┌─────────────────────────────────────┐
│           App (Root)                │
├─────────────────────────────────────┤
│  ┌─────────┐  ┌─────────────────┐  │
│  │ Sidebar │  │   Main Content  │  │
│  │         │  │  ┌───────────┐  │  │
│  │ - Nav   │  │  │  Header   │  │  │
│  │ - Links │  │  ├───────────┤  │  │
│  │         │  │  │  Content  │  │  │
│  │         │  │  │  - Card   │  │  │
│  │         │  │  │  - List   │  │  │
│  └─────────┘  │  └───────────┘  │  │
│               └─────────────────┘  │
└─────────────────────────────────────┘
```

### Component Types

**1. Presentational Components**
- Focus on UI appearance
- Receive data via props
- No business logic
- Highly reusable

**2. Container Components**
- Manage state and data
- Connect to services/stores
- Pass data to presentational components
- Handle business logic

**3. Layout Components**
- Define page structure
- Handle responsive design
- Manage spacing and grid

### Composition Pattern
```
# Instead of inheritance, compose smaller components

<Card>
  <CardHeader>
    <Title>My Title</Title>
  </CardHeader>
  <CardBody>
    <Content />
  </CardBody>
  <CardFooter>
    <Actions />
  </CardFooter>
</Card>
```

## State Management

### State Types
```
1. Local State      - Component-specific (form inputs, toggles)
2. Shared State     - Multiple components (user data, theme)
3. Server State     - Data from API (cached, synced)
4. URL State        - Navigation, filters, pagination
```

### State Lifting
```
# When siblings need shared state, lift to parent

Parent (owns state)
├── ChildA (receives state as prop)
└── ChildB (receives state as prop)
```

### Global State Guidelines
- Only put truly global data in global state
- Keep state as local as possible
- Normalize complex data structures
- Avoid duplicating server data

## Data Fetching Patterns

### Loading States
```
┌─────────────────────────────┐
│  Loading: Show skeleton     │
│  Error: Show error message  │
│  Empty: Show empty state    │
│  Success: Show data         │
└─────────────────────────────┘
```

### Caching Strategy
```
1. Cache-first     - Use cache, fetch in background
2. Network-first   - Try network, fallback to cache
3. Stale-while-    - Show stale data, update when ready
   revalidate
```

### Optimistic Updates
```
1. User clicks "Like"
2. Immediately update UI
3. Send request to server
4. If fails, rollback UI
```

## Form Handling

### Form States
```
- Pristine: No changes made
- Dirty: User has made changes
- Touched: Field has been focused/blurred
- Valid/Invalid: Validation status
- Submitting: Form is being submitted
```

### Validation Approach
```
1. On blur    - Validate when field loses focus
2. On change  - Validate as user types (debounced)
3. On submit  - Validate all fields before submit

# Best: Combine on blur + on submit
```

### Error Display
```
┌─────────────────────────────┐
│ Email                       │
│ ┌─────────────────────────┐ │
│ │ invalid@               │ │
│ └─────────────────────────┘ │
│ ⚠ Please enter valid email  │
└─────────────────────────────┘
```

## Performance Optimization

### Rendering Optimization
```
1. Memoization     - Cache expensive computations
2. Virtualization  - Render only visible items
3. Lazy Loading    - Load components on demand
4. Code Splitting  - Split bundles by route
```

### Virtual Lists
For lists with 100+ items:
```
┌─────────────────┐
│ (buffer above)  │  ← Rendered but hidden
├─────────────────┤
│ Visible Item 1  │  ← Visible viewport
│ Visible Item 2  │
│ Visible Item 3  │
├─────────────────┤
│ (buffer below)  │  ← Rendered but hidden
└─────────────────┘
     ↓
   (1000 more items not rendered)
```

### Image Optimization
```
1. Lazy load images below fold
2. Use appropriate formats (WebP, AVIF)
3. Serve responsive sizes (srcset)
4. Use placeholder/blur during load
```

### Bundle Optimization
```
1. Tree shaking     - Remove unused code
2. Minification     - Reduce file size
3. Compression      - Gzip/Brotli
4. Code splitting   - Load only what's needed
```

## Error Handling

### Error Boundaries
```
┌─────────────────────────────────┐
│         App (Root)              │
│  ┌───────────────────────────┐  │
│  │    Error Boundary         │  │
│  │  ┌─────────────────────┐  │  │
│  │  │   Widget (may fail) │  │  │
│  │  └─────────────────────┘  │  │
│  │                           │  │
│  │  If error:                │  │
│  │  "Something went wrong"   │  │
│  │  [Retry] button           │  │
│  └───────────────────────────┘  │
└─────────────────────────────────┘
```

### Error Display Hierarchy
```
1. Inline errors     - Field-level validation
2. Section errors    - Component-level failures
3. Page errors       - Route-level failures
4. Global errors     - App-level issues (toast/banner)
```

## Accessibility (a11y)

### Semantic HTML
```html
<!-- GOOD: Semantic -->
<nav>
  <ul>
    <li><a href="/home">Home</a></li>
  </ul>
</nav>
<main>
  <article>
    <h1>Title</h1>
    <p>Content</p>
  </article>
</main>

<!-- BAD: Div soup -->
<div class="nav">
  <div class="item" onclick="...">Home</div>
</div>
```

### Keyboard Navigation
```
Tab        - Move between interactive elements
Enter      - Activate buttons, links
Space      - Toggle checkboxes, buttons
Escape     - Close modals, dropdowns
Arrow keys - Navigate within widgets
```

### ARIA Guidelines
```html
<!-- Label for screen readers -->
<button aria-label="Close dialog">×</button>

<!-- Describe current state -->
<button aria-expanded="false">Menu</button>

<!-- Live regions for updates -->
<div aria-live="polite">3 items added to cart</div>
```

### Focus Management
```
1. Visible focus indicator
2. Logical tab order
3. Trap focus in modals
4. Return focus when modal closes
```

## Responsive Design

### Breakpoints
```
Mobile:  < 640px   (sm)
Tablet:  640-1024px (md)
Desktop: > 1024px  (lg/xl)
```

### Mobile-First Approach
```css
/* Base styles for mobile */
.container {
  padding: 16px;
}

/* Enhance for larger screens */
@media (min-width: 640px) {
  .container {
    padding: 24px;
  }
}
```

### Responsive Patterns
```
1. Fluid layouts    - Percentage widths
2. Flexible images  - max-width: 100%
3. Media queries    - Breakpoint styles
4. Container queries - Component-based responsive
```

## Animation Guidelines

### Performance
```
# GPU-accelerated (smooth)
transform, opacity

# Causes reflow (avoid)
width, height, top, left, margin
```

### Motion Principles
```
1. Purpose   - Animation should have meaning
2. Duration  - 150-300ms for UI, 300-500ms for emphasis
3. Easing    - ease-out for enter, ease-in for exit
4. Reduction - Respect prefers-reduced-motion
```

### Animation States
```
Enter:   fade-in, slide-up
Exit:    fade-out, slide-down
Hover:   scale, color change
Loading: skeleton, spinner
```

## Testing Strategies

### Testing Pyramid
```
        /\
       /E2E\      - Critical user flows
      /──────\
     /Integr- \   - Component interactions
    /  ation   \
   /────────────\
  /    Unit      \ - Individual functions
 /________________\
```

### What to Test
```
1. User interactions  - Click, type, submit
2. State changes     - Loading, error, success
3. Edge cases        - Empty, overflow, error
4. Accessibility     - Keyboard, screen reader
```

## File Organization

### Feature-Based Structure
```
src/
├── features/
│   ├── auth/
│   │   ├── components/
│   │   ├── hooks/
│   │   ├── services/
│   │   └── index.js
│   └── dashboard/
│       ├── components/
│       ├── hooks/
│       └── index.js
├── shared/
│   ├── components/
│   ├── hooks/
│   └── utils/
└── App.js
```

---

**Remember**: Modern frontend patterns enable maintainable, performant user interfaces. Choose patterns that fit your project complexity - start simple and add abstraction when needed.
