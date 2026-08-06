# Working Hours and Immediate Ordering Design

## Scope

Implement immediate-order availability from `GET /branches/:id/ordering-status`.
The mobile app will not add scheduled-order controls or submit a
`scheduledFor` value as part of this change.

The status endpoint provides proactive guidance. Authenticated cart preview
and order creation remain authoritative because branch availability can change
between requests.

## Architecture

Add typed ordering-status models for effective weekly hours and independent
pickup and delivery availability. Expose a public repository method that calls
the branch-specific ordering-status endpoint without authentication or an `at`
query for the immediate flow.

The checkout flow owns the status associated with its currently resolved
branch. Pickup uses the customer-selected branch. Delivery continues to let
cart preview select an eligible branch; after preview returns its branch ID,
checkout fetches and displays that branch's delivery status.

Availability state stays local to checkout rather than being added to global
bootstrap state. This avoids fetching every branch at startup and prevents
stale availability from becoming long-lived application state.

## Checkout Data Flow

1. When checkout opens or the pickup branch changes, request the selected
   branch's immediate ordering status.
2. Render pickup and delivery as independent states from the response, while
   emphasizing the state relevant to the selected order type.
3. Continue using authenticated cart preview for pricing and delivery branch
   selection.
4. Once a delivery preview resolves a branch, request its status and show the
   delivery state.
5. Disable final confirmation when the relevant status is known to be closed.
6. Refresh status when it is stale before allowing final confirmation. The
   preview and order-creation responses always override earlier guidance.
7. Keep the same UUID idempotency key while retrying one create-order
   submission.

No weekly-hours inference will be used to decide whether ordering is open.
Only the server-provided availability objects and authoritative preview/create
responses control the flow.

## Availability Presentation

Checkout shows a compact status card with:

- separate pickup and delivery states;
- a polite open or unavailable label;
- the next opening when `nextOpeningAt` is present;
- the branch timezone when it differs from the device timezone;
- retry affordance when working hours could not be loaded.

Returned instants are parsed as UTC and formatted in the returned IANA
timezone. Weekly clock strings remain branch-local display values and are not
interpreted using the device timezone.

## Error Handling

An ordering-status request failure does not independently block checkout,
because the status endpoint is advisory. The app displays a polite message
explaining that hours could not be checked and that availability will be
verified during checkout. Preview and order creation still run and enforce the
backend rules.

For HTTP `409` with `errorCode: ORDERING_CLOSED`, parse the public metadata into
a typed value containing branch ID, order type, check kind, timezone, closure
source, evaluated time, and next opening. Never expose internal or day-off
details.

If `nextOpeningAt` is present, display a localized message with that branch's
next opening time. Otherwise display generic localized copy asking the customer
to choose another branch or try later. The cart remains intact. A preview
conflict remains visible inside checkout; a creation conflict returns the
customer to an editable checkout flow instead of clearing the cart.

Network, timeout, malformed-response, and unrelated backend failures use
polite localized fallback copy and retry actions where safe. Existing-order
payment retry behavior is unchanged and is never gated by new-order status.

## Testing

Add tests for:

- parsing all ordering-status models, seven weekly rows, and independent pickup
  and delivery availability;
- the repository path, public request behavior, and absence of an `at` query;
- timezone-aware next-opening formatting and fallback behavior;
- typed parsing of `ORDERING_CLOSED` metadata, including null
  `nextOpeningAt`;
- closed pickup and delivery checkout gating;
- non-blocking, polite handling when the advisory status request fails;
- `ORDERING_CLOSED` from both preview and create while preserving cart state;
- retention of existing online-payment retry behavior;
- stable idempotency keys across retries of the same create submission.

Run focused Flutter tests, the complete test suite, static analysis, formatting,
and `git diff --check` before completion.
