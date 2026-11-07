class_name ProviderBills
extends RefCounted
## The Provider's bills (DAS-134): a fixed, hand-written set in three acts,
## not random (docs/design/game-architecture.md §4.1). They follow one story:
## the IVF months, the night of the Loss, and the new pregnancy
## (docs/design/story-beats.md §4, Dan, 2026-10-25).
##
## DRAFT: every word of every bill below is a PLACEHOLDER written by Claude
## for the rough chapter, not approved by Dan (CLAUDE.md: a draft stays marked
## until Dan approves it). The bill for the night of the Loss follows the
## story-beats care points: cold billing words, no joke about it, and the UI
## adds nothing.
##
## Each bill:
## - "act": which act it is in (Act).
## - "title": the heading on the paper.
## - "lines": the paper's text, one line each.
## - "reflows": false for a page that can't be enlarged (a faxed copy).
## - "right": the stamp a careful reader would give: APPROVE, DENY, or
##   EITHER (the Loss bill: whatever the player stamps is accepted).
## - "cost": what a wrong stamp takes from the Bank Account.
## - "quiet": true only for the Loss bill. While it is on the desk the Due
##   Date doesn't count and nothing drains.

enum Act { INVOICES, INSURANCE, AUDIT }

const ACT_NAMES := {
	Act.INVOICES: "The Invoices",
	Act.INSURANCE: "The Insurance",
	Act.AUDIT: "The Audit",
}

const APPROVE := "approve"
const DENY := "deny"
const EITHER := "either"

const BILLS: Array[Dictionary] = [
	# --- The Invoices: simple and readable, with absurd line items. Leo is
	# good at this.
	{
		"act": Act.INVOICES,
		"title": "Fertility Clinic: Invoice",
		"lines": [
			"New patient consultation ..... $250.00",
			"Parking validation ........... $0.00",
			"TOTAL DUE .................... $250.00",
		],
		"reflows": true, "right": APPROVE, "cost": 250, "quiet": false,
	},
	{
		"act": Act.INVOICES,
		"title": "Fertility Clinic: Invoice",
		"lines": [
			"Ultrasound, 9:40 AM .......... $400.00",
			"Ultrasound, 9:40 AM .......... $400.00",
			"TOTAL DUE .................... $800.00",
		],
		"reflows": true, "right": DENY, "cost": 400, "quiet": false,
	},
	{
		"act": Act.INVOICES,
		"title": "Pharmacy: Receipt for Payment",
		"lines": [
			"Injectable medication, 10 days  $1,180.00",
			"Sharps container ............. $35.00",
			"TOTAL DUE .................... $1,215.00",
		],
		"reflows": true, "right": APPROVE, "cost": 600, "quiet": false,
	},
	{
		"act": Act.INVOICES,
		"title": "Fertility Clinic: Invoice",
		"lines": [
			"Chair, padded (per sitting) .. $45.00",
			"Use of clinic pen ............ $3.00",
			"Pen, not returned ............ $3.00",
			"TOTAL DUE .................... $51.00",
		],
		"reflows": true, "right": DENY, "cost": 300, "quiet": false,
	},
	# --- The Insurance: harder to read on the desk; read in large type. The
	# bill for the night of the Loss turns up here.
	{
		"act": Act.INSURANCE,
		"title": "Explanation of Benefits",
		"lines": [
			"THIS IS NOT A BILL.",
			"Claim 4471-0093. Service: egg retrieval.",
			"Billed $9,600.00. Plan discount $2,140.00.",
			"Plan paid $5,500.00.",
			"Amount you may owe the provider: $1,960.00.",
			"Please pay the provider.",
		],
		"reflows": true, "right": APPROVE, "cost": 800, "quiet": false,
	},
	{
		"act": Act.INSURANCE,
		"title": "Prior Authorization Request",
		"lines": [
			"Service: embryo transfer (performed).",
			"Status: PRIOR AUTHORIZATION REQUIRED.",
			"Prior authorization must be obtained",
			"before the service is performed.",
			"Please submit the request by the date",
			"of service, which has passed.",
		],
		"reflows": true, "right": DENY, "cost": 700, "quiet": false,
	},
	{
		"act": Act.INSURANCE,
		"title": "Emergency Department: Statement",
		"lines": [
			"Patient: Maya",
			"Date of service: 03/09, 11:52 PM",
			"ED visit, level 4 ............ $1,840.00",
			"Ultrasound, pelvic ........... $620.00",
			"Diagnosis code: O03.9",
			"Insurance paid ............... $1,180.00",
			"PATIENT BALANCE .............. $1,280.00",
		],
		"reflows": true, "right": EITHER, "cost": 0, "quiet": true,
	},
	{
		"act": Act.INSURANCE,
		"title": "Claim Determination",
		"lines": [
			"Claim 4471-0131. Service: pregnancy test.",
			"Determination: NOT COVERED.",
			"Reason code 50: the result was not",
			"medically necessary at the time the",
			"test was taken.",
			"Amount you owe: $212.00.",
		],
		"reflows": true, "right": DENY, "cost": 900, "quiet": false,
	},
	# --- The Audit: the absurdity comes back, harder and funnier. The Due
	# Date runs; the Bank Account drains.
	{
		"act": Act.AUDIT,
		"title": "Coverage Review",
		"lines": [
			"To continue maternity coverage, please",
			"send proof the pregnancy is ongoing.",
			"Acceptable proof: (1) the pregnancy.",
			"Please do not send the pregnancy.",
		],
		"reflows": true, "right": DENY, "cost": 900, "quiet": false,
	},
	{
		"act": Act.AUDIT,
		"title": "Copy of Receipt (faxed)",
		"lines": [
			"OB visit, week 12 ............ $40.00 copay",
			"PAID IN FULL. Thank you.",
		],
		"reflows": false, "right": APPROVE, "cost": 400, "quiet": false,
	},
	{
		"act": Act.AUDIT,
		"title": "Notice of Late Fee",
		"lines": [
			"Your payment was received on time.",
			"Payments received on time are processed late.",
			"Late fee ..................... $35.00",
		],
		"reflows": true, "right": DENY, "cost": 1000, "quiet": false,
	},
	{
		"act": Act.AUDIT,
		"title": "FINAL NOTICE",
		"lines": [
			"Account balance: $0.00.",
			"Pay $0.00 within 10 days to avoid",
			"referral to collections.",
		],
		"reflows": true, "right": DENY, "cost": 1200, "quiet": false,
	},
]


static func act_of(index: int) -> int:
	return BILLS[index].act


## True if `stamp` (APPROVE or DENY) is what this bill should get.
static func is_right(index: int, stamp: String) -> bool:
	var right: String = BILLS[index].right
	return right == EITHER or right == stamp
