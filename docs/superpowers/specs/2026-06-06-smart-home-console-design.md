# Smart Home Console Enhancement Design

- Date: 2026-06-06
- Status: Approved for planning
- Scope: Smart Home page enhancement in `frontend/src/features/smart-home` and `backend/app/domains/smart_home`

## Summary

Upgrade the current Smart Home page from a basic Home Assistant entity list into a fuller device control console. The enhanced page will keep the current card-based layout, add richer inline controls for supported devices, introduce clearer scene and script presentation, and add a two-layer preference system with global defaults plus per-user overrides.

The design intentionally reuses the existing route, existing Home Assistant integration, and existing visual language. The goal is to improve usefulness without turning the feature into a separate management product or redesigning the page into a different application surface.

## Goals

1. Keep `/smart-home` as the single Smart Home entry point.
2. Preserve the current card-grid browsing model and current visual style.
3. Add missing inline control capabilities for `fan` and `climate`.
4. Make `scene` and `script` entities visible and understandable when present.
5. Support page organization with:
   - global defaults
   - per-user overrides
   - aliasing
   - hiding
   - sorting
   - area display customization
   - search and filtering
6. Make the page behavior explainable when a device type is absent because Home Assistant did not return any entities of that type.

## Non-Goals

1. No automation builder.
2. No historical charts or energy analytics.
3. No separate Smart Home admin app.
4. No major route or navigation redesign.
5. No speculative general-purpose metadata platform beyond Smart Home needs.
6. No drag-and-drop-heavy redesign if simpler ordering controls meet the requirement.

## Current State

The current page already:

1. Loads Home Assistant entities through `/v1/smart-home/entities`.
2. Groups entities by `area` or `domain`.
3. Supports:
   - `light` / `switch` / `fan` on-off toggles
   - `cover` open, stop, close
   - `scene` / `script` run button when those entities exist in the payload
4. Shows connection status, refresh, and configuration controls.
5. Uses SSE to reflect live state changes.

The current gaps are:

1. `fan` advanced controls are not surfaced in the UI.
2. `climate` controls are display-only.
3. `scene` and `script` are only conditionally visible as ordinary entity cards and have no dedicated affordance or empty-state explanation.
4. Preference persistence is not implemented end to end for page layout and entity presentation.
5. Search, filtering, visibility control, and area-level organization are missing.

## User Decisions Captured

The user approved these constraints during brainstorming:

1. Build the fuller console instead of a minimal-only enhancement.
2. Preference scope should support both:
   - global defaults
   - per-user overrides
3. Area behavior should remain anchored to Home Assistant source areas, with local display customization layered on top.
4. `fan` and `climate` advanced controls should appear inline on the device card rather than in a drawer or modal-first workflow.

## Recommended Approach

Use a focused enhancement strategy:

1. Keep the current route and page shell.
2. Extend backend APIs only where the page lacks required state or persistence.
3. Add preference APIs centered on Smart Home display needs.
4. Return merged effective display data to the frontend so the page does not have to manually reconcile many preference layers on every render.
5. Keep the frontend card model but enrich controls and page-level organization tools.

This approach avoids over-design and keeps the blast radius lower than introducing a new layout subsystem or a separate configuration product.

## Functional Design

### 1. Top-Level Page Structure

The page remains a single Smart Home console with three visible layers:

1. Header row
   - title
   - subtitle
   - connected or offline status
   - refresh
   - configure
2. Control toolbar
   - search input
   - domain filter
   - area filter
   - availability filter
   - show hidden toggle
   - sort mode selector
   - reset my overrides action
3. Content sections
   - optional scene and script action section
   - grouped device sections by effective area
   - empty states where appropriate

### 2. Entity Presentation

Each entity card should display:

1. effective display name
2. raw `entity_id`
3. state tag
4. availability state
5. type-specific inline controls
6. a settings action for display preferences

The page should prefer effective values rather than raw Home Assistant labels:

1. effective name
2. effective area
3. effective sort order
4. effective hidden state

### 3. Type-Specific Controls

#### Light and Switch

Keep the current on-off switch.

#### Fan

Display inline:

1. on-off switch
2. percentage slider when supported
3. current percentage label

If percentage control is not supported for a given entity, only show the on-off control.

#### Climate

Display inline:

1. current state
2. current or target temperature when available
3. temperature control
4. HVAC mode buttons when supported

Controls should only appear when supported by the entity. The page should not render dead controls for missing attributes or unsupported services.

#### Cover

Keep the current open, stop, and close actions.

#### Scene and Script

Present these in a dedicated action section instead of mixing them into ordinary device groups without explanation. Each card should:

1. show the scene or script name
2. identify whether it is a scene or script
3. provide a clear action label
4. retain confirmation before execution

If there are no scene or script entities, the section should explicitly state that Home Assistant did not return any of that type.

## Preference Model

### 1. Preference Layers

Preference resolution should follow this order:

1. per-user override
2. global default
3. Home Assistant source value

This applies to both entity-level display settings and area-level display settings.

### 2. Entity-Level Preferences

Each entity can store:

1. alias
2. hidden
3. sort order
4. display area override
5. metadata for future Smart Home-specific presentation needs

The UI allows editing these values either:

1. for the current user only
2. as a global default when the user has the required privilege

### 3. Area-Level Preferences

Area preferences are anchored to the Home Assistant source area and should support:

1. display name
2. sort order
3. hidden

This preserves Home Assistant as the source of truth for physical grouping while allowing the local application to tune how those groups appear.

## Backend Design

### 1. Data Storage

Introduce or reshape persistence around two logical levels:

1. global entity preferences
2. per-user entity preferences

and two matching area preference scopes:

1. global area preferences
2. per-user area preferences

The implementation may:

1. extend the existing `SmartHomeEntityPreference` model for user scope
2. add a new model for global entity preferences
3. add one or more area-preference models

The storage design should optimize for clarity over aggressive normalization.

### 2. Effective Entity Payload

`GET /v1/smart-home/entities` should evolve from returning only normalized Home Assistant entities to returning effective display entities with merged preference state. Each entity should include enough information for the frontend to render dynamic controls and settings safely.

Recommended additions:

1. `effective_name`
2. `effective_area`
3. `supports`
4. capability-related attributes needed by `fan` and `climate`
5. markers that help the UI explain hidden or inherited state where needed

### 3. Preference APIs

Add focused APIs for:

1. fetching preference state required by the page
2. updating global entity preferences
3. updating user entity preferences
4. updating global area preferences
5. updating user area preferences
6. resetting current-user overrides

The API surface should stay Smart Home-specific rather than pretending to be a generic settings framework.

### 4. Permission Model

Keep these semantics:

1. `smart_home:read` for reading entities and merged display state
2. `smart_home:control` for device actions
3. `smart_home:configure` for Home Assistant connection configuration

For this feature, global layout management should be handled by the same privilege used for configuration unless later requirements justify a separate permission.

## Frontend Design

### 1. Toolbar Behavior

The toolbar should support:

1. free-text search by effective name and entity id
2. domain filter
3. area filter
4. availability filter
5. hidden toggle
6. sort mode
7. reset current-user overrides

Filtering should happen on the effective merged entity list.

### 2. Grouping Rules

Grouping should use effective area first. If an entity has no area after preference resolution, fall back to domain-based grouping.

The group header should show:

1. display name
2. item count
3. area settings action

### 3. Preference Editing

Each entity card should expose display settings such as:

1. alias
2. hidden
3. display area
4. sort order
5. scope selector: me or global

Area headers should expose:

1. display name
2. hidden
3. sort order
4. scope selector: me or global

If the current user lacks global-management privilege, only the personal scope should be available.

### 4. Empty and Status States

The page must distinguish between:

1. connection failure
2. integration disabled
3. no supported entities
4. no scene entities
5. no script entities
6. filters removing all currently visible results

These states should not collapse into a single vague empty message.

## Error Handling

1. Failed control actions should show the backend reason and refresh relevant data afterward.
2. Failed preference saves should preserve user input and avoid false success states.
3. Unsupported capabilities should simply not render controls.
4. Live-update disconnects should be shown clearly without wiping the current page state.

## Validation Plan

### Backend

Add or extend tests for:

1. preference merge priority
2. global versus user override behavior
3. area preference merge behavior
4. permission enforcement
5. fan percentage service handling
6. climate mode and temperature handling
7. reset behavior

### Frontend

Add focused tests for:

1. grouping and filtering
2. capability-based control rendering
3. scene and script section visibility
4. preference form scope switching
5. state updates after save and after control actions

### Manual Verification

Manual validation should cover real local Home Assistant data for:

1. `switch`
2. `light`
3. `fan`
4. `climate`
5. `cover`
6. `scene`
7. `script`

and confirm:

1. per-user overrides do not leak into global defaults
2. global defaults apply to ordinary users when no personal override exists
3. unsupported advanced controls stay hidden
4. empty states are explanatory

## Risks and Mitigations

### Risk 1: Overcomplicated Preference Resolution

Mitigation:

1. keep merge rules explicit and linear
2. compute effective values server-side
3. add tests around inheritance and reset behavior

### Risk 2: Home Assistant Capability Variance

Mitigation:

1. drive the UI from capability flags and actual attributes
2. avoid assuming every `fan` or `climate` supports the same controls

### Risk 3: UI Clutter

Mitigation:

1. keep advanced controls type-specific
2. use inline expansion only where helpful
3. preserve the current card rhythm and visual restraint

## Open Implementation Choices

These details can be finalized in implementation planning without reopening product scope:

1. whether ordering is done through numeric sort fields only or also through lightweight reorder actions
2. exact API shape for preference batch reads
3. whether some settings are edited in popovers, dropdowns, or a compact modal

Those are engineering and UX mechanics, not unresolved product direction.

## Implementation Readiness

This design is ready to be translated into an implementation plan. The scope, preference model, interaction model, capability rules, and validation boundaries have all been decided closely enough to plan concrete backend and frontend tasks.
