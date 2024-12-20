# This is the Official CI/CD for Blazium Engine
## Note: All Documentation is just thrown in here cause I was yelled at by Dragos......
### If you think it could be better, make a PR god damnit.

Actions below are all things needed for the CI/CD to work.


# Github Actions

## Blazium Cerebro Build (Completed) - GitHub Action

This GitHub Action enables seamless integration with the **Blazium Engine**'s internal service, **Cerebro**, to update the state of a completed build. It simplifies notifying Cerebro about finalized artifacts, their CDN location, and associated metadata, ensuring smooth updates to your Blazium-powered projects.

### Features:
- Sends a POST request to update build state in Cerebro.
- Authenticates via a secure key (`cerebro_auth`).
- Handles artifact metadata including `file_url`, `version`, and `run_id`.
- Validates the response from Cerebro and logs success or failure details.

### Inputs:
- **`name`** (required): The artifact name.
- **`run_id`** (required): Identifier for the entire run.
- **`file_url`** (required): URL pointing to the artifact on a CDN.
- **`version`** (required): Version of the project corresponding to the artifact.
- **`cerebro_url`** (required): Full API endpoint for sending updates.
- **`cerebro_auth`** (required): Authorization key for accessing Cerebro.

### Usage:
```yaml
jobs:
  update-cerebro:
    runs-on: ubuntu-latest
    steps:
      - name: Update Cerebro Build State
        uses: your-org/your-repo/.github/actions/blazium-cerebro-build
        with:
          name: "my-artifact"
          run_id: "12345"
          file_url: "https://cdn.example.com/artifacts/my-artifact.zip"
          version: "1.0.0"
          cerebro_url: "https://cerebro.blazium.internal"
          cerebro_auth: "${{ secrets.CEREBRO_AUTH_KEY }}"
```


## Blazium Cerebro Deploy - GitHub Action

The **Blazium Cerebro Deploy** GitHub Action integrates with **Cerebro**, the internal service of the Blazium Engine, to trigger deployment updates. This action enables developers to initiate deployments for specific components with a designated deployment type (e.g., nightly builds) directly from their CI/CD pipelines.

### Features:
- Sends a POST request to Cerebro to trigger a deployment.
- Supports deployment customization with `name` and `type` inputs.
- Authenticates using a secure key (`cerebro_auth`) for access control.
- Validates the response to confirm successful deployment and logs detailed results.

### Inputs:
- **`name`** (required): Specifies the component or service to deploy.
- **`type`** (required): Defines the deployment type (e.g., `nightly`, `release`, etc.).
- **`cerebro_url`** (required): Full API endpoint for sending deployment commands.
- **`cerebro_auth`** (required): Authorization key to access Cerebro.

### Usage:
```yaml
jobs:
  deploy-cerebro:
    runs-on: ubuntu-latest
    steps:
      - name: Trigger Cerebro Deployment
        uses: your-org/your-repo/.github/actions/blazium-cerebro-deploy
        with:
          name: "my-service"
          type: "nightly"
          cerebro_url: "https://cerebro.blazium.internal"
          cerebro_auth: "${{ secrets.CEREBRO_AUTH_KEY }}"
```

## Blazium Cerebro Get Run Build Data - GitHub Action

The **Blazium Cerebro Get Run Build Data** GitHub Action integrates with **Cerebro**, the internal service of the Blazium Engine, to fetch build data for a specific run. This action retrieves detailed information about a deployment or setup build, downloads the associated artifact file if available, and provides the full file path for further processing.

### Features:
- Fetches build data for a specified run and build name.
- Validates the build completion status and artifact availability.
- Downloads the artifact to a specified folder and returns the full file path.
- Outputs the build data object for use in subsequent steps.

### Inputs:
- **`name`** (required): The name of the build to retrieve.
- **`cerebro_url`** (required): The base URL of the Cerebro server.
- **`cerebro_auth`** (required): Authorization key for accessing Cerebro.
- **`run_id`** (required): The ID of the run to query.
- **`folder`** (required): Folder where the downloaded file will be saved.

### Outputs:
- **`build_data`**: The build data object retrieved from Cerebro.
- **`file_path`**: The full path to the downloaded artifact file.

### Usage:
```yaml
jobs:
  fetch-build-data:
    runs-on: ubuntu-latest
    steps:
      - name: Get Run Build Data from Cerebro
        uses: your-org/your-repo/.github/actions/blazium-cerebro-get-run-build-data
        with:
          name: "my-build"
          cerebro_url: "https://cerebro.blazium.internal"
          cerebro_auth: "${{ secrets.CEREBRO_AUTH_KEY }}"
          run_id: "12345"
          folder: "/workspace/builds"
```

## Blazium Cerebro Get Multiple Run Build Data - GitHub Action

The **Blazium Cerebro Get Multiple Run Build Data** GitHub Action connects with **Cerebro**, the internal service for the Blazium Engine, to retrieve build data for multiple specified names within a given run. It automates the process of fetching build information, downloading associated files, and returning the file paths for further use in your CI/CD pipeline.

### Features:
- Processes multiple build names specified in a YAML-formatted array.
- Fetches build data for each name and verifies completion status.
- Downloads available artifact files and saves them in a specified folder.
- Outputs a list of the full paths to the successfully downloaded files.

### Inputs:
- **`names`** (required): A YAML-formatted array of build names, each on a new line.
- **`cerebro_url`** (required): The base URL of the Cerebro server.
- **`cerebro_auth`** (required): Authorization key to access Cerebro.
- **`run_id`** (required): The ID of the run to query.
- **`folder`** (required): Folder where downloaded files will be saved.

### Outputs:
- **`downloaded_files`**: A JSON array of the full paths to the downloaded files.

### Usage:
```yaml
jobs:
  fetch-multiple-builds:
    runs-on: ubuntu-latest
    steps:
      - name: Get Multiple Run Build Data
        uses: your-org/your-repo/.github/actions/blazium-cerebro-get-multiple-run-build-data
        with:
          names: |
            build-one
            build-two
            build-three
          cerebro_url: "https://cerebro.blazium.internal"
          cerebro_auth: "${{ secrets.CEREBRO_AUTH_KEY }}"
          run_id: "12345"
          folder: "/workspace/builds"
```

## Blazium Cerebro Build (Failed) - GitHub Action

The **Blazium Cerebro Build (Failed)** GitHub Action integrates with **Cerebro**, the internal service for the Blazium Engine, to update the state of a failed build. This action provides a streamlined way to notify Cerebro when a build fails, ensuring accurate tracking of build states for enhanced debugging and monitoring.

### Features:
- Sends a POST request to update the state of a failed build in Cerebro.
- Authenticates using a secure authorization key (`cerebro_auth`).
- Logs detailed success or failure messages in the GitHub Action summary.

### Inputs:
- **`name`** (required): The name of the artifact associated with the failed build.
- **`run_id`** (required): The identifier for the entire run.
- **`cerebro_url`** (required): The full API endpoint to send the update.
- **`cerebro_auth`** (required): Authorization key to access Cerebro.

### Usage:
```yaml
jobs:
  report-failed-build:
    runs-on: ubuntu-latest
    steps:
      - name: Notify Cerebro of Build Failure
        uses: your-org/your-repo/.github/actions/blazium-cerebro-build-failed
        with:
          name: "my-artifact"
          run_id: "12345"
          cerebro_url: "https://cerebro.blazium.internal"
          cerebro_auth: "${{ secrets.CEREBRO_AUTH_KEY }}"
```

## Blazium Cerebro Get Run Build Data - GitHub Action

The **Blazium Cerebro Get Run Build Data** GitHub Action allows seamless integration with **Cerebro**, the internal service of the Blazium Engine, to fetch build data for a specific run after deployment or setup completion. This action retrieves detailed information about a build, enabling enhanced tracking and further processing within your CI/CD pipeline.

### Features:
- Sends a GET request to Cerebro to fetch build data for a specified run and build name.
- Authenticates securely with a provided authorization key (`cerebro_auth`).
- Outputs the build data object for use in subsequent workflow steps.
- Logs detailed information about the process, including success or failure states.

### Inputs:
- **`name`** (required): The name of the build to retrieve.
- **`cerebro_url`** (required): The base URL of the Cerebro server.
- **`cerebro_auth`** (required): Authorization key to access Cerebro.
- **`run_id`** (required): The ID of the run to query.

### Outputs:
- **`build_data`**: The build data object retrieved from Cerebro.

### Usage:
```yaml
jobs:
  fetch-build-data:
    runs-on: ubuntu-latest
    steps:
      - name: Get Run Build Data from Cerebro
        uses: your-org/your-repo/.github/actions/blazium-cerebro-get-run-build-data
        with:
          name: "my-build"
          cerebro_url: "https://cerebro.blazium.internal"
          cerebro_auth: "${{ secrets.CEREBRO_AUTH_KEY }}"
          run_id: "12345"
```


## Blazium Cerebro Build (Started) - GitHub Action

The **Blazium Cerebro Build (Started)** GitHub Action integrates with **Cerebro**, the internal service for the Blazium Engine, to notify and update the state of a build at the start of the process. This action ensures that critical metadata about the build is sent to Cerebro, enabling proper tracking and management of ongoing builds.

### Features:
- Sends a POST request to update Cerebro with details about the build's state and metadata.
- Supports various inputs such as build type, deployment type, branch, operating system, checksum, and production status.
- Logs success or failure of the update in the GitHub Action summary for easy debugging.

### Inputs:
- **`name`** (required): The name of the artifact being built.
- **`run_id`** (required): The identifier for the entire run.
- **`build_type`** (required): Specifies the build type (e.g., `Template` or `Editor`).
- **`mono`** (required): Indicates if Mono is enabled (`true`/`false`).
- **`deploy_type`** (required): Specifies the type of deployment (`nightly`, `prerelease`, or `release`).
- **`branch`** (required): The name of the branch being built.
- **`build_os`** (required): The operating system for the build (e.g., `Windows`).
- **`file_url`** (optional): URL to the build file, if available.
- **`checksum`** (required): The SHA-256 checksum of the file.
- **`production`** (required): Indicates if the build is for production (`true`/`false`).
- **`version`** (optional): The version of the build.
- **`cerebro_url`** (required): The full API endpoint to send the update.
- **`cerebro_auth`** (required): Authorization key for accessing Cerebro.

### Usage:
```yaml
jobs:
  start-build:
    runs-on: ubuntu-latest
    steps:
      - name: Notify Cerebro of Build Start
        uses: your-org/your-repo/.github/actions/blazium-cerebro-build-started
        with:
          name: "my-artifact"
          run_id: "12345"
          build_type: "Editor"
          mono: "true"
          deploy_type: "release"
          branch: "main"
          build_os: "Windows"
          checksum: "abcd1234efgh5678ijkl9012mnop3456qrst7890uvwx1234yzab5678cdef9012"
          production: "false"
          cerebro_url: "https://cerebro.blazium.internal"
          cerebro_auth: "${{ secrets.CEREBRO_AUTH_KEY }}"
```

## Generate SHA-256 Checksums - GitHub Action

The **Generate SHA-256 Checksums** GitHub Action automates the computation of SHA-256 checksums for all files in a specified directory and outputs the results to a `checksum.txt` file. This action is useful for validating file integrity, ensuring reproducibility, and enhancing security workflows in your CI/CD pipelines.

### Features:
- Computes SHA-256 checksums for each file in the specified directory.
- Outputs all checksums and file names into a `checksum.txt` file within the same directory.
- Provides the path to the generated checksum file as an output for downstream workflow steps.

### Inputs:
- **`directory`** (required): The directory containing the files to process.

### Outputs:
- **`checksum_file`**: The path to the generated `checksum.txt` file.

### Usage:
```yaml
jobs:
  generate-checksums:
    runs-on: ubuntu-latest
    steps:
      - name: Generate SHA-256 Checksums
        uses: your-org/your-repo/.github/actions/generate-sha256-checksums
        with:
          directory: "./build/artifacts"
```

## Parse version.py - GitHub Action

The **Parse version.py** GitHub Action extracts version details from a specified `version.py` file, making it easy to retrieve key version information for use in your CI/CD workflows. This action parses variables such as `external_major`, `external_minor`, `external_patch`, `external_status`, and `external_sha`, and outputs their values for downstream processing.

### Features:
- Validates the existence of the `version.py` file.
- Extracts major, minor, patch, status, and SHA version details from the file.
- Outputs parsed values for use in subsequent workflow steps.
- Logs extracted values for visibility and debugging.

### Inputs:
- **`file_path`** (required): Path to the `version.py` file to be parsed.

### Outputs:
- **`external_major`**: The major version extracted from `version.py`.
- **`external_minor`**: The minor version extracted from `version.py`.
- **`external_patch`**: The patch version extracted from `version.py`.
- **`external_status`**: The status extracted from `version.py`.
- **`external_sha`**: The SHA extracted from `version.py`.

### Usage:
```yaml
jobs:
  parse-version:
    runs-on: ubuntu-latest
    steps:
      - name: Parse version.py
        uses: your-org/your-repo/.github/actions/parse-version-py
        with:
          file_path: "./src/version.py"
```

## Rename and Copy Files Action - GitHub Action

The **Rename and Copy Files Action** automates the process of copying and renaming files from a specified input directory to an output directory based on user-provided arrays of subdirectory names, old filenames, and new filenames. This action ensures efficient file management and renaming, simplifying workflows that require dynamic file handling.

### Features:
- Validates input directories, files, and parameter arrays.
- Copies files from `input_dir` to `output_dir` while renaming them based on the provided arrays.
- Ensures all specified directories and files exist, logging errors for missing items.
- Outputs a list of paths to the copied and renamed files for further workflow integration.

### Inputs:
- **`input_dir`** (required): The directory containing the original files.
- **`output_dir`** (required): The directory where the files will be copied and renamed.
- **`names`** (required): A YAML-formatted array of subdirectory names within `input_dir`.
- **`filename_old`** (required): A YAML-formatted array of old filenames to copy.
- **`filename_new`** (required): A YAML-formatted array of new filenames for the copied files.

### Outputs:
- **`copied_files`**: A JSON array of paths to the copied and renamed files.

### Usage:
```yaml
jobs:
  rename-and-copy:
    runs-on: ubuntu-latest
    steps:
      - name: Rename and Copy Files
        uses: your-org/your-repo/.github/actions/rename-and-copy-files
        with:
          input_dir: "./source_files"
          output_dir: "./renamed_files"
          names: |
            subdir1
            subdir2
          filename_old: |
            file1.txt
            file2.txt
          filename_new: |
            renamed1.txt
            renamed2.txt
```

## Upload Files to DigitalOcean Spaces - GitHub Action

The **Upload Files to DigitalOcean Spaces** GitHub Action enables seamless uploading of multiple files to a specified DigitalOcean Space. By leveraging a YAML array input, this action simplifies the management of file uploads, including specifying access control and storage type, making it ideal for integrating file management into CI/CD workflows.

### Features:
- Uploads multiple files to a specified DigitalOcean Space using paths relative to the repository root.
- Supports custom configurations for storage type (`STANDARD`, etc.) and Access-Control List (e.g., `public-read`, `private`).
- Allows specifying a target path within the Space for organized file management.
- Validates input parameters and logs detailed information for each upload.

### Inputs:
- **`files`** (required): YAML array of file paths relative to the repository root to be uploaded.
- **`space_name`** (required): Name of the DigitalOcean Space.
- **`space_region`** (required): Region of the DigitalOcean Space.
- **`storage_type`** (optional, default: `STANDARD`): Storage class for the files.
- **`access_key`** (required): Access key for DigitalOcean Spaces.
- **`secret_key`** (required): Secret key for DigitalOcean Spaces.
- **`space_path`** (required): Target path within the Space for file uploads.
- **`acl`** (optional, default: `public-read`): Access control settings for the uploaded files.

### Usage:
```yaml
jobs:
  upload-to-spaces:
    runs-on: ubuntu-latest
    steps:
      - name: Upload Files to DigitalOcean Spaces
        uses: your-org/your-repo/.github/actions/upload-files-to-digitalocean-spaces
        with:
          files: |
            - "build/artifact1.zip"
            - "build/artifact2.zip"
          space_name: "my-space"
          space_region: "nyc3"
          storage_type: "STANDARD"
          access_key: "${{ secrets.SPACES_ACCESS_KEY }}"
          secret_key: "${{ secrets.SPACES_SECRET_KEY }}"
          space_path: "uploads/artifacts"
          acl: "public-read"
```

## Rename and Zip Folders Action - GitHub Action

The **Rename and Zip Folders Action** automates the process of renaming folders within a specified directory, compressing them into ZIP files, and saving the resulting ZIP archives to a designated output directory. This action is ideal for managing and packaging directories for deployment or archival purposes.

### Features:
- Renames folders in `input_dir` based on a YAML array of new names.
- Compresses renamed folders into ZIP files.
- Places the ZIP files in the specified `output_dir`.
- Validates input parameters and logs detailed progress and errors.

### Inputs:
- **`input_dir`** (required): The directory containing the original folders.
- **`output_dir`** (required): The directory where the ZIP files will be saved.
- **`names`** (required): A YAML array of folder names in `input_dir` to be processed.
- **`filename_new`** (required): A YAML array of new folder names for renaming.

### Outputs:
- **`zipped_files`**: A JSON array of paths to the generated ZIP files.

### Usage:
```yaml
jobs:
  rename-and-zip:
    runs-on: ubuntu-latest
    steps:
      - name: Rename and Zip Folders
        uses: your-org/your-repo/.github/actions/rename-and-zip-folders
        with:
          input_dir: "./source_folders"
          output_dir: "./zipped_folders"
          names: |
            folder1
            folder2
          filename_new: |
            renamed_folder1
            renamed_folder2
```

## Rename Files in Place Action - GitHub Action

The **Rename Files in Place Action** automates renaming files within their original directories based on user-provided arrays of directory names, old filenames, and new filenames. This action ensures efficient file management, enabling seamless renaming without moving files to a new location.

### Features:
- Renames files within their existing directories using specified old and new filenames.
- Validates input parameters to ensure all directories and files exist and that input arrays have matching lengths.
- Outputs a list of paths to the successfully renamed files for further workflow integration.
- Logs detailed information, including errors and directory contents, before and after renaming.

### Inputs:
- **`input_dir`** (required): The base directory containing the target files.
- **`names`** (required): A YAML array of subdirectory names within `input_dir` to process.
- **`filename_old`** (required): A YAML array of original filenames to rename.
- **`filename_new`** (required): A YAML array of new filenames for the renamed files.

### Outputs:
- **`renamed_files`**: A JSON array of paths to the renamed files.

### Usage:
```yaml
jobs:
  rename-files:
    runs-on: ubuntu-latest
    steps:
      - name: Rename Files in Place
        uses: your-org/your-repo/.github/actions/rename-files-in-place
        with:
          input_dir: "./source_files"
          names: |
            folder1
            folder2
          filename_old: |
            oldfile1.txt
            oldfile2.txt
          filename_new: |
            newfile1.txt
            newfile2.txt
```

## Uncompress Files Action - GitHub Action

The **Uncompress Files Action** automates the extraction of multiple `.tar.gz` files, organizing the uncompressed contents into a specified output directory. This action is designed to handle batch operations using a YAML-formatted array of file names, ensuring flexibility and control over how files are extracted.

### Features:
- Uncompresses `.tar.gz` files specified in a YAML array of names.
- Supports uncompressing files directly into the output directory or into individual subfolders.
- Validates the existence of input files and directories, logging errors for missing items.
- Lists the contents of uncompressed folders in the GitHub Action summary for easy verification.
- Outputs an array of paths to the uncompressed folders.

### Inputs:
- **`names`** (required): A YAML array of names corresponding to `.tar.gz` files (without the `.tar.gz` extension).
- **`input_dir`** (required): The directory where the `.tar.gz` files are located.
- **`output_dir`** (required): The directory where the files will be uncompressed.
- **`without_folder`** (optional, default: `false`): If `true`, extracts contents directly into the output directory without creating subfolders.

### Outputs:
- **`uncompressed_folders`**: A JSON array of paths to the directories containing the uncompressed contents.

### Usage:
```yaml
jobs:
  uncompress-files:
    runs-on: ubuntu-latest
    steps:
      - name: Uncompress Files
        uses: your-org/your-repo/.github/actions/uncompress-files
        with:
          names: |
            file1
            file2
          input_dir: "./compressed_files"
          output_dir: "./uncompressed_files"
          without_folder: "false"
```

## Set version.py - GitHub Action

The **Set version.py** GitHub Action automates updating a `version.py` file with new version details, ensuring accurate and consistent version management in your projects. This action is designed to overwrite specific variables in the file, including major, minor, patch, status, and SHA values, based on user-provided inputs.

### Features:
- Validates the existence of the specified `version.py` file.
- Updates the `version.py` file with new version information, including major, minor, patch, status, and SHA.
- Ensures the updates are correctly applied and logs the results for verification.
- Provides cross-platform compatibility for file editing.

### Inputs:
- **`file_path`** (required): Path to the `version.py` file to be updated.
- **`external_major`** (required): Major version to set.
- **`external_minor`** (required): Minor version to set.
- **`external_patch`** (required): Patch version to set.
- **`external_status`** (required): Status to set (e.g., `nightly`, `stable`).
- **`external_sha`** (required): SHA value to set.

### Usage:
```yaml
jobs:
  update-version:
    runs-on: ubuntu-latest
    steps:
      - name: Update version.py
        uses: your-org/your-repo/.github/actions/set-version-py
        with:
          file_path: "./src/version.py"
          external_major: "1"
          external_minor: "2"
          external_patch: "3"
          external_status: "stable"
          external_sha: "abc123def456gh789"
```

## Uncompress File Action - GitHub Action

The **Uncompress File Action** simplifies the process of extracting a `.tar.gz` file and organizing its contents into a specified or default directory. Designed for ease of use, this action validates the file path, prepares a target folder, uncompresses the file, and lists the extracted contents, making it ideal for streamlining workflows that involve compressed files.

### Features:
- Uncompresses a `.tar.gz` file to a specified or default directory.
- Automatically creates the target folder based on the file name if not specified.
- Validates the input file path and ensures proper directory structure.
- Logs detailed information about the process, including the uncompressed contents.

### Inputs:
- **`file_path`** (required): The full path to the `.tar.gz` file to be uncompressed.
- **`output_dir`** (optional): The directory where the file will be uncompressed. Defaults to a `downloads` folder in the GitHub workspace.

### Outputs:
- **`target_folder`**: The path to the folder where the file contents are extracted.

### Usage:
```yaml
jobs:
  uncompress-file:
    runs-on: ubuntu-latest
    steps:
      - name: Uncompress File
        uses: your-org/your-repo/.github/actions/uncompress-file
        with:
          file_path: "./compressed_files/my-archive.tar.gz"
          output_dir: "./extracted_files"
```

## Do we Compile? or do we Skip? - GitHub Action

The **Do we Compile? or do we Skip?** GitHub Action checks the version of a build on the CDN to determine whether to proceed with compilation or skip it. By comparing a provided SHA with the current `build.sha` file on the CDN, this action helps streamline CI/CD workflows by avoiding redundant builds when versions match.

### Features:
- Dynamically constructs the CDN URL based on deployment and build type, with optional template-specific paths.
- Validates if the `build.sha` file exists on the server.
- Downloads and compares the `build.sha` from the CDN with a user-provided SHA.
- Outputs a boolean value (`true` or `false`) indicating whether to compile or skip.

### Inputs:
- **`base_url`** (optional, default: `https://cdn.blazium.app`): Base URL for the CDN.
- **`deploy_type`** (required): Folder name representing the placement on the CDN (e.g., `nightly` or `release`).
- **`build_type`** (required): Build type (e.g., `template`, `editor`).
- **`build_sha`** (required): The SHA to compare against.
- **`is_template`** (optional, default: `false`): Indicates if the build is a template.

### Outputs:
- **`should_compile`**: Boolean output indicating whether to compile (`true`) or skip (`false`).

### Usage:
```yaml
jobs:
  version-check:
    runs-on: ubuntu-latest
    steps:
      - name: Check Version on CDN
        uses: your-org/your-repo/.github/actions/should-we-compile
        with:
          base_url: "https://cdn.blazium.app"
          deploy_type: "nightly"
          build_type: "editor"
          build_sha: "abc123def456gh789"
          is_template: "false"
```

## Parse Changelog Version - GitHub Action

The **Parse Changelog Version** GitHub Action extracts version information from a `changelog.json` file and outputs the version components (major, minor, patch) along with a combined version string. This action is ideal for workflows that require precise versioning information to automate releases, updates, or documentation processes.

### Features:
- Validates the existence of a `changelog.json` file at the specified path.
- Extracts the `major`, `minor`, and `patch` version components using `jq`.
- Combines the extracted version components into a single version string (`X.X.X`).
- Outputs the individual version components and the combined string for use in subsequent workflow steps.

### Inputs:
- **`file_path`** (required): Path to the `changelog.json` file containing version information.

### Outputs:
- **`version_string`**: The combined version string in the format `X.X.X`.
- **`major`**: The major version component.
- **`minor`**: The minor version component.
- **`patch`**: The patch version component.

### Usage:
```yaml
jobs:
  parse-changelog:
    runs-on: ubuntu-latest
    steps:
      - name: Parse Version from changelog.json
        uses: your-org/your-repo/.github/actions/parse-changelog-version
        with:
          file_path: "./changelog.json"
```
