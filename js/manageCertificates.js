/**
 * js/manageCertificates.js
 *
 * Copyright (c) 2026 Panorama Scholarly Group Ltd. <contact@panorama-sg.com>
 * Distributed under the GNU GPL v3.
 *
 * Certificate Management page: tabs, revoke prompt, multi-select and
 * batch actions on the certificate list, batch issuing and notifications,
 * and the settings form loaded into its tab.
 *
 * Loaded as a backend script, because OJS renders the page inside its Vue
 * app, which drops <script> tags in the page body and may replace the page
 * DOM after it was parsed. Every handler is delegated from the document and
 * the page state is applied once the page is ready, so it works whenever
 * the app mounts (OJS 3.3, 3.4 and 3.5).
 */
(function () {
	'use strict';

	function root() {
		return document.querySelector('.rc-manage');
	}

	function text(name) {
		var page = root();
		return (page && page.getAttribute('data-text-' + name)) || '';
	}

	// ---- Tabs -------------------------------------------------------------

	function tabs() {
		return Array.prototype.slice.call(document.querySelectorAll('.rc-manage__tab'));
	}

	function showTab(name, focus) {
		var all = tabs();
		if (!all.length) {
			return;
		}
		if (!all.some(function (tab) { return tab.getAttribute('data-tab') === name; })) {
			name = 'overview';
		}
		all.forEach(function (tab) {
			var on = tab.getAttribute('data-tab') === name;
			var panel = document.getElementById(tab.getAttribute('aria-controls'));
			tab.setAttribute('aria-selected', on ? 'true' : 'false');
			tab.tabIndex = on ? 0 : -1;
			if (panel) {
				panel.hidden = !on;
			}
			if (on && focus) {
				tab.focus();
			}
		});
		if (name === 'settings') {
			loadSettings();
		}
	}

	// ---- Settings form ----------------------------------------------------

	var settingsLoading = false;

	function loadSettings() {
		var page = root();
		var box = document.querySelector('.rc-manage-settings');
		if (!page || !box || box.getAttribute('data-loaded') || settingsLoading) {
			return;
		}
		settingsLoading = true;
		fetch(page.getAttribute('data-settings-url'), {
			credentials: 'same-origin',
			headers: {'X-Requested-With': 'XMLHttpRequest'}
		}).then(function (response) {
			return response.json();
		}).then(function (json) {
			if (!json || !json.status || typeof json.content !== 'string') {
				throw new Error('bad response');
			}
			// jQuery runs the form's inline scripts, as in the settings dialog.
			if (window.jQuery) {
				window.jQuery(box).html(json.content);
			} else {
				box.innerHTML = json.content;
			}
			box.setAttribute('data-loaded', '1');
			box.removeAttribute('aria-busy');
		}).catch(function () {
			box.removeAttribute('aria-busy');
			box.textContent = text('error');
		}).then(function () {
			settingsLoading = false;
		});
	}

	// ---- Batch issuing and notifications ---------------------------------

	function runBatch(tool, button) {
		var notify = tool.hasAttribute('data-rc-notify');
		var ids = Array.prototype.slice.call(tool.querySelectorAll('.rc-manage__picker input[type=checkbox]'))
			.filter(function (box) { return box.checked; })
			.map(function (box) { return box.value; });
		var result = tool.querySelector('.rc-manage__result');
		var progress = tool.querySelector('.rc-manage__progress');
		if (!ids.length) {
			window.alert(text('no-selection'));
			return;
		}
		var totals = {generated: 0, skipped: 0, failed: 0, sent: 0};
		button.disabled = true;
		progress.hidden = false;
		result.textContent = '';
		var finish = function () {
			button.disabled = false;
			progress.hidden = true;
		};
		var page = function (cursor) {
			var body = new URLSearchParams();
			ids.forEach(function (id) { body.append('reviewerIds[]', id); });
			body.append('cursor', cursor);
			var retry = tool.querySelector('.rc-manage__retry');
			body.append('retry', notify && retry && retry.checked ? '1' : '0');
			body.append('csrfToken', root().getAttribute('data-csrf'));
			fetch(tool.getAttribute('data-rc-batch'), {
				method: 'POST',
				credentials: 'same-origin',
				body: body,
				headers: {'X-Requested-With': 'XMLHttpRequest'}
			}).then(function (response) {
				return response.json();
			}).then(function (json) {
				var r = json && json.content;
				if (!r || typeof r.generated !== 'number') {
					throw new Error('bad response');
				}
				totals.generated += r.generated;
				totals.skipped += r.skipped;
				totals.failed += r.failed;
				totals.sent += r.sent || 0;
				result.textContent = text('generated') + ': ' + totals.generated
					+ ' · ' + text('skipped') + ': ' + totals.skipped
					+ ' · ' + text('failed') + ': ' + totals.failed
					+ (notify ? ' · ' + text('sent') + ': ' + totals.sent : '');
				if (r.continuation !== null && r.continuation !== undefined) {
					page(r.continuation);
				} else {
					finish();
				}
			}).catch(function () {
				result.textContent = (result.textContent ? result.textContent + ' ' : '') + text('error');
				finish();
			});
		};
		page(0);
	}

	// ---- Multi-select and batch actions on the certificate list -------------

	function rowBoxes() {
		return Array.prototype.slice.call(document.querySelectorAll('.rc-manage .rc-check--row'));
	}

	function bulkForm() {
		return document.getElementById('rc-bulk-form');
	}

	function fill(template, n) {
		return (template || '').replace('%n%', n);
	}

	/** Number of certificates the batch form acts on. */
	function selectedCount() {
		var form = bulkForm();
		var box = document.querySelector('.rc-manage .rc-certs');
		if (form && form.elements.scope.value === 'all' && box) {
			return parseInt(box.getAttribute('data-total'), 10) || 0;
		}
		return rowBoxes().filter(function (b) { return b.checked; }).length;
	}

	function updateSelection() {
		var form = bulkForm();
		var box = document.querySelector('.rc-manage .rc-certs');
		if (!form || !box) {
			return;
		}
		var rows = rowBoxes();
		var checked = rows.filter(function (b) { return b.checked; }).length;
		var all = form.elements.scope.value === 'all';
		var pageBox = document.querySelector('.rc-manage .rc-check--page');
		if (pageBox) {
			pageBox.checked = rows.length > 0 && checked === rows.length;
			pageBox.indeterminate = checked > 0 && checked < rows.length;
		}
		rows.forEach(function (b) {
			var tr = b.closest('tr');
			if (tr) {
				tr.classList.toggle('is-selected', b.checked);
			}
		});
		form.hidden = checked === 0;
		form.querySelector('.rc-bulk__count').textContent = fill(box.getAttribute('data-text-selected'), selectedCount());
		var scopes = form.querySelectorAll('.rc-bulk__scope');
		if (scopes.length) {
			var pageFull = rows.length > 0 && checked === rows.length;
			scopes[0].hidden = !pageFull || all;
			scopes[1].hidden = !all;
			form.querySelector('.rc-bulk__page-note').textContent = fill(box.getAttribute('data-text-page-selected'), checked);
		}
	}

	function clearSelection() {
		var form = bulkForm();
		if (form) {
			form.elements.scope.value = 'selected';
		}
		rowBoxes().forEach(function (b) { b.checked = false; });
		updateSelection();
	}

	function bulkSubmit(button, event) {
		var form = bulkForm();
		var box = document.querySelector('.rc-manage .rc-certs');
		var action = button.getAttribute('data-bulk');
		var n = selectedCount();
		if (!n) {
			event.preventDefault();
			return;
		}
		if (action === 'revoke') {
			var reason = window.prompt(fill(box.getAttribute('data-text-revoke-prompt'), n));
			if (reason === null) {
				event.preventDefault();
				return;
			}
			form.elements.reason.value = reason;
		} else if (action === 'restore') {
			if (!window.confirm(fill(box.getAttribute('data-text-restore-confirm'), n))) {
				event.preventDefault();
				return;
			}
		}
		form.elements.bulkAction.value = action;
		// Downloads stay on this page: say that the ZIP is being built.
		var note = form.querySelector('.rc-bulk__note');
		if (note) {
			note.hidden = action !== 'download';
			if (action === 'download') {
				setTimeout(function () { note.hidden = true; }, 8000);
			}
		}
	}

	// ---- Delegated events --------------------------------------------------

	document.addEventListener('click', function (event) {
		var target = event.target;
		if (!target.closest || !target.closest('.rc-manage')) {
			return;
		}
		var tab = target.closest('.rc-manage__tab');
		if (tab) {
			showTab(tab.getAttribute('data-tab'));
			if (window.history && history.replaceState) {
				history.replaceState(null, '', '#' + tab.getAttribute('data-tab'));
			}
			return;
		}
		var link = target.closest('[data-tab-link]');
		if (link) {
			event.preventDefault();
			showTab(link.getAttribute('data-tab-link'));
			if (window.history && history.replaceState) {
				history.replaceState(null, '', '#' + link.getAttribute('data-tab-link'));
			}
			return;
		}
		var bulk = target.closest('[data-bulk]');
		if (bulk) {
			bulkSubmit(bulk, event);
			return;
		}
		if (target.closest('.rc-bulk__clear')) {
			clearSelection();
			return;
		}
		if (target.closest('.rc-bulk__all')) {
			bulkForm().elements.scope.value = 'all';
			updateSelection();
			return;
		}
		var revoke = target.closest('.certificate-revoke-btn');
		if (revoke) {
			var reason = window.prompt(revoke.getAttribute('data-prompt'));
			if (reason === null) {
				event.preventDefault();
				return;
			}
			revoke.form.querySelector('input[name=reason]').value = reason;
			return;
		}
		var go = target.closest('.rc-manage__go');
		if (go) {
			runBatch(go.closest('.rc-manage__tool'), go);
		}
	});

	document.addEventListener('change', function (event) {
		var all = event.target;
		if (!all.classList) {
			return;
		}
		if (all.classList.contains('rc-check--page') || all.classList.contains('rc-check--row')) {
			if (all.classList.contains('rc-check--page')) {
				rowBoxes().forEach(function (b) { b.checked = all.checked; });
			}
			// Changing the ticks goes back to "only what is ticked".
			bulkForm().elements.scope.value = 'selected';
			updateSelection();
			return;
		}
		if (!all.classList.contains('rc-manage__all')) {
			return;
		}
		all.closest('.rc-manage__tool').querySelectorAll('.rc-manage__picker input[type=checkbox]')
			.forEach(function (box) { box.checked = all.checked; });
	});

	document.addEventListener('keydown', function (event) {
		var tab = event.target.closest && event.target.closest('.rc-manage__tab');
		var step = event.key === 'ArrowRight' ? 1 : event.key === 'ArrowLeft' ? -1 : 0;
		if (!tab || !step) {
			return;
		}
		var all = tabs();
		var next = all[(all.indexOf(tab) + step + all.length) % all.length];
		showTab(next.getAttribute('data-tab'), true);
	});

	// Apply the tab from the URL once the page (and OJS's app) is ready.
	function init() {
		var page = root();
		if (!page || page.getAttribute('data-rc-ready')) {
			return;
		}
		page.setAttribute('data-rc-ready', '1');
		showTab((window.location.hash || '').replace('#', ''));
		// Browsers may restore ticks after "back": show the bar for them.
		updateSelection();
	}
	if (document.readyState === 'loading') {
		document.addEventListener('DOMContentLoaded', function () { setTimeout(init, 0); });
	} else {
		setTimeout(init, 0);
	}
	window.addEventListener('load', init);
	window.addEventListener('hashchange', function () {
		if (root()) {
			showTab((window.location.hash || '').replace('#', ''));
		}
	});
})();
