{**
 * plugins/generic/reviewerCertificate/templates/manageCertificates.tpl
 *
 * Copyright (c) 2026 Panorama Scholarly Group Ltd. <contact@panorama-sg.com>
 * Distributed under the GNU GPL v3.
 *
 * Certificate Management page, reached from the backend side menu below
 * Statistics. Tabs: overview (statistics, latest certificates), issued
 * certificates (search, status filter, multi-select with "select all
 * matching" and batch download / CSV / revoke / restore), batch issuing
 * and email notifications, and the certificate settings.
 *
 * Own design (css/manageCertificates.css, all rules scoped to .rc-manage)
 * in OJS's backend palette, the same look as the certificate settings form
 * shown in the third tab. Works inside the OJS 3.3, 3.4 and 3.5 backend.
 *}
{extends file="layouts/backend.tpl"}

{block name="page"}
	{capture assign=rcTextNoSelection}{translate key="plugins.generic.reviewerCertificate.batch.noSelection"}{/capture}
	{capture assign=rcTextError}{translate key="plugins.generic.reviewerCertificate.batch.error"}{/capture}
	{capture assign=rcTextGenerated}{translate key="plugins.generic.reviewerCertificate.batch.generatedCountLabel"}{/capture}
	{capture assign=rcTextSkipped}{translate key="plugins.generic.reviewerCertificate.batch.skipped"}{/capture}
	{capture assign=rcTextFailed}{translate key="plugins.generic.reviewerCertificate.batch.failed"}{/capture}
	{capture assign=rcTextSent}{translate key="plugins.generic.reviewerCertificate.notifications.sent"}{/capture}
	{capture assign=rcRevokePrompt}{translate key="plugins.generic.reviewerCertificate.manage.revokePrompt"}{/capture}


	{* v-pre: OJS renders this block inside its Vue app. Without it Vue would
	   compile the page as a template and evaluate any {{ }} in reviewer
	   names or titles. Styles and scripts are loaded as backend files. *}
	<div class="rc-manage" v-pre
		data-csrf="{csrf type="raw"}"
		data-settings-url="{$settingsUrl|escape}"
		data-text-no-selection="{$rcTextNoSelection|escape}"
		data-text-error="{$rcTextError|escape}"
		data-text-generated="{$rcTextGenerated|escape}"
		data-text-skipped="{$rcTextSkipped|escape}"
		data-text-failed="{$rcTextFailed|escape}"
		data-text-sent="{$rcTextSent|escape}">
		<header class="rc-manage__header">
			<h1 class="app__pageHeading">{translate key="plugins.generic.reviewerCertificate.manage.menu"}</h1>
			<p class="rc-manage__intro">{translate key="plugins.generic.reviewerCertificate.manage.pageDescription"}</p>
		</header>

		{if $certificateRevoked}
			<div class="rc-alert rc-alert--ok" role="status">{translate key="plugins.generic.reviewerCertificate.manage.revokedNotice"}</div>
		{/if}
		{if $certificateRestored}
			<div class="rc-alert rc-alert--ok" role="status">{translate key="plugins.generic.reviewerCertificate.manage.restoredNotice"}</div>
		{/if}

		{if $bulkRevoked}
			<div class="rc-alert rc-alert--ok" role="status">{translate key="plugins.generic.reviewerCertificate.manage.bulkRevokedNotice" number=$bulkRevoked}</div>
		{/if}
		{if $bulkRestored}
			<div class="rc-alert rc-alert--ok" role="status">{translate key="plugins.generic.reviewerCertificate.manage.bulkRestoredNotice" number=$bulkRestored}</div>
		{/if}
		{if $bulkError == 'empty'}
			<div class="rc-alert rc-alert--bad" role="alert">{translate key="plugins.generic.reviewerCertificate.manage.bulkEmpty"}</div>
		{elseif $bulkError == 'tooMany'}
			<div class="rc-alert rc-alert--bad" role="alert">{translate key="plugins.generic.reviewerCertificate.manage.bulkTooMany" limit=$bulkZipLimit}</div>
		{elseif $bulkError == 'noZip'}
			<div class="rc-alert rc-alert--bad" role="alert">{translate key="plugins.generic.reviewerCertificate.manage.bulkNoZip"}</div>
		{elseif $bulkError == 'failed'}
			<div class="rc-alert rc-alert--bad" role="alert">{translate key="plugins.generic.reviewerCertificate.manage.bulkFailed"}</div>
		{/if}

		<div class="rc-manage__tabs" role="tablist">
			<button type="button" class="rc-manage__tab" role="tab" id="rc-tab-overview" aria-controls="rc-panel-overview" data-tab="overview">{translate key="plugins.generic.reviewerCertificate.manage.tabOverview"}</button>
			<button type="button" class="rc-manage__tab" role="tab" id="rc-tab-certificates" aria-controls="rc-panel-certificates" data-tab="certificates">{translate key="plugins.generic.reviewerCertificate.manage.title"}</button>
			<button type="button" class="rc-manage__tab" role="tab" id="rc-tab-tools" aria-controls="rc-panel-tools" data-tab="tools">{translate key="plugins.generic.reviewerCertificate.manage.tabTools"}</button>
			{if $settingsUrl}<button type="button" class="rc-manage__tab" role="tab" id="rc-tab-settings" aria-controls="rc-panel-settings" data-tab="settings">{translate key="plugins.generic.reviewerCertificate.manage.tabSettings"}</button>{/if}
		</div>

		<div class="rc-manage__panel" role="tabpanel" id="rc-panel-overview" aria-labelledby="rc-tab-overview">
			{* Statistics: one strip of equal cells *}
			<section class="rc-box rc-stats certificate-statistics" aria-label="{translate key="plugins.generic.reviewerCertificate.statistics.title"}">
				<div class="rc-stat"><span class="rc-stat__label">{translate key="plugins.generic.reviewerCertificate.statistics.totalCertificates"}</span><strong class="rc-stat__value">{$statistics.total|escape}</strong></div>
				<div class="rc-stat"><span class="rc-stat__label">{translate key="plugins.generic.reviewerCertificate.manage.valid"}</span><strong class="rc-stat__value rc-stat__value--ok">{$statistics.valid|escape}</strong></div>
				<div class="rc-stat"><span class="rc-stat__label">{translate key="plugins.generic.reviewerCertificate.manage.revoked"}</span><strong class="rc-stat__value{if $statistics.revoked} rc-stat__value--bad{else} rc-stat__value--muted{/if}">{$statistics.revoked|escape}</strong></div>
				<div class="rc-stat"><span class="rc-stat__label">{translate key="plugins.generic.reviewerCertificate.statistics.totalDownloads"}</span><strong class="rc-stat__value">{$statistics.downloads|escape}</strong></div>
				<div class="rc-stat"><span class="rc-stat__label">{translate key="plugins.generic.reviewerCertificate.statistics.uniqueReviewers"}</span><strong class="rc-stat__value">{$statistics.reviewers|escape}</strong></div>
			</section>

			{* The latest certificates; the full list has its own tab *}
			<section class="rc-box rc-recent">
				<div class="rc-box__head">
					<h2 class="rc-box__title">{translate key="plugins.generic.reviewerCertificate.manage.recent"}</h2>
					<a href="{$allCertificatesUrl|escape}" class="rc-link rc-manage__goto" data-tab-link="certificates">{translate key="plugins.generic.reviewerCertificate.manage.viewAll"} &rarr;</a>
				</div>
				{if $recentCertificates}
					<ul class="rc-list">
						{foreach from=$recentCertificates item=cert}
							<li class="rc-list__item{if $cert.revoked} is-revoked{/if}">
								<span class="rc-list__main">
									<span class="rc-name">{$cert.reviewerName|escape}</span>
									<span class="rc-sub rc-ellipsis" title="{$cert.submissionTitle|escape}">{$cert.submissionTitle|escape}</span>
								</span>
								<span class="rc-list__date">{$cert.dateIssued|escape}</span>
								{if $cert.revoked}<span class="rc-badge rc-badge--bad">{translate key="plugins.generic.reviewerCertificate.manage.revoked"}</span>{else}<span class="rc-badge rc-badge--ok">{translate key="plugins.generic.reviewerCertificate.manage.valid"}</span>{/if}
							</li>
						{/foreach}
					</ul>
				{else}
					<p class="rc-empty">{translate key="plugins.generic.reviewerCertificate.manage.empty"}</p>
				{/if}
			</section>
		</div>

		<div class="rc-manage__panel" role="tabpanel" id="rc-panel-certificates" aria-labelledby="rc-tab-certificates">
			{* Issued certificates with multi-select. Ticking boxes selects
			   rows of this page; "select all matching" switches the batch
			   form to every certificate that matches the search and status
			   filter, across all pages (scope=all). *}
			<section class="rc-box rc-certs" data-total="{$totalCertificates|escape}"
				data-text-selected="{translate key="plugins.generic.reviewerCertificate.manage.selected" selected="%n%"}"
				data-text-page-selected="{translate key="plugins.generic.reviewerCertificate.manage.pageSelected" selected="%n%"}"
				data-text-revoke-prompt="{translate key="plugins.generic.reviewerCertificate.manage.bulkRevokePrompt" selected="%n%"}"
				data-text-restore-confirm="{translate key="plugins.generic.reviewerCertificate.manage.bulkRestoreConfirm" selected="%n%"}">
				<div class="rc-box__head">
					<h2 class="rc-box__title">{translate key="plugins.generic.reviewerCertificate.manage.title"} <span class="rc-count">{$totalCertificates|escape}</span></h2>
					<a href="{$exportUrl|escape}" class="rc-btn certificate-export-btn">{translate key="plugins.generic.reviewerCertificate.manage.exportCsv"}</a>
				</div>

				<form method="get" action="{$manageUrl|escape}" class="rc-toolbar certificate-manage-search" role="search">
					<label for="certificateSearch" class="pkp_screen_reader">{translate key="plugins.generic.reviewerCertificate.manage.search"}</label>
					<input type="search" id="certificateSearch" class="rc-search" name="search" value="{$search|escape}" placeholder="{translate key="plugins.generic.reviewerCertificate.manage.searchPlaceholder"}" />
					<label for="certificateStatus" class="pkp_screen_reader">{translate key="plugins.generic.reviewerCertificate.manage.status"}</label>
					<select id="certificateStatus" name="status" class="rc-select">
						<option value="">{translate key="plugins.generic.reviewerCertificate.manage.allStatuses"}</option>
						<option value="valid"{if $status == 'valid'} selected{/if}>{translate key="plugins.generic.reviewerCertificate.manage.valid"}</option>
						<option value="revoked"{if $status == 'revoked'} selected{/if}>{translate key="plugins.generic.reviewerCertificate.manage.revoked"}</option>
					</select>
					<button type="submit" class="rc-btn">{translate key="plugins.generic.reviewerCertificate.manage.search"}</button>
					{if $isFiltered}<a href="{$manageUrl|escape}" class="rc-link">{translate key="plugins.generic.reviewerCertificate.manage.clearSearch"}</a>{/if}
				</form>

				{* Batch bar: shown once something is ticked *}
				<form method="post" action="{$bulkUrl|escape}" id="rc-bulk-form" class="rc-bulk certificate-bulk" hidden aria-label="{translate key="plugins.generic.reviewerCertificate.manage.bulkActions"}">
					{csrf}
					<input type="hidden" name="bulkAction" value="" />
					<input type="hidden" name="scope" value="selected" />
					<input type="hidden" name="reason" value="" />
					<input type="hidden" name="search" value="{$search|escape}" />
					<input type="hidden" name="status" value="{$status|escape}" />
					<input type="hidden" name="page" value="{$page|escape}" />
					<div class="rc-bulk__bar">
						<strong class="rc-bulk__count" aria-live="polite"></strong>
						<div class="rc-bulk__actions">
							<button type="submit" class="rc-btn rc-btn--sm rc-btn--primary" data-bulk="download">{translate key="plugins.generic.reviewerCertificate.manage.bulkDownload"}</button>
							<button type="submit" class="rc-btn rc-btn--sm" data-bulk="export">{translate key="plugins.generic.reviewerCertificate.manage.exportCsv"}</button>
							<button type="submit" class="rc-btn rc-btn--sm rc-btn--danger" data-bulk="revoke">{translate key="plugins.generic.reviewerCertificate.manage.revoke"}</button>
							<button type="submit" class="rc-btn rc-btn--sm rc-btn--quiet" data-bulk="restore">{translate key="plugins.generic.reviewerCertificate.manage.restore"}</button>
							<button type="button" class="rc-link rc-bulk__clear">{translate key="plugins.generic.reviewerCertificate.manage.clearSelection"}</button>
						</div>
					</div>
					{if $pageCount > 1}
						<div class="rc-bulk__scope" hidden>
							<span class="rc-bulk__page-note"></span>
							<button type="button" class="rc-link rc-bulk__all">{translate key="plugins.generic.reviewerCertificate.manage.selectAllMatching" total=$totalCertificates}</button>
						</div>
						<div class="rc-bulk__scope rc-bulk__scope--all" hidden>
							<span>{translate key="plugins.generic.reviewerCertificate.manage.allSelected" total=$totalCertificates}</span>
							<button type="button" class="rc-link rc-bulk__clear">{translate key="plugins.generic.reviewerCertificate.manage.clearSelection"}</button>
						</div>
					{/if}
					<p class="rc-bulk__note" hidden>{translate key="plugins.generic.reviewerCertificate.manage.bulkPreparing"}</p>
				</form>

				<div class="rc-table-wrap">
				<table class="rc-table rc-table--select certificate-manage-table">
					<colgroup>
						<col class="rc-col-check" /><col class="rc-col-reviewer" /><col /><col class="rc-col-date" /><col class="rc-col-num" /><col class="rc-col-status" /><col class="rc-col-actions" />
					</colgroup>
					<thead>
						<tr>
							<th scope="col" class="rc-cell-check" data-label="{translate key="plugins.generic.reviewerCertificate.manage.selectPage"}">{if $certificates}<input type="checkbox" class="rc-check rc-check--page" aria-label="{translate key="plugins.generic.reviewerCertificate.manage.selectPage"}" title="{translate key="plugins.generic.reviewerCertificate.manage.selectPage"}" />{/if}</th>
							<th scope="col">{translate key="plugins.generic.reviewerCertificate.manage.reviewer"}</th>
							<th scope="col">{translate key="plugins.generic.reviewerCertificate.myCertificates.submissionTitle"}</th>
							<th scope="col">{translate key="plugins.generic.reviewerCertificate.manage.reviewCompleted"}</th>
							<th scope="col" class="rc-num">{translate key="plugins.generic.reviewerCertificate.manage.downloads"}</th>
							<th scope="col">{translate key="plugins.generic.reviewerCertificate.manage.status"}</th>
							<th scope="col" class="rc-actions-col"><span class="pkp_screen_reader">{translate key="plugins.generic.reviewerCertificate.myCertificates.actions"}</span></th>
						</tr>
					</thead>
					<tbody>
						{foreach from=$certificates item=cert}
							<tr class="{if $cert.revoked}is-revoked certificate-revoked{/if}">
								<td class="rc-cell-check"><input type="checkbox" class="rc-check rc-check--row" form="rc-bulk-form" name="certificateIds[]" value="{$cert.certificateId|escape}" aria-label="{translate key="plugins.generic.reviewerCertificate.manage.selectRow"}: {$cert.reviewerName|escape}" /></td>
								<td class="rc-cell-reviewer">
									<span class="rc-name" title="{$cert.reviewerName|escape}">{$cert.reviewerName|escape}</span>
									<span class="rc-sub rc-ellipsis" title="{$cert.reviewerEmail|escape}">{$cert.reviewerEmail|escape}</span>
								</td>
								<td class="rc-cell-title">
									<span class="rc-title" title="{$cert.submissionTitle|escape}">{$cert.submissionTitle|escape}</span>
									<span class="rc-sub"><code class="rc-code">{$cert.certificateCode|escape}</code></span>
								</td>
								<td class="rc-cell-date" data-label="{translate key="plugins.generic.reviewerCertificate.manage.reviewCompleted"}"><span class="rc-nowrap">{$cert.reviewCompleted|escape}</span></td>
								<td class="rc-num" data-label="{translate key="plugins.generic.reviewerCertificate.manage.downloads"}">{$cert.downloads|escape}</td>
								<td class="rc-cell-status">
									{if $cert.revoked}
										<span class="rc-badge rc-badge--bad">{translate key="plugins.generic.reviewerCertificate.manage.revoked"}</span>
										<span class="rc-sub" title="{$cert.revokeReason|escape}">{$cert.dateRevoked|escape}{if $cert.revokeReason} · {$cert.revokeReason|escape}{/if}</span>
									{else}
										<span class="rc-badge rc-badge--ok">{translate key="plugins.generic.reviewerCertificate.manage.valid"}</span>
										{if $cert.notification == 'sent'}<span class="rc-sub">{translate key="plugins.generic.reviewerCertificate.manage.notified"}</span>{/if}
									{/if}
								</td>
								<td class="rc-cell-actions">
									<a href="{$cert.downloadUrl|escape}" class="rc-btn rc-btn--sm" title="{translate key="plugins.generic.reviewerCertificate.downloadCertificate"}">{translate key="plugins.generic.reviewerCertificate.manage.download"}</a>
									<form method="post" action="{$cert.revokeUrl|escape}" class="certificate-revoke-form">
										{csrf}
										<input type="hidden" name="search" value="{$search|escape}" />
										<input type="hidden" name="status" value="{$status|escape}" />
										<input type="hidden" name="page" value="{$page|escape}" />
										{if $cert.revoked}
											<input type="hidden" name="restore" value="1" />
											<button type="submit" class="rc-btn rc-btn--sm rc-btn--quiet">{translate key="plugins.generic.reviewerCertificate.manage.restore"}</button>
										{else}
											<input type="hidden" name="reason" value="" />
											<button type="submit" class="rc-btn rc-btn--sm rc-btn--danger certificate-revoke-btn" data-prompt="{$rcRevokePrompt|escape}">{translate key="plugins.generic.reviewerCertificate.manage.revoke"}</button>
										{/if}
									</form>
								</td>
							</tr>
						{foreachelse}
							<tr class="rc-empty-row"><td colspan="7"><p class="rc-empty">{translate key="plugins.generic.reviewerCertificate.manage.empty"}</p></td></tr>
						{/foreach}
					</tbody>
				</table>
				</div>

				{if $pageCount > 1}
					<div class="rc-pager certificate-manage-pages">
						<span>{translate key="plugins.generic.reviewerCertificate.manage.pageOf" page=$page pageCount=$pageCount}</span>
						{if $prevUrl}<a href="{$prevUrl|escape}" class="rc-btn rc-btn--sm" aria-label="&larr;">&larr;</a>{else}<span class="rc-btn rc-btn--sm is-disabled" aria-hidden="true">&larr;</span>{/if}
						{if $nextUrl}<a href="{$nextUrl|escape}" class="rc-btn rc-btn--sm" aria-label="&rarr;">&rarr;</a>{else}<span class="rc-btn rc-btn--sm is-disabled" aria-hidden="true">&rarr;</span>{/if}
					</div>
				{/if}
			</section>
		</div>

		<div class="rc-manage__panel" role="tabpanel" id="rc-panel-tools" aria-labelledby="rc-tab-tools">
			<div class="rc-tools">
				{* Batch issuing *}
				<section class="rc-box rc-manage__tool" data-rc-batch="{$generateBatchUrl|escape}">
					<div class="rc-box__head rc-box__head--stack">
						<h2 class="rc-box__title">{translate key="plugins.generic.reviewerCertificate.batch.title"}</h2>
						<p class="rc-box__desc">{translate key="plugins.generic.reviewerCertificate.batch.description"}</p>
					</div>
					<div class="rc-box__body">
						{if $eligibleReviewers}
							<div class="rc-picker">
								<label class="rc-picker__all"><input type="checkbox" class="rc-manage__all" /> <span>{translate key="common.selectAll"}</span></label>
								<ul class="rc-manage__picker" id="batchReviewers">
									{foreach from=$eligibleReviewers item=reviewer}
										<li><label>
											<input type="checkbox" name="reviewerIds[]" value="{$reviewer.id|escape}" />
											<span class="rc-picker__name">{$reviewer.name|escape}</span>
											<span class="rc-picker__meta">{$reviewer.completedReviews|escape} {translate key="plugins.generic.reviewerCertificate.batch.completedReviews"}</span>
										</label></li>
									{/foreach}
								</ul>
							</div>
						{else}
							<p class="rc-empty rc-manage__empty">{translate key="plugins.generic.reviewerCertificate.batch.noEligibleReviewers"}</p>
						{/if}
					</div>
					{if $eligibleReviewers}
						<div class="rc-box__foot rc-manage__run">
							<button type="button" id="generateBatchBtn" class="rc-btn rc-btn--primary rc-manage__go">{translate key="plugins.generic.reviewerCertificate.batch.generate"}</button>
							<span class="rc-manage__progress" hidden><span class="pkp_spinner"></span> {translate key="plugins.generic.reviewerCertificate.batch.generating"}</span>
							<span class="rc-manage__result" id="batchResult" role="status"></span>
						</div>
					{/if}
				</section>

				{* Notifications *}
				<section class="rc-box rc-manage__tool" data-rc-batch="{$notifyBatchUrl|escape}" data-rc-notify="1">
					<div class="rc-box__head rc-box__head--stack">
						<h2 class="rc-box__title">{translate key="plugins.generic.reviewerCertificate.notifications.title"}</h2>
						<p class="rc-box__desc">{translate key="plugins.generic.reviewerCertificate.notifications.description"}</p>
					</div>
					<div class="rc-box__body">
						{if $notificationReviewers}
							<div class="rc-picker">
								<label class="rc-picker__all"><input type="checkbox" class="rc-manage__all" /> <span>{translate key="common.selectAll"}</span></label>
								<ul class="rc-manage__picker" id="notificationReviewers">
									{foreach from=$notificationReviewers item=reviewer}
										<li><label>
											<input type="checkbox" name="reviewerIds[]" value="{$reviewer.id|escape}" />
											<span class="rc-picker__name">{$reviewer.name|escape}</span>
										</label></li>
									{/foreach}
								</ul>
							</div>
							<label class="rc-option"><input type="checkbox" class="rc-manage__retry" id="retryNotifications" /> <span><span class="rc-option__label">{translate key="plugins.generic.reviewerCertificate.notifications.retry"}</span><span class="rc-sub">{translate key="plugins.generic.reviewerCertificate.notifications.retryWarning"}</span></span></label>
						{else}
							<p class="rc-empty rc-manage__empty">{translate key="plugins.generic.reviewerCertificate.batch.noEligibleReviewers"}</p>
						{/if}
					</div>
					{if $notificationReviewers}
						<div class="rc-box__foot rc-manage__run">
							<button type="button" id="notifyBatchBtn" class="rc-btn rc-btn--primary rc-manage__go">{translate key="plugins.generic.reviewerCertificate.notifications.send"}</button>
							<span class="rc-manage__progress" hidden><span class="pkp_spinner"></span></span>
							<span class="rc-manage__result" id="notificationResult" role="status"></span>
						</div>
					{/if}
				</section>
			</div>
		</div>

		{if $settingsUrl}
			<div class="rc-manage__panel rc-manage__panel--settings" role="tabpanel" id="rc-panel-settings" aria-labelledby="rc-tab-settings">
				{* Loaded from the plugin's settings route after the page is ready,
				   like the plugin settings dialog, so its own scripts run. *}
				<div class="rc-manage-settings" aria-busy="true"><span class="pkp_spinner"></span></div>
			</div>
		{/if}
	</div>

{/block}
