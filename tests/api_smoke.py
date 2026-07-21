#!/usr/bin/env python3
"""
Black-box HTTP integration test for the Sales Pipeline CRM.

Exercises every endpoint over real HTTP with real auth tokens — the layer the
XanoScript unit/workflow tests can't reach (workflow tests drive the logic via
function.call). Run it against any deployed instance after a seed:

    curl -X POST "$BASE/api:salescrm-seed/seed"
    python3 tests/api_smoke.py https://your-instance.xano.io

It creates its own throwaway users/records where it needs to mutate state, and
reads the shipped seed data for the scoping/analytics assertions. Exit code is
non-zero if any check fails.
"""
import sys, json, time, urllib.request, urllib.error

BASE = (sys.argv[1] if len(sys.argv) > 1 else "https://xuwv-vqfi-rpkp.n7d.xano.io").rstrip("/")
AUTH, CRM, AN, SEED = "/api:salescrm-auth", "/api:salescrm-crm", "/api:salescrm-analytics", "/api:salescrm-seed"
SUF = str(int(time.time()))
PASS, FAIL = 0, 0

def req(method, path, token=None, body=None):
    url = BASE + path
    data = json.dumps(body).encode() if body is not None else None
    r = urllib.request.Request(url, data=data, method=method)
    r.add_header("Content-Type", "application/json")
    if token: r.add_header("Authorization", "Bearer " + token)
    try:
        with urllib.request.urlopen(r) as resp:
            raw = resp.read().decode()
            return resp.status, (json.loads(raw) if raw else None)
    except urllib.error.HTTPError as e:
        raw = e.read().decode()
        try: return e.code, json.loads(raw)
        except Exception: return e.code, raw

def check(name, cond, detail=""):
    global PASS, FAIL
    if cond: PASS += 1; print(f"  \033[32m✓\033[0m {name}")
    else: FAIL += 1; print(f"  \033[31m✗\033[0m {name}  \033[31m{detail}\033[0m")

def login(email, pw="DemoPass1"):
    s, b = req("POST", f"{AUTH}/login", body={"email": email, "password": pw})
    return b.get("authToken") if isinstance(b, dict) else None

print(f"\n== Sales Pipeline CRM — HTTP integration test ==\n{BASE}\n")

# ensure data
req("POST", f"{SEED}/seed", body={})

# ---- AUTH ----
print("AUTH")
s, b = req("POST", f"{AUTH}/login", body={"email": "morgan.lee@northwind.example", "password": "DemoPass1"})
check("manager login returns token + user", s == 200 and b.get("authToken") and b["user"]["role"] == "manager", f"{s} {b}")
MGR = b.get("authToken") if isinstance(b, dict) else None
REP = login("alex.chen@northwind.example")
REP2 = login("priya.patel@northwind.example")
check("rep login returns token", bool(REP))
s, b = req("POST", f"{AUTH}/login", body={"email": "morgan.lee@northwind.example", "password": "wrong"})
check("wrong password is rejected", s >= 400, f"got {s}")
s, b = req("GET", f"{AUTH}/me", MGR)
check("GET /me returns quota fields", s == 200 and "quota_amount" in b and "quota_period" in b, str(b)[:120])
s, b = req("GET", f"{CRM}/board")
check("no token is rejected (401)", s == 401, f"got {s}")

# ---- READS + SCOPING (before any writes) ----
print("\nREADS & ROLE SCOPING")
s, stages = req("GET", f"{CRM}/stages", MGR)
won_stage = next((x for x in stages if x["is_won"]), None)
lost_stage = next((x for x in stages if x["is_closed"] and not x["is_won"]), None)
check("GET /stages returns 10 ordered stages", s == 200 and len(stages) == 10 and stages[0]["sort_order"] == 1, f"len={len(stages) if stages else 0}")
check("Closed Won / Closed Lost stages exist", bool(won_stage) and bool(lost_stage))
s, board = req("GET", f"{CRM}/board", MGR)
mgr_deals = [d for c in board for d in c["deals"]]
check("manager board shows all 20 deals across 10 columns", len(board) == 10 and len(mgr_deals) == 20, f"cols={len(board)} deals={len(mgr_deals)}")
attention = [d for d in mgr_deals if not d["is_closed"] and d.get("alerts", {}).get("needs_attention")]
check("exactly 5 deals flag needs_attention", len(attention) == 5, f"got {len(attention)}")
s, mdeals = req("GET", f"{CRM}/deals", MGR)
s, rdeals = req("GET", f"{CRM}/deals", REP)
check("manager sees more deals than a rep (scoping)", len(mdeals) == 20 and 0 < len(rdeals) < 20, f"mgr={len(mdeals)} rep={len(rdeals)}")
check("every rep-visible deal is owned by the rep", all(d["owner_id"] == rdeals[0]["owner_id"] for d in rdeals), "rep sees others' deals")
s, maccts = req("GET", f"{CRM}/accounts", MGR)
s, raccts = req("GET", f"{CRM}/accounts", REP)
check("accounts are role-scoped too", len(maccts) == 10 and 0 < len(raccts) < 10, f"mgr={len(maccts)} rep={len(raccts)}")
# deal detail structure
did = mgr_deals[0]["id"]
s, det = req("GET", f"{CRM}/deals/{did}", MGR)
keys = set(det.keys()) if isinstance(det, dict) else set()
check("deal detail has full structure", {"deal","account","stage","owner","contact_roles","activities","stage_history"} <= keys, str(keys))
role_ok = (not det["contact_roles"]) or ("contact_first" in det["contact_roles"][0] and "contact_last" in det["contact_roles"][0])
check("contact roles expose contact_first/contact_last (eval fix)", role_ok, str(det["contact_roles"][:1]))

# ---- DEAL MATH + LIFECYCLE (own records) ----
print("\nDEAL MATH & LIFECYCLE")
s, acct = req("POST", f"{CRM}/accounts", REP, {"name": f"QA Account {SUF}"})
qual = next(x for x in stages if x["name"] == "Qualification")
needs = next(x for x in stages if x["name"] == "Needs Analysis")
prospect = next(x for x in stages if x["name"] == "Prospecting")
s, deal = req("POST", f"{CRM}/deals", REP, {"name": f"QA Deal {SUF}", "account_id": acct["id"], "stage_id": qual["id"], "amount": 50000})
check("deal snapshots stage probability", deal.get("probability") == qual["default_probability"], f"{deal.get('probability')} vs {qual['default_probability']}")
check("expected_revenue = amount*probability/100", deal.get("expected_revenue") == 50000 * qual["default_probability"] / 100, str(deal.get("expected_revenue")))
s, adv = req("POST", f"{CRM}/deals/{deal['id']}/advance", REP, {"deal_id": deal["id"], "stage_id": needs["id"]})
check("advance moves stage + re-snapshots probability", adv.get("stage_id") == needs["id"] and adv.get("probability") == needs["default_probability"], str(adv)[:120])
s, det2 = req("GET", f"{CRM}/deals/{deal['id']}", REP)
check("advance writes a stage-history row", len(det2["stage_history"]) >= 2, f"history={len(det2['stage_history'])}")
# rep skip guard
s, skip = req("POST", f"{CRM}/deals/{deal['id']}/advance", REP, {"deal_id": deal["id"], "stage_id": next(x for x in stages if x['name']=='Proposal/Price Quote')["id"]})
check("rep cannot skip stages (guard rejects)", s >= 400, f"got {s}")
# ownership
someone_elses = next((d for d in mgr_deals if d["owner_id"] != rdeals[0]["owner_id"] and not d["is_closed"]), None)
if someone_elses:
    s, own = req("POST", f"{CRM}/deals/{someone_elses['id']}/advance", REP, {"deal_id": someone_elses["id"], "stage_id": needs["id"]})
    check("rep cannot act on another rep's deal (403)", s == 403, f"got {s}")
# won
s, wdeal = req("POST", f"{CRM}/deals", REP, {"name": f"QA Win {SUF}", "account_id": acct["id"], "stage_id": qual["id"], "amount": 80000})
s, won = req("POST", f"{CRM}/deals/{wdeal['id']}/won", REP, {"deal_id": wdeal["id"]})
check("won sets is_won/closed, prob 100, forecast Closed", won.get("is_won") and won.get("is_closed") and won.get("probability") == 100 and won.get("forecast_category") == "Closed" and won.get("actual_close_date"), str(won)[:140])
# lost
s, ldeal = req("POST", f"{CRM}/deals", REP, {"name": f"QA Loss {SUF}", "account_id": acct["id"], "stage_id": qual["id"], "amount": 30000})
s, lbad = req("POST", f"{CRM}/deals/{ldeal['id']}/lost", REP, {"deal_id": ldeal["id"]})
check("lost requires a reason", s >= 400, f"got {s}")
s, lost = req("POST", f"{CRM}/deals/{ldeal['id']}/lost", REP, {"deal_id": ldeal["id"], "lost_reason": "QA test"})
check("lost sets closed, prob 0, Omitted, reason", lost.get("is_closed") and not lost.get("is_won") and lost.get("probability") == 0 and lost.get("forecast_category") == "Omitted" and lost.get("lost_reason") == "QA test", str(lost)[:140])

# ---- ACTIVITIES ----
print("\nACTIVITIES")
s, deal2 = req("POST", f"{CRM}/deals", REP, {"name": f"QA Act {SUF}", "account_id": acct["id"], "stage_id": prospect["id"], "amount": 20000})
s, act = req("POST", f"{CRM}/deals/{deal2['id']}/activities", REP, {"deal_id": deal2["id"], "subject": "QA call", "subtype": "call", "completed": True})
check("logging a completed activity works", s == 200 and act.get("is_closed") == True, str(act)[:120])
s, act2 = req("POST", f"{CRM}/deals/{deal2['id']}/activities", REP, {"deal_id": deal2["id"], "subject": "QA open task", "subtype": "task", "completed": False})
s, done = req("POST", f"{CRM}/activities/{act2['id']}/complete", REP, {"activity_id": act2["id"]})
check("completing an activity works", done.get("is_closed") == True and done.get("status") == "completed", str(done)[:120])

# ---- CONTACT ROLES ----
print("\nCONTACT ROLES")
s, c1 = req("POST", f"{CRM}/contacts", REP, {"account_id": acct["id"], "first_name": "Qa", "last_name": "One"})
s, c2 = req("POST", f"{CRM}/contacts", REP, {"account_id": acct["id"], "first_name": "Qa", "last_name": "Two"})
req("POST", f"{CRM}/deals/{deal2['id']}/contact-roles", REP, {"deal_id": deal2["id"], "contact_id": c1["id"], "role": "decision_maker", "is_primary": True})
req("POST", f"{CRM}/deals/{deal2['id']}/contact-roles", REP, {"deal_id": deal2["id"], "contact_id": c2["id"], "role": "influencer", "is_primary": True})
s, det3 = req("GET", f"{CRM}/deals/{deal2['id']}", REP)
primaries = [r for r in det3["contact_roles"] if r.get("is_primary")]
check("only one primary contact role after two primary adds", len(primaries) == 1, f"primaries={len(primaries)}")

# ---- LEAD CONVERSION ----
print("\nLEAD CONVERSION")
s, lead = req("POST", f"{CRM}/leads", REP, {"first_name": "Qa", "last_name": "Lead", "company": f"QA Co {SUF}"})
s, conv = req("POST", f"{CRM}/leads/{lead['id']}/convert", REP, {"lead_id": lead["id"], "create_opportunity": True, "amount": 40000})
check("convert creates account+contact+opportunity", conv.get("opportunity_id") and conv["account"].get("id") and conv["contact"].get("id"), str(conv)[:140])
check("converted lead is flagged converted", conv["lead"].get("is_converted") == True)
s, conv2 = req("POST", f"{CRM}/leads/{lead['id']}/convert", REP, {"lead_id": lead["id"], "create_opportunity": False})
check("re-converting a lead is rejected", s >= 400, f"got {s}")

# ---- ANALYTICS ----
print("\nANALYTICS")
s, stats = req("GET", f"{AN}/dashboard/stats", MGR)
f = stats.get("forecast", {})
check("dashboard forecast has cumulative columns", all(k in f for k in ["open_pipeline","commit_forecast","closed_only","weighted_expected"]), str(f)[:140])
check("forecast cumulative math (open_pipeline = pipeline+best+commit)", round(f["open_pipeline"],2) == round(f["pipeline"]+f["best_case"]+f["commit"],2), str(f))
check("dashboard has win_rate, leaderboard, pipeline_by_stage", "win_rate" in stats and len(stats["leaderboard"]) > 0 and len(stats["pipeline_by_stage"]) == 10, str(list(stats.keys())))
check("leaderboard rows carry an attainment band", all("band" in r for r in stats["leaderboard"]))
check("stale_deals reflects the 4 no-activity-30d deals", stats["stale_deals"] >= 4, str(stats.get("stale_deals")))
s, fc = req("GET", f"{AN}/forecast", MGR)
check("forecast returns per-rep rows with band", len(fc) > 0 and all(k in fc[0] for k in ["user_id","name","attainment_pct","band"]), str(fc[:1])[:160])
s, feed = req("GET", f"{AN}/activity-feed", MGR)
items = feed.get("items", feed) if isinstance(feed, dict) else feed
check("activity feed returns joined deal/user/stage names", len(items) > 0 and all(k in items[0] for k in ["deal_name","user_name","stage_name"]), str(items[:1])[:160])

print(f"\n== {PASS} passed, {FAIL} failed ==\n")
sys.exit(1 if FAIL else 0)
