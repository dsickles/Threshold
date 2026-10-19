class_name ChapterResult
extends RefCounted
## The one result a chapter hands back when it finishes. A plain Dictionary,
## so it saves as JSON as it is:
##
##   {"chapter": "partner", "answer": ""}
##   {"chapter": "mourner", "answer": "vulnerable", "house": {...}}
##
## - "chapter": the chapter's id (ChapterList.STORY_ORDER).
## - "answer": "" when the chapter offers no choice, else "stoic" or
##   "vulnerable". It changes spoken words and journal wording only (ADR-0004).
## - "house": only when a chapter leaves something the House must keep that
##   the core table can't look up (for example where the Mourner's things were
##   put). Left out otherwise. Plain JSON values only.
##
## Nothing else goes in it. Story facts, House mood and journal entries are
## looked up from the finished-chapter list in the core table, never reported
## by a chapter (docs/design/game-architecture.md §2.1).

const NO_ANSWER := ""
const STOIC := "stoic"
const VULNERABLE := "vulnerable"
const ANSWERS: Array[String] = [NO_ANSWER, STOIC, VULNERABLE]


static func make(chapter: StringName, answer: String = NO_ANSWER,
		house: Dictionary = {}) -> Dictionary:
	var result := {"chapter": String(chapter), "answer": answer}
	if not house.is_empty():
		result["house"] = house
	return result


## True for a well-formed result from a real chapter: the only kind the
## finished-chapter list should record. False for the test-only stand-in.
static func is_story_result(result: Dictionary) -> bool:
	if not result.get("chapter") is String:
		return false
	if not ChapterList.is_story_chapter(StringName(result["chapter"])):
		return false
	if not result.get("answer") is String or not result["answer"] in ANSWERS:
		return false
	if result.has("house") and not result["house"] is Dictionary:
		return false
	for key in result:
		if not key in ["chapter", "answer", "house"]:
			return false
	return true
