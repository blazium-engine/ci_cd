const fs = require('fs');
const path = require('path');

// Function to generate a templated changelog from the JSON file
function generateChangelogText(jsonFilePath) {
    try {
        // Read the JSON file
        const rawData = fs.readFileSync(jsonFilePath, 'utf-8');
        const changelogData = JSON.parse(rawData);

        // Validate JSON structure
        if (!changelogData || typeof changelogData !== "object") {
            throw new Error("Invalid JSON structure.");
        }

        const {
            baseBranch,
            currentBranch,
            totalCommits,
            totalPRs,
            totalFilesChanged,
            timeSinceFirstChange,
            timeSinceLastChange,
            totalContributors,
            contributors,
            changelog,
            version
        } = changelogData;

        // Ensure `changelog` is an array before iterating
        if (!Array.isArray(changelog)) {
            throw new Error("Changelog data is missing or invalid in the JSON file.");
        }

        // Template: Header Section
        let changelogText = `Changelog: ${baseBranch} -> ${currentBranch}

Summary:
- Build Type: ${version?.build_type || ""}
- Version: ${version?.major || 0}.${version?.minor || 0}.${version?.patch || 0}
- Total Commits: ${totalCommits || 0}
- Total PRs: ${totalPRs || 0}
- Total Files Changed: ${totalFilesChanged || 0}
- Time Since First Change: ${timeSinceFirstChange || 'N/A'}
- Time Since Last Change: ${timeSinceLastChange || 'N/A'}
- Total Contributors: ${totalContributors || 0}

---

Commits and PRs:
`;

        // Template: Commits and PRs Section
        changelog.forEach((entry) => {
            if (entry && !entry.pr) {
                changelogText += `
Commit SHA: ${entry.sha || 'N/A'}
Date: ${entry.date ? new Date(entry.date).toLocaleString() : 'Unknown'}
User: ${entry.user || 'Unknown'}
Message: ${entry.message || 'No message'}
---
`;
            }
        });

        // Template: Contributors Section
        changelogText += `\nContributors:\n`;

        if (Array.isArray(contributors)) {
            contributors.forEach((contributor) => {
                changelogText += `- ${contributor.username || 'Unknown'}: ${contributor.contributions || 0} contributions\n`;
            });
        }

        // Clean up new lines
        const cleanedMessage = changelogText.replace(/\r/g, "");

        // Export the text file
        const outputFilePathDetailed = path.join(__dirname, `changelog_${baseBranch}_to_${currentBranch}.txt`);
        const outputFilePathBase = path.join(__dirname, `changelog.txt`);

        fs.writeFileSync(outputFilePathDetailed, cleanedMessage, 'utf-8');
        fs.writeFileSync(outputFilePathBase, cleanedMessage, 'utf-8');

        console.log(`Changelog exported with detailed name to ${outputFilePathDetailed}`);
        console.log(`Changelog exported with base name to ${outputFilePathBase}`);
    } catch (error) {
        console.error(`Error processing the JSON file: ${error.message}`);
    }
}

// Main function to trigger the changelog generation
function main() {
    const args = process.argv.slice(2); // Get the command line arguments

    if (args.length === 0) {
        console.error('Error: Please provide the path to the JSON file as an argument.');
        process.exit(1); // Exit with an error code
    }

    const jsonFilePath = path.resolve(args[0]);

    // Check if the JSON file exists
    if (!fs.existsSync(jsonFilePath)) {
        console.error(`Error: The file '${jsonFilePath}' does not exist.`);
        process.exit(1); // Exit with an error code
    }

    // Generate the changelog from the provided JSON file
    generateChangelogText(jsonFilePath);
}

// Execute the main function
main();
