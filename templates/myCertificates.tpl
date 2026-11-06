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
 * backend side menu) with the same design as the Certificate Management
 * page (css/manageCertificates.css, scoped to .rc-manage), so reviewers
 * and managers see one look whatever the journal's frontend theme does.
 * The certificate-* classes are hooks for the tests.
 *}
{extends file="layouts/backend.tpl"}

{block name="page"}
	{* v-pre: OJS renders this block inside its Vue app; submission titles
	   must never be compiled as Vue templates. *}
	<div class="rc-manage rc-mine" v-pre>
		<header class="rc-manage__header">
			<h1 class="app__pageHeading">{translate key="plugins.generic.reviewerCertificate.myCertificates.title"}</h1>
			<p class="rc-manage__intro">{translate key="plugins.generic.reviewerCertificate.myCertificates.description"}</p>
		</header>

		{if $certificateEmailSent}
			<div class="rc-alert rc-alert--ok certificate-email-banner-success" role="status">{translate key="plugins.generic.reviewerCertificate.myCertificates.emailSent"}</div>
		{/if}
		{if $certificateEmailError}
			<div class="rc-alert rc-alert--bad certificate-email-banner-error" role="alert">{translate key="plugins.generic.reviewerCertificate.myCertificates.emailError"}</div>
		{/if}
		{if $certificateEmailThrottled}
			<div class="rc-alert rc-alert--warn certificate-email-banner-throttled" role="status">{translate key="plugins.generic.reviewerCertificate.myCertificates.emailThrottled"}</div>
		{/if}

		{if $annualCertificates}
			<section class="rc-box rc-summary">
				<div class="rc-box__head rc-box__head--stack">
					<h2 class="rc-box__title">{translate key="plugins.generic.reviewerCertificate.myCertificates.annualHeading"}</h2>
					<p class="rc-box__desc">{translate key="plugins.generic.reviewerCertificate.annual.description"}</p>
				</div>
				{if $cumulativeCertificate}
					<div class="rc-summary__cumulative">
						<span class="rc-summary__status">
							<strong class="rc-badge {if $cumulativeCertificate.status.outstanding}rc-badge--star{else}rc-badge--ok{/if} certificate-reviewer-status{if $cumulativeCertificate.status.outstanding} certificate-reviewer-outstanding{/if}">{$cumulativeCertificate.status.label|escape}</strong>
						</span>
						<a href="{$cumulativeCertificate.url|escape}" class="rc-btn rc-btn--primary certificate-cumulative-btn">{translate key="plugins.generic.reviewerCertificate.annual.cumulative" total=$cumulativeCertificate.count}</a>
					</div>
				{/if}
				<ul class="rc-summary__years certificate-annual-list">
					{foreach from=$annualCertificates item=annual}
						<li><a href="{$annual.url|escape}" class="rc-btn certificate-annual-btn">{translate key="plugins.generic.reviewerCertificate.annual.download" year=$annual.year total=$annual.count}</a></li>
					{/foreach}
				</ul>
			</section>
		{/if}

		<section class="rc-box">
			<div class="rc-box__head">
				<h2 class="rc-box__title">{translate key="plugins.generic.reviewerCertificate.myCertificates.reviewHeading"} <span class="rc-count">{$certificates|@count}</span></h2>
			</div>
			<div class="rc-table-wrap">
			<table class="rc-table certificate-list-table">
				<thead>
					<tr>
						<th scope="col">{translate key="plugins.generic.reviewerCertificate.myCertificates.submissionTitle"}</th>
						<th scope="col">{translate key="plugins.generic.reviewerCertificate.myCertificates.dateIssued"}</th>
						<th scope="col" class="rc-actions-col"><span class="pkp_screen_reader">{translate key="plugins.generic.reviewerCertificate.myCertificates.actions"}</span></th>
					</tr>
				</thead>
				<tbody>
					{foreach from=$certificates item=cert}
						<tr class="{if $cert.revoked}is-revoked{/if}">
							<td class="rc-cell-title">
								<span class="rc-title" title="{$cert.submissionTitle|escape}">{$cert.submissionTitle|escape}</span>
								<span class="rc-sub">{translate key="plugins.generic.reviewerCertificate.myCertificates.certificateCode"} <code class="rc-code">{$cert.certificateCode|escape}</code></span>
							</td>
							<td class="rc-cell-date">{$cert.dateIssued|escape}</td>
							<td class="rc-cell-actions">
								{if $cert.revoked}
									<span class="rc-badge rc-badge--bad certificate-revoked">{translate key="plugins.generic.reviewerCertificate.manage.revoked"}</span>
								{else}
									<div class="rc-actions">
										<a href="{$cert.downloadUrl|escape}" class="rc-btn rc-btn--sm rc-btn--primary certificate-download-btn">{translate key="plugins.generic.reviewerCertificate.downloadCertificate"}</a>
										<form class="certificate-email-form" method="post" action="{$cert.emailUrl|escape}">
											{csrf}
											<button type="submit" class="rc-btn rc-btn--sm certificate-email-btn">{translate key="plugins.generic.reviewerCertificate.myCertificates.emailAction"}</button>
										</form>
									</div>
								{/if}
							</td>
						</tr>
					{foreachelse}
						<tr class="rc-empty-row empty no-certificates">
							<td colspan="3"><p class="rc-empty">
								{if $certificatesPending}
									{translate key="plugins.generic.reviewerCertificate.myCertificates.notEligibleYet" minimum=$minimumReviews completed=$completedReviews}
								{else}
									{translate key="plugins.generic.reviewerCertificate.myCertificates.noCertificates"}
								{/if}
							</p></td>
						</tr>
					{/foreach}
				</tbody>
			</table>
			</div>
		</section>
	</div>
{/block}
