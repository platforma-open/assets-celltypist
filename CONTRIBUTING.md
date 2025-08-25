# Contributing to CellTypist Assets

This guide explains how to create and maintain CellTypist model assets for the Platforma Open project.

## Overview

CellTypist assets are organized by species and condition, with each model having its own package. The structure follows a consistent pattern:

```
assets-celltypist/
├── human-healthy/           # Human healthy tissue models
├── human-disease/          # Human disease models
├── mouse-healthy/          # Mouse healthy tissue models
├── catalogue/              # Catalogue of all models
└── scripts/                # Build and utility scripts
```

## Model Naming Convention

Models follow this naming pattern:
- `{Species}_{Condition}_{Tissue}`

Examples:
- `Human_healthy_ImmunePopulations`
- `Mouse_healthy_Brain`
- `Human_disease_COVID19_Blood`

## Creating New Model Assets

1. **Prepare Model Information**
   - Get the model name from [CellTypist Models](https://www.celltypist.org/models)
   - Note the model URL from the Download column
   - Determine the species and condition categories

2. **Create Model Directory**
   ```bash
   # Convert model name to directory structure
   species=$(echo "Human_healthy_ImmunePopulations" | cut -d'_' -f1)
   condition=$(echo "Human_healthy_ImmunePopulations" | cut -d'_' -f2)
   category=$(echo "${species}-${condition}" | tr '[:upper:]' '[:lower:]')
   
   mkdir -p "$category/Human_healthy_ImmunePopulations"
   ```

3. **Create package.json**
   ```json
   {
     "name": "@platforma-open/milaboratories.celltypist-assets.human-healthy-immunepopulations",
     "version": "1.0.0",
     "description": "CellTypist model for Human_healthy_ImmunePopulations",
     "scripts": {
       "cleanup": "rm -rf ./pkg-*.tgz && rm -rf ./build/ && rm -rf ./dist/",
       "build": "../../scripts/build-everything.sh ./modelFileUrls.json",
       "postbuild": "pl-pkg build && ([ -z \"${CI}\" ] || pl-pkg publish)"
     },
     "block-software": {
       "entrypoints": {
         "main": {
           "asset": {
             "type": "asset",
             "registry": "platforma-open",
             "root": "./indexed_model/Human_healthy_ImmunePopulations"
           }
         }
       }
     },
     "files": ["dist/"],
     "license": "UNLICENSED",
     "devDependencies": {
       "@platforma-sdk/package-builder": "catalog:"
     }
   }
   ```

4. **Create modelFileUrls.json**
   ```json
   {
     "Human_healthy_ImmunePopulations": {
       "model_name": "Immune_All_High",
       "model_url": "https://celltypist.cog.sanger.ac.uk/models/Pan_Immune_CellTypist/v2/Immune_All_High.pkl"
     }
   }
   ```

5. **Update Catalogue**
   - Add the model to the catalogue's package.json dependencies
   - Add the model to the catalogue's entrypoints
   - Update the CHANGELOG.md if needed

## Model Categories

### Human Healthy Models
- Immune Populations (High/Low resolution)
- Skin
- Vascular
- Prefrontal Cortex
- Middle Temporal Gyrus
- Hippocampus
- Breast
- Lung
- Heart
- Liver
- Endometrium
- Pancreatic Islet

### Human Disease Models
- Colorectal Cancer
- Idiopatic Pulmonary Fibrosis
- COVID19 Blood
- COVID19 Lung Blood

### Mouse Healthy Models
- Gut
- Olfactory Bulb
- Liver
- Brain

## Configuration Files

### .gitignore
The project uses a .gitignore file to exclude build artifacts and downloaded models:

```gitignore
downloads/
indexed_model/
build/
dist/
.turbo
node_modules/
pkg-*.tgz
pkg-*.zip
package.sw.json
```

Key exclusions:
- `downloads/` and `indexed_model/`: Downloaded model files
- `build/` and `dist/`: Build artifacts
- `.turbo`: Turborepo cache
- `node_modules/`: Dependencies
- `pkg-*.tgz` and `pkg-*.zip`: Package archives
- `package.sw.json`: Package lock file

### turbo.json
The project uses Turborepo for build orchestration. Here's the configuration:

```json
{
  "$schema": "https://turbo.build/schema.json",
  "globalDependencies": ["tsconfig.json"],
  "tasks": {
    "build": {
      "env": ["CI"],
      "inputs": ["$TURBO_DEFAULT$"],
      "outputs": ["./dist/**"],
      "dependsOn": ["^build"]
    },
    "upload-packages": {
      "dependsOn": ["build", "^upload-packages"]
    },
    "test": {
      "dependsOn": ["build"]
    }
  }
}
```

Key configuration points:
- `build`: Main build task that:
  - Depends on all workspace dependencies
  - Outputs to ./dist directory
  - Uses CI environment variables
- `upload-packages`: Package upload task that depends on build
- `test`: Test task that depends on build
- Global dependencies include tsconfig.json

## Build Process

1. **Local Development**
   ```bash
   cd assets-celltypist
   pnpm install
   pnpm build
   ```

2. **CI/CD Pipeline**
   - The build process is handled by the CI/CD pipeline
   - Each model is built independently
   - The catalogue is built after all models are built

## CI/CD and Large Assets

For models with large file sizes (>100MB), you need to define pre-calculated tasks in the CI pipeline to avoid timeout issues. This is similar to how it's done in the assets-genome project.

1. **Update CI Configuration**
   Add the following configuration to your `.github/workflows/build.yaml`:

   ```yaml
   name: Build, Test and Release Assets
   on:
     merge_group:
     pull_request:
       types: [opened, reopened, synchronize]
       branches:
         - 'main'
     push:
       branches:
         - 'main'
     workflow_dispatch: {}
   jobs:
     init:
       runs-on: ubuntu-latest
       steps:
         - uses: milaboratory/github-ci/actions/context/init@v4
           with:
             version-canonize: false
             branch-versioning: main
     run:
       needs:
         - init
       uses: milaboratory/github-ci/.github/workflows/node-simple-pnpm.yaml@v4
       with:
         app-name: 'Assets: CellTypist'
         app-name-slug: 'assets-celltypist'
         notify-telegram: true
         node-version: '20.x'
         build-script-name: 'build'
         pnpm-recursive-build: false
         test: false
         test-script-name: 'test'
         pnpm-recursive-tests: false
         team-id: 'ciplopen'

         publish-to-public: 'true'
         package-path: 'catalogue'
         create-tag: 'true'

         gha-runner-label: 'ubuntu-2xlarge-amd64'
         aws-login-duration: 43199
         pre-calculated: true
         pre-calculated-task-list: |
           [
               { "step": "@platforma-open/milaboratories.celltypist-assets.human-healthy-immunepopulations" },
               { "step": "@platforma-open/milaboratories.celltypist-assets.human-healthy-immunesubpopulations" },
               { "step": "@platforma-open/milaboratories.celltypist-assets.human-healthy-skin" },
               { "step": "@platforma-open/milaboratories.celltypist-assets.human-healthy-vascular" },
               { "step": "@platforma-open/milaboratories.celltypist-assets.human-healthy-prefrontalcortex" },
               { "step": "@platforma-open/milaboratories.celltypist-assets.human-healthy-middletemporalgyrus" },
               { "step": "@platforma-open/milaboratories.celltypist-assets.human-healthy-hippocampus" },
               { "step": "@platforma-open/milaboratories.celltypist-assets.human-healthy-breast" },
               { "step": "@platforma-open/milaboratories.celltypist-assets.human-healthy-lung" },
               { "step": "@platforma-open/milaboratories.celltypist-assets.human-healthy-heart" },
               { "step": "@platforma-open/milaboratories.celltypist-assets.human-healthy-liver" },
               { "step": "@platforma-open/milaboratories.celltypist-assets.human-healthy-endometrium" },
               { "step": "@platforma-open/milaboratories.celltypist-assets.human-healthy-pancreaticislet" },
               { "step": "@platforma-open/milaboratories.celltypist-assets.human-disease-colorectalcancer" },
               { "step": "@platforma-open/milaboratories.celltypist-assets.human-disease-idiopaticpulmonaryfibrosis" },
               { "step": "@platforma-open/milaboratories.celltypist-assets.human-disease-covid19-blood" },
               { "step": "@platforma-open/milaboratories.celltypist-assets.human-disease-covid19-lungblood" },
               { "step": "@platforma-open/milaboratories.celltypist-assets.mouse-healthy-gut" },
               { "step": "@platforma-open/milaboratories.celltypist-assets.mouse-healthy-olfactorybulb" },
               { "step": "@platforma-open/milaboratories.celltypist-assets.mouse-healthy-liver" },
               { "step": "@platforma-open/milaboratories.celltypist-assets.mouse-healthy-brain" }
           ]

         npmrc-config: |
           {
             "registries": {
               "https://registry.npmjs.org/": {
                 "scopes": ["milaboratories", "platforma-sdk", "platforma-open"],
                 "tokenVar": "NPMJS_TOKEN"
               }
             }
           }
       secrets:
         env: |
           { "PL_LICENSE": ${{ toJSON(secrets.MI_LICENSE) }},
             "MI_LICENSE": ${{ toJSON(secrets.MI_LICENSE) }},
             "NPMJS_TOKEN": ${{ toJSON(secrets.NPMJS_TOKEN) }},
             "PL_CI_TEST_USER": ${{ toJSON(secrets.PL_CI_TEST_USER) }},
             "PL_CI_TEST_PASSWORD": ${{ toJSON(secrets.PL_CI_TEST_PASSWORD) }},

             "AWS_CI_IAM_MONOREPO_SIMPLE_ROLE": ${{ toJSON(secrets.AWS_CI_IAM_MONOREPO_SIMPLE_ROLE) }},
             "AWS_CI_TURBOREPO_S3_BUCKET": ${{ toJSON(secrets.AWS_CI_TURBOREPO_US_S3_BUCKET) }},
             "PL_REGISTRY_PLATFORMA_OPEN_UPLOAD_URL": ${{ toJSON(secrets.PL_REGISTRY_PLOPEN_UPLOAD_URL) }} }

         TELEGRAM_NOTIFICATION_TARGET: ${{ secrets.TG_CHANNEL_MIBUILDS }}
         TELEGRAM_API_TOKEN: ${{ secrets.TG_CI_BOT_TOKEN }}

         GH_ZEN_APP_ID: ${{ secrets.GH_ZEN_APP_ID }}
         GH_ZEN_APP_PRIVATE_KEY: ${{ secrets.GH_ZEN_APP_PRIVATE_KEY }}
   ```

2. **Key Configuration Points**
   - Set `pre-calculated: true` to enable pre-calculated tasks
   - Add all model packages to `pre-calculated-task-list` in kebab-case format
   - Use `ubuntu-2xlarge-amd64` runner for large file downloads
   - Set appropriate `aws-login-duration` for large file operations

3. **Adding New Models**
   When adding a new model:
   1. Convert the model name to kebab-case
   2. Add it to the `pre-calculated-task-list` array
   3. Ensure the model's package.json name matches the task name

## Adding New Models

1. Add the model to the `MODELS` list in `create-assets-celltypist.sh`
2. Run the script to generate the model structure
3. Verify the generated files
4. Test the build process
5. Update documentation if needed

## Troubleshooting

Common issues and solutions:

1. **Build Script Not Found**
   - Ensure you're running the build command from the correct directory
   - Check that the scripts directory exists and contains build-everything.sh

2. **Model Download Fails**
   - Verify the model URL is correct
   - Check network connectivity
   - Ensure the model is publicly available

3. **Package Name Conflicts**
   - Ensure the package name follows the naming convention
   - Check for duplicate entries in the catalogue

4. **CI Timeout Issues**
   - For large models, ensure pre-calculated tasks are properly configured
   - Check timeout settings in CI configuration
   - Verify download URLs are accessible

## Best Practices

1. **Model Organization**
   - Keep models organized by species and condition
   - Use consistent naming conventions
   - Document any special requirements or dependencies

2. **Version Control**
   - Commit changes in logical groups
   - Update CHANGELOG.md for significant changes
   - Include relevant documentation updates

3. **Testing**
   - Test the build process locally
   - Verify model downloads
   - Check catalogue integration

4. **CI/CD Considerations**
   - For large models, always use pre-calculated tasks
   - Set appropriate timeouts for downloads
   - Document any special CI requirements