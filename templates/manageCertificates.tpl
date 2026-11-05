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

		<div class="rc-manage__tabs" role="tablist">
			<button type="button" class="rc-manage__tab" role="tab" id="rc-tab-overview" aria-controls="rc-panel-overview" data-tab="overview">{translate key="plugins.generic.reviewerCertificate.manage.tabOverview"}</button>
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

			{* Issued certificates *}
			<section class="rc-box rc-certs">
				<div class="rc-box__head">
					<h2 class="rc-box__title">{translate key="plugins.generic.reviewerCertificate.manage.title"} <span class="rc-count">{$totalCertificates|escape}</span></h2>
					<a href="{$exportUrl|escape}" class="rc-btn certificate-export-btn">{translate key="plugins.generic.reviewerCertificate.manage.exportCsv"}</a>
				</div>

				<form method="get" action="{$manageUrl|escape}" class="rc-toolbar certificate-manage-search" role="search">
					<label for="certificateSearch" class="pkp_screen_reader">{translate key="plugins.generic.reviewerCertificate.manage.search"}</label>
					<input type="search" id="certificateSearch" class="rc-search" name="search" value="{$search|escape}" placeholder="{translate key="plugins.generic.reviewerCertificate.manage.searchPlaceholder"}" />
					<button type="submit" class="rc-btn">{translate key="plugins.generic.reviewerCertificate.manage.search"}</button>
					{if $isFiltered}<a href="{$manageUrl|escape}" class="rc-link">{translate key="plugins.generic.reviewerCertificate.manage.clearSearch"}</a>{/if}
				</form>

				<div class="rc-table-wrap">
				<table class="rc-table certificate-manage-table">
					<colgroup>
						<col class="rc-col-reviewer" /><col /><col class="rc-col-date" /><col class="rc-col-num" /><col class="rc-col-status" /><col class="rc-col-actions" />
					</colgroup>
					<thead>
						<tr>
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
								<td class="rc-cell-reviewer">
									<span class="rc-name" title="{$cert.reviewerName|escape}">{$cert.reviewerName|escape}</span>
									<span class="rc-sub rc-ellipsis" title="{$cert.reviewerEmail|escape}">{$cert.reviewerEmail|escape}</span>
								</td>
								<td class="rc-cell-title">
									<span class="rc-title" title="{$cert.submissionTitle|escape}">{$cert.submissionTitle|escape}</span>
									<span class="rc-sub"><code class="rc-code">{$cert.certificateCode|escape}</code></span>
								</td>
								<td class="rc-cell-date" data-label="{translate key="plugins.generic.reviewerCertificate.manage.reviewCompleted"}">{$cert.reviewCompleted|escape}</td>
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
							<tr class="rc-empty-row"><td colspan="6"><p class="rc-empty">{translate key="plugins.generic.reviewerCertificate.manage.empty"}</p></td></tr>
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
