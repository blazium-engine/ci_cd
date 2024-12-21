# This is the Official CI/CD for Blazium Engine

Actions below are all things needed for the CI/CD to work.

# CI/CD Workflows

## Blazium Engine Runner Workflow - GitHub Action

This GitHub Action, **Blazium Engine Runner Workflow**, orchestrates builds, deployments, and cleanups for the Blazium Engine across multiple operating systems and configurations. It triggers jobs based on a custom payload, enabling tailored workflows for nightly, template, or editor builds, with support for dynamic branching, versioning, and deployment management.

### Features:
- **Multi-Platform Support**: Handles builds for Linux, macOS, Windows, Android, iOS, Web, and Mono Glue configurations.
- **Dynamic Version Management**: Extracts and manages version details from `version.py` and `changelog.json`.
- **Concurrent Job Management**: Ensures efficient job execution with concurrency groups.
- **Custom Payload Triggering**: Uses a repository dispatch event with client payload for tailored job execution.
- **Full Lifecycle Management**: Includes static checks, builds, deployments, and cleanup.

### Trigger Payload:
Example payload to trigger the workflow:
```json
{
  "production": false,
  "type": "nightly",
  "branch": "blazium-dev",
  "build_type": ["templates", "editors"],
  "force": false,
  "build": ["linux", "monoglue", "ios", "macos", "android", "web", "windows"],
  "deploy": ["templates", "editors"]
}
```

### Jobs:
1. **Get Latest SHA & Base Version**: Fetches the latest commit SHA, parses version details, and generates a changelog.
2. **Static Checks**: Runs static checks to ensure code quality.
3. **Build Jobs**: Executes platform-specific builds for all selected targets:
   - 🌐 **Web**
   - 🐧 **Linux**
   - 🍎 **macOS**
   - 🏁 **Windows**
   - 🤖 **Android**
   - 🍏 **iOS**
   - **Mono Glue**
4. **Deployment**: Deploys all successful builds to their respective targets.
5. **Cleanup**: Ensures clean termination and resource cleanup in case of failures or cancellations.

### Usage:
To trigger this workflow, send a repository dispatch event with the required payload:
```bash
curl -X POST -H "Accept: application/vnd.github.everest-preview+json" \
-H "Authorization: token <YOUR_PERSONAL_ACCESS_TOKEN>" \
https://api.github.com/repos/<OWNER>/<REPO>/dispatches \
-d '{"event_type": "trigger_build", "client_payload": {"production":false,"type":"nightly","branch":"blazium-dev","build_type":["templates","editors"],"force":false,"build":["linux","monoglue","ios","macos","android","web","windows"],"deploy":["templates","editors"]}}'
```

## 🌐 Web Builds - GitHub Action

The **Web Builds** GitHub Action manages the entire build and deployment lifecycle for web-based components of the Blazium Engine. It supports both editors and templates, ensuring compatibility with nightly, prerelease, and release workflows. This action uses Emscripten to compile and optimize the web build, integrates with DigitalOcean Spaces for artifact storage, and notifies **Cerebro** for build tracking and deployment.

---

### Features:
- **Dynamic Version Management**: Updates version information in `version.py` and communicates with Cerebro to track build status.
- **Comprehensive Builds**: Supports multiple configurations for templates and editors with custom `scons` flags.
- **Artifact Storage**: Automatically creates and uploads `.tar.gz` artifacts to DigitalOcean Spaces.
- **Containerization**: Builds Docker images for the web editor, tagged with the latest version and pushed to Docker Hub.
- **Error Handling**: Notifies Cerebro of build success or failure.
- **Streamlined Deployment**: Deploys artifacts to specific environments (`nightly`, `prerelease`, `release`) and creates a web-ready structure.

---

### Inputs:
- **`build_sha`** (required): Commit SHA used to identify the source for the build.
- **`runner_id`** (required): Identifier for the parent runner process.
- **`new_major`** (required): New major version number.
- **`new_minor`** (required): New minor version number.
- **`new_patch`** (required): New patch version number.
- **`new_version`** (required): Full version string (`X.X.X`) for the current build.

---

### Workflow Steps:
1. **Pre-Build Checks**:
   - Verify if a build is required by comparing SHAs (`build.sha`) in the current workflow.
   - Skip builds if `force` is not enabled and the SHA matches the existing artifact.

2. **Editor Builds**:
   - Compiles the web-based editor using Emscripten with custom `scons` flags.
   - Creates tarball archives and uploads artifacts to DigitalOcean Spaces.

3. **Template Builds**:
   - Supports multiple configurations (e.g., with/without threads, `dlink_enabled`).
   - Handles caching for efficient builds.

4. **Deployment**:
   - Creates Docker images for the web editor and pushes them to Docker Hub.
   - Extracts and deploys builds to environments using the `nightly`, `prerelease`, or `release` tags.

5. **Notifications**:
   - Notifies Cerebro at all stages (start, success, failure) for centralized tracking.

---

### Usage:
```yaml
jobs:
  web-build:
    uses: ./.github/workflows/web_builds.yml
    with:
      build_sha: "abc123def456"
      runner_id: "runner-001"
      new_major: "1"
      new_minor: "0"
      new_patch: "2"
      new_version: "1.0.2"
```

## 🏁 Windows Builds - GitHub Action

The **Windows Builds** GitHub Action is designed to handle the complete build lifecycle for the Windows platform in the Blazium Engine. This action supports the compilation of both editors and templates, including Mono-enabled builds, for various architectures such as `x86_64`, `x86_32`, `arm64`, and `arm32`. It integrates with Cerebro for build notifications, leverages DigitalOcean Spaces for artifact storage, and ensures robust build and deployment workflows.

---

### Features:
- **Flexible Build Configurations**: Supports multiple architectures and configurations, including Mono-enabled builds for both editors and templates.
- **Efficient Build Management**:
  - Checks existing `build.sha` files to determine if a new build is necessary.
  - Uses caching for faster rebuilds.
- **Cross-Platform Dependency Setup**: Installs necessary libraries and SDKs, such as Direct3D, Mesa, and ANGLE, for building Windows-specific targets.
- **Artifact Management**: Automatically creates `.tar.gz` archives of build outputs and uploads them to DigitalOcean Spaces.
- **Version Management**: Updates `version.py` with new version details and integrates seamlessly with Cerebro for build tracking and reporting.
- **Error Handling**: Notifies Cerebro of both build successes and failures, ensuring traceability and debugging capabilities.

---

### Inputs:
- **`build_sha`** (required): Commit SHA used to identify the source for the build.
- **`runner_id`** (required): Unique identifier for the runner process.
- **`new_major`** (required): Major version number.
- **`new_minor`** (required): Minor version number.
- **`new_patch`** (required): Patch version number.
- **`new_version`** (required): Full version string (`X.X.X`) for the current build.

---

### Workflow Overview:
1. **Pre-Build Checks**:
   - Verifies whether a build is necessary by comparing `build.sha` files.
   - Provides granular control for forcing builds regardless of SHA comparison.

2. **Editor Builds**:
   - Compiles editor binaries for `x86_64`, `x86_32`, `arm64`, and `arm32` architectures.
   - Supports Mono-enabled builds for enhanced compatibility with C#.

3. **Template Builds**:
   - Builds release and debug templates with optional Mono support.
   - Configurable for various architectures, including ARM.

4. **Dependency Management**:
   - Installs required Windows-specific libraries, SDKs, and toolchains.
   - Downloads and configures Mono glue and graphics libraries like ANGLE and Mesa.

5. **Artifact Handling**:
   - Packages build outputs into `.tar.gz` archives for easy distribution.
   - Uploads artifacts to DigitalOcean Spaces for storage and retrieval.

6. **Notifications**:
   - Integrates with Cerebro for tracking build progress, success, and failure.

---

### Example Usage:
```yaml
jobs:
  windows-build:
    uses: ./.github/workflows/windows_builds.yml
    with:
      build_sha: "abc123def456"
      runner_id: "runner-001"
      new_major: "1"
      new_minor: "0"
      new_patch: "2"
      new_version: "1.0.2"
```

## Mono Glue Build - GitHub Action

The **Mono Glue Build** GitHub Action is a specialized workflow designed to generate and package Mono glue for the Blazium Engine. This action builds Mono-enabled editor components, creates NuGet packages, and archives Mono glue files for deployment. It integrates with Cerebro for build tracking and uses DigitalOcean Spaces for artifact storage, ensuring a smooth and efficient build process for Mono support in the engine.

---

### Features:
- **Efficient Build Management**:
  - Checks existing `build.sha` files to avoid unnecessary builds.
  - Supports forced builds for complete flexibility.
- **Mono Glue Generation**:
  - Compiles the editor with Mono support for `linuxbsd`.
  - Generates Mono glue and packages it into distributable archives.
- **NuGet Integration**:
  - Builds C# assemblies and pushes them to NuGet.
  - Supports signed NuGet packages for secure distribution.
- **Artifact Management**:
  - Creates `.tar.gz` archives of Mono glue files.
  - Uploads build outputs and `build.sha` files to DigitalOcean Spaces.
- **Notification System**:
  - Notifies Cerebro of build progress, success, and failure.
  - Tracks build details, including version, checksum, and deployment type.

---

### Inputs:
- **`build_sha`** (required): The commit SHA for the source code used in the build.
- **`runner_id`** (required): A unique identifier for the runner.
- **`new_major`** (required): Major version number.
- **`new_minor`** (required): Minor version number.
- **`new_patch`** (required): Patch version number.
- **`new_version`** (required): Full version string (`X.X.X`) for the current build.

---

### Workflow Overview:
1. **Pre-Build Checks**:
   - Verifies the necessity of a new build using `build.sha`.
   - Allows forced builds for testing or updates.

2. **Mono Glue Compilation**:
   - Restores dependencies and prepares the build environment.
   - Compiles the editor with Mono support and generates Mono glue files.

3. **NuGet Packaging**:
   - Builds C# assemblies and pushes them to NuGet with authentication.
   - Supports signed packages for enhanced security.

4. **Artifact Creation and Upload**:
   - Archives Mono glue files and uploads them to DigitalOcean Spaces.
   - Ensures accessibility and storage for deployment purposes.

5. **Notifications**:
   - Tracks and reports build status (success or failure) via Cerebro.

---

### Example Usage:
```yaml
jobs:
  monoglue-build:
    uses: ./.github/workflows/monoglue_build.yml
    with:
      build_sha: "abc123def456"
      runner_id: "runner-001"
      new_major: "1"
      new_minor: "0"
      new_patch: "2"
      new_version: "1.0.2"
```

## 🐧 Linux Builds GitHub Action

This workflow manages the Linux builds for the Blazium Engine, supporting both editor and template builds across multiple architectures and configurations. It is triggered via `workflow_call` and integrates version tracking, dependency management, caching, and artifact uploading. The workflow ensures builds are efficient, robust, and properly reported to the Cerebro system.

---

### Features

- **Supports multiple architectures and configurations:**
  - x86_64, x86_32, arm64, arm32.
  - Mono-enabled and standard builds.
  - Debug and release templates.

- **Dependency Management:**
  - Ensures required libraries and tools are installed.
  - Installs architecture-specific dependencies dynamically.

- **Build Cache Integration:**
  - Restores and saves build caches to optimize performance.

- **Artifact Management:**
  - Creates `.tar.gz` archives for build outputs.
  - Uploads artifacts to DigitalOcean Spaces for distribution.

- **Version Control:**
  - Updates `version.py` with new build version details.
  - Tracks `build.sha` for validation and reusability.

- **Notifications:**
  - Sends build progress and status updates to the Cerebro system.
  - Reports success or failure with detailed metadata.

---

### Inputs

| Name          | Description                                    | Required | Type   |
|---------------|------------------------------------------------|----------|--------|
| `build_sha`   | Build commit SHA to use for this job           | ✅       | String |
| `runner_id`   | Runner ID of the parent runner                 | ✅       | String |
| `new_major`   | New major version number                       | ✅       | String |
| `new_minor`   | New minor version number                       | ✅       | String |
| `new_patch`   | New patch version number                       | ✅       | String |
| `new_version` | Full version string for this build             | ✅       | String |

---

### Jobs Overview

#### `editor-check`
Verifies whether the editor needs to be rebuilt based on `build.sha` or if a forced build is requested.

#### `template-check`
Checks if templates require a rebuild, similar to `editor-check`.

#### `build-editors`
Compiles editor builds across architectures:
- Handles x86_64, x86_32, arm64, and arm32 builds.
- Supports Mono-enabled builds.
- Skips builds marked with `skip: true`.

#### `build-templates`
Compiles templates across configurations:
- Supports debug and release builds.
- Handles Mono-enabled and standard builds.

#### `template-success` & `editor-success`
Uploads `build.sha` for version verification and reports success to Cerebro.

---

## Steps

### 1. **Dependency Installation**
Installs necessary dependencies for Linux builds, including 32-bit architecture support and Vulkan drivers.

### 2. **Cache Management**
Restores previously saved build caches and saves new caches post-build.

### 3. **Compilation**
Uses the `godot-build` action to compile the editor or templates with architecture-specific configurations.

### 4. **Artifact Creation**
Creates `.tar.gz` archives for the compiled binaries.

### 5. **Artifact Upload**
Uploads build artifacts to DigitalOcean Spaces, organized by deployment type.

### 6. **Cerebro Integration**
Notifies Cerebro of build start, success, or failure, ensuring transparency and traceability.

---

## Example Usage

```yaml
jobs:
  linux-build:
    uses: ./.github/workflows/linux_builds.yml
    with:
      build_sha: "abc123def456"
      runner_id: "runner-001"
      new_major: "1"
      new_minor: "0"
      new_patch: "3"
      new_version: "1.0.3"
```

# 🍎 macOS Builds GitHub Action

This workflow automates the process of building and packaging the Blazium Engine for macOS, supporting both editor and template builds with Mono and non-Mono configurations. It integrates version tracking, caching, artifact management, and internal service notifications via the **Cerebro** system.

---

## Features

### ✅ Multi-Architecture Support
- Builds for both **x86_64** and **arm64** architectures.
- Creates **universal binaries** using `lipo`.

### ✅ Configuration Support
- Handles Mono-enabled and standard builds.
- Supports `template_release` and `template_debug` targets for templates.
- Builds with and without production optimizations.

### ✅ Artifact Management
- Generates `.tar.gz` and `.zip` packages for editor and template builds.
- Uploads artifacts to DigitalOcean Spaces.

### ✅ Caching
- Restores and saves build caches for efficient builds.

### ✅ Version Tracking
- Updates version information in `version.py`.
- Tracks `build.sha` for validation.

### ✅ Notifications
- Integrates with **Cerebro**, the internal service for Blazium Engine, to notify about build progress, success, and failures.

---

## Inputs

| **Input Name**  | **Description**                     | **Required** | **Type**  |
|------------------|-------------------------------------|--------------|-----------|
| `build_sha`      | Build commit SHA for the job.       | ✅            | `string`  |
| `runner_id`      | Runner ID of the parent runner.     | ✅            | `string`  |
| `new_major`      | New major version number.           | ✅            | `string`  |
| `new_minor`      | New minor version number.           | ✅            | `string`  |
| `new_patch`      | New patch version number.           | ✅            | `string`  |
| `new_version`    | Full version string to deploy.      | ✅            | `string`  |

---

## Workflow Jobs

### **`editor-check`**
- Verifies if an editor rebuild is necessary based on `build.sha`.
- Skips compilation if no changes are detected and `force` is not set.

### **`template-check`**
- Similar to `editor-check`, but for templates.
- Ensures unnecessary builds are avoided.

### **`build-editors`**
- Builds the editor for macOS:
  - Supports Mono-enabled and standard builds.
  - Handles `x86_64` and `arm64` architectures.
  - Merges architectures into universal binaries.
- Signs and packages the editor application.

### **`build-templates`**
- Compiles `template_release` and `template_debug` for macOS:
  - Mono and non-Mono builds supported.
  - Creates universal binaries for `x86_64` and `arm64`.

### **`editor-success` & `template-success`**
- Uploads `build.sha` for future validation.
- Reports success to Cerebro.

---

## Steps Overview

### 1. **Checkout and Version Update**
- Pulls the latest code and submodules.
- Updates `version.py` with the new version details.

### 2. **Dependency Setup**
- Installs necessary dependencies, including Mono, Python, and Vulkan SDK for macOS builds.

### 3. **Build Process**
- Compiles editor and templates for both `x86_64` and `arm64`.
- Combines builds into universal binaries using `lipo`.

### 4. **Packaging and Signing**
- Packages the editor and templates into `.app` bundles.
- Signs the applications using macOS code signing.

### 5. **Artifact Management**
- Archives builds into `.tar.gz` and `.zip` files.
- Uploads to DigitalOcean Spaces.

### 6. **Cerebro Notifications**
- Sends build progress, success, or failure notifications to the internal **Cerebro** system.

---

## Example Usage

```yaml
jobs:
  macos-build:
    uses: ./.github/workflows/macos_builds.yml
    with:
      build_sha: "abc123def456"
      runner_id: "runner-001"
      new_major: "1"
      new_minor: "0"
      new_patch: "3"
      new_version: "1.0.3"
```

# 🍏 iOS Builds GitHub Action

This workflow automates the process of building and packaging Blazium Engine templates for iOS, supporting Mono and non-Mono configurations, and creating XCFrameworks for release and debug templates. It integrates with the internal **Cerebro** service for build notifications and includes caching, artifact management, and dependency setup.

---

## Features

### ✅ Multi-Architecture Support
- **ARM64** builds for iOS devices.
- **x86_64** builds for iOS simulators.
- Combines architecture-specific builds into **XCFrameworks**.

### ✅ Configurable Build Types
- Supports `template_release` and `template_debug` targets.
- Allows Mono and non-Mono builds.
- Supports production builds with optional LTO (Link-Time Optimization).

### ✅ Caching and Artifacts
- Restores and saves build caches to improve efficiency.
- Creates `.tar.gz` and `.zip` artifacts for templates.

### ✅ Notifications
- Sends build progress, success, and failure updates to the **Cerebro** service.

---

## Inputs

| **Input Name**  | **Description**                     | **Required** | **Type**  |
|------------------|-------------------------------------|--------------|-----------|
| `build_sha`      | Build commit SHA for the job.       | ✅            | `string`  |
| `runner_id`      | Runner ID of the parent runner.     | ✅            | `string`  |
| `new_major`      | New major version number.           | ✅            | `string`  |
| `new_minor`      | New minor version number.           | ✅            | `string`  |
| `new_patch`      | New patch version number.           | ✅            | `string`  |
| `new_version`    | Full version string to deploy.      | ✅            | `string`  |

---

## Workflow Jobs

### **`template-check`**
- Verifies if a rebuild is necessary by comparing the `build.sha`.
- Skips unnecessary builds unless `force` is set.

### **`build-templates`**
- Builds templates for iOS, creating the following artifacts:
  - **ARM64** libraries for devices.
  - **x86_64** libraries for simulators.
  - Combines these into **XCFrameworks** for `template_release` and `template_debug`.

### **`template-success`**
- Uploads the `build.sha` for validation.
- Reports success to the **Cerebro** service.

---

## Steps Overview

### 1. **Checkout and Version Update**
- Clones the repository and checks out the specified `build_sha`.
- Updates version details in `version.py`.

### 2. **Dependency Setup**
- Downloads and extracts **MoltenVK** for Vulkan support.
- Installs Vulkan SDK and Python dependencies.

### 3. **Compilation**
- Builds the `template_release` and `template_debug` targets for:
  - **ARM64** (iOS devices).
  - **x86_64** (iOS simulators).
- Utilizes `SCons` for the build process.

### 4. **XCFramework Creation**
- Combines architecture-specific builds into **XCFrameworks**.
- Packages frameworks and Vulkan dependencies.

### 5. **Artifact Management**
- Archives XCFrameworks and uploads them to DigitalOcean Spaces.

### 6. **Cerebro Notifications**
- Sends updates on build progress, success, or failure to **Cerebro**.

---

## Example Usage

```yaml
jobs:
  ios-build:
    uses: ./.github/workflows/ios_builds.yml
    with:
      build_sha: "abc123def456"
      runner_id: "runner-001"
      new_major: "1"
      new_minor: "0"
      new_patch: "3"
      new_version: "1.0.3"
```

# 🤖 Android Builds GitHub Action

This GitHub Action automates the building and packaging process for Android editors and templates for the **Blazium Engine**. It supports multiple architectures and Mono configurations while integrating with **Cerebro** for build notifications and leveraging advanced caching mechanisms.

---

## Features

### ✅ Multi-Architecture Support
- **ARM32**, **ARM64**, **x86_32**, and **x86_64** architectures supported.
- Separate configurations for Android templates and editors.

### ✅ Mono and Non-Mono Builds
- Builds with and without Mono support for both editors and templates.

### ✅ Automated Caching and Artifact Management
- Restores and saves build caches to improve efficiency.
- Generates `.tar.gz` archives for easy distribution.
- Uploads artifacts to DigitalOcean Spaces for persistent storage.

### ✅ Integration with **Cerebro**
- Sends real-time build progress, success, and failure notifications to the internal Cerebro service.

---

## Inputs

| **Input Name**  | **Description**                     | **Required** | **Type**  |
|------------------|-------------------------------------|--------------|-----------|
| `build_sha`      | Build commit SHA for the job.       | ✅            | `string`  |
| `runner_id`      | Runner ID of the parent runner.     | ✅            | `string`  |
| `new_major`      | New major version number.           | ✅            | `string`  |
| `new_minor`      | New minor version number.           | ✅            | `string`  |
| `new_patch`      | New patch version number.           | ✅            | `string`  |
| `new_version`    | Full version string to deploy.      | ✅            | `string`  |

---

## Workflow Jobs

### **`editor-check`**
- Validates whether a rebuild is necessary for Android editors by comparing the `build.sha`.

### **`template-check`**
- Verifies if Android templates need to be rebuilt.

### **`build-editors`**
- Builds Android editors for supported architectures:
  - **ARM32**
  - **ARM64**
  - **x86_32**
  - **x86_64**

### **`build-templates`**
- Builds Android templates with and without Mono support.
- Generates separate builds for `template_release` and `template_debug`.

### **`template-success`**
- Handles success notifications and uploads the `build.sha` for future validation.

---

## Steps Overview

### 1. **Repository Checkout and Version Update**
- Clones the Blazium Engine repository at the specified `build_sha`.
- Updates version details in `version.py`.

### 2. **Dependency Setup**
- Downloads and configures:
  - Android SDK and Java 17.
  - Pre-built **Swappy Frame Pacing Library**.
  - Vulkan dependencies (for Android).
  - Python and SCons.

### 3. **Compilation**
- Compiles Android editors and templates for all supported architectures using `SCons`.
- Supports `template_release` and `template_debug` targets.

### 4. **Template and Editor Packaging**
- Packages editors and templates into `.tar.gz` archives.
- Uploads artifacts to DigitalOcean Spaces for distribution.

### 5. **Integration with Cerebro**
- Sends build progress updates to Cerebro for real-time monitoring.
- Notifies Cerebro of build success or failure.

---

## Example Usage

```yaml
jobs:
  android-build:
    uses: ./.github/workflows/android_build.yml
    with:
      build_sha: "abc123def456"
      runner_id: "runner-001"
      new_major: "1"
      new_minor: "0"
      new_patch: "3"
      new_version: "1.0.3"
```


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
