const fs = require('fs');
const path = require('path');

// Function to generate a templated changelog from the JSON file
function generateChangelogHTML(jsonFilePath) {
    try {
        // Read the JSON file
        const changelogData = JSON.parse(fs.readFileSync(jsonFilePath, 'utf-8'));

        // Extract data from JSON
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

        // Template: Header Section
        
        let changelogText = 
`<h4>Changelog: ${baseBranch} -> ${currentBranch}</h4>
<h2>Summary:</h2>
<ul>
<li><b>Version</b>: <code>${version["major"]}.${version["minor"]}.${version["patch"]}</code></li>
<li><b>Total Commits</b>: <code>${totalCommits}</code></li>
<li><b>Total PRs</b>: <code>${totalPRs}</code></li>
<li><b>Total Files Changed</b>: <code>${totalFilesChanged}</code></li>
<li><b>Time Since First Change</b>: <code>${timeSinceFirstChange}</code></li>
<li><b>Time Since Last Change</b>: <code>${timeSinceLastChange}</code></li>
<li><b>Total Contributors</b>: <code>${totalContributors}</code></li>
</ul>
<hr>
<details><summary><h2>Commits and PRs:</h2></summary>`;

        // Template: Commits and PRs Section
        changelog.forEach((entry) => {
            if (!entry.pr) {
                var [message, details] = entry.message.split(/\n\n/);
                changelogText +=
`<details><summary><b>${message}</b></summary>
<blockquote>
Commit SHA: ${entry.sha}<br>
Date: <code>${new Date(entry.date).toLocaleString()}</code><br>
Author: <b>${entry.user}</b>
</blockquote>${details ? details.replace(/\n/g, "<br>") : ""}
<hr></details>`;
            } 
        });

        changelogText += `</details><details><summary><h2>Contributors:</h2></summary><ul>`;

        // Template: Contributors Section
        uniqueContributors.forEach((contributor) => {
            changelogText += `<li><b>${contributor.username}</b>: <code>${contributor.contributions} contributions</code></li>`;
        });
        changelogText += `</ul></details>`
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
