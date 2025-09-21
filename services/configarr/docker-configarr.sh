#!/bin/bash
set -euo pipefail
# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

log "Check variables..."
count=0
# Laad variabelen uit .env bestand
if [ -f .env ]; then
    source .env
else
    log "ERROR: .env file is missing. Create a .env file with the settings for the relevant services."
    exit 1
fi

# Controleer verplichte variabelen
for var in LIDARR_API LIDARR_URL; do
    if [ -z "${!var:-}" ]; then
        log "ERROR: Variabele $var is missing from .env file. Skipping for LIDARR"
        ((count++))
        export LIDARR_ENA=false
    else
        export LIDARR_ENA=true
    fi
done
for var in RADARR_API RADARR_URL; do
    if [ -z "${!var:-}" ]; then
        log "ERROR: Variabele $var is missing from .env file. Skipping for RADARR"
        ((count++))
        export RADARR_ENA=false
    else
        export RADARR_ENA=true
    fi
done
for var in SONARR_API SONARR_URL; do
    if [ -z "${!var:-}" ]; then
        log "ERROR: Variabele $var is missing from .env file. Skipping for SONARR"
        ((count++))
        export SONARR_ENA=false
    else
        export SONARR_ENA=true
    fi
done

if [ "$count" -gt 5 ]; then
  log "ERROR: Too many missing variables."
  log "ERROR: Please update and check .env file."
  exit 1
fi

log "Start config generation..."

mkdir -p ./config
log "Creating config/custom-size-below-400mb.json"
cat <<EOF > config/custom-size-below-400mb.json
{
  "trash_id": "custom-size-below-400mb",
  "trash_scores": {
    "default": 500
  },
  "trash_description": "Size: Block size smaller than 400Mb",
  "custom_inf": "Does not work because SizeSpecification is not supported by recyclarr",
  "name": "Size: Block sizes lower 400mb - Sonarr",
  "includeCustomFormatWhenRenaming": false,
  "specifications": [
    {
      "name": "Size",
      "implementation": "SizeSpecification",
      "negate": false,
      "required": true,
      "fields": {
        "min": 0,
        "max": 0.4
      }
    }
  ]
}
EOF
log "Creating custom-size-between-0-1.json"
cat <<EOF > config/custom-size-between-0-1.json
{
  "trash_id": "custom-size-between-0-1",
  "trash_scores": {
    "default": 500
  },
  "trash_description": "Size: Prefer Size smaller than 1GB",
  "custom_inf": "Does not work because SizeSpecification is not supported by recyclarr",
  "name": "Size: Prefer between smaller than 1GB - Sonarr",
  "includeCustomFormatWhenRenaming": false,
  "specifications": [
    {
      "name": "Size",
      "implementation": "SizeSpecification",
      "negate": false,
      "required": true,
      "fields": {
        "min": 0.4,
        "max": 1.2
      }
    }
  ]
}
EOF
log "Creating config/custom-size-between-1-10.json"
cat <<EOF > config/custom-size-between-1-10.json
{
  "trash_id": "custom-size-between-1-10",
  "trash_scores": {
    "default": 500
  },
  "trash_description": "Size: Prefer Size between 1 and 10 GB",
  "custom_inf": "Does not work because SizeSpecification is not supported by recyclarr",
  "name": "Size: Prefer between 1GB and 10GB",
  "includeCustomFormatWhenRenaming": false,
  "specifications": [
    {
      "name": "Size",
      "implementation": "SizeSpecification",
      "negate": false,
      "required": true,
      "fields": {
        "min": 1,
        "max": 9
      }
    }
  ]
}
EOF
log "Creating config/custom-size-between-10-20.json"
cat <<EOF > config/custom-size-between-10-20.json
{
  "trash_id": "custom-size-between-10-20",
  "trash_scores": {
    "default": 500
  },
  "trash_description": "Size: Prefer Size between 10 and 20 GB",
  "custom_inf": "Does not work because SizeSpecification is not supported by recyclarr",
  "name": "Size: Prefer between 10GB and 20GB",
  "includeCustomFormatWhenRenaming": false,
  "specifications": [
    {
      "name": "Size",
      "implementation": "SizeSpecification",
      "negate": false,
      "required": true,
      "fields": {
        "min": 9,
        "max": 21
      }
    }
  ]
}
EOF
log "Creating config/custom-size-above-30.json" 
cat <<EOF > config/custom-size-above-30.json
{
  "trash_id": "custom-size-above-30",
  "trash_scores": {
    "default": -10000
  },
  "trash_description": "Size: Block sizes above 30 GB",
  "custom_inf": "Does not work because SizeSpecification is not supported by recyclarr",
  "name": "Size: Block More 40GB",
  "includeCustomFormatWhenRenaming": false,
  "specifications": [
    {
      "name": "Size",
      "implementation": "SizeSpecification",
      "negate": false,
      "required": true,
      "fields": {
        "min": 29,
        "max": 300
      }
    }
  ]
}
EOF


log "Creating Configarr Configuration file with presets for $QUALITY_NAME." 
cat <<EOF > config/config.yml

localCustomFormatsPath: /app/config/
localConfigTemplatesPath: /app/config/

# You can enable or disable
sonarrEnabled: $SONARR_ENA
radarrEnabled: $RADARR_ENA
whisparrEnabled: false
lidarrEnabled: $LIDARR_ENA

radarr:
  radar_profile01:
    base_url: $RADARR_URL
    api_key: $RADARR_API
    delete_old_custom_formats: $OVERWRITE
    replace_existing_custom_formats: $OVERWRITE

    quality_profiles:
      - name: $QUALITY_NAME
        reset_unmatched_scores:
          enabled: true
        upgrade:
          allowed: true
          until_quality: HQ_Download
          until_score: 1500 # Upgrade until
          min_format_score: 250 # Minimum increment for upgrade
        min_format_score: 500 # Minimum custom format needed to download
        quality_sort: top
        qualities:
          - name: HQ_Download
            qualities:
              - WEBDL-2160p
              - HDTV-2160p
              - WEBRip-2160p
              - WEBDL-1080p
              - WEBRip-1080p
              - HDTV-1080p
          - name: HQ_Bluray
            qualities:
              - Bluray-2160p
              - Bluray-1080p


    custom_formats:
      - trash_ids:
          # Most Wanted
          - cae4ca30163749b891686f95532519bd #AV1 Codec
          - bf7e73dd1d85b12cc527dc619761c840 #Pathe Thuis
          - 996e8ce50025e8b1e8fa95fcb28c4e5a #VideoLand
        assign_scores_to:
          - name: $QUALITY_NAME
            score: 2000

      - trash_ids:
          # Most Wanted
          - 5caaaa1c08c1742aa4342d8c4cc463f2 #Repack 3
          - 9de657fd3d327ecf144ec73dfe3a3e9a #Dutchgroups
          - 390455c22a9cac81a738f6cbad705c3c #x266 Codec
          - 496f355514737f7d83bf7aa4d24f8169 #ATMOS Sound
          - 2f22d89048b01681dde8afe203bf2e95 #DTSX Sound
          - 3cafb66171b47f226146a0770576870f #TrueHD Sound
          - dcf3ec6938fa32445f590a4da84256cd #DTS-HD MA Sound
          - 4d74ac4c4db0b64bff6ce0cffef99bf0 #UHD Tier 01
          - a58f517a70193f8e578056642178419d #UHD Tier 02
          - e71939fae578037e7aed3ee219bbe7c1 #UHD Tier 03
          - fb392fb0d61a010ae38e49ceaa24a1ef #UHD
          - custom-size-between-1-10 # Custom JSON between 1 and 10 Gb
        assign_scores_to:
          - name: $QUALITY_NAME
            score: 1250

      - trash_ids:
          # HQ Release Groups
          - c20f169ef63c5f40c2def54abaf4438e # WEB Tier 01
          - 403816d65392c79236dcb6dd591aeda4 # WEB Tier 02
          - af94e0fe497124d1f9ce732069ec8c3b # WEB Tier 03
          - 493b6d1dbec3c3364c59d7607f7e3405 # HDR
          - f700d29429c023a5734505e77daeaea7 # Dolby Vision
          - 820b09bb9acbfde9c35c71e0e565dad8 # 1080p
          - 73613461ac2cea99d52c4cd6e177ab82 # High FrameRate
          - ae43b294509409a6a13919dedd4764c4 # Repack 2
        assign_scores_to:
          - name: $QUALITY_NAME
            score: 500

      - trash_ids:
          # Streaming Services
          - b3b3a6ac74ecbd56bcdbefa4799fb9df # AMZN
          - 40e9380490e748672c2522eaaeb692f7 # ATVP
          - f6ff65b3f4b464a79dcc75950fe20382 # CRAV
          - 84272245b2988854bfb76a16e60baea5 # DSNP
          - 917d1f2c845b2b466036b0cc2d7c72a3 # FOD
          - 509e5f41146e278f9eab1ddaceb34515 # HBO
          - 5763d1b0ce84aff3b21038eea8e9b8ad # HMAX
          - 526d445d4c16214309f0fd2b3be18a89 # Hulu
          - 6185878161f1e2eef9cd0641a0d09eae # iP
          - 6a061313d22e51e0f25b7cd4dc065233 # MAX
          - 170b1d363bd8516fbf3a3eb05d4faff6 # NF
          - fbca986396c5e695ef7b2def3c755d01 # OViD
          - bf7e73dd1d85b12cc527dc619761c840 # Pathe
          - c9fd353f8f5f1baf56dc601c4cb29920 # PCOK
          - e36a0ba1bc902b26ee40818a1d59b8bd # PMTP
          - c2863d2a50c9acad1fb50e53ece60817 # STAN
          - f1b0bae9bc222dab32c1b38b5a7a1088 # TVer
          - 279bda7434fd9075786de274e6c3c202 # U-NEXT
          - b2be17d608fc88818940cd1833b0b24c # 720p
          - e7718d7a3ce595f289bfee26adc178f5 # Repack 1
          - custom-size-between-10-20 # Custom JSON between 10 and 20 Gb
        assign_scores_to:
          - name: $QUALITY_NAME
            score: 250

      - trash_ids:
          - 90a6f9a284dff5103f6346090e6280c8 #LQ
          - e204b80c87be9497a8a6eaff48f72905 #LQ Title
          - b8cd450cbfa689c0259a01d9e29ba3d6 #3D
          - bfd8eb01832d646a0a89c4deb46f8564 #Upscaled 
          - b6832f586342ef70d9c128d40c07b872 #Bad Dual Groups
          - ae9b7c9ebde1f3bd336a8cbd1ec4c5e5 #No-RLS Group
          - custom-size-above-30 # Custom JSON above 30Gb
          - custom-size-between-0-1 # Custom JSON below 1GB - Sonarr
          - custom-size-below-400mb # Custom JSON Block sizes below 400Mb
          - f845be10da4f442654c13e1f2c3d6cd5 #German 1
          - 6aad77771dabe9d3e9d7be86f310b867 #German DL
          - 86bc3115eb4e9873ac96904a4a68e19e #German 2
          - 0dc8aec3bd1c47cd6c40c46ecd27e846 #Not English
        assign_scores_to:
          - name: $QUALITY_NAME
            score: -10000

sonarr:
  sonar_profile01:
    base_url: $SONARR_URL
    api_key: $SONARR_API
    delete_old_custom_formats: $OVERWRITE
    replace_existing_custom_formats: $OVERWRITE

    quality_profiles:
      - name: $QUALITY_NAME
        reset_unmatched_scores:
          enabled: true
        upgrade:
          allowed: true
          until_quality: HQ_Download
          until_score: 1500 # Upgrade until
          min_format_score: 250 # Minimum increment for upgrade
        min_format_score: 500 # Minimum custom format needed to download
        quality_sort: top
        qualities:
          - name: HQ_Download
            qualities:
              - WEBDL-1080p
              - WEBRip-1080p
              - HDTV-1080p
              - WEBDL-2160p
              - HDTV-2160p
              - WEBRip-2160p
          - name: HQ_Bluray
            qualities:
              - Bluray-2160p
              - Bluray-1080p


    custom_formats:
      - trash_ids:
          # Most Wanted
          - 15a05bc7c1a36e2b57fd628f8977e2fc #AV1 Codec
          - b2b980877494b560443631eb1f473867 #NL Ziet
          - 5d2317d99af813b6529c7ebf01c83533 #VideoLand
        assign_scores_to:
          - name: $QUALITY_NAME
            score: 2000

      - trash_ids:
          # Most Wanted
          - 44e7c4de10ae50265753082e5dc76047 #Repack 3
          - 041d90b435ebd773271cea047a457a6a #x266 Codec
          - c429417a57ea8c41d57e6990a8b0033f # DTS MA
          - 1808e4b9cee74e064dfae3f1db99dbfe # True HD
          - 0d7824bb924701997f874e7ff7d4844a # True HD ATMOS
          - d6819cba26b1a6508138d25fb5e32293 # HD Tier 01
          - c2216b7b8aa545dc1ce8388c618f8d57 # HD Tier 02
          - custom-size-between-0-1 # Custom JSON below 1GB - Sonarr
        assign_scores_to:
          - name: $QUALITY_NAME
            score: 1250

      - trash_ids:
          # HQ Release Groups
          - e6258996055b9fbab7e9cb2f75819294 # WEB Tier 01
          - 58790d4e2fdcd9733aa7ae68ba2bb503 # WEB Tier 02
          - d84935abd3f8556dcd51d4f27e22d0a6 # WEB Tier 03
          - d0c516558625b04b363fa6c5c2c7cfd4 # WEB Scene
          - 505d871304820ba7106b693be6fe4a9e # HDR
          - 7c3a61a9c6cb04f52f1544be6d44a026 # Dolby Vision
          - 0c4b99df9206d2cfac3c05ab897dd62a # HDR10Plus
          - eb3d5cc0a2be0db205fb823640db6a3c # Repack 2
          - 1bef6c151fa35093015b0bfef18279e5 # 2160p
        assign_scores_to:
          - name: $QUALITY_NAME
            score: 500

      - trash_ids:
          # Streaming Services
          - d660701077794679fd59e8bdf4ce3a29 # AMZN
          - f67c9ca88f463a48346062e8ad07713f # ATVP
          - 77a7b25585c18af08f60b1547bb9b4fb # CC
          - 36b72f59f4ea20aad9316f475f2d9fbb # DCU
          - dc5f2bb0e0262155b5fedd0f6c5d2b55 # DSCP
          - 7a235133c87f7da4c8cccceca7e3c7a6 # HBO
          - a880d6abc21e7c16884f3ae393f84179 # HMAX
          - f6cce30f1733d5c8194222a7507909bb # Hulu
          - 0ac24a2a68a9700bcb7eeca8e5cd644c # iT
          - 81d1fbf600e2540cee87f3a23f9d3c1c # MAX
          - d34870697c9db575f17700212167be23 # NF
          - c67a75ae4a1715f2bb4d492755ba4195 # PMTP
          - dc503e2425126fa1d0a9ad6168c83b3f # BBC IP
          - 1656adc6d7bb2c8cca6acfb6592db421 # PCOK
          - ae58039e1319178e6be73caab5c42166 # SHO
          - 1efe8da11bfd74fbbcd4d8117ddb9213 # STAN
          - 9623c5c9cac8e939c1b9aedd32f640bf # SYFY
          - 89358767a60cc28783cdc3d0be9388a4 # DSNP
          - ec8fa7296b64e8cd390a1600981f3923 # Repack 1
          - fe4062eac43d4ea75955f8ae48adcf1e # STAR+
          - c30d2958827d1867c73318a5a2957eb1 # RED Youtube Premium
          - 290078c8b266272a5cc8e251b5e2eb0b # 1080p
          - custom-size-between-10-20 # Custom JSON between 10 and 20 Gb
        assign_scores_to:
          - name: $QUALITY_NAME
            score: 250

      - trash_ids:
          - e2315f990da2e2cbfc9fa5b7a6fcfe48 #LQ
          - e2315f990da2e2cbfc9fa5b7a6fcfe48 #LQ Title
          - 23297a736ca77c0fc8e70f8edd7ee56c #Upscaled 
          - 32b367365729d530ca1c124a0b180c64 #Bad Dual Groups
          - 82d40da2bc6923f41e14394075dd4b03 #No-RLS Group
          - custom-size-above-30 # Custom JSON above 30Gb
          - custom-size-between-10-20 # Custom JSON between 10 and 20 Gb
          - custom-size-below-400mb # Custom JSON Block sizes below 400Mb
        assign_scores_to:
          - name: $QUALITY_NAME
            score: -10000

EOF

# Run docker and apply new profiles
log "Applying Quality Profile $QUALITY_NAME and Custom Formats to RADARR($RADARR_URL) and SONARR($SONARR_URL)" 
docker run --rm -v ./config:/app/config ghcr.io/raydak-labs/configarr

log "End of Script" 
# End of the script