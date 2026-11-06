{**
 * plugins/generic/reviewerCertificate/templates/verify.tpl
 *
 * Copyright (c) 2024
 * Modifications copyright (c) 2026 Panorama Scholarly Group Ltd. <contact@panorama-sg.com>
 * Distributed under the GNU GPL v3.
 *
 * Certificate verification page
 *}
{include file="frontend/components/header.tpl" pageTitle="plugins.generic.reviewerCertificate.verify.title"}

<div class="page page_certificate_verify">
	<div class="container rc-verify">
		<h1 class="rc-verify__title">{translate key="plugins.generic.reviewerCertificate.verify.title"}</h1>

		<div class="certificate-verify-content rc-verify__card">
			{if $certificateCode}
				{* Verification result for certificate accessed via QR code *}
				{if $isValid && $isRevoked}
					<div class="certificate-verify-result error certificate-verify-revoked rc-verify__result rc-verify__result--bad">
						<span class="rc-verify__icon" aria-hidden="true"><svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round"><path d="M7 7l10 10M17 7L7 17"/></svg></span>
						<div>
							<h2>{translate key="plugins.generic.reviewerCertificate.verify.revoked"}</h2>
							<p>{translate key="plugins.generic.reviewerCertificate.verify.revokedDescription" date=$dateRevoked}</p>
						</div>
					</div>
					<dl class="certificate-details rc-verify__details">
						<div><dt>{translate key="plugins.generic.reviewerCertificate.verify.certificateCode"}</dt><dd><code>{$certificateCode|escape}</code></dd></div>
					</dl>
				{elseif $isValid}
					<div class="certificate-verify-result success rc-verify__result rc-verify__result--ok">
						<span class="rc-verify__icon" aria-hidden="true"><svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12.5l4.5 4.5L19 7.5"/></svg></span>
						<div><h2>{translate key="plugins.generic.reviewerCertificate.verify.valid"}</h2></div>
					</div>
					<dl class="certificate-details rc-verify__details">
						<div><dt>{translate key="plugins.generic.reviewerCertificate.verify.certificateCode"}</dt><dd><code>{$certificateCode|escape}</code></dd></div>
						{if $showReviewerName}
						<div><dt>{translate key="plugins.generic.reviewerCertificate.verify.reviewerName"}</dt><dd>{$reviewerName|escape}</dd></div>
						{/if}
						<div><dt>{translate key="plugins.generic.reviewerCertificate.verify.journalName"}</dt><dd>{$journalName|escape}</dd></div>
						<div><dt>{translate key="plugins.generic.reviewerCertificate.verify.dateIssued"}</dt><dd>{$dateIssued|escape}</dd></div>
					</dl>
				{else}
					<div class="certificate-verify-result error rc-verify__result rc-verify__result--bad">
						<span class="rc-verify__icon" aria-hidden="true"><svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round"><path d="M7 7l10 10M17 7L7 17"/></svg></span>
						<div>
							<h2>{translate key="plugins.generic.reviewerCertificate.verify.invalid"}</h2>
							<p>{translate key="plugins.generic.reviewerCertificate.verify.invalidDescription"}</p>
						</div>
					</div>
				{/if}
			{else}
				{* Manual verification form *}
				{if $malformedCode}
					<div class="certificate-verify-result error rc-verify__result rc-verify__result--bad rc-verify__result--spaced" role="alert">
						<span class="rc-verify__icon" aria-hidden="true"><svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round"><path d="M7 7l10 10M17 7L7 17"/></svg></span>
						<div>
							<h2>{translate key="plugins.generic.reviewerCertificate.verify.invalid"}</h2>
							<p>{translate key="plugins.generic.reviewerCertificate.verify.invalidDescription"}</p>
						</div>
					</div>
				{/if}
				<div class="certificate-verify-form">
					<p class="rc-verify__intro">{translate key="plugins.generic.reviewerCertificate.verify.description"}</p>
					<form method="get" action="{url page="certificate" op="verify"}">
						<label class="rc-verify__label" for="code">{translate key="plugins.generic.reviewerCertificate.verify.code"}</label>
						<div class="rc-verify__row">
							<input type="text" id="code" name="code" class="rc-verify__input" required maxlength="32" pattern="[A-Fa-f0-9]{ldelim}8,32{rdelim}" autocomplete="off" spellcheck="false" />
							<button type="submit" class="rc-verify__button">
								{translate key="plugins.generic.reviewerCertificate.verify.button"}
							</button>
						</div>
					</form>
				</div>
			{/if}
		</div>
	</div>
</div>

{* Scoped to .rc-verify so the theme's own .btn / .form-control rules are left alone *}
<style>
.rc-verify { --rc-ink: #1f2933; --rc-muted: #5f6b7a; --rc-line: #dde3ea; --rc-accent: #006798; max-width: 40rem; margin: 0 auto; padding: 2rem 1rem 3rem; color: var(--rc-ink); box-sizing: border-box; }
.rc-verify *, .rc-verify *::before, .rc-verify *::after { box-sizing: border-box; }
.rc-verify .rc-verify__title { margin: 0 0 1.25rem; text-align: center; }
.rc-verify .rc-verify__card { margin: 0; padding: 1.5rem; background: #fff; border: 1px solid var(--rc-line); border-radius: 12px; box-shadow: 0 1px 2px rgba(16, 24, 40, .04), 0 8px 24px rgba(16, 24, 40, .06); }
.rc-verify .rc-verify__result { display: flex; gap: 14px; align-items: flex-start; margin: 0; padding: 1rem 1.25rem; border-radius: 10px; border: 1px solid; }
.rc-verify .rc-verify__result h2 { margin: 3px 0 0; font-size: 1.15rem; line-height: 1.4; color: inherit; }
.rc-verify .rc-verify__result p { margin: .35rem 0 0; line-height: 1.5; }
.rc-verify .rc-verify__result--ok { background: #e9f6ee; border-color: #b7e0c5; color: #1f6b3b; }
.rc-verify .rc-verify__result--bad { background: #fdecea; border-color: #f5c2bd; color: #8a1f1f; }
.rc-verify .rc-verify__result--spaced { margin-bottom: 1.25rem; }
.rc-verify .rc-verify__icon { flex: none; display: inline-flex; align-items: center; justify-content: center; width: 36px; height: 36px; border-radius: 50%; background: currentColor; }
.rc-verify .rc-verify__icon svg { stroke: #fff; }
.rc-verify .rc-verify__details { margin: 1.25rem 0 0; padding: 0; }
.rc-verify .rc-verify__details > div { display: grid; grid-template-columns: minmax(8rem, 35%) 1fr; gap: 12px; padding: .7rem 0; border-top: 1px solid #edf0f3; }
.rc-verify .rc-verify__details > div:first-child { border-top: 0; }
.rc-verify .rc-verify__details dt { margin: 0; font-weight: 600; color: var(--rc-muted); font-size: .9em; }
.rc-verify .rc-verify__details dd { margin: 0; overflow-wrap: anywhere; }
.rc-verify .rc-verify__details code { font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace; letter-spacing: .03em; background: none; padding: 0; }
.rc-verify .rc-verify__intro { margin: 0 0 1rem; color: var(--rc-muted); }
.rc-verify .rc-verify__label { display: block; margin: 0 0 .4rem; font-weight: 600; }
.rc-verify .rc-verify__row { display: flex; gap: 8px; }
.rc-verify .rc-verify__input { flex: 1 1 auto; min-width: 0; height: 44px; margin: 0; padding: 0 12px; border: 1px solid #c4ccd6; border-radius: 8px; background: #fff; font: inherit; font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace; letter-spacing: .04em; color: var(--rc-ink); }
.rc-verify .rc-verify__input:focus { outline: 3px solid #e6f1f7; border-color: var(--rc-accent); }
.rc-verify .rc-verify__button { flex: none; height: 44px; margin: 0; padding: 0 20px; border: 0; border-radius: 8px; background: var(--rc-accent); color: #fff; font: inherit; font-weight: 700; cursor: pointer; }
.rc-verify .rc-verify__button:hover, .rc-verify .rc-verify__button:focus { background: #00557d; }
@media (max-width: 30rem) {
	.rc-verify .rc-verify__card { padding: 1rem; }
	.rc-verify .rc-verify__row { flex-direction: column; }
	.rc-verify .rc-verify__details > div { grid-template-columns: 1fr; gap: 2px; }
}
</style>

{include file="frontend/components/footer.tpl"}
