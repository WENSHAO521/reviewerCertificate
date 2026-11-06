{**
 * plugins/generic/reviewerCertificate/templates/reviewerDashboard.tpl
 *
 * Copyright (c) 2024
 * Modifications copyright (c) 2026 Panorama Scholarly Group Ltd. <contact@panorama-sg.com>
 * Distributed under the GNU GPL v3.
 *
 * Certificate download button for reviewer dashboard
 *}

{if $showCertificateButton && $certificateUrl}
	{* Backend page: certificate.css is not loaded here, so the styles are inline *}
	<div class="reviewer-certificate-section" style="margin: 20px 0; padding: 16px 20px; background: #fff; border: 1px solid #dde3ea; border-left: 4px solid #006798; border-radius: 8px; box-shadow: 0 1px 2px rgba(16,24,40,.04); text-align: left;">
		<h3 style="margin: 0 0 4px; font-size: 1rem; font-weight: 700; color: #1f2933;">
			<span class="fa fa-certificate" style="margin-right: 8px; color: #006798;" aria-hidden="true"></span>
			{translate key="plugins.generic.reviewerCertificate.certificateAvailable"}
		</h3>
		<p style="margin: 0 0 12px; color: #5f6b7a; font-size: .875rem;">
			{translate key="plugins.generic.reviewerCertificate.certificateAvailableDescription"}
		</p>
		<div style="display: flex; flex-wrap: wrap; align-items: center; gap: 8px 16px;">
			<a href="{$certificateUrl|escape}" class="certificate-download-button" target="_blank" rel="noopener" style="display: inline-flex; align-items: center; gap: 6px; height: 36px; padding: 0 16px; background: #006798; color: #fff; font-weight: 600; text-decoration: none; border-radius: 6px; box-shadow: none;">
				<span class="fa fa-download" aria-hidden="true"></span>
				{translate key="plugins.generic.reviewerCertificate.downloadCertificate"}
			</a>
			<a href="{url page="certificate" op="myCertificates"}" style="color: #006798; font-weight: 600; text-decoration: none;">
				{translate key="plugins.generic.reviewerCertificate.myCertificates.viewAll"} &rarr;
			</a>
		</div>
		{if !$certificateExists}
			<p class="description" style="margin: 10px 0 0; font-size: .8125rem; color: #5f6b7a;">
				{translate key="plugins.generic.reviewerCertificate.certificateWillBeGenerated"}
			</p>
		{/if}
	</div>
{/if}
