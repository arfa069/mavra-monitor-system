
════════════════════════════════════════════════════════════
 PERFORMANCE BENCHMARK — http://localhost:3000
════════════════════════════════════════════════════════════
 Mode: BASELINE CAPTURE
 Date: 2026-06-11T02:35:30.267Z


┌──────────────────────────────────────────────────────────┐
 Page: Jobs (/jobs)
└──────────────────────────────────────────────────────────┘
  TTFB            9ms
  FCP             936ms
  DOM Interactive 14ms
  DOM Complete    699ms
  Full Load       699ms
  HTTP Requests   40
  Transfer        14095.0KB
  JS Bundles      14073.8KB
  CSS Bundles     21.0KB

  BUDGET CHECK (5/7 passing)
    ✅ PASS  FCP              budget=1800ms   actual=936ms
    ✅ PASS  DOM Complete     budget=3000ms   actual=699ms
    ✅ PASS  Full Load        budget=4000ms   actual=699ms
    ❌ FAIL  Total JS         budget=500.0KB  actual=14073.8KB
    ✅ PASS  Total CSS        budget=100.0KB  actual=21.0KB
    ❌ FAIL  Total Transfer   budget=2MB      actual=13.8MB
    ✅ PASS  HTTP Requests    budget=60       actual=40

  TOP SLOWEST RESOURCES
     1.  index.css                          script   0.3KB      570ms
     2.  antd.js                            script   9349.6KB   516ms
     3.  App.tsx                            script   46.9KB     488ms
     4.  env.mjs                            script   0.3KB      448ms
     5.  react-dom-iaMw4cp5.js              script   696.0KB    448ms
     6.  react_jsx-runtime.js               script   29.0KB     429ms
     7.  chunk-CYJPkc-J.js                  script   7.7KB      319ms
     8.  AuthContext.tsx                    script   10.4KB     92ms

┌──────────────────────────────────────────────────────────┐
 Page: Dashboard (/dashboard)
└──────────────────────────────────────────────────────────┘
  TTFB            5ms
  FCP             840ms
  DOM Interactive 326ms
  DOM Complete    626ms
  Full Load       626ms
  HTTP Requests   40
  Transfer        14452.8KB
  JS Bundles      14431.5KB
  CSS Bundles     21.0KB

  BUDGET CHECK (5/7 passing)
    ✅ PASS  FCP              budget=1800ms   actual=840ms
    ✅ PASS  DOM Complete     budget=3000ms   actual=626ms
    ✅ PASS  Full Load        budget=4000ms   actual=626ms
    ❌ FAIL  Total JS         budget=500.0KB  actual=14431.5KB
    ✅ PASS  Total CSS        budget=100.0KB  actual=21.0KB
    ❌ FAIL  Total Transfer   budget=2MB      actual=14.1MB
    ✅ PASS  HTTP Requests    budget=60       actual=40

  TOP SLOWEST RESOURCES
     1.  react-dom-iaMw4cp5.js              script   696.0KB    197ms
     2.  react_jsx-runtime.js               script   29.0KB     197ms
     3.  react_jsx-dev-runtime.js           script   28.7KB     172ms
     4.  App.tsx                            script   46.9KB     171ms
     5.  index.css                          script   33.7KB     170ms
     6.  antd.js                            script   9349.6KB   168ms
     7.  chunk-CYJPkc-J.js                  script   7.7KB      167ms
     8.  JetBrainsMono-400.woff2            css      21.0KB     75ms

┌──────────────────────────────────────────────────────────┐
 Page: Products (/products)
└──────────────────────────────────────────────────────────┘
  TTFB            6ms
  FCP             864ms
  DOM Interactive 322ms
  DOM Complete    646ms
  Full Load       646ms
  HTTP Requests   40
  Transfer        14452.8KB
  JS Bundles      14431.5KB
  CSS Bundles     21.0KB

  BUDGET CHECK (5/7 passing)
    ✅ PASS  FCP              budget=1800ms   actual=864ms
    ✅ PASS  DOM Complete     budget=3000ms   actual=646ms
    ✅ PASS  Full Load        budget=4000ms   actual=646ms
    ❌ FAIL  Total JS         budget=500.0KB  actual=14431.5KB
    ✅ PASS  Total CSS        budget=100.0KB  actual=21.0KB
    ❌ FAIL  Total Transfer   budget=2MB      actual=14.1MB
    ✅ PASS  HTTP Requests    budget=60       actual=40

  TOP SLOWEST RESOURCES
     1.  react-dom-iaMw4cp5.js              script   696.0KB    227ms
     2.  react_jsx-runtime.js               script   29.0KB     225ms
     3.  react_jsx-dev-runtime.js           script   28.7KB     217ms
     4.  App.tsx                            script   46.9KB     216ms
     5.  index.css                          script   33.7KB     214ms
     6.  antd.js                            script   9349.6KB   213ms
     7.  chunk-CYJPkc-J.js                  script   7.7KB      204ms
     8.  JetBrainsMono-400.woff2            css      21.0KB     73ms

┌──────────────────────────────────────────────────────────┐
 Page: Today (/today)
└──────────────────────────────────────────────────────────┘
  TTFB            3ms
  FCP             856ms
  DOM Interactive 324ms
  DOM Complete    642ms
  Full Load       642ms
  HTTP Requests   40
  Transfer        14452.8KB
  JS Bundles      14431.5KB
  CSS Bundles     21.0KB

  BUDGET CHECK (5/7 passing)
    ✅ PASS  FCP              budget=1800ms   actual=856ms
    ✅ PASS  DOM Complete     budget=3000ms   actual=642ms
    ✅ PASS  Full Load        budget=4000ms   actual=642ms
    ❌ FAIL  Total JS         budget=500.0KB  actual=14431.5KB
    ✅ PASS  Total CSS        budget=100.0KB  actual=21.0KB
    ❌ FAIL  Total Transfer   budget=2MB      actual=14.1MB
    ✅ PASS  HTTP Requests    budget=60       actual=40

  TOP SLOWEST RESOURCES
     1.  react-dom-iaMw4cp5.js              script   696.0KB    210ms
     2.  react_jsx-runtime.js               script   29.0KB     208ms
     3.  react_jsx-dev-runtime.js           script   28.7KB     193ms
     4.  App.tsx                            script   46.9KB     192ms
     5.  index.css                          script   33.7KB     190ms
     6.  chunk-CYJPkc-J.js                  script   7.7KB      189ms
     7.  antd.js                            script   9349.6KB   188ms
     8.  JetBrainsMono-400.woff2            css      21.0KB     75ms

┌──────────────────────────────────────────────────────────┐
 Page: Smart Home (/smart-home)
└──────────────────────────────────────────────────────────┘
  TTFB            2ms
  FCP             840ms
  DOM Interactive 323ms
  DOM Complete    629ms
  Full Load       629ms
  HTTP Requests   40
  Transfer        14452.8KB
  JS Bundles      14431.5KB
  CSS Bundles     21.0KB

  BUDGET CHECK (5/7 passing)
    ✅ PASS  FCP              budget=1800ms   actual=840ms
    ✅ PASS  DOM Complete     budget=3000ms   actual=629ms
    ✅ PASS  Full Load        budget=4000ms   actual=629ms
    ❌ FAIL  Total JS         budget=500.0KB  actual=14431.5KB
    ✅ PASS  Total CSS        budget=100.0KB  actual=21.0KB
    ❌ FAIL  Total Transfer   budget=2MB      actual=14.1MB
    ✅ PASS  HTTP Requests    budget=60       actual=40

  TOP SLOWEST RESOURCES
     1.  react-dom-iaMw4cp5.js              script   696.0KB    197ms
     2.  react_jsx-runtime.js               script   29.0KB     194ms
     3.  react_jsx-dev-runtime.js           script   28.7KB     182ms
     4.  env.mjs                            script   3.7KB      182ms
     5.  App.tsx                            script   46.9KB     181ms
     6.  index.css                          script   33.7KB     180ms
     7.  antd.js                            script   9349.6KB   178ms
     8.  chunk-CYJPkc-J.js                  script   7.7KB      177ms

════════════════════════════════════════════════════════════
