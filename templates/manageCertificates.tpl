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
			{if $settingsUrl}<button type="button" class="rc-manage__tab" role="tab" id="rc-tab-settings" aria-controls="rc-panel-settings" data-tab="settings">{translate key="plugins.generic.reviewerCertificate.manage.tabSettings"}</button>{/if}
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
		</section>
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
