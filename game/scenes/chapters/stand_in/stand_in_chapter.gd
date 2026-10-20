extends Control
## Test-only stand-in chapter, so the chapter runner can be played and tested
## before a real chapter is on it. Not game content: no story, no wording.
## It shows the chapter contract every chapter follows
## (game/_core/chapters/README.md): emit `finished` (with an answer if the
## chapter offers one) to finish, or free yourself to leave with no result.

signal finished(answer: String)


func _ready() -> void:
	%FinishButton.pressed.connect(finished.emit.bind(ChapterResult.NO_ANSWER))
	%StoicButton.pressed.connect(finished.emit.bind(ChapterResult.STOIC))
	%VulnerableButton.pressed.connect(finished.emit.bind(ChapterResult.VULNERABLE))
	%LeaveButton.pressed.connect(queue_free)
