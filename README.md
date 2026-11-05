# Reviewer Certificate Plugin for OJS

**Version 1.16.0** | [Changelog](CHANGELOG.md) | OJS 3.3 / 3.4 / 3.5

## Overview

The Reviewer Certificate Plugin enables reviewers to generate and download personalized PDF certificates of recognition after completing peer reviews. This plugin helps journals acknowledge and incentivize quality peer review work.

**Changes in v1.15.1**:

- Fixes the My Certificates page failing to open (HTTP 500) in v1.15.0.

**Changes in v1.16.0**:

- Issued certificates overview for managers with search, CSV export and certificate revocation.
- Annual and cumulative certificates showing how many reviews a reviewer completed for the journal (per year or in total).
- Verification page can show the reviewer's initials only, or no name.
- Traditional Chinese interface, and certificate dates in English, Chinese, numeric or the reader's language.
- My Certificates issues missing certificates for eligible completed reviews and explains when more reviews are needed.

**Changes in v1.15.0**:

- The My Certificates page opens inside the OJS backend and uses OJS's default table, button and notice styles, so the journal's frontend theme no longer affects it.
- Certificate PDFs are generated in memory when downloaded or emailed and are never stored on the server.

**Changes in v1.14.0**:

- "My Certificates" entry in the OJS backend side menu, right below Statistics, for reviewers who have completed a review.
- The Download and Email buttons on the My Certificates page are aligned and keep their colours under any theme.

**Changes in v1.13.0**:

- Much smaller certificate PDFs: a text-only certificate drops from about 150 KB to about 30 KB, and uploaded images are scaled to print size.
- Chinese, Japanese and Korean text now renders (it used to show as boxes), using non-embedded Adobe CJK fonts.

**Changes in v1.12.1**:

- Smaller QR code in the bottom-right corner with the certificate code beneath it.
- Settings page: saving stays on the page (images included), the button reads "Save", the form uses the full page width, and OJS's form styles no longer override the plugin's controls.

**Changes in v1.12.0**:

- Redesigned settings page: six numbered sections, a visual layout chooser, click-to-insert variables, image cards and a typography table with colour pickers.
- In the structured layout the whole certificate is written in one body template: `# Title` for the title and lines below `---` for the footer.

**Changes in v1.11.0**:

- Optional structured certificate layout: separate size, weight and colour for the title, reviewer name, journal name, acknowledgement text, dates/code and footer, with automatic shrink-to-fit so certificates stay on one page.
- Title placement inside the body (`{{$certificateTitle}}`), uppercase names, a footer pinned to the page bottom and a `{{$reviewMonthYear}}` variable.
- Separate logo, journal cover and seal uploads drawn over the background, placed automatically or by position.
- Classic layout, certificate codes and QR verification are unchanged.

**Changes in v1.10.0**:

- Shared journal-local eligibility, guarded batch actions and resumable pagination.
- Durable automatic notifications and a separate historical-notification action.
- Transactional settings uploads, safer verification input and Unicode template rendering.
- Additive, repeatable database migration; existing certificate codes are preserved.

See [integration testing](tests/environment/README.md) for reproducible checks and current verification limits.

## Author

**Panorama Scholarly Group Ltd.**  
Email: contact@panorama-sg.com

### Original author

This plugin is a fork of [ssemerikov/reviewerCertificate](https://github.com/ssemerikov/reviewerCertificate), created by:

**Serhiy O. Semerikov**  
Academy of Cognitive and Natural Sciences  
Email: semerikov@gmail.com

Releases up to 1.10.x are the original author's work. Later versions are modified by Panorama Scholarly Group Ltd.; see [CHANGELOG.md](CHANGELOG.md) for the changes.

## Development

This plugin was developed with the assistance of **Claude Code (Opus 5)**, an AI-powered coding assistant by Anthropic. Claude Code was used throughout the development process for:

- **Code Architecture**: Designing the plugin structure and component organization
- **Implementation**: Writing PHP classes, controllers, and data access objects
- **OJS Integration**: Ensuring compatibility with OJS 3.3.x, 3.4.x, and 3.5.x APIs
- **Database Design**: Creating the migration system and schema with automatic fallback for legacy versions
- **Testing & Debugging**: Comprehensive test suite with 206 PHP tests + 123 E2E tests across all OJS versions
- **Documentation**: Creating comprehensive user and technical documentation

The iterative development approach with Claude Code enabled rapid prototyping, thorough testing across OJS versions, and production-ready code quality.

## Features

- **Automated Certificate Generation**: Certificates are automatically available when reviewers complete their reviews
- **My Certificates Page**: Reviewers can browse all their issued certificates in one place with submission titles, dates, and download links
- **Customizable Templates**: Each journal can design unique certificate templates with custom backgrounds, fonts, and colors
- **Dynamic Content**: Insert reviewer names, journal names, submission titles, and dates using template variables
- **Unicode Font Support**: Automatic detection of non-Latin scripts (Cyrillic, CJK, Arabic) with seamless font switching
- **Eligibility Criteria**: Set minimum review requirements before certificates become available
- **QR Code Verification**: Include QR codes for certificate authenticity verification
- **Download Tracking**: Track certificate downloads and usage statistics
- **Multi-language Support**: Full internationalization with professional native translations
  - 31 languages; new management controls currently include English fallback text
  - Includes RTL support (Arabic, Persian, Hebrew), CJK languages (Chinese, Japanese, Korean), and Cyrillic scripts
  - Dual format: `.xml` (source of truth) and `.po` (required at runtime by all OJS versions) locale files
  - Automatic language detection from OJS settings
  - All translations validated with comprehensive test suite
- **Batch Generation**: Generate certificates for multiple reviewers at once

## Requirements

- **OJS Version**: 3.3.x, 3.4.x, or 3.5.x
- **PHP**: 7.3 or higher (PHP 8.0+ recommended for OJS 3.5)
- **Required PHP Extensions**:
  - GD or Imagick (for image processing)
  - mbstring
  - zip
- **TCPDF Library**: ✅ Bundled with plugin (v6.11.2) - no additional installation required!
- **Memory**: 128MB minimum PHP memory limit (256MB recommended for large background images)

### Version Compatibility

| OJS Version | Support Status | Notes |
|-------------|----------------|-------|
| 3.3.x | ✅ Supported | Migration through the OJS database connection |
| 3.4.x | ✅ Fully Supported | Modern Laravel migration |
| 3.5.x | ✅ Fully Supported | Latest features, PHP 8+ optimized |

## Installation

### Quick Install via OJS Admin (Recommended)

1. Download `reviewerCertificate-{VERSION}-3_X.tar.gz` from [Releases](https://github.com/WENSHAO521/reviewerCertificate/releases)
   - Use `-3_3.tar.gz` for OJS 3.3.x
   - Use `-3_4.tar.gz` for OJS 3.4.x
   - Use `-3_5.tar.gz` for OJS 3.5.x
   - ⚠️ Do **not** use the auto-generated "Source code" archives — they lack the bundled TCPDF library (git installs must run `composer install` instead)

2. In OJS, go to **Settings → Website → Plugins**

3. Click **Upload A New Plugin** and select the tar.gz file

4. Click **Enable** on the Reviewer Certificate Plugin

5. Click **Settings** to customize certificate templates

**That's it!** No command line needed.

### Alternative: Git Clone

1. Clone or download the plugin:
   ```bash
   cd /path/to/ojs/plugins/generic/
   git clone https://github.com/WENSHAO521/reviewerCertificate.git
   ```

2. Install dependencies:
   ```bash
   cd reviewerCertificate
   composer install --no-dev
   ```

3. Set permissions:
   ```bash
   chmod -R 755 .
   ```

4. Enable in OJS:
   - Log in as Administrator
   - Go to **Settings → Website → Plugins**
   - Find "Reviewer Certificate Plugin"
   - Click **Enable**
   - Database tables will be created automatically

5. Configure and use:
   - Click **Settings** to customize certificate templates
   - Click **Preview Certificate** to test your design

**Note:** The plugin includes TCPDF library in release archives, so no additional dependencies need to be installed when using the tar.gz packages.

## Configuration

### Initial Setup

1. Navigate to: **Settings > Website > Plugins**

2. Find **Reviewer Certificate Plugin** and click **Settings**

3. Configure the following options:

#### Template Settings

- **Background Image**: Upload a custom background image (2100x2970 px recommended). Once one is set, a **Remove the background image** checkbox appears — tick it and save to clear the background without having to upload a replacement.
- **Header Text**: Optional heading (e.g., "Certificate of Recognition"). Leave it empty for a certificate with no heading; the body then starts at the top margin instead of 45 mm down the page.
- **Body Template**: The main certificate content with template variables
- **Footer Text**: Optional footer text

#### Appearance Settings

- **Font Family**: Choose from Helvetica, Times New Roman, Courier, or DejaVu Sans
  - ⚠️ **Note**: Helvetica, Times, and Courier only support Latin scripts. If your certificate contains Cyrillic, CJK, Arabic, or other non-Latin characters, the plugin will automatically switch to DejaVu Sans.
- **Font Size**: Set the base font size (default: 12pt)
- **Text Color**: Set RGB values for text color (0-255 for each component)
- **Body Top Spacing (mm)**: Extra blank space above the body text, 0-100 mm (default: 0). Use this rather than typing blank lines at the start of the body template — OJS trims leading whitespace when the form is saved, so blank lines never reach the PDF.
- **Page Orientation**: Portrait or landscape

#### Typography (Structured Layout)

Set **Certificate Layout** to *Structured* to give the reviewer name, journal name and other parts of the certificate their own size and weight. *Classic* (the default) keeps the single-block body used by earlier versions, so existing certificates do not change until you opt in.

In the structured layout each line of the body template is styled by what it contains:

| Element | Which lines | Default |
|---|---|---|
| Certificate title | Header text | 28 pt, bold |
| Reviewer name | A line containing only `{{$reviewerName}}` (or first/last name) | 25 pt, bold |
| Journal name | A line containing only `{{$journalName}}` (optionally with `{{$journalAcronym}}`) | 17 pt |
| Acknowledgement text | Every other line | 13 pt |
| Review date, certificate code | Lines with a date variable or `{{$certificateCode}}`, and the certificate code line | 10 pt |
| Footer | Lines below a `---` line | 10 pt |

Each element also takes an optional colour (`#rrggbb`; empty uses the general text colour), and the reviewer name can be set to uppercase.

- **Title**: start a line of the body template with `#` to make it the certificate title, e.g. `# Certificate of Reviewing`; it is drawn where it appears, for example below the journal name. In the structured layout the separate Header Text field is folded into the body this way automatically. (`{{$certificateTitle}}` on its own line still works and draws the header text.)
- **Footer**: write the footer at the end of the body template, below a line of three dashes (`---`). Everything under that line is the footer. In the structured layout the separate Footer Text field is folded into the body this way automatically.
- **Footer position**: *Below the content*, or pinned *Bottom left* / *Bottom centre* at a set distance from the bottom edge (e.g. inside a band in your background image). The flowing content is kept above it.
- **Spacing**: blank lines in the template add **paragraph spacing**; **name spacing** adds room above and below the reviewer name; **side margin** narrows the text area so text stays clear of logos in the background (all in mm).
- **Fitting**: titles, names and journal titles shrink (down to 60% of their size) to fit on one line, then wrap; if the content is still too tall, the whole layout scales down so the certificate stays on one page.
- `{{$reviewMonthYear}}` gives the review month, e.g. "October 2026".

The certificate code and QR verification are unchanged.

#### Logo, Journal Cover and Seal

Besides the full-page background image, you can upload a **logo**, a **journal cover** and a **seal** separately (PNG or JPEG, max 5 MB each), so changing the cover for a new issue does not mean redrawing the background. Each image keeps its proportions at the width you set (mm) and is drawn over the background in both layouts. Leave X and Y at -1 for automatic placement: logo top left, cover top right, seal bottom right — or just left of the QR code when the QR code is enabled. Use a PNG with a transparent background for a round seal. Each image has its own remove checkbox.

**Example: recognition-style certificate (A4 landscape).** Upload your logo, journal cover and seal, put a light band along the bottom of the background image, then use:

```
{{$journalName}}

# Certificate of Reviewing

Awarded for 1 review in {{$reviewMonthYear}}
presented to

{{$reviewerName}}

in recognition of the review contributed to the journal

---
The Editors of {{$journalName}}
```

with title 46 pt not bold in your brand colour, journal 20 pt, body 16 pt, name 24 pt bold uppercase, footer 13 pt bold *Bottom left* at 24 mm, paragraph spacing 9 mm, name spacing 2 mm, side margin 55 mm and body top spacing 22 mm.

#### Eligibility Criteria

- **Minimum Reviews**: Set how many completed reviews are required (default: 1)
- **Include QR Code**: Enable/disable QR code for verification

### Template Variables

Use these variables in your templates to insert dynamic content:

| Variable | Description |
|----------|-------------|
| `{{$reviewerName}}` | Full name of the reviewer |
| `{{$reviewerFirstName}}` | Reviewer's first name |
| `{{$reviewerLastName}}` | Reviewer's last name |
| `{{$journalName}}` | Full journal name |
| `{{$journalAcronym}}` | Journal acronym |
| `{{$submissionTitle}}` | Title of the reviewed manuscript |
| `{{$reviewDate}}` | Date review was completed |
| `{{$reviewYear}}` | Year of review completion |
| `{{$currentDate}}` | Current date |
| `{{$currentYear}}` | Current year |
| `{{$certificateCode}}` | Unique certificate verification code |

### Example Certificate Template

```
Certificate of Recognition

This certificate is awarded to

{{$reviewerName}}

In recognition of their valuable contribution as a peer reviewer for

{{$journalName}}

Review completed on {{$reviewDate}}

Manuscript: {{$submissionTitle}}

We deeply appreciate your expertise and dedication to advancing scholarly communication.
```

## Language Support

The Reviewer Certificate Plugin is fully internationalized and available in 31 languages.

### Supported Languages

| Language | Locale Code | Native Name | Status |
|----------|-------------|-------------|--------|
| English (US) | `en_US` | English | ✅ Complete |
| Ukrainian | `uk_UA` | Українська | ✅ Complete |
| Russian | `ru_RU` | Русский | ✅ Complete |
| Spanish | `es_ES` | Español | ✅ Complete |
| Portuguese (BR) | `pt_BR` | Português (Brasil) | ✅ Complete |
| French | `fr_FR` | Français | ✅ Complete |
| German | `de_DE` | Deutsch | ✅ Complete |
| Italian | `it_IT` | Italiano | ✅ Complete |
| Turkish | `tr_TR` | Türkçe | ✅ Complete |
| Polish | `pl_PL` | Polski | ✅ Complete |
| Indonesian | `id_ID` | Bahasa Indonesia | ✅ Complete |
| Dutch | `nl_NL` | Nederlands | ✅ Complete |
| Czech | `cs_CZ` | Čeština | ✅ Complete |
| Catalan | `ca_ES` | Català | ✅ Complete |
| Norwegian (Bokmål) | `nb_NO` | Norsk Bokmål | ✅ Complete |
| Swedish | `sv_SE` | Svenska | ✅ Complete |
| Croatian | `hr_HR` | Hrvatski | ✅ Complete |
| Finnish | `fi_FI` | Suomi | ✅ Complete |
| Romanian | `ro_RO` | Română | ✅ Complete |
| Chinese (Simplified) | `zh_CN` | 简体中文 | ✅ Complete |
| Arabic | `ar_AR` | العربية | ✅ Complete |
| Japanese | `ja_JP` | 日本語 | ✅ Complete |
| Korean | `ko_KR` | 한국어 | ✅ Complete |
| Persian/Farsi | `fa_IR` | فارسی | ✅ Complete |
| Greek | `el_GR` | Ελληνικά | ✅ Complete |
| Hebrew | `he_IL` | עברית | ✅ Complete |
| Hungarian | `hu_HU` | Magyar | ✅ Complete |
| Lithuanian | `lt_LT` | Lietuvių | ✅ Complete |
| Slovak | `sk_SK` | Slovenčina | ✅ Complete |
| Slovenian | `sl_SI` | Slovenščina | ✅ Complete |
| Bulgarian | `bg_BG` | Български | ✅ Complete |

### Language Features

- **Automatic Detection**: The plugin automatically uses the language selected in your OJS installation
- **UTF-8 Support**: Full support for Cyrillic, Latin, CJK, Arabic, and other character sets
- **Certificate Content**: All interface text is translated; certificate templates can be customized in any language
- **Template Variables**: Template variables like `{{$reviewerName}}` work in all languages

## Usage

### For Reviewers

1. Complete a peer review assignment
2. Submit your review
3. If eligible, a certificate download button will appear in your reviewer dashboard
4. Click **Download Certificate** to generate and download your PDF certificate
5. Click **View All My Certificates** to browse all your issued certificates
6. The certificate includes a unique verification code for authenticity

### For Journal Managers

#### Viewing Certificate Statistics

1. Navigate to: **Settings > Website > Plugins > Reviewer Certificate Plugin**
2. View statistics on issued certificates and downloads

#### Batch Certificate Generation

1. Navigate to the plugin settings
2. Select multiple reviewers
3. Click **Generate Batch Certificates**
4. Certificates will be generated for all eligible completed reviews

#### Certificate Verification

To verify a certificate's authenticity:

1. Navigate to: `[your-journal-url]/certificate/verify/[certificate-code]`
2. The system will display certificate details if valid

## Troubleshooting

### Certificates Not Appearing

- Verify the plugin is enabled
- Check that reviews are marked as completed
- Confirm minimum review requirements are met
- Check file permissions on the files directory

### PDF Generation Errors

- Ensure TCPDF library is properly installed (bundled in release archives)
- Verify PHP memory limit (recommended: 256MB)
- Check PHP error logs for specific issues
- Ensure GD or Imagick extension is enabled

### Cyrillic/Unicode Characters Show as "??????"

- This is now handled automatically — the plugin detects non-Latin characters and switches to DejaVu Sans
- If you still see garbled text, ensure your database uses UTF-8 encoding (`utf8mb4`)
- Verify that reviewer names and submission titles are stored correctly in the database

### QR Code Verification Not Working

- Ensure the certificate code in the URL is 8-32 hexadecimal characters
- Older certificates may have 12-character codes (still supported)
- Check that the certificate exists in the `reviewer_certificates` table

## API Endpoints

The plugin provides these API endpoints:

| Endpoint | Description | Access |
|----------|-------------|--------|
| `GET /certificate/download/{reviewId}` | Download certificate | Reviewer (own) |
| `GET /certificate/myCertificates` | Browse all my certificates | Reviewer |
| `GET /certificate/verify/{certificateCode}` | Verify certificate | Public |
| `GET /certificate/preview` | Preview certificate template | Manager |
| `POST /certificate/generateBatch` | Generate batch certificates | Manager |

## Security Considerations

- Certificates include unique verification codes
- Access control ensures reviewers can only access their own certificates
- QR codes link to verification endpoints
- Download tracking for audit purposes
- CSRF protection on all forms
- File upload validation and sanitization
- Context isolation prevents cross-journal data access

## Database Schema

The plugin creates these tables:

- `reviewer_certificate_templates` — Template configurations
- `reviewer_certificates` — Issued certificates
- `reviewer_certificate_settings` — Localized settings

## Compatibility

| OJS Version | PHP Version | Status |
|-------------|-------------|--------|
| 3.3.x | 7.3 - 8.2 | ✅ Fully tested |
| 3.4.x | 7.4 - 8.2 | ✅ Fully tested |
| 3.5.x | 8.0 - 8.2 | ✅ Fully tested |

**Test Coverage**: 206 PHP unit tests + 123 E2E tests = 329 total tests

## Support

For issues, questions, or feature requests:

1. Check the [CHANGELOG.md](CHANGELOG.md) for recent fixes
2. Search existing [Issues](https://github.com/WENSHAO521/reviewerCertificate/issues)
3. Create a new issue with:
   - OJS version
   - PHP version
   - Error messages
   - Steps to reproduce

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

This plugin is licensed under the GNU General Public License v3.0.

Copyright (c) 2025-2026 Serhiy O. Semerikov, Academy of Cognitive and Natural Sciences (original work)  
Copyright (c) 2026 Panorama Scholarly Group Ltd. (modifications)

This is a modified version of the original plugin, distributed under the same license.

## Acknowledgments

We extend our sincere gratitude to the following contributors who helped improve this plugin:

- **Dr. Olha Pinchuk** (ITLT Journal, Ukraine) — For extensive production testing on OJS 3.4.0.8, reporting critical bugs (Cyrillic PDF rendering, QR verification, date display), and inspiring the "My Certificates" page feature. Your thorough testing and feedback were invaluable for v1.7.0.

- **Dr. Uğur Koçak** ([@drugurkocak](https://github.com/drugurkocak)) — For extensive testing across OJS 3.5 and detailed bug reports that led to fixes in versions 1.0.7 through 1.1.2.

- **Pedro Felipe Rocha** — For Brazilian Portuguese translation and feedback on OJS 3.5 locale requirements.

- **Željko Filajdić** (Diacovensia – Teološki prilozi, Catholic Faculty of Theology in Đakovo, Croatia) — For reporting the short locale-code issue (#72) and contributing a native-speaker Croatian translation, translated and proofread by the journal's editorial staff, shipped in v1.8.1.

- **Dr. Pavlo Nechypurenko** — For reporting the font size configuration issue fixed in v1.0.3.

Thank you to everyone in the PKP Community Forum who provided feedback and helped test the plugin!

## Credits

**Author**: Panorama Scholarly Group Ltd., contact@panorama-sg.com  
**Original author**: Serhiy O. Semerikov (Academy of Cognitive and Natural Sciences), semerikov@gmail.com, [ssemerikov/reviewerCertificate](https://github.com/ssemerikov/reviewerCertificate)

Developed for the Open Journal Systems community to support and recognize peer reviewers' contributions to scholarly publishing.

**Development Tools**: Built with Claude Code (Opus 5) by Anthropic

## Additional Resources

- [OJS Documentation](https://docs.pkp.sfu.ca/learning-ojs/)
- [PKP Community Forum](https://forum.pkp.sfu.ca/)
- [TCPDF Documentation](https://tcpdf.org/)

---

**Note**: Always backup your database and files before installing new plugins.
