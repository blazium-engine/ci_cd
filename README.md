# Blazium Engine CI/CD

Actions needed to build engine and templates for the Blazium Engine, as well as deploy them.

# Design Decisions

Dockerfile for macos will not work because of the build size of the container on the github runners (including XCode built, about 20GB), and it will not start build because of the memory limit of the runners.

# Table of contents

1. [Features](#features)
2. [Main Workflow](#main-workflow)

# Features:
- **Multi-Platform Support**: Handles builds for Linux, macOS, Windows, Android, iOS, Web, and Mono Glue configurations.
- **Dynamic Version Management**: Extracts and manages version details from `version.py` and `changelog.json`.
- **Concurrent Job Management**: Ensures efficient job execution with concurrency groups.
- **Custom Payload Triggering**: Uses a repository dispatch event with client payload for tailored job execution.
- **Full Lifecycle Management**: Includes static checks, builds, deployments, and cleanup.

# Main Workflow

- GHA: `.github/workflows/runner.yml` - Orchestrates builds, deployments, and cleanups for the Blazium Engine across multiple operating systems and configurations. It triggers jobs based on a custom payload, enabling tailored workflows for nightly, template, or editor builds, with support for dynamic branching, versioning, and deployment management.

Note: This workflow can also be triggered using the `.github/workflows/trigger_runner.yml` workflow and giving it inputs.

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

## Jobs

These are individual jobs used by the Main Workflow.

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

[Documentation](DOCUMENTATION.md) - More about the jobs and actions in the documentation file.
