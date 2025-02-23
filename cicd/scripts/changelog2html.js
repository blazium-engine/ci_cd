const fs = require('fs');
const path = require('path');

// Function to generate a templated changelog from the JSON file
function generateChangelogHTML(jsonFilePath) {
    try {
        // Read and parse the JSON file
        const rawData = fs.readFileSync(jsonFilePath, 'utf-8');
        const changelogData = JSON.parse(rawData);

        // Validate required keys
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
            uniqueContributors,
            changelog,
            version
        } = changelogData;

        // Check if `changelog` is defined and is an array
        if (!Array.isArray(changelog)) {
            throw new Error("Changelog data is missing or invalid in the JSON file.");
        }

        // Template: Header Section
        let changelogText = 
`<h4>Changelog: ${baseBranch} -> ${currentBranch}</h4>
<h2>Summary:</h2>
<ul>
<li><b>Version</b>: <code>${version?.major || 0}.${version?.minor || 0}.${version?.patch || 0}</code></li>
<li><b>Total Commits</b>: <code>${totalCommits || 0}</code></li>
<li><b>Total PRs</b>: <code>${totalPRs || 0}</code></li>
<li><b>Total Files Changed</b>: <code>${totalFilesChanged || 0}</code></li>
<li><b>Time Since First Change</b>: <code>${timeSinceFirstChange || 'N/A'}</code></li>
<li><b>Time Since Last Change</b>: <code>${timeSinceLastChange || 'N/A'}</code></li>
<li><b>Total Contributors</b>: <code>${totalContributors || 0}</code></li>
</ul>
<hr>
<details><summary><h2>Commits and PRs:</h2></summary>`;

        // Template: Commits and PRs Section
        changelog.forEach((entry) => {
            if (!entry.pr && entry.message) {
                let [message, details] = entry.message.split(/\n\n/);
                changelogText +=
`<details><summary><b>${message}</b></summary>
<blockquote>
Commit SHA: ${entry.sha || 'N/A'}<br>
Date: <code>${entry.date ? new Date(entry.date).toLocaleString() : 'N/A'}</code><br>
Author: <b>${entry.user || 'Unknown'}</b>
</blockquote>${details ? details.replace(/\n/g, "<br>") : ""}
<hr></details>`;
            }
        });

        changelogText += `</details><details><summary><h2>Contributors:</h2></summary><ul>`;

        // Template: Contributors Section
        if (Array.isArray(uniqueContributors)) {
            uniqueContributors.forEach((contributor) => {
                changelogText += `<li><b>${contributor.username || 'Unknown'}</b>: <code>${contributor.contributions || 0} contributions</code></li>`;
            });
        }
        
        changelogText += `</ul></details>`;

        const cleanedMessage = changelogText.replace(/\n/g, "");

        // Export the text file
        const outputFilePathDetailed = path.join(__dirname, `changelog_${baseBranch}_to_${currentBranch}.html`);
        const outputFilePathBase = path.join(__dirname, `changelog.html`);

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
    generateChangelogHTML(jsonFilePath);
}

// Execute the main function
main();
