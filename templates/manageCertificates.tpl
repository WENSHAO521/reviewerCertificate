{**
 * plugins/generic/reviewerCertificate/templates/manageCertificates.tpl
 *
 * Copyright (c) 2026 Panorama Scholarly Group Ltd. <contact@panorama-sg.com>
 * Distributed under the GNU GPL v3.
 *
 * Manager overview of issued certificates: search, CSV export, download,
 * revoke and restore. Styled only with OJS classes present in 3.3–3.5.
 *}
{extends file="layouts/backend.tpl"}

{block name="page"}
	{capture assign=rcRevokePrompt}{translate key="plugins.generic.reviewerCertificate.manage.revokePrompt"}{/capture}
	<h1 class="app__pageHeading">
		{translate key="plugins.generic.reviewerCertificate.manage.title"}
	</h1>

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

	<p>{translate key="plugins.generic.reviewerCertificate.manage.description" count=$totalCertificates}</p>

	<form method="get" action="{$manageUrl|escape}" class="certificate-manage-search" style="margin: 1em 0;">
		<label for="certificateSearch" class="pkp_screen_reader">{translate key="plugins.generic.reviewerCertificate.manage.search"}</label>
		<input type="search" id="certificateSearch" name="search" value="{$search|escape}" placeholder="{translate key="plugins.generic.reviewerCertificate.manage.searchPlaceholder"}" style="min-width: 20em;" />
		<button type="submit" class="pkp_button">{translate key="plugins.generic.reviewerCertificate.manage.search"}</button>
		<a href="{$exportUrl|escape}" class="pkp_button certificate-export-btn">{translate key="plugins.generic.reviewerCertificate.manage.exportCsv"}</a>
	</form>

	<div class="pkp_controllers_grid">
		<table class="certificate-manage-table">
			<thead>
				<tr>
					<th scope="col" style="text-align: left;">{translate key="plugins.generic.reviewerCertificate.myCertificates.certificateCode"}</th>
					<th scope="col" style="text-align: left;">{translate key="plugins.generic.reviewerCertificate.manage.reviewer"}</th>
					<th scope="col" style="text-align: left;">{translate key="plugins.generic.reviewerCertificate.myCertificates.submissionTitle"}</th>
					<th scope="col" style="text-align: left;">{translate key="plugins.generic.reviewerCertificate.manage.reviewCompleted"}</th>
					<th scope="col" style="text-align: left;">{translate key="plugins.generic.reviewerCertificate.manage.downloads"}</th>
					<th scope="col" style="text-align: left;">{translate key="plugins.generic.reviewerCertificate.manage.status"}</th>
					<th scope="col" style="text-align: left;">{translate key="plugins.generic.reviewerCertificate.myCertificates.actions"}</th>
				</tr>
			</thead>
			<tbody>
				{foreach from=$certificates item=cert}
					<tr class="gridRow{if $cert.revoked} certificate-revoked{/if}">
						<td style="white-space: nowrap;">{$cert.certificateCode|escape}</td>
						<td>{$cert.reviewerName|escape}<br /><small>{$cert.reviewerEmail|escape}</small></td>
						<td>{$cert.submissionTitle|escape}</td>
						<td style="white-space: nowrap;">{$cert.reviewCompleted|escape}</td>
						<td>{$cert.downloads|escape}</td>
						<td>
							{if $cert.revoked}
								<strong>{translate key="plugins.generic.reviewerCertificate.manage.revoked"}</strong>
								<br /><small>{$cert.dateRevoked|escape}{if $cert.revokeReason} · {$cert.revokeReason|escape}{/if}</small>
							{else}
								{translate key="plugins.generic.reviewerCertificate.manage.valid"}
								{if $cert.notification == 'sent'}<br /><small>{translate key="plugins.generic.reviewerCertificate.manage.notified"}</small>{/if}
							{/if}
						</td>
						<td style="white-space: nowrap;">
							<a href="{$cert.downloadUrl|escape}" class="pkp_button">{translate key="plugins.generic.reviewerCertificate.downloadCertificate"}</a>
							<form method="post" action="{$cert.revokeUrl|escape}" style="display: inline;" class="certificate-revoke-form">
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
		<p class="certificate-manage-pages">
			{if $prevUrl}<a href="{$prevUrl|escape}" class="pkp_button">&larr;</a>{/if}
			{translate key="plugins.generic.reviewerCertificate.manage.pageOf" page=$page pageCount=$pageCount}
			{if $nextUrl}<a href="{$nextUrl|escape}" class="pkp_button">&rarr;</a>{/if}
		</p>
	{/if}

	{literal}
	<script>
		document.querySelectorAll('.certificate-revoke-btn').forEach(function (button) {
			button.addEventListener('click', function (event) {
				var reason = window.prompt(button.getAttribute('data-prompt'));
				if (reason === null) { event.preventDefault(); return; }
				button.form.querySelector('input[name=reason]').value = reason;
			});
		});
	</script>
	{/literal}
{/block}
