{**
 * plugins/generic/reviewerCertificate/templates/certificateSettings.tpl
 *
 * Copyright (c) 2024
 * Modifications copyright (c) 2026 Panorama Scholarly Group Ltd. <contact@panorama-sg.com>
 * Distributed under the GNU GPL v3.
 *
 * Certificate settings form template
 *}
<style>
{literal}
.rc-settings, .rc-panel {
	--rc-ink: #1f2933;
	--rc-muted: #5f6b7a;
	--rc-line: #dde3ea;
	--rc-soft: #f5f7fa;
	--rc-accent: #006798;
	--rc-accent-soft: #e6f1f7;
	--rc-radius: 8px;
	color: var(--rc-ink);
}
/* OJS's .pkp_form label/input rules outrank single-class selectors, so each
   rule below also carries a .pkp_form.rc-settings copy that wins inside the form. */
.rc-settings [hidden] { display: none !important; }
.pkp_form.rc-settings label { font-size: inherit; font-weight: inherit; }
.rc-settings .rc-intro { color: var(--rc-muted); margin: 0 0 16px; }
.rc-errors, .pkp_form.rc-settings .rc-errors { border: 1px solid #e3a4a4; background: #fdf2f2; color: #8a1f1f; border-radius: var(--rc-radius); padding: 12px 16px; margin-bottom: 16px; }
.rc-errors ul, .pkp_form.rc-settings .rc-errors ul { margin: 6px 0 0 18px; }

.rc-card, .pkp_form.rc-settings .rc-card { background: #fff; border: 1px solid var(--rc-line); border-radius: var(--rc-radius); padding: 20px 24px 8px; margin-bottom: 16px; box-shadow: 0 1px 2px rgba(16, 24, 40, .04); }
.rc-card__head, .pkp_form.rc-settings .rc-card__head { display: flex; gap: 14px; align-items: flex-start; margin-bottom: 18px; padding-bottom: 14px; border-bottom: 1px solid var(--rc-line); }
.rc-card__head h3, .pkp_form.rc-settings .rc-card__head h3 { margin: 0 0 2px; font-size: 1.05rem; font-weight: 700; }
.rc-card__head p, .pkp_form.rc-settings .rc-card__head p { margin: 0; color: var(--rc-muted); font-size: .875rem; }
.rc-step, .pkp_form.rc-settings .rc-step { flex: none; width: 28px; height: 28px; border-radius: 50%; background: var(--rc-accent); color: #fff; font-weight: 700; display: inline-flex; align-items: center; justify-content: center; font-size: .875rem; }

.rc-field, .pkp_form.rc-settings .rc-field { display: block; margin-bottom: 16px; }
.rc-label, .pkp_form.rc-settings .rc-label, .rc-settings .rc-field > .rc-label { display: block; font-weight: 600; font-size: .875rem; margin-bottom: 6px; }
.rc-label-row, .pkp_form.rc-settings .rc-label-row { display: flex; justify-content: space-between; align-items: baseline; gap: 12px; flex-wrap: wrap; }
.rc-required, .pkp_form.rc-settings .rc-required { color: #b42318; }
.rc-hint, .pkp_form.rc-settings .rc-hint { color: var(--rc-muted); font-size: .8125rem; margin: 6px 0 0; line-height: 1.45; }
.rc-input, .pkp_form.rc-settings .rc-input { box-sizing: border-box; width: 100%; height: auto; line-height: 1.4; padding: 8px 10px; border: 1px solid #c4ccd6; border-radius: 6px; font: inherit; font-size: .9rem; background: #fff; color: var(--rc-ink); }
.rc-input:focus, .pkp_form.rc-settings .rc-input:focus { outline: 2px solid var(--rc-accent-soft); border-color: var(--rc-accent); }
.rc-textarea, .pkp_form.rc-settings .rc-textarea { font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace; font-size: .85rem; line-height: 1.55; min-height: 190px; resize: vertical; }
.rc-input--num, .pkp_form.rc-settings .rc-input--num { width: 84px; }
.rc-inline .rc-input--num, .pkp_form.rc-settings .rc-inline .rc-input--num { width: 100%; }
.rc-link, .pkp_form.rc-settings .rc-link { background: none; border: 0; padding: 0; color: var(--rc-accent); font-size: .8125rem; cursor: pointer; text-decoration: underline; white-space: nowrap; }
.rc-actions, .pkp_form.rc-settings .rc-actions { display: inline-flex; flex-wrap: wrap; gap: 6px 14px; }

/* Layout chooser */
.rc-layout-choice, .pkp_form.rc-settings .rc-layout-choice { display: grid; grid-template-columns: repeat(auto-fit, minmax(240px, 1fr)); gap: 12px; }
.rc-layout-option, .pkp_form.rc-settings .rc-layout-option { position: relative; cursor: pointer; }
.rc-layout-option input, .pkp_form.rc-settings .rc-layout-option input { position: absolute; opacity: 0; }
.rc-layout-option__body, .pkp_form.rc-settings .rc-layout-option__body { display: grid; grid-template-columns: 120px 1fr; grid-template-rows: auto 1fr; column-gap: 14px; padding: 12px; border: 1.5px solid var(--rc-line); border-radius: var(--rc-radius); background: #fff; height: 100%; box-sizing: border-box; }
.rc-layout-option__body svg, .pkp_form.rc-settings .rc-layout-option__body svg { grid-row: span 2; width: 120px; height: 84px; }
.rc-layout-option__body strong, .pkp_form.rc-settings .rc-layout-option__body strong { font-size: .9rem; align-self: end; }
.rc-layout-option__body small, .pkp_form.rc-settings .rc-layout-option__body small { color: var(--rc-muted); font-size: .8rem; line-height: 1.4; }
.rc-layout-option input:checked + .rc-layout-option__body, .pkp_form.rc-settings .rc-layout-option input:checked + .rc-layout-option__body { border-color: var(--rc-accent); background: var(--rc-accent-soft); box-shadow: 0 0 0 1px var(--rc-accent); }
.rc-layout-option input:focus-visible + .rc-layout-option__body, .pkp_form.rc-settings .rc-layout-option input:focus-visible + .rc-layout-option__body { outline: 2px solid var(--rc-accent); outline-offset: 2px; }
.rc-thumb-page, .pkp_form.rc-settings .rc-thumb-page { fill: #fff; stroke: #c4ccd6; }
.rc-thumb-line, .pkp_form.rc-settings .rc-thumb-line { fill: #c9d1db; }
.rc-thumb-strong, .pkp_form.rc-settings .rc-thumb-strong { fill: #5f6b7a; }
.rc-thumb-accent, .pkp_form.rc-settings .rc-thumb-accent { fill: #2f86a8; }
.rc-thumb-band, .pkp_form.rc-settings .rc-thumb-band { fill: #eef1f4; }
.rc-thumb-seal, .pkp_form.rc-settings .rc-thumb-seal { fill: #d4a64a; }

/* Variable chips */
.rc-chips, .pkp_form.rc-settings .rc-chips { display: flex; flex-wrap: wrap; gap: 6px; align-items: center; margin-top: 10px; }
.rc-chips__label, .pkp_form.rc-settings .rc-chips__label { color: var(--rc-muted); font-size: .8rem; margin-right: 4px; }
.rc-chip, .pkp_form.rc-settings .rc-chip { font-family: ui-monospace, Menlo, Consolas, monospace; font-size: .75rem; padding: 3px 8px; border-radius: 999px; border: 1px solid var(--rc-line); background: var(--rc-soft); color: var(--rc-ink); cursor: pointer; }
.rc-chip:hover, .pkp_form.rc-settings .rc-chip:hover { border-color: var(--rc-accent); color: var(--rc-accent); }

/* Images */
.rc-image-grid, .pkp_form.rc-settings .rc-image-grid { display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 12px; margin-bottom: 16px; }
.rc-image, .pkp_form.rc-settings .rc-image { border: 1px solid var(--rc-line); border-radius: var(--rc-radius); padding: 14px; background: var(--rc-soft); }
.rc-image--wide, .pkp_form.rc-settings .rc-image--wide { grid-column: 1 / -1; }
.rc-image__head, .pkp_form.rc-settings .rc-image__head { display: flex; justify-content: space-between; gap: 8px; align-items: center; }
.rc-image .rc-hint, .pkp_form.rc-settings .rc-image .rc-hint { margin: 4px 0 10px; }
.rc-badge, .pkp_form.rc-settings .rc-badge { font-size: .75rem; padding: 2px 8px; border-radius: 999px; background: #e3f4ea; color: #1f6b3b; max-width: 60%; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.rc-badge--empty, .pkp_form.rc-settings .rc-badge--empty { background: #eceff3; color: var(--rc-muted); }
.rc-file, .pkp_form.rc-settings .rc-file { display: block; width: 100%; font-size: .8125rem; height: auto; line-height: 1.4; padding: 10px; border: 1.5px dashed #b8c2cd; border-radius: 6px; background: #fff; box-sizing: border-box; cursor: pointer; }
.rc-file:hover, .pkp_form.rc-settings .rc-file:hover { border-color: var(--rc-accent); }
.rc-file-chosen, .pkp_form.rc-settings .rc-file-chosen { display: block; margin-top: 6px; font-size: .8rem; color: #1f6b3b; }
.rc-check, .pkp_form.rc-settings .rc-check { display: block; margin-top: 8px; font-size: .8125rem; }
.rc-inline, .pkp_form.rc-settings .rc-inline { display: flex; gap: 10px; margin-top: 10px; flex-wrap: wrap; }
.rc-inline label, .pkp_form.rc-settings .rc-inline label { flex: 1 1 60px; display: flex; flex-direction: column; gap: 4px; font-size: .75rem; color: var(--rc-muted); }

/* Typography table */
.rc-type-table, .pkp_form.rc-settings .rc-type-table { width: 100%; border-collapse: collapse; margin-bottom: 18px; }
.rc-type-table th, .pkp_form.rc-settings .rc-type-table th, .rc-type-table td, .pkp_form.rc-settings .rc-type-table td { padding: 10px 8px; border-bottom: 1px solid var(--rc-line); text-align: left; vertical-align: middle; }
.rc-type-table thead th, .pkp_form.rc-settings .rc-type-table thead th { font-size: .75rem; text-transform: uppercase; letter-spacing: .04em; color: var(--rc-muted); font-weight: 600; background: var(--rc-soft); }
.rc-type-table tbody th, .pkp_form.rc-settings .rc-type-table tbody th { font-weight: 600; font-size: .875rem; width: 42%; }
.rc-type-table tbody th small, .pkp_form.rc-settings .rc-type-table tbody th small { display: block; font-weight: 400; color: var(--rc-muted); font-size: .75rem; margin-top: 2px; line-height: 1.35; }
.rc-color, .pkp_form.rc-settings .rc-color { display: inline-flex; align-items: center; gap: 6px; }
.rc-color__swatch, .pkp_form.rc-settings .rc-color__swatch { width: 34px; height: 34px; padding: 0; border: 1px solid #c4ccd6; border-radius: 6px; background: #fff; cursor: pointer; }
.rc-color__hex, .pkp_form.rc-settings .rc-color__hex { width: 96px; font-family: ui-monospace, Menlo, Consolas, monospace; }
.rc-color__value, .pkp_form.rc-settings .rc-color__value { font-size: .8rem; color: var(--rc-muted); }
.rc-style-cell, .pkp_form.rc-settings .rc-style-cell { white-space: nowrap; }
.rc-toggle, .pkp_form.rc-settings .rc-toggle { display: inline-flex; align-items: center; gap: 6px; margin-right: 12px; font-size: .8125rem; cursor: pointer; }
.rc-toggle--block, .pkp_form.rc-settings .rc-toggle--block { display: flex; margin-top: 8px; }

.rc-grid, .pkp_form.rc-settings .rc-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(190px, 1fr)); gap: 0 16px; }
.rc-notice, .pkp_form.rc-settings .rc-notice { background: var(--rc-soft); border: 1px dashed var(--rc-line); border-radius: var(--rc-radius); padding: 12px 14px; color: var(--rc-muted); font-size: .875rem; margin: 0 0 16px; }

/* Show only what applies to the chosen layout */
.rc-settings[data-layout="structured"] .rc-only-classic, .rc-settings:not([data-layout="structured"]) .rc-only-structured { display: none !important; }

/* Save bar */
.rc-savebar, .pkp_form.rc-settings .rc-savebar { margin-top: 20px; display: flex; align-items: center; gap: 14px; flex-wrap: wrap; padding: 12px 16px; background: #fff; border: 1px solid var(--rc-line); border-radius: var(--rc-radius); }
.rc-savebar .formButtons, .pkp_form.rc-settings .rc-savebar .formButtons { margin: 0; padding: 0; border: 0; }
.rc-savebar__status, .pkp_form.rc-settings .rc-savebar__status { margin-left: auto; font-size: .85rem; font-weight: 600; }
.rc-savebar__status.is-ok, .pkp_form.rc-settings .rc-savebar__status.is-ok { color: #1f6b3b; }
.rc-savebar__status.is-error, .pkp_form.rc-settings .rc-savebar__status.is-error { color: #b42318; }
.rc-savebar__hint, .pkp_form.rc-settings .rc-savebar__hint { color: var(--rc-muted); font-size: .8rem; }
.pkp_form.rc-settings .rc-savebar .submitFormButton { min-width: 96px; padding: 0 18px; background: var(--rc-accent); border-color: var(--rc-accent); color: #fff; font-weight: 700; }
.pkp_form.rc-settings .rc-savebar .submitFormButton:hover, .pkp_form.rc-settings .rc-savebar .submitFormButton:focus { background: #00557d; border-color: #00557d; color: #fff; }

/* Statistics and batch tools below the form */
.rc-panel { background: #fff; border: 1px solid var(--rc-line); border-radius: var(--rc-radius); padding: 20px 24px; margin-top: 20px; box-sizing: border-box; }
.rc-panel h2 { margin-top: 0; font-size: 1.05rem; }
.rc-panel > p { color: var(--rc-muted); font-size: .875rem; line-height: 1.5; }
.rc-panel .rc-input[multiple] { padding: 6px; }
.rc-panel .rc-toggle { margin: 10px 0 0; }
.rc-panel__actions { display: flex; align-items: center; gap: 14px; margin-top: 14px; }
.rc-stats { display: grid; grid-template-columns: repeat(auto-fit, minmax(160px, 1fr)); gap: 12px; margin: 14px 0 0; }
.rc-stat { background: var(--rc-soft, #f5f7fa); border-radius: 8px; padding: 16px; }
.rc-stat strong { display: block; font-size: 1.75rem; line-height: 1.1; color: #006798; }
.rc-stat span { color: #5f6b7a; font-size: .8125rem; }

@media (max-width: 900px) {
	.rc-image-grid, .pkp_form.rc-settings .rc-image-grid { grid-template-columns: 1fr; }
}
@media (max-width: 640px) {
	.rc-card, .pkp_form.rc-settings .rc-card { padding: 16px 14px 4px; }
	.rc-layout-option__body, .pkp_form.rc-settings .rc-layout-option__body { grid-template-columns: 80px 1fr; column-gap: 10px; }
	.rc-layout-option__body svg, .pkp_form.rc-settings .rc-layout-option__body svg { width: 80px; height: 56px; }
	.rc-type-table thead, .pkp_form.rc-settings .rc-type-table thead { display: none; }
	.rc-type-table tr, .pkp_form.rc-settings .rc-type-table tr { display: grid; grid-template-columns: 1fr 1fr; border-bottom: 1px solid var(--rc-line); }
	.rc-type-table tbody th, .pkp_form.rc-settings .rc-type-table tbody th { grid-column: 1 / -1; width: auto; border: 0; }
	.rc-type-table td, .pkp_form.rc-settings .rc-type-table td { border: 0; min-width: 0; }
	.rc-type-table .rc-style-cell, .pkp_form.rc-settings .rc-type-table .rc-style-cell { grid-column: 1 / -1; padding-top: 0; }
}
{/literal}
</style>

<script>
{literal}
$(function() {
	var $form = $('#certificateSettingsForm');

	var $body = $('#bodyTemplate');
	var $header = $('#headerText');
	var $footer = $('#footerText');
	var imageInputs = '#backgroundImage, #logoImage, #coverImage, #sealImage';

	// ---- Layout mode: show the controls that apply, and fold the header into the body
	function bodyHasTitleLine() {
		return /^\s*#\s*\S/m.test($body.val());
	}
	function foldHeaderIntoBody() {
		var header = $.trim($header.val());
		if (!header) { return; }
		var text = $body.val();
		if (/^\s*\{\{?\$certificateTitle\}\}?\s*$/m.test(text)) {
			text = text.replace(/^\s*\{\{?\$certificateTitle\}\}?\s*$/m, '# ' + header);
		} else if (!bodyHasTitleLine()) {
			text = '# ' + header + '\n\n' + text;
		}
		$body.val(text);
		$header.val('');
	}
	function foldFooterIntoBody() {
		var footer = $.trim($footer.val());
		if (!footer) { return; }
		var text = $body.val();
		if (!/^[ \t]*-{3,}[ \t]*$/m.test(text)) {
			$body.val(text.replace(/\s+$/, '') + '\n\n---\n' + footer);
		}
		$footer.val('');
	}
	// Back to classic: the classic layout has its own header and footer fields
	function unfoldBody() {
		var text = $body.val();
		var parts = text.split(/^[ \t]*-{3,}[ \t]*$/m);
		if (parts.length > 1) {
			if (!$.trim($footer.val())) { $footer.val($.trim(parts.slice(1).join('---'))); }
			text = parts[0];
		}
		var title = text.match(/^[ \t]*#[ \t]*(\S.*)$/m);
		if (title) {
			if (!$.trim($header.val())) { $header.val($.trim(title[1])); }
			text = text.replace(title[0], '');
		}
		$body.val($.trim(text));
	}
	function applyLayout(event) {
		var mode = $form.find('input[name="layoutMode"]:checked').val() || 'classic';
		$form.attr('data-layout', mode);
		if (mode === 'structured') { foldHeaderIntoBody(); foldFooterIntoBody(); }
		else if (event) { unfoldBody(); }
	}
	$form.on('change', 'input[name="layoutMode"]', applyLayout);
	applyLayout();

	// ---- Template helpers
	$form.on('click', '.rc-chip', function() {
		var el = $body.get(0), token = $(this).attr('data-insert');
		var start = el.selectionStart || 0, end = el.selectionEnd || 0;
		el.value = el.value.slice(0, start) + token + el.value.slice(end);
		el.focus();
		el.selectionStart = el.selectionEnd = start + token.length;
	});
	$('#rcUseDefaultBody').on('click', function() {
		var text = $('#defaultBodyTemplate').val();
		if ($form.attr('data-layout') === 'structured') {
			// Keep the title line and the footer the user already wrote
			var current = $body.val();
			var title = current.match(/^[ \t]*#[ \t]*\S.*$/m);
			var footer = current.split(/^[ \t]*-{3,}[ \t]*$/m)[1];
			text = $.trim(title ? title[0] : '# Certificate of Recognition') + '\n\n' + text;
			if (footer && $.trim(footer)) { text += '\n\n---\n' + $.trim(footer); }
		}
		$body.val(text);
	});
	var recognitionPreset = {
		titleFontSize: 46, titleBold: false, titleColor: '#1b6f8a',
		nameFontSize: 24, nameBold: true, nameUppercase: true,
		journalFontSize: 20, journalBold: false, bodyFontSize: 16, bodyBold: false,
		detailFontSize: 8, footerFontSize: 13, footerBold: true,
		footerPosition: 'bottomLeft', footerBottomSpacing: 24,
		paragraphSpacing: 9, nameSpacing: 2, sideMargin: 55, bodyTopOffset: 22
	};
	$('#rcUseRecognition').on('click', function() {
		$body.val($('#recognitionBodyTemplate').val());
		$header.val('');
		$footer.val('');
		$.each(recognitionPreset, function(name, value) {
			var $field = $form.find('[name="' + name + '"]');
			if ($field.is(':checkbox')) { $field.prop('checked', value); }
			else { $field.val(value).trigger('input'); }
		});
		$form.find('select[name="pageOrientation"]').val('L');
	});

	// ---- Colour fields: swatch and hex text stay in sync; empty hex = default colour
	$form.find('.rc-color').each(function() {
		var $swatch = $(this).find('.rc-color__swatch'), $hex = $(this).find('.rc-color__hex');
		if (!$hex.length) { return; }
		$swatch.on('input change', function() { $hex.val($swatch.val()); });
		$hex.on('input', function() {
			var v = $.trim($hex.val());
			if (/^#?[0-9a-f]{6}$/i.test(v)) { $swatch.val(v.charAt(0) === '#' ? v : '#' + v); }
		}).trigger('input');
	});

	// General text colour is stored as R/G/B
	function toHex(n) { return ('0' + Math.max(0, Math.min(255, parseInt(n, 10) || 0)).toString(16)).slice(-2); }
	var $picker = $('#colorPicker');
	function showRgb() {
		var hex = '#' + toHex($('#textColorR').val()) + toHex($('#textColorG').val()) + toHex($('#textColorB').val());
		$picker.val(hex);
		$('#colorHex').text(hex);
	}
	$picker.on('input change', function() {
		var v = $picker.val();
		$('#textColorR').val(parseInt(v.substr(1, 2), 16));
		$('#textColorG').val(parseInt(v.substr(3, 2), 16));
		$('#textColorB').val(parseInt(v.substr(5, 2), 16));
		$('#colorHex').text(v);
	});
	showRgb();

	// ---- Image files: show the chosen name; uploads need a regular (non-AJAX) POST
	$form.on('change', imageInputs, function(e) {
		var file = e.target.files[0], $info = $(this).siblings('.rc-file-chosen');
		if (file && (!file.type.match('image.*') || file.size > 5 * 1024 * 1024)) {
			alert('Please choose a PNG or JPEG image under 5 MB.');
			$(this).val('');
			file = null;
		}
		if (!$info.length) { $info = $('<span class="rc-file-chosen"></span>').insertAfter(this); }
		$info.text(file ? file.name : '').toggle(!!file);
	});
	// ---- Save: post the whole form (files included) over AJAX and stay on
	// this page. OJS's AjaxFormHandler cannot send files, and the regular POST
	// we used for uploads reloaded the page and left the settings.
	var saving = false;
	var $status = $('#rcSaveStatus');
	function showStatus(ok) {
		$status.toggleClass('is-error', !ok).toggleClass('is-ok', ok)
			.text($status.attr(ok ? 'data-saved' : 'data-failed'));
	}
	$form.on('submit', function(e) {
		e.preventDefault();
		if (saving) { return false; }
		saving = true;
		var $button = $form.find('.rc-savebar .submitFormButton'), $spinner = $form.find('.rc-savebar .pkp_spinner');
		$button.prop('disabled', true);
		$spinner.addClass('is_visible');
		$status.removeClass('is-ok is-error').text('');
		$.ajax({
			url: $form.attr('action'), type: 'POST', data: new FormData(this),
			processData: false, contentType: false, dataType: 'json'
		}).done(function(json) {
			var $fresh = $('<div>').append($.parseHTML((json && json.content) || ''));
			$form.find('.rc-errors').remove();
			if (json && json.status) {
				// New badges, cleared file inputs, remove boxes for stored images
				var $grid = $fresh.find('.rc-image-grid');
				if ($grid.length) { $form.find('.rc-image-grid').replaceWith($grid); }
				showStatus(true);
			} else {
				var $errors = $fresh.find('.rc-errors');
				if ($errors.length) {
					$errors.insertBefore($form.find('.rc-intro'));
					$errors.get(0).scrollIntoView({ behavior: 'smooth', block: 'center' });
				}
				showStatus(false);
			}
		}).fail(function() {
			showStatus(false);
		}).always(function() {
			saving = false;
			$button.prop('disabled', false);
			$spinner.removeClass('is_visible');
		});
		return false;
	});
});
{/literal}
</script>

{assign var=rcKey value="plugins.generic.reviewerCertificate.settings."}
{capture assign=rcRecognitionBody}{literal}{{$journalName}}

# Certificate of Reviewing

Awarded for 1 review in {{$reviewMonthYear}}
presented to

{{$reviewerName}}

in recognition of the review contributed to the journal

---
The Editors of {{$journalName}}{/literal}{/capture}

<form class="pkp_form rc-settings" id="certificateSettingsForm" method="post" action="{url router=$smarty.const.ROUTE_COMPONENT op="manage" category="generic" plugin=$pluginName verb="settings" save=true}" enctype="multipart/form-data" data-layout="{$layoutMode|escape}">
	{csrf}
	{include file="controllers/notification/inPlaceNotification.tpl" notificationId="certificateSettingsFormNotification"}

	{if $isError}
		<div class="rc-errors" role="alert">
			<strong>{translate key="form.errorsOccurred"}</strong>
			<ul>{foreach from=$errors key=field item=message}<li>{$message|escape}</li>{/foreach}</ul>
		</div>
	{/if}

	<p class="rc-intro">{translate key="plugins.generic.reviewerCertificate.settings.description"}</p>

	{* ------------------------------------------------------------ 1. Layout and text *}
	<section class="rc-card" id="rcLayoutCard">
		<header class="rc-card__head">
			<span class="rc-step">1</span>
			<div>
				<h3>{translate key="`$rcKey`section.layout"}</h3>
				<p>{translate key="`$rcKey`section.layoutDescription"}</p>
			</div>
		</header>

		<div class="rc-field">
			<span class="rc-label">{translate key="`$rcKey`layoutMode"}</span>
			<div class="rc-layout-choice" role="radiogroup">
				<label class="rc-layout-option">
					<input type="radio" name="layoutMode" value="classic" {if $layoutMode != 'structured'}checked{/if} />
					<span class="rc-layout-option__body">
						<svg viewBox="0 0 120 84" aria-hidden="true"><rect x="1" y="1" width="118" height="82" rx="4" class="rc-thumb-page"/><rect x="34" y="12" width="52" height="7" rx="2" class="rc-thumb-strong"/>{section name=l loop=6}<rect x="22" y="{$smarty.section.l.index*8+28}" width="76" height="3.5" rx="1.5" class="rc-thumb-line"/>{/section}</svg>
						<strong>{translate key="`$rcKey`layoutMode.classic"}</strong>
						<small>{translate key="`$rcKey`layoutMode.classicHint"}</small>
					</span>
				</label>
				<label class="rc-layout-option">
					<input type="radio" name="layoutMode" value="structured" {if $layoutMode == 'structured'}checked{/if} />
					<span class="rc-layout-option__body">
						<svg viewBox="0 0 120 84" aria-hidden="true"><rect x="1" y="1" width="118" height="82" rx="4" class="rc-thumb-page"/><rect x="8" y="8" width="14" height="14" rx="2" class="rc-thumb-line"/><rect x="100" y="8" width="12" height="16" rx="1" class="rc-thumb-line"/><rect x="42" y="12" width="36" height="3.5" rx="1.5" class="rc-thumb-line"/><rect x="26" y="21" width="68" height="9" rx="2" class="rc-thumb-accent"/><rect x="40" y="36" width="40" height="3" rx="1.5" class="rc-thumb-line"/><rect x="38" y="44" width="44" height="7" rx="2" class="rc-thumb-strong"/><rect x="30" y="56" width="60" height="3" rx="1.5" class="rc-thumb-line"/><rect x="0" y="66" width="120" height="17" class="rc-thumb-band"/><circle cx="96" cy="68" r="7" class="rc-thumb-seal"/></svg>
						<strong>{translate key="`$rcKey`layoutMode.structured"}</strong>
						<small>{translate key="`$rcKey`layoutMode.structuredHint"}</small>
					</span>
				</label>
			</div>
		</div>

		<div class="rc-field rc-only-classic" id="rcHeaderField">
			<label class="rc-label" for="headerText">{translate key="`$rcKey`headerText"}</label>
			<input type="text" class="rc-input" id="headerText" name="headerText" value="{$headerText|escape}" maxlength="255" />
			<p class="rc-hint">{translate key="`$rcKey`headerTextDescription"}</p>
		</div>

		<div class="rc-field">
			<div class="rc-label-row">
				<label class="rc-label" for="bodyTemplate">{translate key="`$rcKey`bodyTemplate"} <span class="rc-required">*</span></label>
				<span class="rc-actions">
					<button type="button" class="rc-link" id="rcUseDefaultBody">{translate key="`$rcKey`useDefaultTemplate"}</button>
					<button type="button" class="rc-link rc-only-structured" id="rcUseRecognition">{translate key="`$rcKey`useRecognitionTemplate"}</button>
				</span>
			</div>
			<textarea class="rc-input rc-textarea" id="bodyTemplate" name="bodyTemplate" rows="14" spellcheck="false">{$bodyTemplate|escape}</textarea>
			<p class="rc-hint rc-only-structured">{translate key="`$rcKey`titleLineHint"}</p>
			<div class="rc-chips" aria-label="{translate key="`$rcKey`availableVariables"}">
				<span class="rc-chips__label">{translate key="`$rcKey`insertVariable"}</span>
				{foreach from=$templateVariables item=variable}
					<button type="button" class="rc-chip" data-insert="{$variable|escape}">{$variable|escape}</button>
				{/foreach}
			</div>
			<textarea id="defaultBodyTemplate" hidden>{$defaultBodyTemplate|escape}</textarea>
			<textarea id="recognitionBodyTemplate" hidden>{$rcRecognitionBody|escape}</textarea>
		</div>

		<div class="rc-field rc-only-classic">
			<label class="rc-label" for="footerText">{translate key="`$rcKey`footerText"}</label>
			<textarea class="rc-input" id="footerText" name="footerText" rows="2">{$footerText|escape}</textarea>
			<p class="rc-hint">{translate key="`$rcKey`footerTextDescription"}</p>
		</div>
	</section>

	{* ------------------------------------------------------------ 2. Images *}
	<section class="rc-card">
		<header class="rc-card__head">
			<span class="rc-step">2</span>
			<div>
				<h3>{translate key="`$rcKey`section.images"}</h3>
				<p>{translate key="`$rcKey`section.imagesDescription"}</p>
			</div>
		</header>

		<div class="rc-image-grid">
			<div class="rc-image rc-image--wide">
				<div class="rc-image__head">
					<strong>{translate key="`$rcKey`backgroundImage"}</strong>
					{if $backgroundImage}<span class="rc-badge">{$backgroundImageName|escape}</span>{else}<span class="rc-badge rc-badge--empty">{translate key="`$rcKey`image.none"}</span>{/if}
				</div>
				<p class="rc-hint">{translate key="`$rcKey`backgroundImageDescription"}</p>
				<input type="file" id="backgroundImage" name="backgroundImage" accept="image/png,image/jpeg" class="rc-file" />
				{if $backgroundImage}
					<label class="rc-check"><input type="checkbox" id="removeBackgroundImage" name="removeBackgroundImage" value="1" /> {translate key="`$rcKey`removeBackgroundImage"}</label>
				{/if}
			</div>
			{foreach from=$overlayImages key=field item=name}
				<div class="rc-image">
					<div class="rc-image__head">
						<strong>{translate key="`$rcKey``$field`"}</strong>
						{if $field == 'logoImage' && $logoImage}<span class="rc-badge">{$logoImageName|escape}</span>
						{elseif $field == 'coverImage' && $coverImage}<span class="rc-badge">{$coverImageName|escape}</span>
						{elseif $field == 'sealImage' && $sealImage}<span class="rc-badge">{$sealImageName|escape}</span>
						{else}<span class="rc-badge rc-badge--empty">{translate key="`$rcKey`image.none"}</span>{/if}
					</div>
					<p class="rc-hint">{translate key="`$rcKey``$field`Description"}</p>
					<input type="file" id="{$field}" name="{$field}" accept="image/png,image/jpeg" class="rc-file" />
					{if ($field == 'logoImage' && $logoImage) || ($field == 'coverImage' && $coverImage) || ($field == 'sealImage' && $sealImage)}
						{if $field == 'logoImage'}{assign var=removeField value='removeLogoImage'}{elseif $field == 'coverImage'}{assign var=removeField value='removeCoverImage'}{else}{assign var=removeField value='removeSealImage'}{/if}
						<label class="rc-check"><input type="checkbox" id="{$removeField}" name="{$removeField}" value="1" /> {translate key="`$rcKey`removeImage"}</label>
					{/if}
					{if $name == 'logo'}{assign var=w value=$logoWidth}{assign var=x value=$logoX}{assign var=y value=$logoY}
					{elseif $name == 'cover'}{assign var=w value=$coverWidth}{assign var=x value=$coverX}{assign var=y value=$coverY}
					{else}{assign var=w value=$sealWidth}{assign var=x value=$sealX}{assign var=y value=$sealY}{/if}
					<div class="rc-inline">
						<label>{translate key="`$rcKey`image.width"}<input type="number" class="rc-input rc-input--num" name="{$name}Width" value="{$w|escape}" min="5" max="200" /></label>
						<label>{translate key="`$rcKey`image.xShort"}<input type="number" class="rc-input rc-input--num" name="{$name}X" value="{if $x >= 0}{$x|escape}{/if}" min="0" max="297" placeholder="{translate key="`$rcKey`image.auto"}" /></label>
						<label>{translate key="`$rcKey`image.yShort"}<input type="number" class="rc-input rc-input--num" name="{$name}Y" value="{if $y >= 0}{$y|escape}{/if}" min="0" max="297" placeholder="{translate key="`$rcKey`image.auto"}" /></label>
					</div>
				</div>
			{/foreach}
		</div>
	</section>

	{* ------------------------------------------------------------ 3. Typography *}
	<section class="rc-card">
		<header class="rc-card__head">
			<span class="rc-step">3</span>
			<div>
				<h3>{translate key="`$rcKey`typography"}</h3>
				<p>{translate key="`$rcKey`section.typographyDescription"}</p>
			</div>
		</header>

		<p class="rc-notice rc-only-classic">{translate key="`$rcKey`typography.classicNotice"}</p>

		<div class="rc-only-structured">
			<table class="rc-type-table">
				<thead>
					<tr>
						<th>{translate key="`$rcKey`typography.element"}</th>
						<th>{translate key="`$rcKey`typography.size"}</th>
						<th>{translate key="`$rcKey`typography.color"}</th>
						<th>{translate key="`$rcKey`typography.style"}</th>
					</tr>
				</thead>
				<tbody>
					{foreach from=$typographyRows item=row}
						{assign var=sizeField value="`$row.role`FontSize"}
						{assign var=colorField value="`$row.role`Color"}
						{assign var=boldField value="`$row.role`Bold"}
						<tr>
							<th scope="row">
								{translate key="`$rcKey`typography.`$row.role`"}
								<small>{translate key="`$rcKey`typography.`$row.role`Description"}</small>
							</th>
							<td><input type="number" class="rc-input rc-input--num" name="{$sizeField}" value="{$row.size|escape}" min="6" max="72" aria-label="{translate key="`$rcKey`typography.size"}" /></td>
							<td>
								<span class="rc-color">
									<input type="color" class="rc-color__swatch" value="{if $row.color}{$row.color|escape}{else}#222222{/if}" aria-label="{translate key="`$rcKey`typography.color"}" />
									<input type="text" class="rc-input rc-color__hex" name="{$colorField}" value="{$row.color|escape}" maxlength="7" placeholder="{translate key="`$rcKey`typography.defaultColor"}" />
								</span>
							</td>
							<td class="rc-style-cell">
								{if $row.hasBold}<label class="rc-toggle"><input type="checkbox" name="{$boldField}" value="1" {if $row.bold}checked{/if} /><span>{translate key="`$rcKey`typography.bold"}</span></label>{/if}
								{if $row.role == 'name'}<label class="rc-toggle"><input type="checkbox" name="nameUppercase" value="1" {if $nameUppercase}checked{/if} /><span>{translate key="`$rcKey`typography.uppercase"}</span></label>{/if}
							</td>
						</tr>
					{/foreach}
				</tbody>
			</table>

			<div class="rc-grid">
				<label class="rc-field">
					<span class="rc-label">{translate key="`$rcKey`typography.footerPosition"}</span>
					<select class="rc-input" name="footerPosition">
						{foreach from=$footerPositionOptions key=value item=label}
							<option value="{$value|escape}" {if $footerPosition == $value}selected{/if}>{$label|escape}</option>
						{/foreach}
					</select>
				</label>
				<label class="rc-field">
					<span class="rc-label">{translate key="`$rcKey`typography.footerBottomSpacing"}</span>
					<input type="number" class="rc-input" name="footerBottomSpacing" value="{$footerBottomSpacing|escape}" min="5" max="150" />
				</label>
				<label class="rc-field">
					<span class="rc-label">{translate key="`$rcKey`typography.paragraphSpacing"}</span>
					<input type="number" class="rc-input" name="paragraphSpacing" value="{$paragraphSpacing|escape}" min="0" max="50" />
				</label>
				<label class="rc-field">
					<span class="rc-label">{translate key="`$rcKey`typography.nameSpacing"}</span>
					<input type="number" class="rc-input" name="nameSpacing" value="{$nameSpacing|escape}" min="0" max="50" />
				</label>
				<label class="rc-field">
					<span class="rc-label">{translate key="`$rcKey`typography.sideMargin"}</span>
					<input type="number" class="rc-input" name="sideMargin" value="{$sideMargin|escape}" min="10" max="120" />
				</label>
			</div>
			<p class="rc-hint">{translate key="`$rcKey`typography.spacingDescription"}</p>
		</div>
	</section>

	{* ------------------------------------------------------------ 4. Page *}
	<section class="rc-card">
		<header class="rc-card__head">
			<span class="rc-step">4</span>
			<div>
				<h3>{translate key="`$rcKey`section.page"}</h3>
				<p>{translate key="`$rcKey`section.pageDescription"}</p>
			</div>
		</header>
		<div class="rc-grid">
			<label class="rc-field">
				<span class="rc-label">{translate key="`$rcKey`pageOrientation"}</span>
				<select class="rc-input" name="pageOrientation">
					{foreach from=$orientationOptions key=value item=label}
						<option value="{$value|escape}" {if $pageOrientation == $value}selected{/if}>{$label|escape}</option>
					{/foreach}
				</select>
			</label>
			<label class="rc-field">
				<span class="rc-label">{translate key="`$rcKey`fontFamily"}</span>
				<select class="rc-input" name="fontFamily">
					{foreach from=$fontOptions key=value item=label}
						<option value="{$value|escape}" {if $fontFamily == $value}selected{/if}>{$label|escape}</option>
					{/foreach}
				</select>
			</label>
			<label class="rc-field">
				<span class="rc-label">{translate key="`$rcKey`textColor"}</span>
				<span class="rc-color">
					<input type="color" id="colorPicker" class="rc-color__swatch" aria-label="{translate key="`$rcKey`textColor"}" />
					<input type="hidden" id="textColorR" name="textColorR" value="{$textColorR|default:0|escape}" />
					<input type="hidden" id="textColorG" name="textColorG" value="{$textColorG|default:0|escape}" />
					<input type="hidden" id="textColorB" name="textColorB" value="{$textColorB|default:0|escape}" />
					<code id="colorHex" class="rc-color__value"></code>
				</span>
			</label>
			<label class="rc-field rc-only-classic">
				<span class="rc-label">{translate key="`$rcKey`fontSize"}</span>
				<input type="number" class="rc-input" name="fontSize" value="{$fontSize|default:12|escape}" min="6" max="72" />
			</label>
			<label class="rc-field">
				<span class="rc-label">{translate key="`$rcKey`dateFormat"}</span>
				<select class="rc-input" name="dateFormat">
					{foreach from=$dateFormatOptions key=value item=label}
						<option value="{$value|escape}" {if $dateFormat == $value}selected{/if}>{$label|escape}</option>
					{/foreach}
				</select>
			</label>
			<label class="rc-field">
				<span class="rc-label">{translate key="`$rcKey`bodyTopOffset"}</span>
				<input type="number" class="rc-input" name="bodyTopOffset" value="{$bodyTopOffset|default:0|escape}" min="0" max="100" />
			</label>
		</div>
		<p class="rc-hint">{translate key="`$rcKey`fontUnicodeWarning"}</p>
	</section>

	{* ------------------------------------------------------------ 5. Eligibility and verification *}
	<section class="rc-card">
		<header class="rc-card__head">
			<span class="rc-step">5</span>
			<div>
				<h3>{translate key="`$rcKey`eligibility"}</h3>
				<p>{translate key="`$rcKey`section.eligibilityDescription"}</p>
			</div>
		</header>
		<div class="rc-grid">
			<label class="rc-field">
				<span class="rc-label">{translate key="`$rcKey`minimumReviews"} <span class="rc-required">*</span></span>
				<input type="number" class="rc-input" name="minimumReviews" value="{$minimumReviews|default:1|escape}" min="1" required />
			</label>
			<div class="rc-field">
				<span class="rc-label">{translate key="`$rcKey`verification"}</span>
				<label class="rc-toggle rc-toggle--block"><input type="checkbox" name="includeQRCode" value="1" {if $includeQRCode}checked{/if} /><span>{translate key="`$rcKey`includeQRCode"}</span></label>
			</div>
			<label class="rc-field">
				<span class="rc-label">{translate key="`$rcKey`verifyNameDisplay"}</span>
				<select class="rc-input" name="verifyNameDisplay">
					{foreach from=$verifyNameDisplayOptions key=value item=label}
						<option value="{$value|escape}" {if $verifyNameDisplay == $value}selected{/if}>{$label|escape}</option>
					{/foreach}
				</select>
			</label>
			<label class="rc-field">
				<span class="rc-label">{translate key="`$rcKey`certificateCodeLabel"}</span>
				<input type="text" class="rc-input" name="certificateCodeLabel" value="{$certificateCodeLabel|escape}" maxlength="60" />
			</label>
		</div>
	</section>

	{* ------------------------------------------------------------ Annual summary certificate *}
	<section class="rc-card">
		<header class="rc-card__head">
			<span class="rc-step">★</span>
			<div>
				<h3>{translate key="`$rcKey`annualBodyTemplate"}</h3>
				<p>{translate key="`$rcKey`annualBodyTemplateDescription"}</p>
			</div>
		</header>
		<div class="rc-field">
			<label class="rc-label" for="annualBodyTemplate">{translate key="`$rcKey`annualBodyTemplateLabel"}</label>
			<textarea class="rc-input rc-textarea" id="annualBodyTemplate" name="annualBodyTemplate" rows="7">{$annualBodyTemplate|escape}</textarea>
		</div>
		<div class="rc-field">
			<label class="rc-label" for="cumulativeBodyTemplate">{translate key="`$rcKey`cumulativeBodyTemplate"}</label>
			<p class="rc-hint">{translate key="`$rcKey`cumulativeBodyTemplateDescription"}</p>
			<textarea class="rc-input rc-textarea" id="cumulativeBodyTemplate" name="cumulativeBodyTemplate" rows="7">{$cumulativeBodyTemplate|escape}</textarea>
		</div>
	</section>

	{* ------------------------------------------------------------ 6. Acknowledgement email *}
	<section class="rc-card">
		<header class="rc-card__head">
			<span class="rc-step">6</span>
			<div>
				<h3>{translate key="`$rcKey`section.email"}</h3>
				<p>{translate key="`$rcKey`ackEmailDescription"}</p>
			</div>
		</header>
		<div class="rc-field">
			<label class="rc-label" for="ackEmailSubject">{translate key="`$rcKey`ackEmailSubject"}</label>
			<input type="text" class="rc-input" id="ackEmailSubject" name="ackEmailSubject" value="{$ackEmailSubject|escape}" maxlength="255" />
		</div>
		<div class="rc-field">
			<label class="rc-label" for="ackEmailBody">{translate key="`$rcKey`ackEmailBody"}</label>
			<textarea class="rc-input rc-textarea" id="ackEmailBody" name="ackEmailBody" rows="8">{$ackEmailBody|escape}</textarea>
		</div>
	</section>

	<div class="rc-savebar">
		<a href="{url router=$smarty.const.ROUTE_COMPONENT op="manage" category="generic" plugin=$pluginName verb="preview"}" target="_blank" class="pkp_button rc-preview">
			{translate key="`$rcKey`previewCertificate"}
		</a>
		<span class="rc-savebar__hint">{translate key="`$rcKey`previewHint"}</span>
		{capture assign=rcSavedText}{translate key="common.changesSaved"}{/capture}
		{capture assign=rcFailedText}{translate key="`$rcKey`saveFailed"}{/capture}
		<span id="rcSaveStatus" class="rc-savebar__status" role="status" aria-live="polite" data-saved="{$rcSavedText|escape}" data-failed="{$rcFailedText|escape}"></span>
		{fbvFormButtons hideCancel=true submitText="common.save"}
	</div>
</form>


<!-- Certificate Statistics -->
<div class="rc-panel">
	<h2>{translate key="plugins.generic.reviewerCertificate.statistics.title"}</h2>
	<p class="description">{translate key="plugins.generic.reviewerCertificate.statistics.description"}</p>
	{if $manageCertificatesUrl}<p><a href="{$manageCertificatesUrl|escape}" target="_blank" class="pkp_button rc-manage-link">{translate key="plugins.generic.reviewerCertificate.manage.open"}</a></p>{/if}
	<div class="rc-stats">
		<div class="rc-stat"><strong>{$totalCertificates|default:0}</strong><span>{translate key="plugins.generic.reviewerCertificate.statistics.totalCertificates"}</span></div>
		<div class="rc-stat"><strong>{$totalDownloads|default:0}</strong><span>{translate key="plugins.generic.reviewerCertificate.statistics.totalDownloads"}</span></div>
		<div class="rc-stat"><strong>{$uniqueReviewers|default:0}</strong><span>{translate key="plugins.generic.reviewerCertificate.statistics.uniqueReviewers"}</span></div>
	</div>
</div>

<!-- Batch Certificate Generation -->
<div class="rc-panel">
	<h2>{translate key="plugins.generic.reviewerCertificate.batch.title"}</h2>
	<p>{translate key="plugins.generic.reviewerCertificate.batch.description"}</p>

	{if $eligibleReviewers}
		<form id="batchGenerateForm">
			<div class="rc-field">
				<label class="rc-label" for="batchReviewers">{translate key="plugins.generic.reviewerCertificate.batch.selectReviewers"}</label>
				<select id="batchReviewers" class="rc-input" name="reviewerIds[]" multiple size="8">
					{foreach from=$eligibleReviewers item=reviewer}
						<option value="{$reviewer.id|escape}">{$reviewer.name|escape} ({$reviewer.completedReviews|escape} {translate key="plugins.generic.reviewerCertificate.batch.completedReviews"})</option>
					{/foreach}
				</select>
				<p class="rc-hint">{translate key="plugins.generic.reviewerCertificate.batch.selectMultipleHint"}</p>
			</div>
			<div class="rc-panel__actions">
				<button type="button" id="generateBatchBtn" class="pkp_button pkp_button_primary">
					{translate key="plugins.generic.reviewerCertificate.batch.generate"}
				</button>
				<span id="batchProgress" style="display: none;">
					<span class="pkp_spinner"></span> {translate key="plugins.generic.reviewerCertificate.batch.generating"}
				</span>
			</div>
		</form>
	{else}
		<p class="rc-notice">{translate key="plugins.generic.reviewerCertificate.batch.noEligibleReviewers"}</p>
	{/if}

	<div id="batchResult" style="margin-top: 16px; display: none;"></div>
</div>

<div class="rc-panel">
	<h2>{translate key="plugins.generic.reviewerCertificate.notifications.title"}</h2>
	<p>{translate key="plugins.generic.reviewerCertificate.notifications.description"}</p>
	<div class="rc-field">
		<label class="rc-label" for="notificationReviewers">{translate key="plugins.generic.reviewerCertificate.batch.selectReviewers"}</label>
		<select id="notificationReviewers" class="rc-input" multiple size="6">
			{foreach from=$notificationReviewers item=reviewer}
				<option value="{$reviewer.id|escape}">{$reviewer.name|escape}</option>
			{/foreach}
		</select>
		<p class="rc-hint">{translate key="plugins.generic.reviewerCertificate.batch.selectMultipleHint"}</p>
		<label class="rc-toggle"><input type="checkbox" id="retryNotifications" /> {translate key="plugins.generic.reviewerCertificate.notifications.retry"}</label>
		<p class="rc-hint">{translate key="plugins.generic.reviewerCertificate.notifications.retryWarning"}</p>
	</div>
	<div class="rc-panel__actions">
		<button type="button" id="notifyBatchBtn" class="pkp_button">{translate key="plugins.generic.reviewerCertificate.notifications.send"}</button>
	</div>
	<div id="notificationResult" role="status"></div>
</div>
<script>
$(function() {ldelim}
    $('#generateBatchBtn, #notifyBatchBtn').on('click', function() {ldelim}
        var notify = this.id === 'notifyBatchBtn';
        var resultBox = notify ? '#notificationResult' : '#batchResult';
        var reviewers = $(notify ? '#notificationReviewers' : '#batchReviewers').val();
        if (!reviewers || !reviewers.length) {ldelim}
            alert('{translate key="plugins.generic.reviewerCertificate.batch.noSelection" escape="js"}');
            return;
        {rdelim}
        var totals = {ldelim}generated: 0, skipped: 0, failed: 0, sent: 0{rdelim};
        var button = $(this).prop('disabled', true);
        $('#batchProgress').show();
        function finish() {ldelim} button.prop('disabled', false); $('#batchProgress').hide(); {rdelim}
        function page(cursor) {ldelim}
            $.ajax({ldelim}
                url: notify
                    ? '{url router=$smarty.const.ROUTE_COMPONENT op="manage" category="generic" plugin=$pluginName verb="notifyBatch" escape=false}'
                    : '{url router=$smarty.const.ROUTE_COMPONENT op="manage" category="generic" plugin=$pluginName verb="generateBatch" escape=false}',
                type: 'POST', dataType: 'json',
                data: {ldelim}reviewerIds: reviewers, cursor: cursor,
                    retry: $('#retryNotifications').is(':checked') ? '1' : '0',
                    csrfToken: $('#certificateSettingsForm input[name="csrfToken"]').val(){rdelim}
            {rdelim}).done(function(response) {ldelim}
                var result = response.content;
                if (!result || typeof result.generated !== 'number') {ldelim}
                    $(resultBox).text('{translate key="plugins.generic.reviewerCertificate.batch.error" escape="js"}').show();
                    finish(); return;
                {rdelim}
                totals.generated += result.generated;
                totals.skipped += result.skipped;
                totals.failed += result.failed;
                totals.sent += result.sent || 0;
                $(resultBox).text(
                    '{translate key="plugins.generic.reviewerCertificate.batch.generatedCountLabel" escape="js"}: ' + totals.generated +
                    ' / {translate key="plugins.generic.reviewerCertificate.batch.skipped" escape="js"}: ' + totals.skipped +
                    ' / {translate key="plugins.generic.reviewerCertificate.batch.failed" escape="js"}: ' + totals.failed +
                    (notify ? ' / {translate key="plugins.generic.reviewerCertificate.notifications.sent" escape="js"}: ' + totals.sent : '')
                ).show().attr('role', 'status');
                if (result.continuation !== null) {ldelim} page(result.continuation); {rdelim}
                else {ldelim} finish(); {rdelim}
            {rdelim}).fail(function() {ldelim}
                $(resultBox).append(document.createTextNode(' {translate key="plugins.generic.reviewerCertificate.batch.error" escape="js"}')).show();
                finish();
            {rdelim});
        {rdelim}
        page(0);
    {rdelim});
{rdelim});
</script>
