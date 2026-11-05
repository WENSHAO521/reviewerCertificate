{**
 * plugins/generic/reviewerCertificate/templates/manageCertificates.tpl
 *
 * Copyright (c) 2026 Panorama Scholarly Group Ltd. <contact@panorama-sg.com>
 * Distributed under the GNU GPL v3.
 *
 * Certificate Management page, reached from the backend side menu below
 * Statistics: statistics, the issued certificates (search, CSV export,
 * download, revoke and restore), batch issuing and email notifications.
 *
 * Built from OJS classes present in 3.3–3.5 (grid panels, .pkp_button,
 * .pkp_notification) plus a few layout rules scoped to .rc-manage that only
 * use OJS's default palette, so it looks like the rest of the backend.
 *}
{extends file="layouts/backend.tpl"}

{block name="page"}
	{capture assign=rcRevokePrompt}{translate key="plugins.generic.reviewerCertificate.manage.revokePrompt"}{/capture}

	<style>
		.rc-manage { max-width: 80rem; }
		.rc-manage__intro { margin: 0 0 1.5rem; color: rgba(0, 0, 0, .54); font-size: .875rem; line-height: 1.5rem; }
		.rc-manage__section { margin: 0 0 2rem; }
		.rc-manage__section > h2 { margin: 0 0 .75rem; font-size: 1rem; font-weight: 700; line-height: 1.5rem; }
		.rc-manage .pkp_controllers_grid .header h4 .rc-manage__count { margin-left: .5rem; font-weight: 400; color: rgba(0, 0, 0, .54); }

		/* Tabs (modelled on the OJS backend tabs) */
		.rc-manage__tabs { display: flex; flex-wrap: wrap; gap: 0; margin: 0 0 1.5rem; border-bottom: 1px solid #ddd; }
		.rc-manage__tab { position: relative; margin: 0 0 -1px; padding: .5rem 1rem; background: transparent; border: 0; border-bottom: 2px solid transparent; font: inherit; font-size: .875rem; font-weight: 700; line-height: 1.5rem; color: rgba(0, 0, 0, .54); cursor: pointer; }
		.rc-manage__tab:hover { color: #006798; }
		.rc-manage__tab:focus-visible { outline: 0; box-shadow: inset 0 0 0 1px #006798; }
		.rc-manage__tab[aria-selected="true"] { color: #006798; border-bottom-color: #006798; }
		.rc-manage__panel[hidden] { display: none; }
		.rc-manage__panel--settings .rc-manage-settings { max-width: 64rem; }

		/* Statistics */
		.rc-manage__stats { display: grid; grid-template-columns: repeat(auto-fit, minmax(min(10rem, 100%), 1fr)); gap: 1rem; margin: 0; padding: 0; list-style: none; }
		.rc-manage__stat { padding: 1rem 1.25rem; background: #fff; border-radius: 2px; box-shadow: 0 1px 2px rgba(0, 0, 0, .3); }
		.rc-manage__stat strong { display: block; font-size: 2rem; line-height: 2.5rem; font-weight: 700; color: #006798; }
		.rc-manage__stat span { display: block; font-size: .75rem; line-height: 1rem; color: rgba(0, 0, 0, .54); }
		.rc-manage__stat--revoked strong { color: #d00a6c; }
		.rc-manage__stat--zero strong { color: rgba(0, 0, 0, .54); }

		/* Search row inside the grid */
		.rc-manage__filter { display: flex; flex-wrap: wrap; align-items: center; gap: .5rem; padding: .75rem 1rem; border-bottom: 1px solid #eee; }
		.rc-manage__filter input[type="search"] { flex: 1 1 18rem; max-width: 28rem; height: 2rem; padding: 0 .75rem; border: 1px solid #bbb; border-radius: 2px; font-size: .875rem; box-sizing: border-box; }
		.rc-manage__filter input[type="search"]:focus { border-color: #006798; outline: 0; box-shadow: 0 0 0 1px #006798; }
		.rc-manage__filter .rc-manage__clear { font-size: .875rem; }

		/* Certificate table */
		.rc-manage .certificate-manage-table th { text-align: left; white-space: nowrap; }
		.rc-manage .certificate-manage-table td { vertical-align: middle; }
		.rc-manage .certificate-manage-table .rc-num { text-align: right; }
		.rc-manage__code { font-family: SFMono-Regular, Menlo, Consolas, monospace; font-size: .8125rem; white-space: nowrap; }
		.rc-manage__sub { display: block; font-size: .75rem; line-height: 1rem; color: rgba(0, 0, 0, .54); }
		.rc-manage__title { min-width: 12rem; max-width: 22rem; }
		.rc-manage__status { min-width: 9rem; }
		.rc-manage__actions { white-space: nowrap; text-align: right; }
		.rc-manage__actions form { display: inline; margin: 0; }
		.rc-manage__actions .pkp_button { margin-left: .25rem; }
		.rc-manage .certificate-revoked td { background: #fafafa; }
		.rc-manage .certificate-revoked .rc-manage__code { text-decoration: line-through; color: rgba(0, 0, 0, .54); }
		.rc-manage__badge { display: inline-block; padding: 0 .5rem; border-radius: 1rem; font-size: .75rem; line-height: 1.25rem; font-weight: 700; white-space: nowrap; }
		.rc-manage__badge--valid { background: #e5f7ed; color: #00703a; }
		.rc-manage__badge--revoked { background: #fbe6f0; color: #b50e61; }

		/* Pagination */
		.rc-manage__pages { display: flex; align-items: center; justify-content: flex-end; gap: .75rem; padding: .5rem 1rem; border-top: 1px solid #eee; font-size: .875rem; color: rgba(0, 0, 0, .54); }

		/* Batch tools */
		.rc-manage__tools { display: grid; grid-template-columns: repeat(auto-fit, minmax(min(22rem, 100%), 1fr)); gap: 1.5rem; align-items: start; }
		.rc-manage__body { padding: 1rem; font-size: .875rem; line-height: 1.5rem; }
		.rc-manage__body > p { margin: 0 0 .75rem; color: rgba(0, 0, 0, .54); }
		.rc-manage__picker { max-height: 15rem; overflow-y: auto; margin: 0; padding: 0; list-style: none; border: 1px solid #ddd; border-radius: 2px; }
		.rc-manage__picker li + li { border-top: 1px solid #eee; }
		.rc-manage__picker label { display: flex; align-items: center; gap: .5rem; padding: .375rem .75rem; cursor: pointer; }
		.rc-manage__picker label:hover { background: #f6f8f9; }
		.rc-manage__picker .rc-manage__sub { margin-left: auto; }
		.rc-manage__selectall { display: flex; align-items: center; gap: .5rem; margin: 0 0 .5rem; font-size: .75rem; color: rgba(0, 0, 0, .54); cursor: pointer; }
		.rc-manage__option { display: flex; align-items: flex-start; gap: .5rem; margin: .75rem 0 0; cursor: pointer; }
		.rc-manage__hint { margin: .25rem 0 0 1.5rem; font-size: .75rem; line-height: 1rem; color: rgba(0, 0, 0, .54); }
		.rc-manage__run { display: flex; flex-wrap: wrap; align-items: center; gap: .75rem; margin-top: 1rem; }
		.rc-manage__result { font-size: .875rem; }
		.rc-manage__empty { margin: 0; font-style: italic; color: rgba(0, 0, 0, .54); }
		.rc-manage__scroll { overflow-x: auto; }
		@media (max-width: 40rem) {
			.rc-manage__stats { grid-template-columns: repeat(2, 1fr); }
			.rc-manage__stat strong { font-size: 1.5rem; line-height: 2rem; }
		}
	</style>

	<div class="rc-manage">
		<h1 class="app__pageHeading">
			{translate key="plugins.generic.reviewerCertificate.manage.menu"}
		</h1>
		<p class="rc-manage__intro">{translate key="plugins.generic.reviewerCertificate.manage.pageDescription"}</p>

		{if $certificateRevoked}
			<div class="pkp_notification">
				<div class="notifySuccess" role="status">{translate key="plugins.generic.reviewerCertificate.manage.revokedNotice"}</div>
			</div>
		{/if}
		{if $certificateRestored}
			<div class="pkp_notification">
				<div class="notifySuccess" role="status">{translate key="plugins.generic.reviewerCertificate.manage.restoredNotice"}</div>
			</div>
		{/if}

		<div class="rc-manage__tabs" role="tablist">
			<button type="button" class="rc-manage__tab" role="tab" id="rc-tab-overview" aria-controls="rc-panel-overview" data-tab="overview">{translate key="plugins.generic.reviewerCertificate.manage.tabOverview"}</button>
			<button type="button" class="rc-manage__tab" role="tab" id="rc-tab-tools" aria-controls="rc-panel-tools" data-tab="tools">{translate key="plugins.generic.reviewerCertificate.manage.tabTools"}</button>
			{if $settingsFormHtml}<button type="button" class="rc-manage__tab" role="tab" id="rc-tab-settings" aria-controls="rc-panel-settings" data-tab="settings">{translate key="plugins.generic.reviewerCertificate.manage.tabSettings"}</button>{/if}
		</div>

		<div class="rc-manage__panel" role="tabpanel" id="rc-panel-overview" aria-labelledby="rc-tab-overview">
		{* Statistics *}
		<section class="rc-manage__section" aria-labelledby="rcStatsHeading">
			<h2 id="rcStatsHeading">{translate key="plugins.generic.reviewerCertificate.statistics.title"}</h2>
			<ul class="rc-manage__stats certificate-statistics">
				<li class="rc-manage__stat"><strong>{$statistics.total|escape}</strong><span>{translate key="plugins.generic.reviewerCertificate.statistics.totalCertificates"}</span></li>
				<li class="rc-manage__stat"><strong>{$statistics.valid|escape}</strong><span>{translate key="plugins.generic.reviewerCertificate.manage.valid"}</span></li>
				<li class="rc-manage__stat {if $statistics.revoked}rc-manage__stat--revoked{else}rc-manage__stat--zero{/if}"><strong>{$statistics.revoked|escape}</strong><span>{translate key="plugins.generic.reviewerCertificate.manage.revoked"}</span></li>
				<li class="rc-manage__stat"><strong>{$statistics.downloads|escape}</strong><span>{translate key="plugins.generic.reviewerCertificate.statistics.totalDownloads"}</span></li>
				<li class="rc-manage__stat"><strong>{$statistics.reviewers|escape}</strong><span>{translate key="plugins.generic.reviewerCertificate.statistics.uniqueReviewers"}</span></li>
			</ul>
		</section>

		{* Issued certificates *}
		<section class="rc-manage__section">
			<div class="pkp_controllers_grid">
				<div class="header">
					<h4>{translate key="plugins.generic.reviewerCertificate.manage.title"}<span class="rc-manage__count">{$totalCertificates|escape}</span></h4>
					<ul class="actions">
						<li><a href="{$exportUrl|escape}" class="certificate-export-btn">{translate key="plugins.generic.reviewerCertificate.manage.exportCsv"}</a></li>
					</ul>
				</div>

				<form method="get" action="{$manageUrl|escape}" class="rc-manage__filter certificate-manage-search" role="search">
					<label for="certificateSearch" class="pkp_screen_reader">{translate key="plugins.generic.reviewerCertificate.manage.search"}</label>
					<input type="search" id="certificateSearch" name="search" value="{$search|escape}" placeholder="{translate key="plugins.generic.reviewerCertificate.manage.searchPlaceholder"}" />
					<button type="submit" class="pkp_button">{translate key="plugins.generic.reviewerCertificate.manage.search"}</button>
					{if $isFiltered}<a href="{$manageUrl|escape}" class="rc-manage__clear">{translate key="plugins.generic.reviewerCertificate.manage.clearSearch"}</a>{/if}
				</form>

				<div class="rc-manage__scroll">
				<table class="certificate-manage-table">
					<thead>
						<tr>
							<th scope="col">{translate key="plugins.generic.reviewerCertificate.myCertificates.certificateCode"}</th>
							<th scope="col">{translate key="plugins.generic.reviewerCertificate.manage.reviewer"}</th>
							<th scope="col">{translate key="plugins.generic.reviewerCertificate.myCertificates.submissionTitle"}</th>
							<th scope="col">{translate key="plugins.generic.reviewerCertificate.manage.reviewCompleted"}</th>
							<th scope="col" class="rc-num">{translate key="plugins.generic.reviewerCertificate.manage.downloads"}</th>
							<th scope="col" class="rc-manage__status">{translate key="plugins.generic.reviewerCertificate.manage.status"}</th>
							<th scope="col" class="rc-manage__actions"><span class="pkp_screen_reader">{translate key="plugins.generic.reviewerCertificate.myCertificates.actions"}</span></th>
						</tr>
					</thead>
					<tbody>
						{foreach from=$certificates item=cert}
							<tr class="gridRow{if $cert.revoked} certificate-revoked{/if}">
								<td>
									<span class="rc-manage__code">{$cert.certificateCode|escape}</span>
									<span class="rc-manage__sub">{$cert.dateIssued|escape}</span>
								</td>
								<td>
									{$cert.reviewerName|escape}
									<span class="rc-manage__sub">{$cert.reviewerEmail|escape}</span>
								</td>
								<td class="rc-manage__title">{$cert.submissionTitle|escape}</td>
								<td style="white-space: nowrap;">{$cert.reviewCompleted|escape}</td>
								<td class="rc-num">{$cert.downloads|escape}</td>
								<td>
									{if $cert.revoked}
										<span class="rc-manage__badge rc-manage__badge--revoked">{translate key="plugins.generic.reviewerCertificate.manage.revoked"}</span>
										<span class="rc-manage__sub">{$cert.dateRevoked|escape}{if $cert.revokeReason} · {$cert.revokeReason|escape}{/if}</span>
									{else}
										<span class="rc-manage__badge rc-manage__badge--valid">{translate key="plugins.generic.reviewerCertificate.manage.valid"}</span>
										{if $cert.notification == 'sent'}<span class="rc-manage__sub">{translate key="plugins.generic.reviewerCertificate.manage.notified"}</span>{/if}
									{/if}
								</td>
								<td class="rc-manage__actions">
									<a href="{$cert.downloadUrl|escape}" class="pkp_button">{translate key="plugins.generic.reviewerCertificate.downloadCertificate"}</a>
									<form method="post" action="{$cert.revokeUrl|escape}" class="certificate-revoke-form">
										{csrf}
										<input type="hidden" name="search" value="{$search|escape}" />
										<input type="hidden" name="page" value="{$page|escape}" />
										{if $cert.revoked}
											<input type="hidden" name="restore" value="1" />
											<button type="submit" class="pkp_button">{translate key="plugins.generic.reviewerCertificate.manage.restore"}</button>
										{else}
											<input type="hidden" name="reason" value="" />
											<button type="submit" class="pkp_button pkp_button_offset certificate-revoke-btn" data-prompt="{$rcRevokePrompt|escape}">{translate key="plugins.generic.reviewerCertificate.manage.revoke"}</button>
										{/if}
									</form>
								</td>
							</tr>
						{foreachelse}
							<tr class="empty"><td colspan="7">{translate key="plugins.generic.reviewerCertificate.manage.empty"}</td></tr>
						{/foreach}
					</tbody>
				</table>
				</div>

				{if $pageCount > 1}
					<div class="rc-manage__pages certificate-manage-pages">
						{if $prevUrl}<a href="{$prevUrl|escape}" class="pkp_button" aria-label="&larr;">&larr;</a>{/if}
						<span>{translate key="plugins.generic.reviewerCertificate.manage.pageOf" page=$page pageCount=$pageCount}</span>
						{if $nextUrl}<a href="{$nextUrl|escape}" class="pkp_button" aria-label="&rarr;">&rarr;</a>{/if}
					</div>
				{/if}
			</div>
		</section>

		</div>

		<div class="rc-manage__panel" role="tabpanel" id="rc-panel-tools" aria-labelledby="rc-tab-tools">
		{* Batch issuing and notifications *}
		<section class="rc-manage__section rc-manage__tools">
			<div class="pkp_controllers_grid rc-manage__tool" data-rc-batch="{$generateBatchUrl|escape}">
				<div class="header"><h4>{translate key="plugins.generic.reviewerCertificate.batch.title"}</h4></div>
				<div class="rc-manage__body">
					<p>{translate key="plugins.generic.reviewerCertificate.batch.description"}</p>
					{if $eligibleReviewers}
						<label class="rc-manage__selectall"><input type="checkbox" class="rc-manage__all" /> {translate key="common.selectAll"}</label>
						<ul class="rc-manage__picker" id="batchReviewers">
							{foreach from=$eligibleReviewers item=reviewer}
								<li><label>
									<input type="checkbox" name="reviewerIds[]" value="{$reviewer.id|escape}" />
									<span>{$reviewer.name|escape}</span>
									<span class="rc-manage__sub">{$reviewer.completedReviews|escape} {translate key="plugins.generic.reviewerCertificate.batch.completedReviews"}</span>
								</label></li>
							{/foreach}
						</ul>
						<div class="rc-manage__run">
							<button type="button" id="generateBatchBtn" class="pkp_button pkp_button_primary rc-manage__go">{translate key="plugins.generic.reviewerCertificate.batch.generate"}</button>
							<span class="rc-manage__progress" hidden><span class="pkp_spinner"></span> {translate key="plugins.generic.reviewerCertificate.batch.generating"}</span>
							<span class="rc-manage__result" id="batchResult" role="status"></span>
						</div>
					{else}
						<p class="rc-manage__empty">{translate key="plugins.generic.reviewerCertificate.batch.noEligibleReviewers"}</p>
					{/if}
				</div>
			</div>

			<div class="pkp_controllers_grid rc-manage__tool" data-rc-batch="{$notifyBatchUrl|escape}" data-rc-notify="1">
				<div class="header"><h4>{translate key="plugins.generic.reviewerCertificate.notifications.title"}</h4></div>
				<div class="rc-manage__body">
					<p>{translate key="plugins.generic.reviewerCertificate.notifications.description"}</p>
					{if $notificationReviewers}
						<label class="rc-manage__selectall"><input type="checkbox" class="rc-manage__all" /> {translate key="common.selectAll"}</label>
						<ul class="rc-manage__picker" id="notificationReviewers">
							{foreach from=$notificationReviewers item=reviewer}
								<li><label>
									<input type="checkbox" name="reviewerIds[]" value="{$reviewer.id|escape}" />
									<span>{$reviewer.name|escape}</span>
								</label></li>
							{/foreach}
						</ul>
						<label class="rc-manage__option"><input type="checkbox" class="rc-manage__retry" id="retryNotifications" /> <span>{translate key="plugins.generic.reviewerCertificate.notifications.retry"}</span></label>
						<p class="rc-manage__hint">{translate key="plugins.generic.reviewerCertificate.notifications.retryWarning"}</p>
						<div class="rc-manage__run">
							<button type="button" id="notifyBatchBtn" class="pkp_button rc-manage__go">{translate key="plugins.generic.reviewerCertificate.notifications.send"}</button>
							<span class="rc-manage__progress" hidden><span class="pkp_spinner"></span></span>
							<span class="rc-manage__result" id="notificationResult" role="status"></span>
						</div>
					{else}
						<p class="rc-manage__empty">{translate key="plugins.generic.reviewerCertificate.batch.noEligibleReviewers"}</p>
					{/if}
				</div>
			</div>
			<input type="hidden" id="rcCsrfToken" value="{csrf type="raw"}" />
		</section>
		</div>

		{if $settingsFormHtml}
			<div class="rc-manage__panel rc-manage__panel--settings" role="tabpanel" id="rc-panel-settings" aria-labelledby="rc-tab-settings">
				<div class="rc-manage-settings">{$settingsFormHtml}</div>
			</div>
		{/if}
	</div>

	<script>
		(function () {ldelim}
			var text = {ldelim}
				noSelection: '{translate key="plugins.generic.reviewerCertificate.batch.noSelection" escape="js"}',
				error: '{translate key="plugins.generic.reviewerCertificate.batch.error" escape="js"}',
				generated: '{translate key="plugins.generic.reviewerCertificate.batch.generatedCountLabel" escape="js"}',
				skipped: '{translate key="plugins.generic.reviewerCertificate.batch.skipped" escape="js"}',
				failed: '{translate key="plugins.generic.reviewerCertificate.batch.failed" escape="js"}',
				sent: '{translate key="plugins.generic.reviewerCertificate.notifications.sent" escape="js"}'
			{rdelim};
			{literal}
			var tabs = document.querySelectorAll('.rc-manage__tab');
			var showTab = function (name, focus) {
				var found = false;
				tabs.forEach(function (tab) { if (tab.getAttribute('data-tab') === name) { found = true; } });
				if (!found) { name = 'overview'; }
				tabs.forEach(function (tab) {
					var on = tab.getAttribute('data-tab') === name;
					tab.setAttribute('aria-selected', on ? 'true' : 'false');
					tab.tabIndex = on ? 0 : -1;
					document.getElementById(tab.getAttribute('aria-controls')).hidden = !on;
					if (on && focus) { tab.focus(); }
				});
			};
			tabs.forEach(function (tab, index) {
				tab.addEventListener('click', function () {
					showTab(tab.getAttribute('data-tab'));
					if (window.history && history.replaceState) { history.replaceState(null, '', '#' + tab.getAttribute('data-tab')); }
				});
				tab.addEventListener('keydown', function (event) {
					var step = event.key === 'ArrowRight' ? 1 : event.key === 'ArrowLeft' ? -1 : 0;
					if (!step) { return; }
					var next = tabs[(index + step + tabs.length) % tabs.length];
					showTab(next.getAttribute('data-tab'), true);
				});
			});
			showTab((window.location.hash || '').replace('#', ''));

			document.querySelectorAll('.certificate-revoke-btn').forEach(function (button) {
				button.addEventListener('click', function (event) {
					var reason = window.prompt(button.getAttribute('data-prompt'));
					if (reason === null) { event.preventDefault(); return; }
					button.form.querySelector('input[name=reason]').value = reason;
				});
			});

			document.querySelectorAll('.rc-manage__tool').forEach(function (tool) {
				var all = tool.querySelector('.rc-manage__all');
				var boxes = tool.querySelectorAll('.rc-manage__picker input[type=checkbox]');
				var button = tool.querySelector('.rc-manage__go');
				if (!button) { return; }
				all.addEventListener('change', function () {
					boxes.forEach(function (box) { box.checked = all.checked; });
				});
				button.addEventListener('click', function () {
					var notify = tool.hasAttribute('data-rc-notify');
					var ids = Array.prototype.filter.call(boxes, function (box) { return box.checked; })
						.map(function (box) { return box.value; });
					var result = tool.querySelector('.rc-manage__result');
					var progress = tool.querySelector('.rc-manage__progress');
					if (!ids.length) { window.alert(text.noSelection); return; }
					var totals = {generated: 0, skipped: 0, failed: 0, sent: 0};
					button.disabled = true;
					progress.hidden = false;
					result.textContent = '';
					var finish = function () { button.disabled = false; progress.hidden = true; };
					var page = function (cursor) {
						var body = new URLSearchParams();
						ids.forEach(function (id) { body.append('reviewerIds[]', id); });
						body.append('cursor', cursor);
						body.append('retry', notify && tool.querySelector('.rc-manage__retry').checked ? '1' : '0');
						body.append('csrfToken', document.getElementById('rcCsrfToken').value);
						fetch(tool.getAttribute('data-rc-batch'), {
							method: 'POST', credentials: 'same-origin', body: body,
							headers: {'X-Requested-With': 'XMLHttpRequest'}
						}).then(function (response) { return response.json(); }).then(function (json) {
							var r = json && json.content;
							if (!r || typeof r.generated !== 'number') { throw new Error('bad response'); }
							totals.generated += r.generated;
							totals.skipped += r.skipped;
							totals.failed += r.failed;
							totals.sent += r.sent || 0;
							result.textContent = text.generated + ': ' + totals.generated
								+ ' · ' + text.skipped + ': ' + totals.skipped
								+ ' · ' + text.failed + ': ' + totals.failed
								+ (notify ? ' · ' + text.sent + ': ' + totals.sent : '');
							if (r.continuation !== null && r.continuation !== undefined) { page(r.continuation); }
							else { finish(); }
						}).catch(function () {
							result.textContent = (result.textContent ? result.textContent + ' ' : '') + text.error;
							finish();
						});
					};
					page(0);
				});
			});
			{/literal}
		{rdelim})();
	</script>
{/block}
