{**
 * plugins/generic/reviewerCertificate/templates/certificateSettings.tpl
 *
 * Copyright (c) 2024
 * Distributed under the GNU GPL v3.
 *
 * Certificate settings form template
 *}
<script>
	$(function() {ldelim}
		// Flag to track if file is selected
		var fileSelected = false;

		// Initially setup as AJAX form
		$('#certificateSettingsForm').pkpHandler('$.pkp.controllers.form.AjaxFormHandler');

		// Handle image file selection (background, logo, cover, seal)
		$('#backgroundImage, #logoImage, #coverImage, #sealImage').on('change', function(e) {ldelim}
			var file = e.target.files[0];
			if (file) {ldelim}
				// Validate file type
				if (!file.type.match('image.*')) {ldelim}
					alert('Please select an image file (JPEG or PNG)');
					$(this).val('');
					return;
				{rdelim}
				// Validate file size (max 5MB)
				if (file.size > 5 * 1024 * 1024) {ldelim}
					alert('Image file size must be less than 5MB');
					$(this).val('');
					return;
				{rdelim}
				// Show filename
				var fileName = file.name;
				var previewId = this.id + 'PreviewText';
				if ($('#' + previewId).length === 0) {ldelim}
					$(this).after('<p id="' + previewId + '" class="description" style="color: #28a745; margin-top: 5px;"></p>');
				{rdelim}
				$('#' + previewId).text('Selected: ' + fileName);

				// Disable AJAX submission when file is selected
				fileSelected = true;
				console.log('ReviewerCertificate: File selected, will use regular form submission');
			{rdelim} else {ldelim}
				$('#' + this.id + 'PreviewText').remove();
			{rdelim}
			// Use a regular POST while any image input holds a file
			fileSelected = $('#backgroundImage, #logoImage, #coverImage, #sealImage').filter(function() {ldelim}
				return this.files && this.files.length > 0;
			{rdelim}).length > 0;
		{rdelim});

		// Intercept form submission BEFORE AjaxFormHandler
		$('#certificateSettingsForm').on('submit.fileUpload', function(e) {ldelim}
			fileSelected = $('#backgroundImage, #logoImage, #coverImage, #sealImage').filter(function() {ldelim}
				return this.files && this.files.length > 0;
			{rdelim}).length > 0;
			if (fileSelected) {ldelim}
				console.log('ReviewerCertificate: File selected - destroying AjaxFormHandler for regular submission');
				// Stop event propagation to prevent AjaxFormHandler from handling it
				e.stopImmediatePropagation();

				// Unbind AjaxFormHandler
				$(this).off('.pkpHandler');

				// Submit form normally
				console.log('ReviewerCertificate: Submitting form with regular POST');
				this.submit();

				// Prevent default to avoid double submission
				return false;
			{rdelim}
			// For non-file submissions, let AJAX handler process it
		{rdelim});

		// Initialize color picker from RGB values
		function rgbToHex(r, g, b) {ldelim}
			return "#" + ((1 << 24) + (r << 16) + (g << 8) + b).toString(16).slice(1);
		{rdelim}

		function hexToRgb(hex) {ldelim}
			var result = /^#?([a-f\d]{ldelim}2{rdelim})([a-f\d]{ldelim}2{rdelim})([a-f\d]{ldelim}2{rdelim})$/i.exec(hex);
			return result ? {ldelim}
				r: parseInt(result[1], 16),
				g: parseInt(result[2], 16),
				b: parseInt(result[3], 16)
			{rdelim} : null;
		{rdelim}

		// Use attribute selectors to handle OJS's dynamic ID suffixes
		var $rInput = $('input[id^="textColorR"]');
		var $gInput = $('input[id^="textColorG"]');
		var $bInput = $('input[id^="textColorB"]');

		// Set initial color picker value from RGB inputs
		var r = parseInt($rInput.val()) || 0;
		var g = parseInt($gInput.val()) || 0;
		var b = parseInt($bInput.val()) || 0;
		$('#colorPicker').val(rgbToHex(r, g, b));
		$('#colorPreview').css('background-color', rgbToHex(r, g, b));

		// Update RGB values when color picker changes
		// Use 'change' and 'blur' events to ensure values are set before form serialization
		$('#colorPicker').on('input change blur', function() {ldelim}
			var rgb = hexToRgb($(this).val());
			if (rgb) {ldelim}
				$rInput.val(rgb.r);
				$gInput.val(rgb.g);
				$bInput.val(rgb.b);
				$('#colorPreview').css('background-color', $(this).val());
			{rdelim}
		{rdelim});

		// Update color picker when RGB values change manually
		$rInput.add($gInput).add($bInput).on('input change blur', function() {ldelim}
			// Get values and constrain to 0-255 range
			var r = Math.max(0, Math.min(255, parseInt($rInput.val()) || 0));
			var g = Math.max(0, Math.min(255, parseInt($gInput.val()) || 0));
			var b = Math.max(0, Math.min(255, parseInt($bInput.val()) || 0));

			// Update the input values if they were out of range
			$rInput.val(r);
			$gInput.val(g);
			$bInput.val(b);

			// Update color picker and preview
			$('#colorPicker').val(rgbToHex(r, g, b));
			$('#colorPreview').css('background-color', rgbToHex(r, g, b));
		{rdelim});
	{rdelim});
</script>

<form class="pkp_form" id="certificateSettingsForm" method="post" action="{url router=$smarty.const.ROUTE_COMPONENT op="manage" category="generic" plugin=$pluginName verb="settings" save=true}" enctype="multipart/form-data">
	{csrf}
	{include file="controllers/notification/inPlaceNotification.tpl" notificationId="certificateSettingsFormNotification"}

	<div id="description">
		<p>{translate key="plugins.generic.reviewerCertificate.settings.description"}</p>
	</div>

	{fbvFormArea id="certificateTemplateSettings" title="plugins.generic.reviewerCertificate.settings.templateSettings"}

		{* Background Image Upload *}
		{fbvFormSection title="plugins.generic.reviewerCertificate.settings.backgroundImage" description="plugins.generic.reviewerCertificate.settings.backgroundImageDescription"}
			<input type="file" id="backgroundImage" name="backgroundImage" accept="image/*" class="pkp_form_file" />
			{if $backgroundImage}
				<p class="description">{translate key="plugins.generic.reviewerCertificate.settings.currentImage"}: {$backgroundImageName|escape}</p>
				{* Ticking this clears the setting without needing a replacement upload (Issue #73) *}
				{fbvElement type="checkbox" id="removeBackgroundImage" value="1" label="plugins.generic.reviewerCertificate.settings.removeBackgroundImage"}
			{/if}
		{/fbvFormSection}

		{* Logo image, drawn over the background *}
		{fbvFormSection title="plugins.generic.reviewerCertificate.settings.logoImage" description="plugins.generic.reviewerCertificate.settings.logoImageDescription"}
			<input type="file" id="logoImage" name="logoImage" accept="image/png,image/jpeg" class="pkp_form_file" />
			{if $logoImage}
				<p class="description">{translate key="plugins.generic.reviewerCertificate.settings.currentImage"}: {$logoImageName|escape}</p>
				{fbvElement type="checkbox" id="removeLogoImage" value="1" label="plugins.generic.reviewerCertificate.settings.removeImage"}
			{/if}
			<div class="pkp_helpers_clear" style="margin-top: 8px;">
				<div style="float:left; margin-right: 15px;">
					<label for="logoWidth">{translate key="plugins.generic.reviewerCertificate.settings.image.width"}</label>
					{fbvElement type="text" id="logoWidth" value=$logoWidth size=$fbvStyles.size.SMALL inline=true}
				</div>
				<div style="float:left; margin-right: 15px;">
					<label for="logoX">{translate key="plugins.generic.reviewerCertificate.settings.image.x"}</label>
					{fbvElement type="text" id="logoX" value=$logoX size=$fbvStyles.size.SMALL inline=true}
				</div>
				<div style="float:left;">
					<label for="logoY">{translate key="plugins.generic.reviewerCertificate.settings.image.y"}</label>
					{fbvElement type="text" id="logoY" value=$logoY size=$fbvStyles.size.SMALL inline=true}
				</div>
			</div>
		{/fbvFormSection}

		{* Cover image, drawn over the background *}
		{fbvFormSection title="plugins.generic.reviewerCertificate.settings.coverImage" description="plugins.generic.reviewerCertificate.settings.coverImageDescription"}
			<input type="file" id="coverImage" name="coverImage" accept="image/png,image/jpeg" class="pkp_form_file" />
			{if $coverImage}
				<p class="description">{translate key="plugins.generic.reviewerCertificate.settings.currentImage"}: {$coverImageName|escape}</p>
				{fbvElement type="checkbox" id="removeCoverImage" value="1" label="plugins.generic.reviewerCertificate.settings.removeImage"}
			{/if}
			<div class="pkp_helpers_clear" style="margin-top: 8px;">
				<div style="float:left; margin-right: 15px;">
					<label for="coverWidth">{translate key="plugins.generic.reviewerCertificate.settings.image.width"}</label>
					{fbvElement type="text" id="coverWidth" value=$coverWidth size=$fbvStyles.size.SMALL inline=true}
				</div>
				<div style="float:left; margin-right: 15px;">
					<label for="coverX">{translate key="plugins.generic.reviewerCertificate.settings.image.x"}</label>
					{fbvElement type="text" id="coverX" value=$coverX size=$fbvStyles.size.SMALL inline=true}
				</div>
				<div style="float:left;">
					<label for="coverY">{translate key="plugins.generic.reviewerCertificate.settings.image.y"}</label>
					{fbvElement type="text" id="coverY" value=$coverY size=$fbvStyles.size.SMALL inline=true}
				</div>
			</div>
		{/fbvFormSection}

		{* Seal image, drawn over the background *}
		{fbvFormSection title="plugins.generic.reviewerCertificate.settings.sealImage" description="plugins.generic.reviewerCertificate.settings.sealImageDescription"}
			<input type="file" id="sealImage" name="sealImage" accept="image/png,image/jpeg" class="pkp_form_file" />
			{if $sealImage}
				<p class="description">{translate key="plugins.generic.reviewerCertificate.settings.currentImage"}: {$sealImageName|escape}</p>
				{fbvElement type="checkbox" id="removeSealImage" value="1" label="plugins.generic.reviewerCertificate.settings.removeImage"}
			{/if}
			<div class="pkp_helpers_clear" style="margin-top: 8px;">
				<div style="float:left; margin-right: 15px;">
					<label for="sealWidth">{translate key="plugins.generic.reviewerCertificate.settings.image.width"}</label>
					{fbvElement type="text" id="sealWidth" value=$sealWidth size=$fbvStyles.size.SMALL inline=true}
				</div>
				<div style="float:left; margin-right: 15px;">
					<label for="sealX">{translate key="plugins.generic.reviewerCertificate.settings.image.x"}</label>
					{fbvElement type="text" id="sealX" value=$sealX size=$fbvStyles.size.SMALL inline=true}
				</div>
				<div style="float:left;">
					<label for="sealY">{translate key="plugins.generic.reviewerCertificate.settings.image.y"}</label>
					{fbvElement type="text" id="sealY" value=$sealY size=$fbvStyles.size.SMALL inline=true}
				</div>
			</div>
		{/fbvFormSection}

		{* Header Text *}
		{fbvFormSection title="plugins.generic.reviewerCertificate.settings.headerText" description="plugins.generic.reviewerCertificate.settings.headerTextDescription"}
			{fbvElement type="text" id="headerText" value=$headerText maxlength="255" size=$fbvStyles.size.LARGE}
		{/fbvFormSection}

		{* Body Template *}
		{fbvFormSection title="plugins.generic.reviewerCertificate.settings.bodyTemplate" description="plugins.generic.reviewerCertificate.settings.bodyTemplateDescription" required=true}
			{fbvElement type="textarea" id="bodyTemplate" value=$bodyTemplate height=$fbvStyles.height.TALL rich=false}
			<p class="description">
				{translate key="plugins.generic.reviewerCertificate.settings.defaultTemplate"}:
				<a href="#" onclick="$('[id^=bodyTemplate]').not('#defaultBodyTemplate').val($('#defaultBodyTemplate').val()); return false;">
					{translate key="plugins.generic.reviewerCertificate.settings.useDefaultTemplate"}
				</a>
			</p>
			<textarea id="defaultBodyTemplate" style="display:none;">{$defaultBodyTemplate}</textarea>
		{/fbvFormSection}

		{* Footer Text *}
		{fbvFormSection title="plugins.generic.reviewerCertificate.settings.footerText" description="plugins.generic.reviewerCertificate.settings.footerTextDescription"}
			{fbvElement type="textarea" id="footerText" value=$footerText height=$fbvStyles.height.SHORT}
		{/fbvFormSection}

		{* Available Variables *}
		{fbvFormSection title="plugins.generic.reviewerCertificate.settings.availableVariables"}
			<div class="pkp_helpers_clear">
				<p class="description">{translate key="plugins.generic.reviewerCertificate.settings.availableVariablesDescription"}</p>
				<ul class="template-variables">
					{foreach from=$templateVariables item=variable}
						<li><code>{$variable}</code></li>
					{/foreach}
				</ul>
			</div>
		{/fbvFormSection}

	{/fbvFormArea}

	{fbvFormArea id="certificateAppearance" title="plugins.generic.reviewerCertificate.settings.appearance"}

		{* Font Family *}
		{fbvFormSection title="plugins.generic.reviewerCertificate.settings.fontFamily"}
			{fbvElement type="select" id="fontFamily" from=$fontOptions selected=$fontFamily translate=false defaultValue="helvetica"}
			<p class="description" style="color: #996600; margin-top: 5px;">
				{translate key="plugins.generic.reviewerCertificate.settings.fontUnicodeWarning"}
			</p>
		{/fbvFormSection}

		{* Font Size *}
		{fbvFormSection title="plugins.generic.reviewerCertificate.settings.fontSize"}
			{fbvElement type="text" id="fontSize" value=$fontSize|default:12 size=$fbvStyles.size.SMALL}
		{/fbvFormSection}

		{* Body Top Offset *}
		{fbvFormSection title="plugins.generic.reviewerCertificate.settings.bodyTopOffset" description="plugins.generic.reviewerCertificate.settings.bodyTopOffsetDescription"}
			{fbvElement type="text" id="bodyTopOffset" value=$bodyTopOffset|default:0 size=$fbvStyles.size.SMALL}
		{/fbvFormSection}

		{* Page Orientation *}
		{fbvFormSection title="plugins.generic.reviewerCertificate.settings.pageOrientation" description="plugins.generic.reviewerCertificate.settings.pageOrientationDescription"}
			{fbvElement type="select" id="pageOrientation" from=$orientationOptions selected=$pageOrientation translate=false defaultValue="P"}
		{/fbvFormSection}

		{* Text Color *}
		{fbvFormSection title="plugins.generic.reviewerCertificate.settings.textColor" description="plugins.generic.reviewerCertificate.settings.textColorDescription"}
			<div class="pkp_helpers_clear">
				<div style="margin-bottom: 10px;">
					<label for="colorPicker">Color Picker:</label>
					<input type="color" id="colorPicker" style="width: 60px; height: 30px; border: 1px solid #ccc; cursor: pointer;" />
					<span id="colorPreview" style="display: inline-block; width: 30px; height: 30px; border: 1px solid #ccc; margin-left: 5px; vertical-align: middle;"></span>
				</div>
				<div style="float:left; margin-right: 10px;">
					<label for="textColorR">R:</label>
					{fbvElement type="text" id="textColorR" value=$textColorR|default:0 size=$fbvStyles.size.SMALL inline=true}
				</div>
				<div style="float:left; margin-right: 10px;">
					<label for="textColorG">G:</label>
					{fbvElement type="text" id="textColorG" value=$textColorG|default:0 size=$fbvStyles.size.SMALL inline=true}
				</div>
				<div style="float:left;">
					<label for="textColorB">B:</label>
					{fbvElement type="text" id="textColorB" value=$textColorB|default:0 size=$fbvStyles.size.SMALL inline=true}
				</div>
			</div>
		{/fbvFormSection}

	{/fbvFormArea}

	{fbvFormArea id="certificateTypography" title="plugins.generic.reviewerCertificate.settings.typography"}

		{* Layout mode: classic keeps the single-block body; structured styles each line by role *}
		{fbvFormSection title="plugins.generic.reviewerCertificate.settings.layoutMode" description="plugins.generic.reviewerCertificate.settings.layoutModeDescription"}
			{fbvElement type="select" id="layoutMode" from=$layoutModeOptions selected=$layoutMode translate=false defaultValue="classic"}
		{/fbvFormSection}

		{fbvFormSection title="plugins.generic.reviewerCertificate.settings.typography.title" description="plugins.generic.reviewerCertificate.settings.typography.titleDescription"}
			<div class="pkp_helpers_clear">
				<div style="float:left; margin-right: 15px;">
					<label for="titleFontSize">{translate key="plugins.generic.reviewerCertificate.settings.typography.size"}</label>
					{fbvElement type="text" id="titleFontSize" value=$titleFontSize|default:28 size=$fbvStyles.size.SMALL inline=true}
				</div>
				<div style="float:left; margin-right: 15px;">
					<label for="titleColor">{translate key="plugins.generic.reviewerCertificate.settings.typography.color"}</label>
					{fbvElement type="text" id="titleColor" value=$titleColor maxlength="7" size=$fbvStyles.size.SMALL inline=true}
				</div>
				<div style="float:left; padding-top: 18px; margin-right: 15px;">
					{fbvElement type="checkbox" id="titleBold" value="1" checked=$titleBold label="plugins.generic.reviewerCertificate.settings.typography.bold"}
				</div>
			</div>
		{/fbvFormSection}

		{fbvFormSection title="plugins.generic.reviewerCertificate.settings.typography.name" description="plugins.generic.reviewerCertificate.settings.typography.nameDescription"}
			<div class="pkp_helpers_clear">
				<div style="float:left; margin-right: 15px;">
					<label for="nameFontSize">{translate key="plugins.generic.reviewerCertificate.settings.typography.size"}</label>
					{fbvElement type="text" id="nameFontSize" value=$nameFontSize|default:25 size=$fbvStyles.size.SMALL inline=true}
				</div>
				<div style="float:left; margin-right: 15px;">
					<label for="nameColor">{translate key="plugins.generic.reviewerCertificate.settings.typography.color"}</label>
					{fbvElement type="text" id="nameColor" value=$nameColor maxlength="7" size=$fbvStyles.size.SMALL inline=true}
				</div>
				<div style="float:left; padding-top: 18px; margin-right: 15px;">
					{fbvElement type="checkbox" id="nameBold" value="1" checked=$nameBold label="plugins.generic.reviewerCertificate.settings.typography.bold"}
				</div>
				<div style="float:left; padding-top: 18px; margin-right: 15px;">
					{fbvElement type="checkbox" id="nameUppercase" value="1" checked=$nameUppercase label="plugins.generic.reviewerCertificate.settings.typography.uppercase"}
				</div>
			</div>
		{/fbvFormSection}

		{fbvFormSection title="plugins.generic.reviewerCertificate.settings.typography.journal" description="plugins.generic.reviewerCertificate.settings.typography.journalDescription"}
			<div class="pkp_helpers_clear">
				<div style="float:left; margin-right: 15px;">
					<label for="journalFontSize">{translate key="plugins.generic.reviewerCertificate.settings.typography.size"}</label>
					{fbvElement type="text" id="journalFontSize" value=$journalFontSize|default:17 size=$fbvStyles.size.SMALL inline=true}
				</div>
				<div style="float:left; margin-right: 15px;">
					<label for="journalColor">{translate key="plugins.generic.reviewerCertificate.settings.typography.color"}</label>
					{fbvElement type="text" id="journalColor" value=$journalColor maxlength="7" size=$fbvStyles.size.SMALL inline=true}
				</div>
				<div style="float:left; padding-top: 18px; margin-right: 15px;">
					{fbvElement type="checkbox" id="journalBold" value="1" checked=$journalBold label="plugins.generic.reviewerCertificate.settings.typography.bold"}
				</div>
			</div>
		{/fbvFormSection}

		{fbvFormSection title="plugins.generic.reviewerCertificate.settings.typography.body" description="plugins.generic.reviewerCertificate.settings.typography.bodyDescription"}
			<div class="pkp_helpers_clear">
				<div style="float:left; margin-right: 15px;">
					<label for="bodyFontSize">{translate key="plugins.generic.reviewerCertificate.settings.typography.size"}</label>
					{fbvElement type="text" id="bodyFontSize" value=$bodyFontSize|default:13 size=$fbvStyles.size.SMALL inline=true}
				</div>
				<div style="float:left; margin-right: 15px;">
					<label for="bodyColor">{translate key="plugins.generic.reviewerCertificate.settings.typography.color"}</label>
					{fbvElement type="text" id="bodyColor" value=$bodyColor maxlength="7" size=$fbvStyles.size.SMALL inline=true}
				</div>
				<div style="float:left; padding-top: 18px; margin-right: 15px;">
					{fbvElement type="checkbox" id="bodyBold" value="1" checked=$bodyBold label="plugins.generic.reviewerCertificate.settings.typography.bold"}
				</div>
			</div>
		{/fbvFormSection}

		{fbvFormSection title="plugins.generic.reviewerCertificate.settings.typography.detail" description="plugins.generic.reviewerCertificate.settings.typography.detailDescription"}
			<div class="pkp_helpers_clear">
				<div style="float:left; margin-right: 15px;">
					<label for="detailFontSize">{translate key="plugins.generic.reviewerCertificate.settings.typography.size"}</label>
					{fbvElement type="text" id="detailFontSize" value=$detailFontSize|default:10 size=$fbvStyles.size.SMALL inline=true}
				</div>
				<div style="float:left; margin-right: 15px;">
					<label for="detailColor">{translate key="plugins.generic.reviewerCertificate.settings.typography.color"}</label>
					{fbvElement type="text" id="detailColor" value=$detailColor maxlength="7" size=$fbvStyles.size.SMALL inline=true}
				</div>
			</div>
		{/fbvFormSection}

		{fbvFormSection title="plugins.generic.reviewerCertificate.settings.typography.footer" description="plugins.generic.reviewerCertificate.settings.typography.footerDescription"}
			<div class="pkp_helpers_clear">
				<div style="float:left; margin-right: 15px;">
					<label for="footerFontSize">{translate key="plugins.generic.reviewerCertificate.settings.typography.size"}</label>
					{fbvElement type="text" id="footerFontSize" value=$footerFontSize|default:10 size=$fbvStyles.size.SMALL inline=true}
				</div>
				<div style="float:left; margin-right: 15px;">
					<label for="footerColor">{translate key="plugins.generic.reviewerCertificate.settings.typography.color"}</label>
					{fbvElement type="text" id="footerColor" value=$footerColor maxlength="7" size=$fbvStyles.size.SMALL inline=true}
				</div>
				<div style="float:left; padding-top: 18px; margin-right: 15px;">
					{fbvElement type="checkbox" id="footerBold" value="1" checked=$footerBold label="plugins.generic.reviewerCertificate.settings.typography.bold"}
				</div>
				<div style="float:left; margin-right: 15px;">
					<label for="footerPosition">{translate key="plugins.generic.reviewerCertificate.settings.typography.footerPosition"}</label>
					{fbvElement type="select" id="footerPosition" from=$footerPositionOptions selected=$footerPosition translate=false defaultValue="flow" inline=true}
				</div>
				<div style="float:left;">
					<label for="footerBottomSpacing">{translate key="plugins.generic.reviewerCertificate.settings.typography.footerBottomSpacing"}</label>
					{fbvElement type="text" id="footerBottomSpacing" value=$footerBottomSpacing|default:20 size=$fbvStyles.size.SMALL inline=true}
				</div>
			</div>
		{/fbvFormSection}

		{fbvFormSection title="plugins.generic.reviewerCertificate.settings.typography.spacing" description="plugins.generic.reviewerCertificate.settings.typography.spacingDescription"}
			<div class="pkp_helpers_clear">
				<div style="float:left; margin-right: 15px;">
					<label for="paragraphSpacing">{translate key="plugins.generic.reviewerCertificate.settings.typography.paragraphSpacing"}</label>
					{fbvElement type="text" id="paragraphSpacing" value=$paragraphSpacing|default:4 size=$fbvStyles.size.SMALL inline=true}
				</div>
				<div style="float:left; margin-right: 15px;">
					<label for="nameSpacing">{translate key="plugins.generic.reviewerCertificate.settings.typography.nameSpacing"}</label>
					{fbvElement type="text" id="nameSpacing" value=$nameSpacing|default:4 size=$fbvStyles.size.SMALL inline=true}
				</div>
				<div style="float:left;">
					<label for="sideMargin">{translate key="plugins.generic.reviewerCertificate.settings.typography.sideMargin"}</label>
					{fbvElement type="text" id="sideMargin" value=$sideMargin|default:15 size=$fbvStyles.size.SMALL inline=true}
				</div>
			</div>
		{/fbvFormSection}

	{/fbvFormArea}

	{fbvFormArea id="certificateEligibility" title="plugins.generic.reviewerCertificate.settings.eligibility"}

		{* Minimum Reviews *}
		{fbvFormSection title="plugins.generic.reviewerCertificate.settings.minimumReviews" description="plugins.generic.reviewerCertificate.settings.minimumReviewsDescription" required=true}
			{fbvElement type="text" id="minimumReviews" value=$minimumReviews|default:1 size=$fbvStyles.size.SMALL}
		{/fbvFormSection}

		{* Include QR Code *}
		{fbvFormSection title="plugins.generic.reviewerCertificate.settings.verification" list=true}
			{fbvElement type="checkbox" id="includeQRCode" value="1" checked=$includeQRCode label="plugins.generic.reviewerCertificate.settings.includeQRCode"}
		{/fbvFormSection}

	{/fbvFormArea}

	{fbvFormArea id="certificateAckEmail" title="plugins.generic.reviewerCertificate.settings.ackEmailBody"}

		{* Acknowledgement email sent from the My Certificates page *}
		{fbvFormSection title="plugins.generic.reviewerCertificate.settings.ackEmailSubject" description="plugins.generic.reviewerCertificate.settings.ackEmailDescription"}
			{fbvElement type="text" id="ackEmailSubject" value=$ackEmailSubject maxlength="255" size=$fbvStyles.size.LARGE}
		{/fbvFormSection}

		{fbvFormSection title="plugins.generic.reviewerCertificate.settings.ackEmailBody"}
			{fbvElement type="textarea" id="ackEmailBody" value=$ackEmailBody height=$fbvStyles.height.TALL rich=false}
		{/fbvFormSection}

	{/fbvFormArea}

	{fbvFormButtons}
	<p>
		<a href="{url router=$smarty.const.ROUTE_COMPONENT op="manage" category="generic" plugin=$pluginName verb="preview"}" target="_blank" class="pkp_button">
			{translate key="plugins.generic.reviewerCertificate.settings.previewCertificate"}
		</a>
	</p>
</form>

<!-- Certificate Statistics -->
<div class="section" style="margin-top: 40px;">
	<h2>{translate key="plugins.generic.reviewerCertificate.statistics.title"}</h2>
	<p class="description">{translate key="plugins.generic.reviewerCertificate.statistics.description"}</p>

	<div class="statistics-grid" style="display: grid; grid-template-columns: repeat(3, 1fr); gap: 20px; margin: 20px 0;">
		<div class="stat-card" style="background: #f5f5f5; padding: 20px; border-radius: 5px; text-align: center;">
			<h3 style="font-size: 2em; margin: 0; color: #007bff;">{$totalCertificates|default:0}</h3>
			<p style="margin: 5px 0 0 0; color: #666;">{translate key="plugins.generic.reviewerCertificate.statistics.totalCertificates"}</p>
		</div>
		<div class="stat-card" style="background: #f5f5f5; padding: 20px; border-radius: 5px; text-align: center;">
			<h3 style="font-size: 2em; margin: 0; color: #28a745;">{$totalDownloads|default:0}</h3>
			<p style="margin: 5px 0 0 0; color: #666;">{translate key="plugins.generic.reviewerCertificate.statistics.totalDownloads"}</p>
		</div>
		<div class="stat-card" style="background: #f5f5f5; padding: 20px; border-radius: 5px; text-align: center;">
			<h3 style="font-size: 2em; margin: 0; color: #ffc107;">{$uniqueReviewers|default:0}</h3>
			<p style="margin: 5px 0 0 0; color: #666;">{translate key="plugins.generic.reviewerCertificate.statistics.uniqueReviewers"}</p>
		</div>
	</div>
</div>

<!-- Batch Certificate Generation -->
<div class="section" style="margin-top: 40px; padding: 20px; background: #f9f9f9; border-radius: 5px;">
	<h2>{translate key="plugins.generic.reviewerCertificate.batch.title"}</h2>
	<p class="description">{translate key="plugins.generic.reviewerCertificate.batch.description"}</p>

	<form id="batchGenerateForm" style="margin-top: 20px;">
		<div style="margin-bottom: 15px;">
			<label>{translate key="plugins.generic.reviewerCertificate.batch.selectReviewers"}</label>
			<select id="batchReviewers" name="reviewerIds[]" multiple size="10" style="width: 100%; padding: 10px;">
				{if $eligibleReviewers}
					{foreach from=$eligibleReviewers item=reviewer}
						<option value="{$reviewer.id|escape}">{$reviewer.name|escape} ({$reviewer.completedReviews|escape} {translate key="plugins.generic.reviewerCertificate.batch.completedReviews"})</option>
					{/foreach}
				{else}
					<option disabled>{translate key="plugins.generic.reviewerCertificate.batch.noEligibleReviewers"}</option>
				{/if}
			</select>
			<p class="description" style="margin-top: 5px;">{translate key="plugins.generic.reviewerCertificate.batch.selectMultipleHint"}</p>
		</div>

		<button type="button" id="generateBatchBtn" class="pkp_button" style="background: #28a745; color: white;">
			{translate key="plugins.generic.reviewerCertificate.batch.generate"}
		</button>
		<span id="batchProgress" style="margin-left: 15px; display: none;">
			<span class="pkp_spinner"></span> {translate key="plugins.generic.reviewerCertificate.batch.generating"}
		</span>
	</form>

	<div id="batchResult" style="margin-top: 20px; display: none;"></div>
</div>

<div class="section" style="margin-top: 30px;">
    <h2>{translate key="plugins.generic.reviewerCertificate.notifications.title"}</h2>
    <p>{translate key="plugins.generic.reviewerCertificate.notifications.description"}</p>
    <label for="notificationReviewers">{translate key="plugins.generic.reviewerCertificate.batch.selectReviewers"}</label>
    <select id="notificationReviewers" multiple size="8" style="width:100%">
        {foreach from=$notificationReviewers item=reviewer}
            <option value="{$reviewer.id|escape}">{$reviewer.name|escape}</option>
        {/foreach}
    </select>
    <label><input type="checkbox" id="retryNotifications" /> {translate key="plugins.generic.reviewerCertificate.notifications.retry"}</label>
    <p>{translate key="plugins.generic.reviewerCertificate.notifications.retryWarning"}</p>
    <button type="button" id="notifyBatchBtn" class="pkp_button">{translate key="plugins.generic.reviewerCertificate.notifications.send"}</button>
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

<style>
.template-variables {
	display: grid;
	grid-template-columns: repeat(3, 1fr);
	gap: 5px;
	list-style: none;
	padding: 10px;
	background: #f5f5f5;
	border-radius: 3px;
}

.template-variables li {
	font-size: 0.9em;
}

.template-variables code {
	background: #fff;
	padding: 2px 5px;
	border-radius: 2px;
	font-family: monospace;
}
</style>
