extends RefCounted
## A test tool for Dan, not for players: he plays the song with no notes and
## taps the way he wants to tap to it, and the taps become the beat chart
## (Dan, 2026-10-22: the measured chart "may technically be on some sort of
## beat ... but it's not a fun rhythm aligned with what I hear"). Shown only
## with the Partner's test info on. When the song ends, or he taps "Stop", the
## taps show in a box with a Copy button, to paste into the thread;
## tools/partner/make_chart.py --taps turns them into the chart. A tap on the
## game after closing the box goes back to the menu, without finishing.
##
## The box and its buttons are the page's own, not the game's: a browser only
## lets a page copy inside a real tap on one of its own buttons.

# Runs once in the page.
const BROWSER_JS := """
window.partnerRecorder = window.partnerRecorder || (function () {
	var stop = false, bar = null, panel = null;
	function button(text, onTap) {
		var b = document.createElement('button');
		b.textContent = text;
		b.style.cssText = 'min-height:48px;min-width:96px;padding:8px 18px;font:18px sans-serif;' +
			'border-radius:8px;border:0;background:#F4EFE6;color:#221726;margin:6px;';
		b.addEventListener('click', function (e) { e.stopPropagation(); onTap(b); });
		return b;
	}
	return {
		open: function () {
			stop = false;
			bar = document.createElement('div');
			bar.style.cssText = 'position:fixed;top:8px;right:8px;z-index:10;';
			bar.appendChild(button('Stop', function () { stop = true; }));
			document.body.appendChild(bar);
		},
		stopped: function () { return stop; },
		show: function (text) {
			if (bar) { bar.remove(); bar = null; }
			try { localStorage.setItem('partnerTaps', text); } catch (e) {}
			panel = document.createElement('div');
			panel.style.cssText = 'position:fixed;left:16px;right:16px;top:16px;z-index:10;padding:12px;' +
				'background:#221726;color:#F4EFE6;font:18px sans-serif;border-radius:8px;';
			var note = document.createElement('div');
			note.textContent = 'Copy these and paste them in the thread.';
			var box = document.createElement('textarea');
			box.readOnly = true;
			box.value = text;
			box.style.cssText = 'width:100%;height:30vh;font:14px monospace;box-sizing:border-box;';
			panel.appendChild(note);
			panel.appendChild(box);
			panel.appendChild(button('Copy', function (b) {
				box.focus();
				box.setSelectionRange(0, text.length);
				var done = function () { b.textContent = 'Copied'; };
				if (navigator.clipboard) {
					navigator.clipboard.writeText(text).then(done, function () {
						document.execCommand('copy');
						done();
					});
				} else {
					document.execCommand('copy');
					done();
				}
			}));
			panel.appendChild(button('Close', function () { panel.remove(); }));
			document.body.appendChild(panel);
		},
	};
})();
"""

var from := 0.0  # Song time the recording starts at, from bar 1 beat 1.
var taps: Array[float] = []  # Seconds from bar 1 beat 1, as heard.
var _web := OS.has_feature("web")


func _init(start_from: float) -> void:
	from = start_from
	if _web:
		JavaScriptBridge.eval(BROWSER_JS, true)
		JavaScriptBridge.eval("window.partnerRecorder.open()", true)


func add(time: float) -> void:
	taps.append(time)


func is_stopped() -> bool:
	return _web and _is_true(JavaScriptBridge.eval("window.partnerRecorder.stopped()", true))


## What Dan pastes: where it started, then each tap in ms from bar 1 beat 1.
func text() -> String:
	var ms := PackedStringArray()
	for t in taps:
		ms.append(str(roundi(t * 1000.0)))
	return "partner-taps from=%d: %s" % [roundi(from * 1000.0), ",".join(ms)]


func finish() -> void:
	print(text())
	if _web:
		JavaScriptBridge.eval("window.partnerRecorder.show(%s)" % JSON.stringify(text()), true)


static func _is_true(value: Variant) -> bool:
	match typeof(value):
		TYPE_BOOL:
			return value
		TYPE_INT, TYPE_FLOAT:
			return value != 0
	return false
