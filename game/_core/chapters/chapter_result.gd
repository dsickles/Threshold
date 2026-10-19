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
	if result.has("house") and not (result["house"] is Dictionary and is_plain_json(result["house"])):
		return false
	for key in result:
		if not key in ["chapter", "answer", "house"]:
			return false
	return true


## True if `value` saves as JSON and loads back the same (apart from ints
## coming back as floats): null, bool, int, float, String, and Arrays and
## String-keyed Dictionaries of those. False for anything Godot-only, like a
## Vector2 or a Node, which JSON would quietly turn into a string.
static func is_plain_json(value: Variant) -> bool:
	match typeof(value):
		TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_STRING:
			return true
		TYPE_FLOAT:
			return is_finite(value)
		TYPE_ARRAY:
			for item in value:
				if not is_plain_json(item):
					return false
			return true
		TYPE_DICTIONARY:
			for key in value:
				if typeof(key) != TYPE_STRING or not is_plain_json(value[key]):
					return false
			return true
	return false
