{**
 * plugins/generic/reviewerCertificate/templates/myCertificates.tpl
 *
 * Copyright (c) 2024
 * Modifications copyright (c) 2026 Panorama Scholarly Group Ltd. <contact@panorama-sg.com>
 * Distributed under the GNU GPL v3.
 *
 * My Certificates listing page for reviewers.
 *
 * Rendered inside the OJS backend layout (the page is reached from the
 * backend side menu) and styled only with OJS's own classes: the legacy
 * grid table, .pkp_button and .pkp_notification. These exist in OJS
 * 3.3, 3.4 and 3.5, so the page follows OJS's default look and colours
 * whatever the journal's frontend theme does. The certificate-* classes
 * carry no styles; they are hooks for the tests.
 *}
{extends file="layouts/backend.tpl"}

{block name="page"}
	<h1 class="app__pageHeading">
		{translate key="plugins.generic.reviewerCertificate.myCertificates.title"}
	</h1>

	{if $certificateEmailSent}
		<div class="pkp_notification">
			<div class="notifySuccess certificate-email-banner-success" role="status">
				{translate key="plugins.generic.reviewerCertificate.myCertificates.emailSent"}
			</div>
		</div>
	{/if}
	{if $certificateEmailError}
		<div class="pkp_notification">
			<div class="notifyError certificate-email-banner-error" role="alert">
				{translate key="plugins.generic.reviewerCertificate.myCertificates.emailError"}
			</div>
		</div>
	{/if}

	{if $certificateEmailThrottled}
		<div class="pkp_notification">
			<div class="notifyWarning certificate-email-banner-throttled" role="status">
				{translate key="plugins.generic.reviewerCertificate.myCertificates.emailThrottled"}
			</div>
		</div>
	{/if}

	<p>{translate key="plugins.generic.reviewerCertificate.myCertificates.description"}</p>

	<div class="pkp_controllers_grid">
		<table class="certificate-list-table">
			<thead>
				<tr>
					<th scope="col" style="text-align: left;">{translate key="plugins.generic.reviewerCertificate.myCertificates.dateIssued"}</th>
					<th scope="col" style="text-align: left;">{translate key="plugins.generic.reviewerCertificate.myCertificates.submissionTitle"}</th>
					<th scope="col" style="text-align: left;">{translate key="plugins.generic.reviewerCertificate.myCertificates.certificateCode"}</th>
					<th scope="col" style="text-align: left;">{translate key="plugins.generic.reviewerCertificate.myCertificates.actions"}</th>
				</tr>
			</thead>
			<tbody>
				{foreach from=$certificates item=cert}
					<tr class="gridRow">
						<td style="white-space: nowrap;">{$cert.dateIssued|escape}</td>
						<td>{$cert.submissionTitle|escape}</td>
						<td style="white-space: nowrap;">{$cert.certificateCode|escape}</td>
						<td style="white-space: nowrap;">
							{if $cert.revoked}
								<span class="certificate-revoked">{translate key="plugins.generic.reviewerCertificate.manage.revoked"}</span>
							{else}
							<a href="{$cert.downloadUrl|escape}" class="pkp_button pkp_button_primary certificate-download-btn">
								{translate key="plugins.generic.reviewerCertificate.downloadCertificate"}
							</a>
							<form class="certificate-email-form" method="post" action="{$cert.emailUrl|escape}" style="display: inline;">
								{csrf}
								<button type="submit" class="pkp_button certificate-email-btn">
									{translate key="plugins.generic.reviewerCertificate.myCertificates.emailAction"}
								</button>
							</form>
							{/if}
						</td>
					</tr>
				{foreachelse}
					<tr class="empty no-certificates">
						<td colspan="4">
							{if $certificatesPending}
								{translate key="plugins.generic.reviewerCertificate.myCertificates.notEligibleYet" minimum=$minimumReviews completed=$completedReviews}
							{else}
								{translate key="plugins.generic.reviewerCertificate.myCertificates.noCertificates"}
							{/if}
						</td>
					</tr>
				{/foreach}
			</tbody>
		</table>
	</div>
	{if $annualCertificates}
		<h2>{translate key="plugins.generic.reviewerCertificate.annual.title"}</h2>
		<p>{translate key="plugins.generic.reviewerCertificate.annual.description"}</p>
		<ul class="certificate-annual-list">
			{if $cumulativeCertificate}
				<li>
					<a href="{$cumulativeCertificate.url|escape}" class="pkp_button pkp_button_primary certificate-cumulative-btn">
						{translate key="plugins.generic.reviewerCertificate.annual.cumulative" count=$cumulativeCertificate.count}
					</a>
					<strong class="certificate-reviewer-status{if $cumulativeCertificate.status.outstanding} certificate-reviewer-outstanding{/if}">{$cumulativeCertificate.status.label|escape}</strong>
				</li>
			{/if}
			{foreach from=$annualCertificates item=annual}
				<li>
					<a href="{$annual.url|escape}" class="pkp_button certificate-annual-btn">
						{translate key="plugins.generic.reviewerCertificate.annual.download" year=$annual.year count=$annual.count}
					</a>
				</li>
			{/foreach}
		</ul>
	{/if}
{/block}
