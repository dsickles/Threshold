class_name ChapterList
extends RefCounted
## The chapters, by id, and the scene each one starts from. Story order is the
## order players meet them (docs/roadmap.md). Ids are lowercase archetype
## names from GLOSSARY.md and are what the finished-chapter list stores.

const STORY_ORDER: Array[StringName] = [
	&"partner", &"protector", &"novice", &"provider",
	&"tuner", &"anchor", &"mourner", &"arrival",
]

## Test-only chapter on the menu. Its results are not story results, so
## progress never records them (see ChapterResult.is_story_result).
const STAND_IN := &"stand_in"

## The scene each chapter starts from. A chapter that isn't built yet has no
## entry.
const SCENES := {
	&"partner": "res://scenes/chapters/partner/partner.tscn",
	STAND_IN: "res://scenes/chapters/stand_in/stand_in_chapter.tscn",
}


static func is_story_chapter(id: StringName) -> bool:
	return id in STORY_ORDER


static func scene_path(id: StringName) -> String:
	return SCENES.get(id, "")
