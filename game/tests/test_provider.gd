extends TestCase
## The Provider's desk (DAS-134), on the desk's own clock instead of real
## time. The rules come from the ticket, docs/design/story-beats.md §4 and
## docs/design/stories/epic-4-stories.md. How the bills read on a phone, how
## the stamps feel and whether the Loss bill lands are Dan's to check.

const PROVIDER := preload("res://scenes/chapters/provider/provider.tscn")
const Provider := preload("res://scenes/chapters/provider/provider.gd")
const Bills := preload("res://scenes/chapters/provider/bills.gd")
const MENU := preload("res://scenes/ui/m0_menu.tscn")

var _desk: Node
var _finished := 0


func before_each() -> void:
	_desk = add_scene(PROVIDER)
	_desk.auto_advance = false
	_desk.finished.connect(func() -> void: _finished += 1)


# --- The bills.

func test_three_acts_in_order_from_a_fixed_hand_written_set() -> void:
	var acts: Array[int] = []
	for bill in Bills.BILLS:
		if acts.is_empty() or acts[-1] != bill.act:
			acts.append(bill.act)
	check_eq(acts, [Bills.Act.INVOICES, Bills.Act.INSURANCE, Bills.Act.AUDIT],
			"The Invoices, then The Insurance, then The Audit, each once")
	check_eq(Bills.BILLS.size(), 12, "twelve bills")
	# The same bills in the same order every time the desk opens.
	var seen: Array[String] = []
	for i in Bills.BILLS.size():
		seen.append(_desk.current().title)
		_stamp_right()
		_step(Provider.STAMPED_HOLD)
	var again: Node = add_scene(PROVIDER)
	again.auto_advance = false
	check_eq(again.current().title, seen[0], "a new desk starts from the same first bill")
	for i in Bills.BILLS.size():
		check_eq(seen[i], Bills.BILLS[i].title, "bill %d is the hand-written one" % i)


func test_the_act_title_follows_the_bills() -> void:
	check_eq(_desk.get_node("ActTitle").text, "The Invoices", "first act")
	while _desk.act() == Bills.Act.INVOICES:
		_stamp_right()
		_step(Provider.STAMPED_HOLD)
	check_eq(_desk.get_node("ActTitle").text, "The Insurance", "second act")
	while _desk.act() == Bills.Act.INSURANCE:
		_stamp_right()
		_step(Provider.STAMPED_HOLD)
	check_eq(_desk.get_node("ActTitle").text, "The Audit", "third act")


func test_exactly_one_bill_is_the_night_of_the_loss_in_the_insurance() -> void:
	var quiet := Bills.BILLS.filter(func(bill: Dictionary) -> bool: return bill.quiet)
	check_eq(quiet.size(), 1, "one quiet bill")
	check_eq(quiet[0].act, Bills.Act.INSURANCE, "in The Insurance")
	check_eq(quiet[0].right, Bills.EITHER, "either stamp is accepted")
	check_eq(quiet[0].cost, 0, "and costs nothing")


func test_every_other_bill_has_one_right_stamp_and_a_cost() -> void:
	for i in Bills.BILLS.size():
		var bill: Dictionary = Bills.BILLS[i]
		if bill.quiet:
			continue
		check(bill.right in [Bills.APPROVE, Bills.DENY], "bill %d has one right stamp" % i)
		check(bill.cost > 0, "bill %d costs something when stamped wrong" % i)


# --- Reading.

func test_tapping_a_bill_that_reflows_shows_large_type_and_back_returns() -> void:
	await frames()
	tap(_desk.get_node("Paper"))
	await frames()
	var reader: Control = _desk.get_node("Reader")
	check(_desk.is_reading(), "reading")
	check(reader.visible, "the large-type page is up")
	check(not _desk.get_node("Paper").visible, "it replaces the page")
	var text: Label = reader.find_child("ReaderText", true, false)
	check_eq(text.get_theme_font_size("font_size"), Provider.READER_TEXT_SIZE, "large type")
	check(text.text.contains(Bills.BILLS[0].title), "the bill's own words")
	check(text.text.contains("$250.00"), "with its amounts")
	check(not text.text.contains(".."), "the dotted leaders are gone, so it wraps")
	tap(reader.find_child("ReaderBack", true, false))
	await frames()
	check(not _desk.is_reading(), "back to the desk")
	check(not reader.visible, "the large-type page is gone")
	check(_desk.get_node("Paper").visible, "the paper is back")


func test_a_page_that_cant_reflow_stays_on_the_desk_and_says_so() -> void:
	var fax := _go_to_first(func(bill: Dictionary) -> bool: return not bill.reflows)
	check(fax >= 0, "there is a page that can't be enlarged")
	await frames()
	var notice: Label = _desk.get_node("CantEnlarge")
	check(not notice.visible, "no notice before the tap")
	tap(_desk.get_node("Paper"))
	await frames()
	check(not _desk.is_reading(), "no large type")
	check(_desk.get_node("Paper").visible, "the desk stays")
	check(notice.visible, "the notice shows")
	check_eq(notice.text, "can't enlarge this page.", "its words")
	_step(Provider.CANT_ENLARGE_TIME + 0.1)
	check(not notice.visible, "and goes again")


func test_the_stamps_stay_on_the_desk_and_work_while_reading() -> void:
	await frames()
	tap(_desk.get_node("Paper"))
	await frames()
	var reader: Control = _desk.get_node("Reader")
	for name in ["ApproveStamp", "DenyStamp"]:
		var stamp: Control = _desk.find_child(name, true, false)
		check(stamp.is_visible_in_tree(), "%s on the desk" % name)
		check(not reader.get_global_rect().intersects(stamp.get_global_rect()),
				"%s not covered by the large-type page" % name)
	tap(_desk.find_child("ApproveStamp", true, false))
	await frames()
	check_eq(_desk.probe_state().mark, "APPROVED", "the stamp marked the paper")
	check(not _desk.is_reading(), "stamping puts the page back on the desk")


func test_the_insurance_is_harder_to_read_on_the_desk() -> void:
	var invoice: int = Provider.DESK_TEXT_SIZE[Bills.Act.INVOICES]
	var insurance: int = Provider.DESK_TEXT_SIZE[Bills.Act.INSURANCE]
	check(insurance < invoice, "smaller type on the desk (%d vs %d)" % [insurance, invoice])
	check(Provider.READER_TEXT_SIZE >= 2 * insurance, "the large-type page is at least twice as big")
	_go_to_first(func(bill: Dictionary) -> bool: return bill.act == Bills.Act.INSURANCE)
	var text: Label = _desk.find_child("PaperText", true, false)
	check_eq(text.get_theme_font_size("font_size"), insurance, "an Insurance bill uses the small type")
	for i in Bills.BILLS.size():
		if Bills.BILLS[i].act == Bills.Act.INSURANCE:
			check(Bills.BILLS[i].reflows, "Insurance bill %d can be read in large type" % i)


# --- Stamping.

func test_one_tap_on_a_stamp_marks_the_paper_and_thunks() -> void:
	await frames()
	check_eq(_desk.probe_state().mark, "", "no mark before")
	tap(_desk.find_child("ApproveStamp", true, false))
	await frames()
	check_eq(_desk.probe_state().mark, "APPROVED", "APPROVE marks it APPROVED")
	check_eq(_desk.thunks(), 1, "an ink thunk")
	var thunk: AudioStreamPlayer = _thunk_player()
	check(thunk != null and thunk.stream != null, "the thunk has a sound")
	_step(Provider.STAMPED_HOLD)
	await frames()
	check_eq(_desk.bill_index(), 1, "the next bill comes")
	check_eq(_desk.probe_state().mark, "", "clean paper")
	tap(_desk.find_child("DenyStamp", true, false))
	await frames()
	check_eq(_desk.probe_state().mark, "DENIED", "DENY marks it DENIED")
	check_eq(_desk.thunks(), 2, "another thunk")


func test_a_bill_takes_only_one_stamp() -> void:
	await frames()
	tap(_desk.find_child("ApproveStamp", true, false))
	tap(_desk.find_child("DenyStamp", true, false))
	await frames()
	check_eq(_desk.probe_state().mark, "APPROVED", "the first stamp stays")
	check_eq(_desk.thunks(), 1, "one thunk")


func test_a_wrong_stamp_drops_the_bank_account_in_number_and_track() -> void:
	# The second bill is the same ultrasound twice: it should be denied.
	_stamp_right()
	_step(Provider.STAMPED_HOLD)
	check_eq(Bills.BILLS[1].right, Bills.DENY, "the second bill is wrong")
	var number: Label = _desk.find_child("BankNumber", true, false)
	var fill: Control = _desk.find_child("BankTrack", true, false).get_node("Fill")
	var drop: Label = _desk.find_child("BankDrop", true, false)
	var bank_before: float = _desk.bank()
	var number_before := number.text
	var fill_before := fill.anchor_right
	await frames()
	tap(_desk.find_child("ApproveStamp", true, false))
	await frames()
	check_near(_desk.bank(), bank_before - Bills.BILLS[1].cost, 0.01, "the bill's cost comes off")
	check(number.text != number_before, "the number changes (%s to %s)" % [number_before, number.text])
	check(fill.anchor_right < fill_before, "the track shortens")
	check(drop.visible, "the drop is written out")
	check_eq(drop.text, "-$400", "as an amount")
	# The bank's colours don't change: the drop is never colour alone.
	check_eq(number.get_theme_color("font_color"), Provider.PAPER, "the number keeps its colour")
	check_eq((fill as ColorRect).color, Provider.PAPER, "the track keeps its colour")


func test_a_right_stamp_costs_nothing() -> void:
	var before: float = _desk.bank()
	_stamp_right()
	check_near(_desk.bank(), before, 0.01, "nothing comes off for a right stamp")


func test_the_bank_drains_and_never_goes_below_zero() -> void:
	var before: float = _desk.bank()
	_step(10.0)
	check_near(_desk.bank(), before - 10.0 * Provider.DRAIN_PER_SECOND, 0.01, "it drains")
	for i in 40:
		var bill: Dictionary = _desk.current()
		_desk.stamp(Bills.DENY if bill.right == Bills.APPROVE else Bills.APPROVE)
		_step(Provider.STAMPED_HOLD)
		if _desk.is_ending():
			break
	check(_desk.bank() >= 0.0, "never below zero (is %s)" % _desk.bank())


# --- The HUD.

func test_due_date_and_bank_account_sit_in_the_top_start_corner() -> void:
	for screen in [Vector2i(1280, 720), Vector2i(844, 390), Vector2i(390, 844)]:
		set_screen(screen)
		await frames(2)
		var view := get_viewport().get_visible_rect()
		var hud: Control = _desk.get_node("Hud")
		var rect := hud.get_global_rect()
		check(rect.position.x < view.size.x * 0.3 and rect.position.y < view.size.y * 0.1,
				"the HUD starts in the top-start corner on %s (at %s)" % [screen, rect.position])
		for name in ["DueNumber", "BankNumber"]:
			var label: Label = _desk.find_child(name, true, false)
			check(label.is_visible_in_tree() and label.text != "", "%s shown on %s" % [name, screen])
			check(view.encloses(label.get_global_rect()), "%s on screen on %s" % [name, screen])
		# The other three corners stay empty.
		var corner := Vector2(200, 120)
		var corners := [
			Rect2(Vector2(view.size.x - corner.x, 0), corner),
			Rect2(Vector2(0, view.size.y - corner.y), corner),
			Rect2(view.size - corner, corner),
		]
		for node in _visible_things(_desk):
			for c in corners:
				check(not c.intersects(node.get_global_rect()),
						"%s stays out of the corner %s on %s" % [node.name, c, screen])
	set_screen(Vector2i(1280, 720))


func test_the_due_date_counts_down_in_days() -> void:
	check_eq(_desk.probe_state().due, "30 days", "starts at 30 days")
	_step(Provider.SECONDS_PER_DAY)
	check_eq(_desk.probe_state().due, "29 days", "a day goes by")


# --- The night of the Loss.

func test_the_desk_goes_quiet_for_the_bill_from_the_night_of_the_loss() -> void:
	var loss := _go_to_first(func(bill: Dictionary) -> bool: return bill.quiet)
	check(loss >= 0, "reached the bill")
	check(_desk.is_quiet(), "the desk is quiet")
	var due: float = _desk.due_left()
	var bank: float = _desk.bank()
	_step(60.0)
	check_eq(_desk.due_left(), due, "the Due Date doesn't count")
	check_eq(_desk.bank(), bank, "nothing drains")
	check_eq(_desk.bill_index(), loss, "it waits for the player")
	_desk.stamp(Bills.APPROVE)
	check_eq(_desk.bank(), bank, "APPROVE costs nothing")


func test_either_stamp_on_the_loss_bill_gives_the_same_desk() -> void:
	var results := []
	for which in [Bills.APPROVE, Bills.DENY]:
		var desk: Node = add_scene(PROVIDER)
		desk.auto_advance = false
		while not desk.current().quiet:
			desk.stamp(desk.current().right)
			desk.advance(Provider.STAMPED_HOLD)
		desk.stamp(which)
		desk.advance(Provider.STAMPED_HOLD)
		results.append([desk.bank(), desk.due_left(), desk.bill_index()])
	check_eq(results[0], results[1], "APPROVE and DENY leave the desk the same")


# --- The ending.

func test_finishing_the_bills_finishes_the_chapter_once() -> void:
	for i in Bills.BILLS.size():
		_stamp_right()
		_step(Provider.STAMPED_HOLD)
	check(_desk.is_ending(), "the bills are done")
	check_eq(_finished, 0, "a beat before the end")
	_step(Provider.END_HOLD + Provider.FADE_TIME + 0.1)
	check_eq(_finished, 1, "finished once")
	_step(10.0)
	check_eq(_finished, 1, "and only once")


func test_the_due_date_running_out_moves_the_story_on() -> void:
	# Nothing tapped at all: the desk can't trap the player.
	_step(Provider.DUE_SECONDS)
	check(_desk.is_ending(), "the Due Date ran out")
	check_eq(_desk.due_left(), 0.0, "at zero")
	check(_desk.find_child("ApproveStamp", true, false).disabled, "no more stamping")
	_step(Provider.END_HOLD + Provider.FADE_TIME + 0.1)
	check_eq(_finished, 1, "finished once, the same as a finished desk")


func test_the_runner_gets_the_same_result_either_way() -> void:
	var results := []
	for play in ["bills done", "due date"]:
		var runner := ChapterRunner.of(get_tree())
		var got := []
		var on_finished := func(result: Dictionary) -> void: got.append(result)
		runner.chapter_finished.connect(on_finished)
		var house := Node.new()
		add_child(house)
		check(runner.enter(&"provider", house), "%s: the desk opens through the runner" % play)
		var desk: Node = runner.get_child(0)
		desk.auto_advance = false
		if play == "bills done":
			for i in Bills.BILLS.size():
				desk.stamp(desk.current().right if desk.current().right != Bills.EITHER else Bills.APPROVE)
				desk.advance(Provider.STAMPED_HOLD)
		else:
			desk.advance(Provider.DUE_SECONDS)
		desk.advance(Provider.END_HOLD + Provider.FADE_TIME + 0.1)
		await frames()
		runner.chapter_finished.disconnect(on_finished)
		check_eq(got.size(), 1, "%s: one result" % play)
		results.append(got[0] if got.size() > 0 else {})
		house.free()
	ChapterRunner.of(get_tree()).free()  # It lives on the root; don't outlast this test.
	check_eq(results[0], {"chapter": "provider", "answer": ""}, "no answer")
	check_eq(results[0], results[1], "the same result either way")


func test_the_chapter_never_touches_saved_state_and_leaving_starts_over() -> void:
	var state: Node = get_node("/root/GameState")
	var before: Array = state.finished_chapters()
	for i in 5:
		_stamp_right()
		_step(Provider.STAMPED_HOLD)
	check_eq(_desk.bill_index(), 5, "part-way through")
	_desk.free()
	await frames()
	check_eq(state.finished_chapters(), before, "leaving saves nothing")
	var again: Node = add_scene(PROVIDER)
	again.auto_advance = false
	check_eq(again.bill_index(), 0, "the next visit starts from the first bill")
	check_near(again.due_left(), Provider.DUE_SECONDS, 0.001, "with the whole Due Date")
	check_near(again.bank(), Provider.BANK_START, 0.001, "and the whole Bank Account")


func test_hiding_the_tab_pauses_the_due_date_and_drain_and_never_saves() -> void:
	var state: Node = get_node("/root/GameState")
	var before: Array = state.finished_chapters()
	_step(3.0)
	_desk.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(_desk.is_paused(), "paused")
	var due: float = _desk.due_left()
	var bank: float = _desk.bank()
	_step(30.0)
	check_eq(_desk.due_left(), due, "the Due Date waits")
	check_eq(_desk.bank(), bank, "nothing drains")
	check_eq(state.finished_chapters(), before, "nothing saved")
	_desk.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	check(not _desk.is_paused(), "back")
	_step(1.0)
	check(_desk.due_left() < due, "the Due Date runs again")


# --- One tap scheme.

func test_every_button_is_at_least_44px_and_on_screen() -> void:
	for screen in [Vector2i(1280, 720), Vector2i(844, 390), Vector2i(390, 844)]:
		set_screen(screen)
		await frames(2)
		var view := get_viewport().get_visible_rect()
		for name in ["Paper", "ApproveStamp", "DenyStamp"]:
			var button: Control = _desk.find_child(name, true, false)
			var rect := button.get_global_rect()
			check(rect.size.x >= 44.0 and rect.size.y >= 44.0, "%s at least 44px on %s" % [name, screen])
			check(view.encloses(rect), "%s on screen on %s" % [name, screen])
		_desk.open_reader()
		await frames(2)
		var back: Control = _desk.find_child("ReaderBack", true, false)
		check(back.size.y >= 44.0, "Back to desk at least 44px on %s" % screen)
		check(view.encloses(back.get_global_rect()), "Back to desk on screen on %s" % screen)
		_desk.close_reader()
	set_screen(Vector2i(1280, 720))


func test_hovering_does_nothing() -> void:
	await frames()
	var move := InputEventMouseMotion.new()
	move.position = _desk.get_node("Paper").get_global_rect().get_center()
	move.global_position = move.position
	get_viewport().push_input(move, true)
	await frames()
	check(not _desk.is_reading(), "hovering the paper doesn't open it")
	check_eq(_desk.probe_state().mark, "", "nor stamp it")


func test_the_look_is_black_and_white() -> void:
	check_eq(_desk.get_node("Desk").color, Color.BLACK, "a black desk")
	var paper: StyleBoxFlat = _desk.get_node("Paper").get_theme_stylebox("normal")
	check_eq(paper.bg_color, Color.WHITE, "white paper")
	check(get_viewport().world_2d != null, "plain 2D, no compositor effects")


# --- Opening it.

func test_the_menu_opens_the_provider_and_takes_it_back() -> void:
	_desk.free()  # It covers the screen, so it would take the menu's taps.
	var menu := add_scene(MENU)
	tap(menu.get_node("%BeginButton"))
	await frames()
	tap(menu.get_node("%ProviderButton"))
	await frames()
	var runner := ChapterRunner.of(get_tree())
	check_eq(runner.current_chapter(), &"provider", "the desk is playing")
	check(not menu.visible, "menu hidden while it plays")
	var desk: Node = runner.get_child(0)
	desk.auto_advance = false
	desk.advance(Provider.DUE_SECONDS)
	desk.advance(Provider.END_HOLD + Provider.FADE_TIME + 0.1)
	await frames()
	check(menu.visible, "menu back")
	check_eq(menu.get_node("%Status").text, "Finished provider (answer: none)", "status")
	runner.free()  # It lives on the root, so it would outlast this test.


func test_the_playtest_clock_counts_the_desk() -> void:
	_step(12.5)
	check_near(_desk.playtest_time(), 12.5, 0.001, "seconds since the desk opened")


func test_a_rough_playthrough_takes_about_two_to_four_minutes() -> void:
	# The Due Date bounds a slow player at three minutes plus the quiet bill;
	# a player taking about 12 s a bill lands inside 2 to 4 minutes too.
	check(Provider.DUE_SECONDS >= 120.0 and Provider.DUE_SECONDS <= 240.0,
			"the Due Date is 2 to 4 minutes (%s s)" % Provider.DUE_SECONDS)
	for i in Bills.BILLS.size():
		_step(12.0 - Provider.STAMPED_HOLD)
		if _desk.is_ending():
			break
		_stamp_right()
		_step(Provider.STAMPED_HOLD)
	_step(Provider.END_HOLD + Provider.FADE_TIME + 0.1)
	check_eq(_finished, 1, "finished")
	var minutes: float = _desk.playtest_time() / 60.0
	check(minutes >= 2.0 and minutes <= 4.0, "about 2 to 4 minutes (%.1f)" % minutes)


# --- Helpers.

func _step(seconds: float) -> void:
	var left := seconds
	while left > 0.0:
		var d := minf(0.1, left)
		_desk.advance(d)
		left -= d


func _stamp_right() -> void:
	var right: String = _desk.current().right
	_desk.stamp(Bills.APPROVE if right == Bills.EITHER else right)


# Stamps right until the first bill that `match` is true for; its index.
func _go_to_first(match: Callable) -> int:
	while not match.call(_desk.current()):
		if _desk.is_ending():
			return -1
		_stamp_right()
		_step(Provider.STAMPED_HOLD)
	return _desk.bill_index()


func _thunk_player() -> AudioStreamPlayer:
	for child in _desk.get_children():
		if child is AudioStreamPlayer:
			return child
	return null


func _visible_things(root: Node) -> Array[Control]:
	var out: Array[Control] = []
	for child in root.get_children():
		if child is Control and child.is_visible_in_tree() \
				and not child.name in ["Desk", "Fade"] and child.get_global_rect().has_area():
			out.append(child)
	return out
